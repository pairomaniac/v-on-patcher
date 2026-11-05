#!/usr/bin/env python3
"""The region table of docs/MAP.md, from the script itself.

    python3 tools/map.py            # print the table
    python3 tools/map.py --write    # replace it in docs/MAP.md
    python3 tools/map.py --check    # exit 1 if docs/MAP.md is stale

Each region starts at the first line matching its anchor, in order, and
ends where the next begins. check.py runs --check.
"""

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SCRIPT = os.path.join(ROOT, 'v-on-patcher.py')
MAP = os.path.join(ROOT, 'docs', 'MAP.md')
BEGIN = '<!-- REGIONS BEGIN: tools/map.py -->'
END = '<!-- REGIONS END -->'

# (anchor regex on the line, region)
REGIONS = [
    (r'', 'header, imports, PE helpers'),
    (r'^# The resolution patch', 'widescreen: the layouts, `UI_CODE`, the port tables, the site builder'),
    (r'^def hires_install', 'widescreen apply: `hires_install`, section append, F4 table'),
    (r'^DISC_IMAGES = ', 'disc images table, `Build` class, annex order'),
    (r'^RETAIL = Build', 'the five builds: symbols, caves, site maps, `unsupported()`'),
    (r'^# SITES JPRE BEGIN', 'generated site maps for three builds (`tools/buildsites.py`), the PowerVR one by hand'),
    (r'^BLOBS = ', 'the blobs, `BLOBS`, and `link()`'),
    (r'^LEVERS_CODE = ', 'banner and credit bitmaps, tile expansion'),
    (r'^FEATURES = ', 'the patch table: `FEATURES`, `BY_KEY`, labels, tips, apply order'),
    (r'^# --- ripping', 'ripping (`RAW = 2352`) and installing (`LOGICAL = 2048`)'),
    (r'^# --- netplay ', 'netplay setup, `SYNC_SITES`, cnc-ddraw, CD audio'),
    (r'^class Patcher', '`Patcher`: reading a file, applying, restoring'),
    (r'^# ASSETS BLOB BEGIN', 'the logo and icon (`tools/assets.py`), then the window strings'),
    (r'^def run_tk', 'the window (`run_tk`), the CLI, `main`'),
]


def table():
    lines = open(SCRIPT, encoding='utf-8').read().splitlines()
    starts = []
    pos = 0
    for pattern, name in REGIONS:
        rx = re.compile(pattern)
        for n in range(pos, len(lines)):
            if rx.match(lines[n]):
                starts.append((n + 1, name, lines[n][:28].rstrip()))
                pos = n + 1
                break
        else:
            raise SystemExit('anchor not found in order: %s' % pattern)
    out = ['| Lines | Region | Starts with |', '| --- | --- | --- |']
    for i, (start, name, first) in enumerate(starts):
        end = starts[i + 1][0] - 1 if i + 1 < len(starts) else len(lines)
        out.append('| %d–%d | %s | `%s` |' % (start, end, name, first))
    return '\n'.join(out)


def main(argv):
    text = table()
    if argv[1:] == []:
        print(text)
        return 0
    doc = open(MAP, encoding='utf-8').read()
    a, b = doc.index(BEGIN), doc.index(END)
    new = doc[:a] + BEGIN + '\n' + text + '\n' + doc[b:]
    if argv[1] == '--check':
        if new != doc:
            print('docs/MAP.md region table is stale: python3 tools/map.py --write')
            return 1
        return 0
    if argv[1] == '--write':
        open(MAP, 'w', encoding='utf-8').write(new)
        return 0
    raise SystemExit(__doc__)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
