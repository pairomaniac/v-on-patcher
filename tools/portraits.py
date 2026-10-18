#!/usr/bin/env python3
"""Bake the bosses' select portraits in assets/ into the patcher.

    python3 tools/portraits.py            # bake them in
    python3 tools/portraits.py --check    # the committed blob matches the PNGs

assets/portrait_jaguarandi.png and assets/portrait_z-gradt.png, 48x64
each, framed as the eight's are, go between the BOSS PORTRAITS markers in
v-on-patcher.py as the select's 16-bit colour (RGB565), row by row. Pure
black is the tiles' transparent colour, so it becomes the near-black the
eight's portraits are backed with. Needs Pillow; --check without it says
so and passes, having tested nothing.
"""

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ASSETS = os.path.join(ROOT, 'assets')
PATCHER = os.path.join(ROOT, 'v-on-patcher.py')

SOURCES = ('portrait_jaguarandi.png', 'portrait_z-gradt.png')
SIZE = (48, 64)
GROUND = 0x0020                 # as BOSS_ICON_GROUND in the patcher
BEGIN = '# BOSS PORTRAITS BEGIN - tools/portraits.py\n'
END = '# BOSS PORTRAITS END\n'
WIDTH = 72


def rgb565(image):
    out = bytearray()
    raw = image.tobytes()
    for i in range(0, len(raw), 3):
        r, g, b = raw[i], raw[i + 1], raw[i + 2]
        v = (r >> 3) << 11 | (g >> 2) << 5 | b >> 3
        out += (v or GROUND).to_bytes(2, 'little')
    return bytes(out)


def bake():
    """The block the markers hold, from the PNGs. Returns (block, bytes)."""
    from PIL import Image
    data = b''
    for name in SOURCES:
        image = Image.open(os.path.join(ASSETS, name)).convert('RGB')
        if image.size != SIZE:
            raise SystemExit('%s is %dx%d, not %dx%d'
                             % ((name,) + image.size + SIZE))
        data += rgb565(image)
    text = data.hex()
    lines = [text[i:i + WIDTH] for i in range(0, len(text), WIDTH)]
    return (BEGIN + 'BOSS_PORTRAITS = bytes.fromhex(\n'
            + '\n'.join("    '%s'" % l for l in lines) + ')\n' + END), data


def main():
    check = '--check' in sys.argv
    try:
        block, data = bake()
    except ImportError:
        if check:
            print('Pillow is not installed, so the portraits were not '
                  'rebaked and nothing was compared: pip install pillow')
            return 0
        raise SystemExit('baking needs Pillow: pip install pillow')
    with open(PATCHER, encoding='utf-8') as fh:
        source = fh.read()
    pattern = re.compile(re.escape(BEGIN) + '.*?' + re.escape(END), re.S)
    found = pattern.search(source)
    if not found:
        raise SystemExit('no BOSS PORTRAITS markers in v-on-patcher.py')
    if check:
        if found.group(0) == block:
            print('the committed portraits match assets/portrait_*.png')
            return 0
        print('the committed portraits differ from assets/portrait_*.png: '
              'run python3 tools/portraits.py and commit')
        return 1
    source = pattern.sub(lambda _m: block, source, count=1)
    with open(PATCHER, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(source)
    print('%d portraits, %d bytes -> v-on-patcher.py'
          % (len(SOURCES), len(data)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
