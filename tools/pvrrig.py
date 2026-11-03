#!/usr/bin/env python3
"""Run the PowerVR build through a scripted scene, on a hidden display.

    python3 tools/pvrrig.py SCENE [--exe FILE] [--tag NAME] [--layout ver|hor] [--narrow]

Scenes: title (the title screen and its menu), roll (the ending credits),
sweep (1P select, rightward), bounce (1P select, Apharmd and
Bal-Bas-Bow), round (1P match), split (2P round, a live layout switch, a loss),
select2p (the 2P select with the 3D hangar), bbb and apharmd (1P, a lost round and
the continue), jag and zgradt (1P as a boss, a lost round), fullj and fullz (a whole
game as one, by the debug kill), lastz (the last stage as Z-Gradt), again (Z-Gradt,
game over, Z-Gradt again), igr and igrj (Z-Gradt or Jaguarandi, the reset and the attract demo, again),
hold0, hold and holdz (parked on Temjin, Jaguarandi or Z-Gradt). It captures at 60 FPS and reports frames that are nearly all black
and frames with flat red or blue at the right edge. Screen changes show as black, and the flat-colour count only means something
on the machine select. One game runs at a time; the captures are in the rig's
shots/ folder.

The game comes from VO_GAME_PVR in ~/.vo-test, with its .bak as the original and
pvr-sgl-wrapper's sgl.dll beside it. --exe runs that file; without it the working
tree's patches are applied. The rig is a folder of links with its own Wine prefix,
in $VO_PVR_RIG or ~/.cache/vo-pvr-rig, so the install is not written to. It needs
wine, xvfb-run, xdotool, ffmpeg, i686-w64-mingw32-gcc and Pillow.

The keyboard does not move the title's or the select's cursor in Xvfb, so the 2P
scenes force the title's choice in the rig's copy of the executable, and cursor
moves are written to memory. 2P's view of the select was not reached.
"""

import argparse
import glob
import importlib.util
import os
import re
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

from check import config                                    # noqa: E402

DISPLAY = 91
WRITES = ('vonpvr.exe', 'vonpvr.exe.bak', 'v_on.ini', 'ddraw.ini', 'bkup.bin',
          'pvrsgl.log', 'vo-net.ini', 'bosses.bin')
# Title's choice, read at 0x5aa6a3: forced to two players.
FORCE_2P = 0x5aa6a3, bytes.fromhex('a1c0ccd201'), bytes.fromhex('b801000000')
CURSOR, TURN, HOLD = 0x1df6738, 0x1df6700, 0x1df673c   # what a key press writes
SPLIT_RADIO, KILL_1P, KILL_2P = 0x6a34a4, 0x9c61, 0x9c62


def moves(start, step, cursors):
    """Cursor writes: (position, 1 for rightward or 0 for leftward)."""
    return [(start + i * step, 'move', c, r) for i, (c, r) in enumerate(cursors)]


BOOT = [(5, 'key', 'space'), (8, 'key', 'space')]
ROUND = BOOT + [(10, 'key', 'space'), (13, 'key', 'space'), (16, 'key', 'space'),
                (19, 'key', 'space')]
ROUND2 = ROUND + [(14, 'key', 'KP_0')]


def continue_scene(cursor):
    """1P: pick the machine, lose the first round, sit out the continue."""
    return ('0', False, 62, 10, 50, BOOT + moves(10.5, 1.5, [
        (2, 1), (4, 1), (cursor, 1)]) + [
            (16, 'key', 'space'), (19, 'key', 'space'), (22, 'key', 'space'),
            (25, 'key', 'space'), (36, 'post', 0x111, KILL_1P)])


def boss_scene(cursor):
    """1P with the bosses unlocked: walk the row to a boss, fight, lose. The
    camera slides a machine a move, so the walk goes one at a time."""
    walk = 17 + cursor * 1.4
    return ('0', False, walk + 85, 14, walk + 70, [(t, 'key', 'space') for t in (5, 8, 14)]
            + [(walk + 49, 'key', 'space')]
            + moves(17, 1.4, [(i, 1) for i in range(1, cursor + 1)]) + [
                (walk + 4 + i * 3, 'key', 'space') for i in range(4)] + [
                (walk + 32, 'post', 0x111, KILL_1P)])


def win_scene(cursor):
    """1P as a boss, winning every round by the debug kill, to the ending."""
    return ('0', False, 420, 40, 370, [(t, 'key', 'space') for t in (5, 8, 14)]
            + moves(17, 1.6, [(2, 1), (4, 1), (6, 1), (cursor, 1)])
            + [(t, 'key', 'space') for t in range(25, 410, 3)]
            + [(t + 0.5, 'post', 0x111, KILL_2P) for t in range(38, 410, 4)])


SCENES = {
    # selmode, two players, seconds, capture start and length, events
    'sweep': ('0', False, 25, 9.5, 13.5, BOOT + moves(10.5, 1.5, [
        (i, 1) for i in range(1, 8)])),
    'bounce': ('0', False, 25, 9.5, 13.5, BOOT + moves(10.5, 1.35, [
        (2, 1), (4, 1), (5, 1), (6, 1), (5, 0), (6, 1), (5, 0), (6, 1), (5, 0)])),
    'round': ('0', False, 40, 20, 18, ROUND),
    'title': ('0', False, 26, 8, 16, [(5, 'key', 'space'), (15, 'key', 'space')]),
    'roll': ('0', False, 120, 28, 90, ROUND + [(30, 'poke', 0x200c5b0, 0x1f), (80, 'key', 'space')]),
    'split': ('2', True, 70, 25, 40, ROUND2 + [
        (35, 'poke', SPLIT_RADIO, 0), (44, 'post', 0x111, KILL_2P)]),
    'select2p': ('0', True, 25, 9.5, 13.5, BOOT + moves(10.5, 1.3, [
        (i, 1) for i in range(1, 6)])),
    'lastz': ('0', False, 75, 18, 55, [(t, 'key', 'space') for t in (5, 8, 14)]
              + moves(17, 1.6, [(2, 1), (4, 1), (6, 1), (9, 1)]) + [
                  (t / 2, 'poke', 0x200a29c, 9) for t in range(48, 70)] + [
                  (25, 'key', 'space'), (28, 'key', 'space'), (31, 'key', 'space'),
                  (34, 'key', 'space')] + [(t + 0.5, 'post', 0x111, KILL_2P) for t in range(38, 74, 4)]
              + [(t, 'key', 'space') for t in range(37, 74, 3)]),
    'fullj': win_scene(8),
    'fullz': win_scene(9),
    'igr': ('0', False, 125, 14, 108, [(t, 'key', 'space') for t in (5, 8, 14)]
            + moves(17, 1.4, [(i, 1) for i in range(1, 10)]) + [
                (31, 'key', 'space'), (58, 'poke', 0x200b760, -1)]
            + [(t, 'key', 'space') for t in (65, 68, 79, 82)]
            + [(89, 'key', 'space')]),
    'hold': ('0', False, 62, 14, 45, [(t, 'key', 'space') for t in (5, 8, 14)]
             + moves(17, 1.4, [(i, 1) for i in range(1, 9)])),
    'holdz': ('0', False, 62, 14, 45, [(t, 'key', 'space') for t in (5, 8, 14)]
              + moves(17, 1.4, [(i, 1) for i in range(1, 10)])),
    'hold0': ('0', False, 45, 14, 28, [(t, 'key', 'space') for t in (5, 8, 14)]),
    'igrj': ('0', False, 125, 14, 108, [(t, 'key', 'space') for t in (5, 8, 14)]
             + moves(17, 1.4, [(i, 1) for i in range(1, 9)]) + [
                 (31, 'key', 'space'), (58, 'poke', 0x200b760, -1)]
             + [(t, 'key', 'space') for t in (65, 68, 79, 82, 88)]),
    'again': ('0', False, 145, 14, 128, [(t, 'key', 'space') for t in (5, 8, 14)]
              + moves(17, 1.4, [(i, 1) for i in range(1, 10)]) + [
                  (34, 'key', 'space'), (37, 'key', 'space'), (40, 'key', 'space'),
                  (43, 'key', 'space'), (60, 'post', 0x111, KILL_1P)]
              + [(t, 'key', 'space') for t in (92, 97)]
              + moves(101, 1.4, [(i, 1) for i in range(1, 10)])),
    'jag': boss_scene(8),
    'zgradt': boss_scene(9),
    'bbb': continue_scene(5),
    'apharmd': continue_scene(6),
}


def load_patcher():
    spec = importlib.util.spec_from_file_location(
        'vp', os.path.join(ROOT, 'v-on-patcher.py'))
    vp = importlib.util.module_from_spec(spec)
    sys.modules['vp'] = vp
    spec.loader.exec_module(vp)
    return vp


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
    vp = load_patcher()
    with open(os.path.join(game, 'vonpvr.exe.bak'), 'rb') as fh:
        original = fh.read()
    wanted = {key: True for key in vp.PVR.patches}
    if narrow:
        del wanted['hires']
    buf = vp.apply_selected(bytearray(original), wanted, vp.PVR)[0]
    vp.stamp_version(buf, vp.PVR)
    stock = []
    for name in (vp.SCRSTFCG, vp.SCRSTFMP):
        path = os.path.join(game, name)
        if os.path.exists(path + '.bak'):
            path += '.bak'
        with open(path, 'rb') as fh:
            stock.append(fh.read())
    for name, data in zip((vp.SCRSTFCG, vp.SCRSTFMP),
                          vp.credit_roll(stock[0], stock[1], vp.PVR)):
        path = os.path.join(folder, name)
        if os.path.lexists(path):
            os.remove(path)             # a link into the install
        with open(path, 'wb') as fh:
            fh.write(data)
    return buf


def play(folder, helper, out, seconds, start, length, events):
    """Inside xvfb-run: start the game, keep to the events, capture."""
    game = subprocess.Popen(['wine', 'vonpvr.exe'], cwd=folder,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    began = time.time()
    capture = None

    def tool(*args):
        subprocess.run(['wine', helper] + [str(a) for a in args],
                       capture_output=True)

    def key(name):
        found = subprocess.run(['xdotool', 'search', '--onlyvisible', '--name',
                                '.+'], capture_output=True, text=True).stdout
        for window in found.split():
            subprocess.run(['xdotool', 'windowfocus', window], capture_output=True)
        subprocess.run(['xdotool', 'keydown', name])
        time.sleep(0.3)
        subprocess.run(['xdotool', 'keyup', name])

    pending = sorted(events, key=lambda e: e[0])
    while time.time() - began < seconds:
        now = time.time() - began
        if capture is None and now >= start:
            capture = subprocess.Popen([
                'ffmpeg', '-v', 'error', '-y', '-f', 'x11grab', '-framerate', '60',
                '-video_size', '1024x576', '-i', os.environ['DISPLAY'],
                '-t', str(length), '-c:v', 'libx264', '-preset', 'ultrafast',
                '-qp', '8', '-pix_fmt', 'yuv444p',
                os.path.join(out, 'cap.mkv')])
        if pending and now >= pending[0][0]:
            event = pending.pop(0)
            if event[1] == 'key':
                key(event[2])
            elif event[1] == 'move':
                tool('poke', '0x%x=%d' % (CURSOR, event[2]),
                     '0x%x=%d' % (TURN, event[3]), '0x%x=20' % HOLD)
            elif event[1] == 'poke':
                tool('poke', '0x%x=%d' % (event[2], event[3]))
            else:
                tool('post', event[2], event[3])
        time.sleep(0.03)
    print('game %s' % ('running at the end' if game.poll() is None else 'EXITED'))
    if capture:
        capture.wait()
    subprocess.run(['wineserver', '-k'], capture_output=True)


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
        folder, helper, out, scene = sys.argv[2:6]
        _sel, _two, seconds, start, length, events = SCENES[scene]
        play(folder, helper, out, seconds, start, length, events)
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
    selmode, two, seconds, _start, _length, _events = SCENES[args.scene]
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
    if two:
        at = FORCE_2P[0] - 0x401000 + 0x400
        if exe[at:at + 5] != FORCE_2P[1]:
            return 'The title choice is not where it should be.'
        exe[at:at + 5] = FORCE_2P[2]
    with open(os.path.join(folder, 'vonpvr.exe'), 'wb') as fh:
        fh.write(exe)
    with open(os.path.join(folder, 'bosses.bin'), 'wb') as fh:
        fh.write((2).to_bytes(4, 'little'))         # both unlocked
    with open(os.path.join(folder, 'v_on.ini'), 'w', newline='') as fh:
        fh.write('[View]\r\nSky=On\r\nOutside=On\r\n[Option]\r\nMovie=Off\r\n'
                 'Motion=1\r\nColorFormat=565\r\nScrSize=0\r\nSSHoriz=%d\r\n'
                 'FieldGraphic=Rich\r\nTexture=7\r\nSelMode=%s\r\n'
                 % (args.layout == 'hor', selmode))
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
    subprocess.run(['timeout', str(seconds + 120), 'xvfb-run', '-n', str(DISPLAY),
                    '-s', '-screen 0 1024x576x24', sys.executable,
                    os.path.abspath(__file__), '_play', folder, helper, out,
                    args.scene], env=env, check=False)
    with open(os.path.join(folder, 'pvrsgl.log'), errors='replace') as fh:
        print('exceptions in pvrsgl.log: %d' % fh.read().count('*** exception'))
    if os.path.exists(os.path.join(out, 'cap.mkv')):
        report(out)
    return None


if __name__ == '__main__':
    sys.exit(main())
