#!/usr/bin/env python3
"""Apply the bosses patch to real game files and read the portraits back.

    python3 tools/portraittest.py /path/to/VIRTUAL-ON

CI cannot do this - neither v_on.exe nor escrgame.bin is in the repository -
so run it by hand before tagging, the same as bannertest.py.

The select's portraits of the bosses are tiles the patcher writes into
escrgame.bin (BOSS_ICON_TILES), read by the game through the row the blob
builds. A wrong slot draws another part of the sheet in their place while
every other check passes. So this patches copies of both files, reads the
tiles back from the slots the row names and compares them with the
portraits the patcher started from, and checks the executable carries the
blob's section only when the patch is on. Both files have to restore byte
for byte, and the patch alone must leave bosses.bin unwritten.
"""

import os
import shutil
import struct
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from bannertest import build_of, load_patcher, pristine     # noqa: E402


def read_back(vp, art):
    """The portraits as the game finds them: 48 tiles each, in reading
    order, from the two slots the row builder uses."""
    tiles = []
    for base in vp.BOSS_ICON_TILES:
        for i in range(48):
            off = (base + i) * 128
            if off + 128 > len(art):
                raise AssertionError('tile %d is past the end of the artwork'
                                     % (base + i))
            tiles.append(bytes(art[off:off + 128]))
    return tiles


def section_names(data):
    """The names of the executable's sections, in header order."""
    pe = struct.unpack_from('<I', data, 0x3c)[0]
    nsec = struct.unpack_from('<H', data, pe + 6)[0]
    optsz = struct.unpack_from('<H', data, pe + 20)[0]
    return [data[pe + 24 + optsz + 40 * i:][:8].rstrip(b'\0').decode()
            for i in range(nsec)]


def main(gamedir):
    vp = load_patcher()
    if os.path.isfile(gamedir):
        gamedir = os.path.dirname(gamedir)
    exe_src = vp.game_exe(gamedir) or os.path.join(gamedir, 'v_on.exe')
    build = build_of(vp, exe_src)
    if build is None:
        return 'not found, or not a build with tables: %s' % exe_src
    art_name, _size, art_md5 = build.art
    art_src = os.path.join(gamedir, art_name)
    if not os.path.exists(art_src):
        return 'not found: %s' % art_src

    exe_before, exe_used = pristine(exe_src, build.md5)
    art_before, art_used = pristine(art_src, art_md5)
    for path, data in ((exe_src, exe_before), (art_src, art_before)):
        if data is None:
            return ('%s is not the original and there is no %s.bak holding '
                    'it' % (path, os.path.basename(path)))
    for src, used in ((exe_src, exe_used), (art_src, art_used)):
        if used != src:
            print('note: read %s, not the patched file beside it'
                  % os.path.basename(used))

    section = vp.OWN_SECTIONS['BOSSES'][0]
    work = tempfile.mkdtemp(prefix='vo-portrait-')
    try:
        exe = os.path.join(work, os.path.basename(exe_src))
        art = os.path.join(work, art_name)
        with open(exe, 'wb') as fh:
            fh.write(exe_before)
        with open(art, 'wb') as fh:
            fh.write(art_before)

        patcher = vp.Patcher()
        note, ok = patcher.load(exe)
        if not ok:
            return 'the patcher refused the copy: %s' % note
        ok, log = patcher.apply({'bosses': True})
        if not ok:
            return 'apply failed: %s' % '; '.join(log[-2:])
        print('applied: %s' % ', '.join(l for l in log if 'wrote' in l))

        with open(exe, 'rb') as fh:
            exe_after = fh.read()
        with open(art, 'rb') as fh:
            art_after = fh.read()

        names = section_names(exe_after)
        if section not in names:
            return 'FAILED - %s has no %s section: %s' % (build.exe, section, names)
        got = read_back(vp, art_after)
        want = vp.boss_icon_tiles()
        wrong = sum(1 for a, b in zip(got, want) if a != b)
        print('portraits: %d tiles, %d differ' % (len(want), wrong))
        if wrong or len(got) != len(want):
            return 'FAILED - the portraits do not read back as written'
        changed = sum(1 for a, b in zip(art_before, art_after) if a != b)
        print('%s: %d bytes changed of %d' % (art_name, changed,
                                              len(art_before)))
        if os.path.exists(os.path.join(work, vp.BOSSES_FILE)):
            return 'FAILED - %s written without Pre-unlock' % vp.BOSSES_FILE

        for line in patcher.restore():
            print('restore: %s' % line)
        with open(exe, 'rb') as fh:
            exe_back = fh.read()
        with open(art, 'rb') as fh:
            art_back = fh.read()
        if exe_back != exe_before:
            return 'FAILED - %s did not restore byte for byte' % build.exe
        if art_back != art_before:
            return 'FAILED - %s did not restore byte for byte' % art_name
        print('restore: both files byte for byte')

        # Unticked (the default), the patch appends no section.
        plain, _applied, _skipped = vp.apply_selected(bytearray(exe_before),
                                                      vp.default_state(), build)
        if section in section_names(plain):
            return 'FAILED - %s appended with the patch unticked' % section
        print('unticked: no %s section' % section)
    finally:
        shutil.rmtree(work, ignore_errors=True)

    print('OK')
    return None


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit('Usage: python3 tools/portraittest.py /path/to/VIRTUAL-ON')
    sys.exit(main(sys.argv[1]))
