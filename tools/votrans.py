#!/usr/bin/env python3
"""Translate the patch table and the asm sources' addresses through a
vomap.py map.

    python3 tools/votrans.py sites   [MAP.pkl]   every FEATURES site
    python3 tools/votrans.py asm     [MAP.pkl]   every address in asm/*.asm
    python3 tools/votrans.py symbols [MAP.pkl]   RETAIL.symbols for the other
                                                 build, to paste into a Build
    python3 tools/votrans.py one VA... [MAP.pkl] single addresses

MAP.pkl defaults to vomap.pkl in the current directory; the executables are
read from the paths recorded in it.
"""
import pickle, re, sys, struct, bisect, importlib.util, collections, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from vomap import Exe, md, BASE                              # noqa: E402

_args = [a for a in sys.argv[1:] if a.endswith('.pkl')]
M = pickle.load(open(_args[0] if _args else 'vomap.pkl', 'rb'))
A, B, pairs, votes, insmap, quality = (M[k] for k in ('A', 'B', 'pairs', 'votes', 'insmap', 'quality'))
exeA, exeB = Exe(M['retail']), Exe(M['other'])
fstart = [f['s'] for f in A]
fmap = {A[ia]['s']: B[ib]['s'] for ia, ib in pairs}
inv_pairs = dict(pairs)


def import_map():
    """retail IAT slot VA -> jp IAT slot VA, by dll/name."""
    def iat(exe):
        d = exe.d
        n, va0, vs, ro, rs = exe.sec['.idata']
        out = {}
        i = ro
        while True:
            ilt, _ts, _fc, name, iatp = struct.unpack_from('<5I', d, i)
            if not name:
                break
            dll = d[exe.off(BASE + name):].split(b'\0')[0].decode().lower()
            t = exe.off(BASE + (ilt or iatp))
            k = 0
            while True:
                v = struct.unpack_from('<I', d, t)[0]
                if not v:
                    break
                fn = '#%d' % (v & 0xffff) if v & 0x80000000 else d[exe.off(BASE + v) + 2:].split(b'\0')[0].decode()
                out[(dll, fn)] = BASE + iatp + 4 * k
                t += 4
                k += 1
            i += 20
        return out
    a, b = iat(exeA), iat(exeB)
    return {va: b[k] for k, va in a.items() if k in b}, {va: k for k, va in a.items()}


IAT, IATNAME = import_map()


def enclosing(va):
    i = bisect.bisect_right(fstart, va) - 1
    if i >= 0 and A[i]['s'] <= va < A[i]['e']:
        return i
    return None


def translate(va):
    """Return (jp_va, how) or (None, why)."""
    if va in MANUAL_VA:
        return MANUAL_VA[va], 'manual'
    if va in IAT:
        return IAT[va], 'iat ' + IATNAME[va][1]
    if va in fmap:
        return fmap[va], 'func'
    if va in insmap:
        return insmap[va], 'insn'
    if exeA.text_lo <= va < exeA.text_hi:
        for back in range(1, 15):
            if va - back in insmap:
                # same instruction length on both sides -> same offset inside it
                la = next(md.disasm(exeA.d[exeA.off(va - back):exeA.off(va - back) + 15], va - back)).size
                jb = insmap[va - back]
                lb = next(md.disasm(exeB.d[exeB.off(jb):exeB.off(jb) + 15], jb)).size
                if la == lb and back < la:
                    return jb + back, 'insn+%d' % back
                break
        i = enclosing(va)
        if i is None:
            return None, 'code, no function'
        if i not in inv_pairs:
            return None, 'code, function %x unmatched' % A[i]['s']
        # inside a matched function but not on an aligned instruction
        return None, 'code, in %x (%s) not aligned' % (A[i]['s'], quality.get(A[i]['s']))
    if va in votes:
        c = votes[va].most_common(2)
        if len(c) == 1 or c[0][1] >= 3 * c[1][1]:
            return c[0][0], 'data %d votes' % c[0][1]
        return c[0][0], 'data CONTESTED %s' % c
    # untouched data: interpolate from neighbours with the same delta
    lo = [k for k in votes if k < va and abs(k - va) < 0x400]
    hi = [k for k in votes if k > va and abs(k - va) < 0x400]
    if lo and hi:
        kl, kh = max(lo), min(hi)
        dl = votes[kl].most_common(1)[0][0] - kl
        dh = votes[kh].most_common(1)[0][0] - kh
        if dl == dh:
            return va + dl, 'data interp delta %+x' % dl
        return None, 'data between %x(%+x) and %x(%+x)' % (kl, dl, kh, dh)
    return None, 'no data'


def translate_off(off):
    va = exeA.va(off)
    if va is None:
        return None, 'outside sections'
    r, how = translate(va)
    return (exeB.off(r) if r is not None else None), how


# Resolved by hand from the disassembly, per target build (by MD5); see
# docs/NOTES.md. Sites by retail file offset, then addresses by retail VA.
HAND = {'d19320bdc3381a48228990907910a391': ({           # Japanese rerelease
    0x000970bf: 0x00095c1c, 0x000970d5: 0x00095c32,   # bind page fill loop, [ebp-8] is [ebp-0x18] in JPRE
    0x00095ec7: 0x00094a26,                           # mov dl,[eax+ecx*2+block]: block moved
    0x00096b61: 0x000956bf,                           # 2P-key check, retail split this function in two
    0x000958aa: 0x0009440a,                           # jmp +0 at loop exit
    0x00189546: 0x0018491a, 0x00058189: 0x0005749d,   # sound: same code, no aligned insn
    0x006035ac: 0x005fd5ac, 0x0060b34e: 0x0060534e,   # .rsrc, whole section is -0x6000
    0x0009703f: 0x00095b9c,                           # bind page fill: the letter loop entry;
                                                      # its bytes also occur in another function
    0x0000023f: 0x0000023f, 0x000000a8: 0x000000a8,   # PE header: same section order, same field
    # bosses: the select's launch and lineup, the palette event handler, the
    # chase camera and Z-Gradt's clone are compiled differently here; their
    # sites placed by the references each table has, in order, and by the
    # instructions around each hook
    0x0000594e: 0x000a421f, 0x00061070: 0x00032be0,
    0x000f3e48: 0x000f0e98, 0x000f3ecd: 0x000f0f1d,
    0x000f3f3d: 0x000f0f8d, 0x000f3fcd: 0x000f101d,
    0x00110109: 0x0010c691, 0x0011297d: 0x0010ef6d,
    0x001129f8: 0x0010efe8, 0x00112a2c: 0x0010f01c,
    0x00112a60: 0x0010f050, 0x00189e7e: 0x00185256,
    0x0019bf93: 0x00196d93, 0x0019bff7: 0x00196df7,
    0x0019c6ab: 0x001974ab, 0x0019d8e5: 0x001986e5,
    0x0019dc03: 0x00198a03, 0x0019dd4a: 0x00198b4a,
    0x0019df8a: 0x00198d8a, 0x0019e0c2: 0x00198e92,
    0x0019e0f9: 0x00198ec9, 0x0019e209: 0x00198fd9,
    0x0019e241: 0x00199011, 0x0019e3f8: 0x001991c8,
    0x0019e590: 0x00199360, 0x0019e728: 0x001994f8,
    0x0019e8cf: 0x0019969f, 0x0019eae2: 0x001998b2,
    0x0019f6a5: 0x0019a43d, 0x0019f6f4: 0x0019a48c,
    0x0019f71e: 0x0019a4b6, 0x0019f780: 0x0019a518,
    0x0019f7aa: 0x0019a542, 0x0019f8bd: 0x0019a655,
    0x0019f8c1: 0x0019a659, 0x0019f8ec: 0x0019a684,
    0x0019f91f: 0x0019a6b7, 0x0019f9c1: 0x0019a759,
    0x0019fc26: 0x0019a9be, 0x0019fc2c: 0x0019a9c4,
    0x0019fc3d: 0x0019a9d5, 0x0019fc64: 0x0019a9fc,
    0x0019fc97: 0x0019aa2f, 0x0019fccb: 0x0019aa63,
    0x001a0c81: 0x0019ba19, 0x001a0e80: 0x0019bc18,
    0x001a0e84: 0x0019bc1c, 0x001a0eaf: 0x0019bc47,
    0x001a0ee2: 0x0019bc7a, 0x001d39b1: 0x001ce241,
}, {
    0x0049776e: 0x004962cc, 0x004977c6: 0x00496324,   # kbpage: 2P-key check labels
    0x00497c70: 0x004967cd, 0x00497cb0: 0x0049680d,   # pagesec: bind page loop heads
    0x00497cf7: 0x00496854,                           # bindlist: loop exit
    0x005c680b: 0x005c10da,                           # f11pause: GRESUME
}), '4c70f780a7f0d98d74be62304fb99021': ({            # USA OEM
    0x00107930: None,                                 # no vendor check: its processor
                                                      # check is an MMX test via cpuid32.dll
    0x000958aa: 0x0009574a,                           # jmp +0 at loop exit
    0x006035ac: 0x00602fac,                           # .rsrc, whole section is -0x600
    0x0000023f: 0x0000023f, 0x000000a8: 0x000000a8,   # PE header: same section order
    0x0019f8c1: 0x0019f391, 0x001a0e84: 0x001a0954,   # bosses: confirm, in functions
                                                      # that do not align
    0x0000594e: 0x0000594e,                           # bosses: Z-Gradt's clone
    0x000f3e48: 0x000f3ce8, 0x000f3ecd: 0x000f3d6d,   # bosses: Z-Gradt's gold
}, {
    0x004977c6: 0x00497664,                           # kbpage: the 2P-key accept label
}), '9764d946ffc8cee94788707c91753478': ({            # Japanese original
    0x00107930: None,                                 # no vendor check: the OEM's
                                                      # cpuid32.dll test, sites of its own
    0x000958aa: 0x0009584a,                           # jmp +0 at loop exit
    0x006035ac: 0x00601dac,                           # .rsrc: the directory is -0x1800,
                                                      # the dialog data -0x180c
    0x0000023f: 0x0000023f, 0x000000a8: 0x000000a8,   # PE header: same section order
    # bosses: sites the map places by function but cannot align - the select's
    # launch and the palette event handler hold jump tables, and the chase
    # camera and Z-Gradt's clone are split differently - placed by the
    # instructions that follow each, in order where a stretch repeats
    0x0000593f: 0x0000593f, 0x0000594e: 0x0000594e,
    0x000f3e48: 0x000f36d8, 0x000f3ecd: 0x000f375d,
    0x000f3f3d: 0x000f37cd, 0x000f3fcd: 0x000f385d,
    0x0011297d: 0x00111edd, 0x001129f8: 0x00111f58,
    0x00112a2c: 0x00111f8c, 0x00112a60: 0x00111fc0,
    0x0019f6a5: 0x0019e545, 0x0019f6f4: 0x0019e594,
    0x0019f71e: 0x0019e5be, 0x0019f780: 0x0019e620,
    0x0019f7aa: 0x0019e64a, 0x0019f8bd: 0x0019e75d,
    0x0019f8c1: 0x0019e761, 0x0019f8ec: 0x0019e78c,
    0x0019f91f: 0x0019e7bf, 0x0019f9c1: 0x0019e861,
    0x0019fc26: 0x0019eac6, 0x0019fc2c: 0x0019eacc,
    0x0019fc3d: 0x0019eadd, 0x0019fc64: 0x0019eaf2,
    0x0019fc97: 0x0019eb24, 0x0019fccb: 0x0019eb59,
    0x001a0c81: 0x0019fb21, 0x001a0e80: 0x0019fd20,
    0x001a0e84: 0x0019fd24, 0x001a0eaf: 0x0019fd4f,
    0x001a0ee2: 0x0019fd82,
}, {
    0x004977c6: 0x00497764,                           # kbpage: the 2P-key accept label,
                                                      # its two loads the other way round
}), '383d3bff66504954f84924a0b41dc3fa': ({            # PowerVR
    # What the map could not place when this build's sites were generated. Its
    # site map is now kept by hand in v-on-patcher.py, so this is a record.
    0x000000a8: 0x000000a8,                           # PE header: the entry point field
    0x001c5900: 0x0009759c,                           # titlever: the load before the flip
    0x001fcec8: None, 0x001fcecc: None,               # the roll's byte counts and block
    0x002bbb54: None,                                 # list: PowerVR has In() sites
    0x006035ac: None, 0x0060c064: None,               # retail's F5 resource: the
                                                      # PowerVR one has In() sites
    0x0010afbe: 0x0016d234, 0x0010afeb: 0x0016d261,   # Motion= fallbacks: the ini
    0x0010b002: 0x0016d278,                           # loader does not align
    0x001c6941: None, 0x001c6950: None,               # no reset of Motion at start-up
    0x001c8bc4: None, 0x001c8bd3: None,               # or after a mode change
    # continuefix: the same ten blocks in the same order, [ebp-0x14] for
    # retail's [ebp-4], in functions the map does not match
    0x00077f5a: 0x00009e07, 0x00078b1c: 0x0000a9c9,
    0x00079bb6: 0x0000ba63, 0x00079f3f: 0x0000bdec,
    0x0007d04a: 0x0000eef7, 0x000bb9ea: 0x000651c7,
    0x000bc5ac: 0x00065d89, 0x000bd646: 0x00066e23,
    0x000bd9cf: 0x000671ac, 0x000c0ada: 0x0006a2b7,
    # sound: Fei-Yen's hypermode test, twice, in functions the map does not
    # match; told apart by the callee after each (retail 0x597311 is 0x574f41)
    0x00058189: 0x000ba24d, 0x00170dc9: 0x001049cd,
    # defaults: the ini loader does not align. Sky, ScrSize, the three
    # Texture flags; Field Graphic is an In() site, its fallback being two
    # stores where retail's is one
    0x0010acd7: 0x0016cf4d, 0x0010b088: 0x0016d2fe,
    0x0010b131: None,
    0x0010b1b0: 0x0016d444, 0x0010b1ba: 0x0016d44e,
    0x0010b1c4: 0x0016d458,
    # movie: the PE header's .rsrc characteristics, the same field; the
    # initials screen's trigger tests, the same code and jump distances
    0x0000023f: 0x0000023f, 0x000d60c8: 0x0007a353,
    # the call before the flip that HOLD TO SKIP hooks: not placed (the one
    # at 0x498178 runs only behind a toggle), so the build goes without it
    0x001c58e7: None,
    # padxinput: the bind page fill, which the map does not match; its loop
    # counter is [ebp-0x18] here, which also put "raw unique" for 0x9703f
    # in the wrong function
    0x000970bf: 0x001264bb, 0x000970d5: 0x001264d1, 0x0009703f: 0x0012643b,
    0x000958aa: 0x00124cb3,                           # the ini load loop's exit
    # switch-table entries, paired entry by entry with retail's through
    # each function's alignment: the 2P profile switch (0x54b457), the
    # startup check (0x525229), the F7 OK spend (0x52672f), the F7 page
    # (0x525bdc) and the save switch (0x526257)
    0x001bc13b: 0x0014a85b, 0x001bc13f: 0x0014a85f, 0x001bc143: 0x0014a863,
    0x00095213: 0x0012462d, 0x00095217: 0x00124631,
    0x00096731: 0x00125b2f, 0x00096735: 0x00125b33,
    0x00095bdc: 0x00124fe4, 0x00095be0: 0x00124fe8,
    0x00096253: 0x0012565b, 0x0009625b: 0x00125663,
    # the startup check spends joysticks per device here, Keyboard (Simple)
    # among them, and has no last check for devices 3 and 7: the two table
    # entries above cover it
    0x0009522e: None, 0x00095248: None,
}, {
})}

import hashlib                                                  # noqa: E402
MANUAL, MANUAL_VA = HAND.get(hashlib.md5(exeB.d).hexdigest(), ({}, {}))


if __name__ == '__main__':
    what = sys.argv[1]
    if what == 'sites':
        spec = importlib.util.spec_from_file_location('vp', os.path.join(ROOT, 'v-on-patcher.py'))
        vp = importlib.util.module_from_spec(spec); spec.loader.exec_module(vp)
        ok = bad = 0
        for key, label, tip, sites in vp.FEATURES:
            for off, orig, new in sites:
                o = bytes.fromhex(orig)
                if set(o) == {0}:
                    print('%-11s %08x blob %4d' % (key, off, len(o)))
                    continue
                jo, how = translate_off(off)
                if off in MANUAL:
                    jo, how = MANUAL[off], 'manual'
                if jo is None and len(o) == 4:
                    p = struct.unpack('<I', o)[0]
                    if exeA.text_lo <= p < exeA.text_hi:
                        q, qh = translate(p)
                        if q is not None:
                            # dword in jp within +-0x8000 of the retail file offset
                            lo, hi = max(0, off - 0x8000), off + 0x8000
                            hits = [lo + m.start() for m in re.finditer(re.escape(struct.pack('<I', q)), exeB.d[lo:hi])]
                            if len(hits) == 1:
                                jo, how = hits[0], 'ptr->%x (%s)' % (q, qh.split()[0])
                            elif len(hits) > 1:
                                # the entry before this one settles it
                                prev, ph = translate_off(off - 4)
                                if prev is None:
                                    po = struct.unpack_from('<I', exeA.d, off - 4)[0]
                                    pq, _ = translate(po) if exeA.text_lo <= po < exeA.text_hi else (None, None)
                                    if pq is not None:
                                        ph_ = [h for h in hits if struct.unpack_from('<I', exeB.d, h - 4)[0] == pq]
                                        if len(ph_) == 1:
                                            jo, how = ph_[0], 'ptr->%x (by prev entry)' % q
                                elif prev + 4 in hits:
                                    jo, how = prev + 4, 'ptr->%x (next to %x)' % (q, prev)
                            if jo is None:
                                how = 'ptr->%x %d hits' % (q, len(hits))
                if jo is None and len(o) >= 4:
                    hits = [m.start() for m in re.finditer(re.escape(o), exeB.d)]
                    if len(hits) == 1:
                        jo, how = hits[0], 'raw unique %+x' % (hits[0] - off)
                if jo is None:
                    print('%-11s %08x  ????????  %s' % (key, off, how)); bad += 1; continue
                got = exeB.d[jo:jo + len(o)]
                same = got == o
                # masked compare
                m = sum(1 for x, y in zip(o, got) if x == y)
                print('%-11s %08x  %08x  %-22s %s' % (key, off, jo, how, 'same' if same else '%d/%d bytes' % (m, len(o))))
                ok += 1
        print('translated %d, failed %d' % (ok, bad))
    elif what == 'asm':
        import glob
        addrs = collections.defaultdict(set)
        for f in glob.glob(os.path.join(ROOT, 'asm', '*.asm')):
            for m in re.finditer(r'0x0?([0-9a-fA-F]{6,8})', open(f).read()):
                addrs[int(m.group(1), 16)].add(f.split('/')[-1])
        ok = bad = 0
        for va in sorted(addrs):
            r, how = translate(va)
            sec = exeA.secname(va)
            if r is None:
                bad += 1
            else:
                ok += 1
            print('%08x -> %-8s %-6s %-32s %s' % (va, '%08x' % r if r else '????????', sec, how, ','.join(sorted(addrs[va]))))
        print('translated %d, failed %d' % (ok, bad))
    elif what == 'symbols':
        # RETAIL's symbols as the other build would have them, to paste into
        # a new Build; what could not be resolved is listed for the hand
        spec = importlib.util.spec_from_file_location('vp', os.path.join(ROOT, 'v-on-patcher.py'))
        vp = importlib.util.module_from_spec(spec); spec.loader.exec_module(vp)
        unresolved = []
        for name, value in vp.RETAIL.symbols.items():
            if isinstance(value, tuple):
                print("    '%s': %r," % (name, value))
            elif value < 0:
                print("    '%s': %s,%s" % (name, '-0x%x' % -value,
                                          '   # frame offset: read the disassembly'))
            else:
                r, how = translate(value)
                if r is None:
                    unresolved.append((name, value, how))
                    print("    # '%s': 0x%08x -> ?  %s" % (name, value, how))
                else:
                    print("    '%s': 0x%08x,%s" % (name, r, '' if 'votes' in how and int(how.split()[1]) >= 3
                                                   else '   # ' + how))
        print('# %d unresolved' % len(unresolved))
    elif what == 'one':
        for a in [x for x in sys.argv[2:] if not x.endswith('.pkl')]:
            va = int(a, 16)
            r, how = translate(va); print('%08x -> %s  %s' % (va, '%08x' % r if r else '????????', how))
