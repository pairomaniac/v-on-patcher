#!/usr/bin/env python3
"""Run the PowerVR build through a scripted scene, on a hidden display.

    python3 tools/pvrrig.py SCENE [--exe FILE] [--tag NAME] [--layout ver|hor]

Scenes: sweep (1P select, rightward), bounce (1P select, Apharmd and
Bal-Bas-Bow), round (1P match), split (2P round, a live layout switch, a loss),
select2p (the 2P select with the 3D hangar). It captures at 60 FPS and reports
frames that are nearly all black and frames with flat red or blue at the right
edge. Screen changes show as black, and the flat-colour count only means something
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
          'pvrsgl.log', 'vo-net.ini')
# Title's choice, read at 0x5aa6a3: forced to two players.
FORCE_2P = 0x5aa6a3, bytes.fromhex('a1c0ccd201'), bytes.fromhex('b801000000')
CURSOR, TURN, HOLD = 0x1df6738, 0x1df6700, 0x1df673c   # what a key press writes
SPLIT_RADIO, KILL_2P = 0x6a34a4, 0x9c62


def moves(start, step, cursors):
    """Cursor writes: (position, 1 for rightward or 0 for leftward)."""
    return [(start + i * step, 'move', c, r) for i, (c, r) in enumerate(cursors)]


BOOT = [(5, 'key', 'space'), (8, 'key', 'space')]
ROUND = BOOT + [(10, 'key', 'space'), (13, 'key', 'space'), (16, 'key', 'space'),
                (19, 'key', 'space')]
ROUND2 = ROUND + [(14, 'key', 'KP_0')]
SCENES = {
    # selmode, two players, seconds, capture start and length, events
    'sweep': ('0', False, 25, 9.5, 13.5, BOOT + moves(10.5, 1.5, [
        (i, 1) for i in range(1, 8)])),
    'bounce': ('0', False, 25, 9.5, 13.5, BOOT + moves(10.5, 1.35, [
        (2, 1), (4, 1), (5, 1), (6, 1), (5, 0), (6, 1), (5, 0), (6, 1), (5, 0)])),
    'round': ('0', False, 40, 20, 18, ROUND),
    'split': ('2', True, 70, 25, 40, ROUND2 + [
        (35, 'poke', SPLIT_RADIO, 0), (44, 'post', 0x111, KILL_2P)]),
    'select2p': ('0', True, 25, 9.5, 13.5, BOOT + moves(10.5, 1.3, [
        (i, 1) for i in range(1, 6)])),
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
    with open(os.path.join(folder, 'ddraw.ini'), 'w', newline='') as fh:
        fh.write(text)
    helper = os.path.join(rig, 'pvrrig.exe')
    source = os.path.join(HERE, 'pvrrig.c')
    if not os.path.exists(helper) \
            or os.path.getmtime(helper) < os.path.getmtime(source):
        subprocess.run(['i686-w64-mingw32-gcc', '-O1', '-o', helper, source],
                       check=True)
    return rig, folder, helper


def patched(game):
    """The working tree's patches on the original, all of them."""
    vp = load_patcher()
    with open(os.path.join(game, 'vonpvr.exe.bak'), 'rb') as fh:
        original = fh.read()
    wanted = {key: True for key in vp.PVR.patches}
    wanted['hires'] = (1920, 1080)
    return vp.apply_selected(bytearray(original), wanted, vp.PVR)[0]


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
    else:
        exe = bytearray(patched(game))
    if two:
        at = FORCE_2P[0] - 0x401000 + 0x400
        if exe[at:at + 5] != FORCE_2P[1]:
            return 'The title choice is not where it should be.'
        exe[at:at + 5] = FORCE_2P[2]
    with open(os.path.join(folder, 'vonpvr.exe'), 'wb') as fh:
        fh.write(exe)
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
    subprocess.run(['timeout', str(seconds + 120), 'xvfb-run', '-n', str(DISPLAY),
                    '-s', '-screen 0 1280x800x24', sys.executable,
                    os.path.abspath(__file__), '_play', folder, helper, out,
                    args.scene], env=env, check=False)
    with open(os.path.join(folder, 'pvrsgl.log'), errors='replace') as fh:
        print('exceptions in pvrsgl.log: %d' % fh.read().count('*** exception'))
    if os.path.exists(os.path.join(out, 'cap.mkv')):
        report(out)
    return None


if __name__ == '__main__':
    sys.exit(main())
