#!/usr/bin/env python3
"""Does the credit line read back out of the patched files as written?

Same idea as bannertest.py, one layer further in. The line is spread over
three files - the block list in the executable, the cells in scrstfmp.bin
and the tiles in scrstfcg.bin - and a mistake in any one of them shows up
as garbage in the roll rather than as a failure anywhere else.

So this patches a copy, walks the block list the way 0x448d39 does, pulls
the cells for the two new blocks, expands them back through the tile sheet,
and compares the pixels against the bitmap the patcher started from.

    python3 tools/credittest.py /path/to/VIRTUAL-ON

CI cannot run it: none of the three files is in the repository.
"""

import hashlib
import os
import shutil
import struct
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))


def pristine(path, want):
    """The unmodified file, from `path` or from the backup beside it.

    A development copy of the game is usually patched, which is the whole
    point of having one. selftest.py and bannertest.py both do this; without
    it the first site to be checked fails on bytes an earlier run wrote."""
    for candidate in (path, path + '.bak'):
        try:
            with open(candidate, 'rb') as fh:
                data = fh.read()
        except OSError:
            continue
        if hashlib.md5(data).hexdigest() == want:
            return data, candidate
    return None, None


def load_patcher():
    import importlib.util
    path = os.path.join(os.path.dirname(HERE), 'v-on-patcher.py')
    spec = importlib.util.spec_from_file_location('v-on-patcher', path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def blocks(exe, vp, build):
    """(flag, width, height) per entry, read the way the renderer does.
    The credit site starts one entry into the table; the table's own start
    is that much before it in every build."""
    roll = vp.roll_of(build)
    if roll.table is not None:
        return [struct.unpack_from('<3I', exe, roll.table + (i - 1) * 12)
                for i in range(200)]
    site = next(off for off, _o, _n in vp.by_key(vp.RETAIL)['credits'][2]
                if not isinstance(off, (vp.At, vp.In))
                and vp.RETAIL.va(off) > vp.CREDIT_TABLE
                and vp.RETAIL.va(off) - vp.CREDIT_TABLE < 12 * 200)
    off = vp.site_in(site, build) - (vp.RETAIL.va(site) - vp.CREDIT_TABLE)
    return [struct.unpack_from('<3I', exe, off + i * 12) for i in range(200)]


def wanted_pixels(vp):
    """The bitmap the patcher was built from, as a set of lit (x, y)."""
    out = []
    for width, height, bits in vp.CREDITS:
        lit = set()
        for y in range(height * 8):
            for x in range(width * 8):
                if bits[y * width + (x >> 3)] >> (7 - (x & 7)) & 1:
                    lit.add((x, y))
        out.append((width, height, lit))
    return out


def place(flag, width):
    """The column the renderer starts this block at.

    Two rules, chosen by the flag at 0x448e5c: below zero centres the block
    on the 51 cells, 0x63 pushes it flush right. The difference is five
    cells for a 42-cell block, and it does not show in the cells themselves,
    so it has to be modelled rather than assumed."""
    if flag & 0x80000000:
        return (0x33 - width) >> 1
    if flag == 0x63:
        return 0x33 - width
    return 0


def got_pixels(cells, sheet, width, vp):
    """Expand one block's cells back into lit (x, y) through the sheet."""
    lit = set()
    for i, cell in enumerate(cells):
        if not cell:
            continue
        tile = (cell & 0x7fff) * 128
        cx, cy = (i % width) * 8, (i // width) * 8
        for k in range(64):
            px = struct.unpack_from('<H', sheet, tile + k * 2)[0]
            if px:
                lit.add((cx + k % 8, cy + k // 8))
    return lit


def main(folder):
    vp = load_patcher()
    tmp = tempfile.mkdtemp(prefix='vo-credit-')
    build = None
    for exe_name in ('v_on.exe', 'vonpvr.exe'):
        for candidate in (exe_name, exe_name + '.bak'):
            try:
                with open(os.path.join(folder, candidate), 'rb') as fh:
                    build = vp.BUILDS.get(hashlib.md5(fh.read()).hexdigest())
            except OSError:
                continue
            if build:
                break
        if build:
            break
    if build is None:
        print('no executable of a build with tables in %s' % folder)
        return 1
    art_name, _size, art_md5 = build.art
    roll = vp.roll_of(build)
    names = (build.exe, vp.SCRSTFCG, vp.SCRSTFMP, art_name)
    try:
        wanted = {build.exe: build.md5,
                  vp.SCRSTFCG: roll.cg_md5,
                  vp.SCRSTFMP: roll.mp_md5,
                  art_name: art_md5}
        for name in names:
            src = os.path.join(folder, name)
            data, used = pristine(src, wanted[name])
            if data is None:
                print('%s: no unmodified copy in %s' % (name, folder))
                print('  neither it nor its .bak has the expected MD5')
                return 1
            if used != src:
                print('  read %s, not the patched file beside it'
                      % os.path.basename(used))
            with open(os.path.join(tmp, name), 'wb') as fh:
                fh.write(data)

        patcher = vp.Patcher()
        note, ok = patcher.load(os.path.join(tmp, build.exe))
        if not ok:
            print('patcher refused the copy: %s' % note)
            return 1
        ok, log = patcher.apply(dict.fromkeys(vp.BY_KEY, True))
        for line in log:
            print('  %s' % line)
        if not ok:
            return 1

        exe = open(os.path.join(tmp, build.exe), 'rb').read()

        # Read the files the way the game does: to the byte counts held at
        # 0x5fdac8 and 0x5fdacc, not to their size on disk. A grown file
        # loads truncated unless the patch grows the constant with it.
        counts = (roll.counts if roll.counts is not None
                  else vp.site_in(0x1fcec8, build))
        cg_size, mp_size = struct.unpack_from('<2I', exe, counts)
        sheet = open(os.path.join(tmp, vp.SCRSTFCG), 'rb').read()
        raw = open(os.path.join(tmp, vp.SCRSTFMP), 'rb').read()
        if (cg_size, mp_size) != (len(sheet), len(raw)):
            print('loader constants say %d+%d bytes, files are %d+%d'
                  % (cg_size, mp_size, len(sheet), len(raw)))
            return 1
        sheet = sheet[:cg_size]
        raw = raw[:mp_size]
        cells = struct.unpack('<%dH' % (len(raw) // 2), raw)

        # The site's patched bytes are committed rather than built at patch
        # time, so check they still match what credit_table() produces. It
        # starts one entry in, at the first spacer, so put the title block
        # back on the front first.
        site = [s for s in vp.BY_KEY['credits'][2] if len(s[1]) > 64][0]
        title = struct.pack('<3I', 0xffffffff, 42, 3)
        rebuilt = vp.credit_table(title + bytes.fromhex(site[1]))
        if rebuilt[12:].hex() != site[2]:
            print('the committed block table is not what credit_table() '
                  'builds - rerun tools/vocredits.py and rebuild the site')
            return 1

        table = blocks(exe, vp, build)
        want = wanted_pixels(vp)

        # Walk to each new block exactly as the renderer accumulates. The
        # spacers become gap, line 1, gap, line 2, gap; the middle gap is
        # inside line 1's block where the build has no entry to spare for it.
        at, bad = 0, 0
        lines = (vp.CREDIT_AFTER + 1,
                 vp.CREDIT_AFTER + (3 if roll.gaps[1] else 2))
        for i, (_flag, width, height) in enumerate(table):
            if i in lines:
                which = lines.index(i)
                exp_w, exp_h, exp_lit = want[which]
                if which == 0:
                    exp_h += roll.pad
                if width != exp_w or height != exp_h:
                    print('block %d is %dx%d, expected %dx%d'
                          % (i, width, height, exp_w, exp_h))
                    return 1
                got = got_pixels(cells[at:at + width * height], sheet,
                                 width, vp)
                # Screen column the text ends at: a block placed by the
                # wrong rule still matches its own bitmap.
                ends = place(_flag, width) * 8 + max(x for x, _y in got) + 1
                if ends != vp.CREDIT_RIGHT:
                    print('block %d ends at pixel %d, the title at %d'
                          % (i, ends, vp.CREDIT_RIGHT))
                    return 1
                if got != exp_lit:
                    bad += 1
                    print('block %d: %d pixels differ'
                          % (i, len(got ^ exp_lit)))
                else:
                    print('block %d: %d cells, %d lit pixels, exact'
                          % (i, width * height, len(got)))
            at += width * height
            if at >= len(cells):
                break

        # Stop where the map runs out, not at the end of the table: the
        # entries past that are blank spacers the roll never reaches.
        used = rows = n = 0
        while used < len(cells):
            _flag, width, height = table[n]
            used += width * height
            rows += height
            n += 1
        end = rows * 8 + 0x116
        print('roll is %d blocks, %d rows, ends at tick %d of %d (%d spare)'
              % (n, rows, end, 0x10e2, 0x10e2 - end))
        if end >= 0x10e2:
            print('the roll now outlasts the sequence that drives it')
            bad += 1

        for name in (vp.SCRSTFCG, vp.SCRSTFMP):
            path = os.path.join(tmp, name)
            before = wanted[name]
            patcher.restore()
            after = hashlib.md5(open(path, 'rb').read()).hexdigest()
            print('%s restores: %s' % (name, 'yes' if before == after
                                       else 'NO'))
            if before != after:
                bad += 1
        return 1 if bad else 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        raise SystemExit(2)
    raise SystemExit(main(sys.argv[1]))
