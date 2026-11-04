#!/usr/bin/env python3
"""Run the PowerVR build through a scripted scene, on a hidden display.

    python3 tools/pvrrig.py SCENE [--exe FILE] [--tag NAME] [--layout ver|hor] [--narrow]

Scenes are in SCENES below and in docs/DEVELOPING.md, The PowerVR rig, which says how a
run works. Some record at 60 FPS and report black and flat-colour frames. Others follow the
game's state and leave screenshots and a contact sheet, sheet.jpg, and stop once they have
them. One game runs at a time; the output is in the rig's shots/ folder.

The game comes from VO_GAME_PVR in ~/.vo-test, with its .bak as the original and
pvr-sgl-wrapper's sgl.dll beside it. --exe runs that file, and a scene that writes a label
of asm/bosses.asm needs it built from the working tree; without --exe the working tree's
patches are applied. The rig is a folder of links with its own Wine prefix,
in $VO_PVR_RIG or ~/.cache/vo-pvr-rig, so the install is not written to. It needs
wine, xvfb-run, xdotool, ffmpeg, i686-w64-mingw32-gcc and Pillow.

The keyboard does not move the title's or the select's cursor in Xvfb, so the 2P
scenes force the title's choice in the rig's copy of the executable, and cursor
moves are written to memory. 2P's view of the select was not reached.
"""

import argparse
import collections
import glob
import importlib.util
import os
import re
import shutil
import struct
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

from check import config                                    # noqa: E402


def load_patcher():
    spec = importlib.util.spec_from_file_location(
        'vp', os.path.join(ROOT, 'v-on-patcher.py'))
    vp = importlib.util.module_from_spec(spec)
    sys.modules['vp'] = vp
    spec.loader.exec_module(vp)
    return vp


VP = load_patcher()
SYMBOLS = VP.PVR.symbols
DISPLAY = 91
WRITES = ('vonpvr.exe', 'vonpvr.exe.bak', 'v_on.ini', 'ddraw.ini', 'bkup.bin',
          'pvrsgl.log', 'vo-net.ini', 'bosses.bin')

# What the patcher's table has.
STATE, STAGE = SYMBOLS['BS_STATEA'], SYMBOLS['BS_STAGEA']
CURSOR, DIFF = SYMBOLS['SELCURSOR'], SYMBOLS['BS_DIFF']
REPORT_FRAME = SYMBOLS['BS_REPCNT']
# What only the rig needs.
FORCE_2P = 0x5aa6a3, bytes.fromhex('a1c0ccd201'), bytes.fromhex('b801000000')   # title's choice
TURN, HOLD = 0x1df6700, 0x1df6738 + 4   # with the cursor, what a key press writes
SPLIT_RADIO, MODE = 0x6a34a4, 0x200b760 # -1 in the mode word is a reset
MISSION_TIME = 0x200b69c
COMMAND, KILL_1P, KILL_2P = 0x111, 0x9c61, 0x9c62

# The game's states and values.
ROUNDS, ROUND_START, ROLL_START, REPORT, ROLL, NAMES = (0xa, 0xb), 0xa, 0x1f, 0x1e, 0x20, 0x17
VERY_HARD, MIDDLE_STAGE, LAST_STAGE = 2, 4, 9
# Jaguarandi's stage is skipped when the missions so far average 1680 units of the time or
# less, as the debug kill's do. A unit is about 1/50 second, and this is over that.
SLOW_MISSIONS = 10000
CARD_FRAME = 0x2a8          # the report's frame with its whole card up
BOTH_BOSSES = 2             # bosses.bin
CARD = 'card'               # a screenshot taken at CARD_FRAME, not after some seconds

# A round is killed this many seconds in. Jaguarandi kills a standing machine in about 5
# seconds. An early kill on the last stage has stuck the game once, and the player's Z-Gradt
# flies in for up to 10 seconds first.
FIRST_KILL, LAST_KILL, Z_KILL = 2, 6, 12

Scene = collections.namedtuple(
    'Scene', 'seconds events capture selmode two unlocks shots',
    defaults=(None, '0', False, BOTH_BOSSES, None))
Scene.__doc__ = """seconds: how long at the most. events: (time, kind, what...). capture: start
and length of a recording. selmode: the ini's SelMode. two: the title forced to two players.
unlocks: bosses.bin. shots: {state: when in it}, and the scene ends when it has them all."""


def moves(start, step, cursors):
    """Cursor writes: (position, 1 for rightward or 0 for leftward)."""
    return [(start + i * step, 'move', c, r) for i, (c, r) in enumerate(cursors)]


def walk_to(cursor):
    """To the select, and along the row one machine at a time, since the camera slides a
    machine a move. It ends by the second this returns, the camera about still."""
    return ([(t, 'key', 'space') for t in (5, 8, 14)]
            + moves(17, 1.4, [(i, 1) for i in range(1, cursor + 1)])), 17 + cursor * 1.4


BOOT = [(5, 'key', 'space'), (8, 'key', 'space')]
ROUND = BOOT + [(10, 'key', 'space'), (13, 'key', 'space'), (16, 'key', 'space'),
                (19, 'key', 'space')]
ROUND2 = ROUND + [(14, 'key', 'KP_0')]


def continue_scene(cursor):
    """1P: pick the machine, lose the first round, sit out the continue."""
    return Scene(62, BOOT + moves(10.5, 1.5, [(2, 1), (4, 1), (cursor, 1)]) + [
        (16, 'key', 'space'), (19, 'key', 'space'), (22, 'key', 'space'),
        (25, 'key', 'space'), (36, 'post', COMMAND, KILL_1P)], capture=(10, 50))


def boss_scene(cursor):
    """1P with the bosses unlocked: walk the row to a boss, fight, lose."""
    events, walk = walk_to(cursor)
    return Scene(walk + 85, events + [(walk + 49, 'key', 'space')] + [
        (walk + 4 + i * 3, 'key', 'space') for i in range(4)] + [
            (walk + 32, 'post', COMMAND, KILL_1P)], capture=(14, walk + 70))


def hold_scene(cursor, seconds):
    """Parked on a machine in the hangar."""
    return Scene(seconds, walk_to(cursor)[0], capture=(14, seconds - 17))


def reset_scene(cursor, presses):
    """A boss, the reset, the attract demo, and the select again."""
    events, _walk = walk_to(cursor)
    return Scene(125, events + [(31, 'key', 'space'), (58, 'poke', MODE, -1)]
                 + [(t, 'key', 'space') for t in presses], capture=(14, 108))


def state_scene(cursor, seconds, shots, can_unlock=False, last=False, unlocks=BOTH_BOSSES,
                kill=FIRST_KILL):
    """1P, driven by the game's state once the pick is settled. can_unlock makes the game one
    that can, Very Hard and nothing lost, from the select on, which is past the write the
    new game's own start would need. last writes the stage to the last until its round."""
    events, walk = walk_to(cursor)
    return Scene(seconds, events
                 + ([(walk + 3, 'clean')] if can_unlock else [])
                 + ([(walk + 3, 'last')] if last else [])
                 + [(walk + 3.5, 'kill', kill), (walk + 4, 'auto')],
                 unlocks=unlocks, shots=shots)


NAME_ENTRY = (0.3, 1.2, 2.7, 3.7, 5.7, 7.5)
A_GAME = {ROUND_START: (1.5,), REPORT: (CARD,), ROLL: (2,), NAMES: (1, 4)}

SCENES = {
    'title': Scene(26, [(5, 'key', 'space'), (15, 'key', 'space')], capture=(8, 16)),
    'roll': Scene(120, ROUND + [(30, 'poke', STATE, ROLL_START), (80, 'key', 'space')],
                  capture=(28, 90)),
    # The select.
    'sweep': Scene(25, BOOT + moves(10.5, 1.5, [(i, 1) for i in range(1, 8)]),
                   capture=(9.5, 13.5)),
    'bounce': Scene(25, BOOT + moves(10.5, 1.35, [
        (2, 1), (4, 1), (5, 1), (6, 1), (5, 0), (6, 1), (5, 0), (6, 1), (5, 0)]),
                    capture=(9.5, 13.5)),
    'select2p': Scene(25, BOOT + moves(10.5, 1.3, [(i, 1) for i in range(1, 6)]),
                      capture=(9.5, 13.5), two=True),
    'hold0': hold_scene(0, 45),
    'hold': hold_scene(8, 62),
    'holdz': hold_scene(9, 62),
    # Rounds.
    'round': Scene(40, ROUND, capture=(20, 18)),
    'split': Scene(70, ROUND2 + [(35, 'poke', SPLIT_RADIO, 0), (44, 'post', COMMAND, KILL_2P)],
                   capture=(25, 40), selmode='2', two=True),
    'bbb': continue_scene(5),
    'apharmd': continue_scene(6),
    # The bosses.
    'jag': boss_scene(8),
    'zgradt': boss_scene(9),
    'igr': reset_scene(9, (65, 68, 79, 82, 89)),
    'igrj': reset_scene(8, (65, 68, 79, 82, 88)),
    'again': Scene(145, walk_to(9)[0] + [
        (34, 'key', 'space'), (37, 'key', 'space'), (40, 'key', 'space'),
        (43, 'key', 'space'), (60, 'post', COMMAND, KILL_1P),
        (92, 'key', 'space'), (97, 'key', 'space')]
                   + moves(101, 1.4, [(i, 1) for i in range(1, 10)]), capture=(14, 128)),
    'fullj': state_scene(8, 400, A_GAME),
    'fullz': state_scene(9, 500, A_GAME, kill=Z_KILL),
    'lastz': state_scene(9, 150, {ROUND_START: (1.5, 5), ROLL: (2,), NAMES: (1, 4)}, last=True,
                         kill=Z_KILL),
    'report': state_scene(8, 200, {REPORT: (CARD,)}),
    # The unlocks: bosses.bin says what is unlocked already.
    'unlock': state_scene(0, 330, {REPORT: (2, 6, CARD), NAMES: NAME_ENTRY}, can_unlock=True,
                          unlocks=0),
    'lastu': state_scene(0, 120, {REPORT: (2, 6), NAMES: NAME_ENTRY}, can_unlock=True, last=True,
                         unlocks=1),
    'unlj': Scene(70, walk_to(8)[0] + [(t, 'key', 'space') for t in (33, 36, 39)] + [
        (44, 'poke', 'unl_on', 8), (44, 'poke', 'unl_t', 0), (44, 'poke', STATE, REPORT)],
                  shots={REPORT: (2, 6)}),
}


def rig_folder(game):
    """The rig: links to the game, and copies of what the game writes."""
    rig = os.environ.get('VO_PVR_RIG', os.path.expanduser('~/.cache/vo-pvr-rig'))
    folder = os.path.join(rig, 'game')
    os.makedirs(folder, exist_ok=True)
    for name in os.listdir(game):
        link = os.path.join(folder, name)
        if name.lower() not in WRITES and not name.startswith('pvrshot') \
                and not os.path.lexists(link):
            os.symlink(os.path.join(game, name), link)
    # cnc-ddraw's GDI renderer: Xvfb has no OpenGL to speak of.
    with open(os.path.join(game, 'ddraw.ini'), newline='') as fh:
        text = fh.read()
    text = re.sub(r'(?m)^renderer=\w+', 'renderer=gdi', text, count=1)
    # And the hidden display's size, whatever a played game saved there.
    for key, value in (('width', '0'), ('height', '0'), ('fullscreen', 'true'),
                       ('windowed', 'false'), ('posX', '0'), ('posY', '0')):
        text = re.sub(r'(?m)^%s=.*?(\r?)$' % key, r'%s=%s\1' % (key, value), text, count=1)
    with open(os.path.join(folder, 'ddraw.ini'), 'w', newline='') as fh:
        fh.write(text)
    helper = os.path.join(rig, 'pvrrig.exe')
    source = os.path.join(HERE, 'pvrrig.c')
    if not os.path.exists(helper) \
            or os.path.getmtime(helper) < os.path.getmtime(source):
        subprocess.run(['i686-w64-mingw32-gcc', '-O1', '-o', helper, source],
                       check=True)
    return rig, folder, helper


def patched(game, folder, narrow=False):
    """The working tree's patches on the original, all of them, and the two
    roll files they go with, as copies in place of the rig's links."""
    with open(os.path.join(game, 'vonpvr.exe.bak'), 'rb') as fh:
        original = fh.read()
    wanted = {key: True for key in VP.PVR.patches}
    if narrow:
        del wanted['hires']
    buf = VP.apply_selected(bytearray(original), wanted, VP.PVR)[0]
    VP.stamp_version(buf, VP.PVR)
    stock = []
    for name in (VP.SCRSTFCG, VP.SCRSTFMP):
        path = os.path.join(game, name)
        if os.path.exists(path + '.bak'):
            path += '.bak'
        with open(path, 'rb') as fh:
            stock.append(fh.read())
    for name, data in zip((VP.SCRSTFCG, VP.SCRSTFMP),
                          VP.credit_roll(stock[0], stock[1], VP.PVR)):
        path = os.path.join(folder, name)
        if os.path.lexists(path):
            os.remove(path)             # a link into the install
        with open(path, 'wb') as fh:
            fh.write(data)
    return buf


def label(folder, name):
    """Where a label of asm/bosses.asm is in the rig's executable: BOSSES opens .vobs."""
    with open(os.path.join(folder, 'vonpvr.exe'), 'rb') as fh:
        exe = fh.read()
    pe = struct.unpack_from('<I', exe, 0x3c)[0]
    count = struct.unpack_from('<H', exe, pe + 6)[0]
    table = pe + 24 + struct.unpack_from('<H', exe, pe + 20)[0]
    for i in range(count):
        at = table + 40 * i
        if exe[at:at + 8].rstrip(b'\0') == b'.vobs':
            base = 0x400000 + struct.unpack_from('<I', exe, at + 12)[0]
            return base + VP.BLOBS['BOSSES'][2][name]
    raise ValueError('no .vobs')


class Run:
    """Inside xvfb-run: the game, a scene's events, and what it is watching."""

    def __init__(self, folder, helper, out, scene):
        self.folder, self.helper, self.out, self.scene = folder, helper, out, scene
        self.shots = scene.shots or {}
        self.left = {(state, when) for state, whens in self.shots.items() for when in whens}
        self.log = open(os.path.join(out, 'states.txt'), 'w')
        self.auto = self.last = self.state = None
        self.since = self.pressed = 0
        self.kill = FIRST_KILL
        self.due = []

    def tool(self, *args):
        return subprocess.run(['wine', self.helper] + [str(a) for a in args],
                              capture_output=True, text=True).stdout

    def peek(self, address):
        got = self.tool('peek', '0x%x' % address).split()
        return int(got[0]) if got else None

    def poke(self, where, value):
        address = label(self.folder, where) if isinstance(where, str) else where
        self.tool('poke', '0x%x=%d' % (address, value))

    def key(self, name, hold=0.3):
        found = subprocess.run(['xdotool', 'search', '--onlyvisible', '--name',
                                '.+'], capture_output=True, text=True).stdout
        for window in found.split():
            subprocess.run(['xdotool', 'windowfocus', window], capture_output=True)
        subprocess.run(['xdotool', 'keydown', name])
        time.sleep(hold)
        subprocess.run(['xdotool', 'keyup', name])

    def shoot(self, now, when):
        name = 'shot_%06.1f_%02x_%s.png' % (now, self.state, when)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'x11grab', '-video_size',
                        '1024x576', '-i', os.environ['DISPLAY'], '-frames:v', '1',
                        os.path.join(self.out, name)])
        self.left.discard((self.state, when))

    def watch(self, now):
        """The state, logged, and the screenshots due in it."""
        got = self.peek(STATE)
        if got != self.state:
            self.state, self.since = got, now
            print('%.1f state 0x%x' % (now, got or 0), file=self.log, flush=True)
            self.due = list(self.shots.get(got, ()))
        if not self.due:
            return
        when = self.due[0]
        if when == CARD:
            frame = self.peek(REPORT_FRAME)
            ready = frame is not None and CARD_FRAME <= frame < 0x7fffffff
        else:
            ready = now - self.since >= when
        if ready:
            self.due.pop(0)
            self.shoot(now, when)

    def drive(self, now):
        """Through the game by its state. A round is killed once it has run a while, a report
        stands 7 seconds so that an unlock's screen is seen, the rest is pressed through."""
        if self.last and self.state not in ROUNDS:
            self.poke(STAGE, LAST_STAGE)
        if self.state in ROUNDS:
            self.last = None
            stage = self.peek(STAGE)
            if stage == MIDDLE_STAGE:
                self.poke(MISSION_TIME, SLOW_MISSIONS)
            wait = LAST_KILL if stage == LAST_STAGE and self.kill < LAST_KILL else self.kill
            if now - self.since > wait and now - self.pressed > 4:
                self.tool('post', COMMAND, KILL_2P)
                self.pressed = now
        elif (self.state != REPORT or now - self.since > 7) and now - self.pressed > 2:
            self.key('space', 1.5 if self.state == ROLL else 0.3)
            self.pressed = now

    def event(self, kind, *what):
        if kind == 'auto':
            self.auto = True
        elif kind == 'last':
            self.last = True
        elif kind == 'kill':
            self.kill = what[0]
        elif kind == 'clean':
            self.tool('pokeb', '0x%x=%d' % (DIFF, VERY_HARD))
            self.poke('unl_clean', 1)
        elif kind == 'key':
            self.key(what[0])
        elif kind == 'move':
            self.tool('poke', '0x%x=%d' % (CURSOR, what[0]),
                      '0x%x=%d' % (TURN, what[1]), '0x%x=20' % HOLD)
        elif kind == 'poke':
            self.poke(*what)
        else:
            self.tool('post', *what)

    def play(self):
        scene = self.scene
        game = subprocess.Popen(['wine', 'vonpvr.exe'], cwd=self.folder,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        began = time.time()
        capture = None
        pending = sorted(scene.events, key=lambda e: e[0])
        while time.time() - began < scene.seconds:
            now = time.time() - began
            if self.shots and not self.left:
                break
            if (self.auto or self.shots) and now > 10:
                self.watch(now)
            if self.auto:
                self.drive(now)
            if capture is None and scene.capture and now >= scene.capture[0]:
                capture = subprocess.Popen([
                    'ffmpeg', '-v', 'error', '-y', '-f', 'x11grab', '-framerate', '60',
                    '-video_size', '1024x576', '-i', os.environ['DISPLAY'],
                    '-t', str(scene.capture[1]), '-c:v', 'libx264', '-preset', 'ultrafast',
                    '-qp', '8', '-pix_fmt', 'yuv444p',
                    os.path.join(self.out, 'cap.mkv')])
            if pending and now >= pending[0][0]:
                self.event(*pending.pop(0)[1:])
            time.sleep(0.03)
        print('game %s after %d seconds' % (
            'running' if game.poll() is None else 'EXITED', time.time() - began))
        if self.left:
            print('screenshots not taken: %s' % sorted(self.left, key=str))
        if capture:
            capture.wait()
        subprocess.run(['wineserver', '-k'], capture_output=True)


def sheet(out):
    """The screenshots, in order, on one image, each captioned with its time and state."""
    from PIL import Image, ImageDraw
    names = sorted(glob.glob(os.path.join(out, 'shot_*.png')))
    if not names:
        print('no screenshots')
        return
    width, height, across = 512, 288, 2
    image = Image.new('RGB', (width * across, height * ((len(names) + 1) // across)))
    draw = ImageDraw.Draw(image)
    for i, name in enumerate(names):
        at = i % across * width, i // across * height
        image.paste(Image.open(name).convert('RGB').resize((width, height)), at)
        now, state, when = os.path.basename(name)[5:-4].split('_')
        draw.text((at[0] + 4, at[1] + 2), '%ss  state 0x%s  %s' % (now, state, when),
                  fill=(255, 255, 0))
    image.save(os.path.join(out, 'sheet.jpg'))
    print('%d screenshots: %s' % (len(names), os.path.join(out, 'sheet.jpg')))


def report(out):
    """Black frames, flat-colour frames and repeats in the capture."""
    from PIL import Image
    import numpy as np
    frames = os.path.join(out, 'frames')
    shutil.rmtree(frames, ignore_errors=True)
    os.makedirs(frames)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i',
                    os.path.join(out, 'cap.mkv'), '-fps_mode', 'passthrough',
                    '-q:v', '3', os.path.join(frames, 'f%05d.jpg')], check=True)
    names = sorted(glob.glob(os.path.join(frames, 'f*.jpg')))
    black, flat, repeats, last = [], [], 0, None
    for i, name in enumerate(names, 1):
        image = Image.open(name)
        grey = np.asarray(image.convert('L').crop((0, 60, 1024, 380)),
                          dtype=np.int16)
        if (grey < 14).mean() > 0.6:
            black.append(i)
        if last is not None and np.abs(grey - last).mean() < 0.15:
            repeats += 1
        last = grey
        edge = np.asarray(image.convert('RGB').crop((820, 30, 1024, 430)),
                          dtype=np.int16)
        r, g, b = edge[..., 0], edge[..., 1], edge[..., 2]
        if (((b > 200) & (r < 70) & (g < 90))
                | ((r > 200) & (g < 50) & (b < 50))).mean() > 0.008:
            flat.append(i)
    print('%d frames, %d repeated' % (len(names), repeats))
    print('black: %d %s' % (len(black), black[:24]))
    print('flat colour at the right edge: %d %s' % (len(flat), flat[:24]))
    print('frames in %s' % frames)


def main():
    if len(sys.argv) > 1 and sys.argv[1] == '_play':
        folder, helper, out, name = sys.argv[2:6]
        Run(folder, helper, out, SCENES[name]).play()
        return None
    parser = argparse.ArgumentParser(description='Script the PowerVR build.')
    parser.add_argument('scene', choices=sorted(SCENES))
    parser.add_argument('--exe')
    parser.add_argument('--tag')
    parser.add_argument('--narrow', action='store_true',
                        help='without Native widescreen')
    parser.add_argument('--layout', choices=('ver', 'hor'), default='hor')
    args = parser.parse_args()
    game = os.environ.get('VO_GAME_PVR') or config().get('VO_GAME_PVR')
    if not game:
        return 'Set VO_GAME_PVR in ~/.vo-test.'
    rig, folder, helper = rig_folder(game)
    scene = SCENES[args.scene]
    if args.exe:
        with open(args.exe, 'rb') as fh:
            exe = bytearray(fh.read())
        for name in ('scrstfcg.bin', 'scrstfmp.bin'):   # stock, not the last run's
            stock = os.path.join(game, name)
            if os.path.exists(stock + '.bak'):
                stock += '.bak'
            link = os.path.join(folder, name)
            if os.path.lexists(link):
                os.remove(link)
            os.symlink(stock, link)
    else:
        exe = bytearray(patched(game, folder, args.narrow))
    if scene.two:
        at = FORCE_2P[0] - 0x401000 + 0x400
        if exe[at:at + 5] != FORCE_2P[1]:
            return 'The title choice is not where it should be.'
        exe[at:at + 5] = FORCE_2P[2]
    with open(os.path.join(folder, 'vonpvr.exe'), 'wb') as fh:
        fh.write(exe)
    with open(os.path.join(folder, 'bosses.bin'), 'wb') as fh:
        fh.write(scene.unlocks.to_bytes(4, 'little'))
    with open(os.path.join(folder, 'v_on.ini'), 'w', newline='') as fh:
        fh.write('[View]\r\nSky=On\r\nOutside=On\r\n[Option]\r\nMovie=Off\r\n'
                 'Motion=1\r\nColorFormat=565\r\nScrSize=0\r\nSSHoriz=%d\r\n'
                 'FieldGraphic=Rich\r\nTexture=7\r\nSelMode=%s\r\n'
                 % (args.layout == 'hor', scene.selmode))
    out = os.path.join(rig, 'shots', args.tag or args.scene)
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    env = dict(os.environ, WINEPREFIX=os.path.join(rig, 'prefix'), WINEDEBUG='-all',
               WINEDLLOVERRIDES='ddraw=n,b;winemenubuilder.exe=d;mscoree=d;mshtml=d')
    if not os.path.isdir(env['WINEPREFIX']):        # not during a scene's clock
        subprocess.run(['xvfb-run', '-n', str(DISPLAY), 'wineboot', '-i'], env=env,
                       capture_output=True)
        subprocess.run(['wineserver', '-w'], env=env, capture_output=True)
    # No audio driver in the rig's prefix, so the runs are silent.
    subprocess.run(['wine', 'reg', 'add', r'HKCU\Software\Wine\Drivers', '/v', 'Audio',
                    '/d', '', '/f'], env=env, capture_output=True)
    subprocess.run(['wineserver', '-w'], env=env, capture_output=True)
    subprocess.run(['timeout', str(scene.seconds + 120), 'xvfb-run', '-n', str(DISPLAY),
                    '-s', '-screen 0 1024x576x24', sys.executable,
                    os.path.abspath(__file__), '_play', folder, helper, out,
                    args.scene], env=env, check=False)
    with open(os.path.join(folder, 'pvrsgl.log'), errors='replace') as fh:
        print('exceptions in pvrsgl.log: %d' % fh.read().count('*** exception'))
    if os.path.exists(os.path.join(out, 'cap.mkv')):
        report(out)
    if scene.shots:
        sheet(out)
    return None


if __name__ == '__main__':
    sys.exit(main())
