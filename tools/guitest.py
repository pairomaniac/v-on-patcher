#!/usr/bin/env python3
"""The window, driven headlessly.

Every check here is one a person found by clicking: a button that came back
when it should have stayed down, a heading that redrew as an empty box, a
column that ended level with nothing. None of them raise on their own - the
widgets are all present and the right size and the wrong thing is on screen -
so each one asserts the property rather than the absence of an exception.

Needs a display. Under CI that is xvfb; locally, run it inside

    xvfb-run -a -s "-screen 0 1600x1400x24" python3 tools/guitest.py

With no display it skips rather than fails, so a checkout on a headless box
without xvfb still gets a clean run - but it says so as a `note:` line, which
is what check.py surfaces. Under CI (CI=true) the same skip is a failure: the
runner is meant to have xvfb and tkinter, and a green run that tested no
window at all should not look like one that did.

Most of it needs no copy of the game - the disc is built by disctest, with a
stand-in for v_on.exe. Pass a game folder (or set VO_GAME) and the checks
that need the patcher to accept the disc run as well:

    xvfb-run -a python3 tools/guitest.py /path/to/VIRTUAL-ON

The patching side itself is selftest.py's, and check.py's offsets, banner and
credit.
"""

import atexit
import hashlib
import io
import json
import os
import shutil
import struct
import sys
import tempfile
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import disctest                                             # noqa: E402
import selftest                                             # noqa: E402

FAILED = []


def check(label, condition, detail=''):
    print('%-4s %s%s' % ('ok' if condition else 'FAIL', label,
                         '' if condition else '   <- %s' % (detail,)))
    if not condition:
        FAILED.append(label)


def build_window(vp, tk):
    """Open the window without entering its loop, and hand back the root."""
    state = {}
    original = tk.Misc.mainloop

    def stop(self, n=0):
        state['root'] = self
        raise SystemExit(0)

    tk.Misc.mainloop = stop
    try:
        vp.run_tk()
    except SystemExit:
        pass
    finally:
        tk.Misc.mainloop = original
    return state['root']


def walk(widget, out=None):
    out = [] if out is None else out
    out.append(widget)
    for child in widget.winfo_children():
        walk(child, out)
    return out


def text_of(widget):
    try:
        return str(widget.cget('text'))
    except Exception:                                       # noqa: BLE001
        return ''


def main():
    # A skip is a note locally and a failure in CI, where the runner is
    # meant to have both and a green run that tested no window is wrong.
    skip = 1 if os.environ.get('CI') == 'true' else 0
    try:
        import tkinter as tk
        from tkinter import ttk
    except ImportError:
        print('note: no tkinter, so the window was not tested')
        return skip
    try:
        tk.Tk().destroy()
    except tk.TclError as exc:
        print('note: no display (%s), so the window was not tested - run it '
              'under xvfb-run' % exc)
        return skip

    vp = disctest.load_patcher()
    tmp = tempfile.mkdtemp(prefix='vo-guitest-')
    # However the run ends, including on a check that raises: the disc built
    # below is tens of megabytes and there is no reason to keep it.
    atexit.register(shutil.rmtree, tmp, ignore_errors=True)
    here = os.path.join(tmp, 'disc')
    os.makedirs(here)

    # A stand-in reads as a build without tables, which is what the check
    # below wants; the real one is what the copy is exercised on.
    #
    # pristine, because a development copy of the game is normally patched -
    # which is the point of having one - and the patched file is not a build
    # the patcher will install. selftest and bannertest fall back the same
    # way, to the .bak beside it.
    game = (sys.argv[1] if len(sys.argv) > 1 else '') or os.environ.get(
        'VO_GAME', '')
    exe = None
    if game:
        if os.path.isfile(game):
            game = os.path.dirname(game) or '.'
        exe, source = selftest.pristine(os.path.join(game, 'v_on.exe'), vp)
        if exe is None:
            print('note: no unmodified v_on.exe in %s, so the copy is not '
                  'exercised' % game)
        else:
            print('note: using %s' % source)
    real = exe is not None
    if not real:
        exe = b'M' * vp.EXE_SIZE
    tree = disctest.retail_tree(exe)
    # Padded so the copy lasts more than one turn of the event loop, which
    # is all the "during" the check below needs. A real disc is 95 MB.
    tree['v_on']['escrgame.bin'] = b'E' * (12 << 20)
    cue = disctest.write_disc(here, 'RETAIL', disctest.build_iso(tree),
                              'MODE1/2352', audio=26)

    root = build_window(vp, tk)
    root.overrideredirect(True)        # no window manager under xvfb
    root.geometry('+0+0')
    root.update()
    everything = walk(root)

    canvas = [w for w in everything if isinstance(w, tk.Canvas)][0]
    inner = canvas.winfo_children()[0]
    entries = [w for w in everything
               if isinstance(w, ttk.Entry) and not isinstance(w, ttk.Combobox)]
    buttons = {}
    for w in everything:
        if isinstance(w, ttk.Button):
            buttons.setdefault(text_of(w), []).append(w)
    heads = {text_of(w): w for w in everything
             if isinstance(w, ttk.Label)
             and text_of(w) in ('INSTALL', 'GAME FILE', 'ESSENTIAL PATCHES',
                                'EXTRA PATCHES', 'ADD-ONS', 'LOG', 'ABOUT')}

    def pump(ms=0):
        root.update_idletasks()
        root.update()
        if ms:
            end = root.tk.call('clock', 'milliseconds') + ms
            while root.tk.call('clock', 'milliseconds') < end:
                root.update()

    def enabled(name):
        return 'disabled' not in buttons[name][0].state()

    def card_of(head):
        return head.master.master

    def is_open(label):
        card = card_of(heads[label])
        return bool(card.winfo_children()[-1].winfo_manager())

    def set_open(label, want):
        # Driven to a state rather than toggled: the log opens itself on the
        # first line it is given, so what is open at this point depends on
        # what has happened above.
        if is_open(label) != want:
            heads[label].event_generate('<Button-1>')
            pump()

    def set_entry(entry, value):
        root.setvar(entry.cget('textvariable'), value)

    # ---- the source decides what is offered --------------------------
    check('nothing offered for an empty source',
          not enabled('Install game') and not enabled('Rip soundtrack'))
    set_entry(entries[0], os.path.join(tmp, 'no-such-file.cue'))
    pump(200)
    check('nothing offered for a path that is not there',
          not enabled('Install game') and not enabled('Rip soundtrack'))
    set_entry(entries[0], cue)
    set_entry(entries[1], os.path.join(tmp, 'game'))
    for _ in range(200):                     # the source is read on a timer
        pump(20)
        if enabled('Rip soundtrack'):
            break
    check('the rip is offered for a readable image', enabled('Rip soundtrack'),
          'it needs a destination as well as a source')
    if not real:
        check('another build is offered for the install too',
              enabled('Install game'),
              'the copy does not depend on which build is on the disc')
    else:
        check('the install is offered for a retail disc',
              enabled('Install game'))

        # ---- a long job holds the buttons down -----------------------
        buttons['Install game'][0].invoke()
        pump()
        running = not enabled('Install game')
        check('a copy disables both buttons',
              running and not enabled('Rip soundtrack'))
        if running:
            # No pump in between: the destination's trace runs inside the
            # set, so if it re-arms the buttons it has already done it by
            # the time this looks. Waiting instead would race the copy,
            # which on a fast disk finishes first and passes for the wrong
            # reason.
            set_entry(entries[1], os.path.join(tmp, 'elsewhere'))
            check('editing a path mid-copy does not re-arm them',
                  not enabled('Install game')
                  and not enabled('Rip soundtrack'),
                  'a second copy could start on top of the first')
        else:
            print('     the copy finished too quickly to interrupt; skipped')
        for _ in range(600):
            pump(20)
            if enabled('Install game'):
                break
        check('and they come back when it finishes', enabled('Install game'))

    # ---- an Alcohol 120% image takes the same path --------------------
    mds, _spans = disctest.write_mds(here, 'ALCOHOL', disctest.build_iso(
        disctest.retail_tree(exe)), audio=2)

    def note_says(words):
        return any(words in text_of(w) for w in walk(root)
                   if isinstance(w, ttk.Label) and w.winfo_ismapped())

    set_entry(entries[0], mds[:-4] + '.mdf')
    for _ in range(100):
        pump(20)
        if note_says('.mds file beside it'):
            break
    check('an .mdf asks for the .mds beside it',
          note_says('.mds file beside it') and not enabled('Rip soundtrack'))
    set_entry(entries[0], mds)
    for _ in range(200):
        pump(20)
        if enabled('Rip soundtrack'):
            break
    check('an .mds is offered for the rip', enabled('Rip soundtrack'))
    check('and for the install', enabled('Install game'))

    # ---- a patch the build warns about --------------------------------
    for raw, want in (
            ('AMD Ryzen 7 9800X3D 8-Core Processor', 'AMD Ryzen 7 9800X3D'),
            ('AMD Ryzen 5 5600G with Radeon Graphics', 'AMD Ryzen 5 5600G'),
            ('Intel(R) Core(TM) i5-12400F CPU @ 2.50GHz',
             'Intel Core i5-12400F'),
            ('13th Gen Intel(R) Core(TM) i7-13700K',
             '13th Gen Intel Core i7-13700K')):
        check('the CPU name %s tidies' % want, vp.tidy_cpu_name(raw) == want,
              vp.tidy_cpu_name(raw))
    # A stand-in the patcher takes for the PowerVR build, so this runs in CI.
    # The real file, if there is one, is only for applying it.
    pvr = None
    if game:
        pvr, source = selftest.pristine(os.path.join(game, 'vonpvr.exe'), vp)
    stand_in = bytearray(0x200)
    struct.pack_into('<I', stand_in, 0x3c, 0x80)
    stand_in[0x80:0x84] = b'PE\0\0'
    struct.pack_into('<I', stand_in, 0x88, vp.PVR.stamp)
    vp.BUILDS[hashlib.md5(bytes(stand_in)).hexdigest()] = vp.PVR
    from tkinter import filedialog
    pvr_dir = os.path.join(tmp, 'pvr')
    os.makedirs(pvr_dir)
    path = os.path.join(pvr_dir, 'vonpvr.exe')
    with open(path, 'wb') as fh:
        fh.write(stand_in)
    pick = filedialog.askopenfilename
    filedialog.askopenfilename = lambda **_kw: path
    if True:                            # keeps the block's indent
        try:
            buttons['Browse\u2026'][-1].invoke()
            pump()
            box = [w for w in walk(root) if isinstance(w, ttk.Checkbutton)
                   and text_of(w) == 'Native widescreen'][0]
            shown = []

            def answer(label):
                """Press a button of the warning once it has opened."""
                popups = [w for w in root.winfo_children()
                          if isinstance(w, tk.Toplevel) and w.winfo_viewable()]
                if not popups:
                    root.after(20, answer, label)
                    return
                shown.append(True)
                said = ' '.join(text_of(w) for w in walk(popups[0])
                                if isinstance(w, ttk.Label))
                if label == 'Leave it off':
                    check('the warning names the CPU and the chart',
                          'Your CPU' in said and 'cpubenchmark.net' in said)
                [w for w in walk(popups[0]) if isinstance(w, ttk.Button)
                 and text_of(w) == label][0].invoke()

            check('PowerVR widescreen starts unticked',
                  not box.instate(['selected']))
            root.after(20, answer, 'Leave it off')
            box.invoke()
            check('ticking it warns, and declining leaves it off',
                  shown and not box.instate(['selected']))
            root.after(20, answer, 'Turn it on')
            box.invoke()
            check('accepting ticks it', box.instate(['selected']))
            del shown[:]
            box.invoke()
            pump(60)
            check('unticking it does not warn',
                  not shown and not box.instate(['selected']))

            # ---- sgl.dll, which the game cannot start without ---------
            check('a missing sgl.dll is flagged where it installs',
                  note_says('does not start without sgl.dll'))

            # ---- the add-ons' installs, with a server of our own ---------
            def row_button(name):
                for w in walk(root):
                    if isinstance(w, ttk.Button) and text_of(w) in (
                            'Install', 'Remove'):
                        line = w.grid_info().get('row')
                        for cell in w.master.winfo_children():
                            if cell.grid_info().get('row') == line and any(
                                    name in text_of(x) for x in walk(cell)
                                    if isinstance(x, ttk.Label)):
                                return w
                return None

            def archive(*names):
                blob = io.BytesIO()
                with zipfile.ZipFile(blob, 'w') as zf:
                    for name in names:
                        zf.writestr(name, b'stand-in ' + name.encode())
                return blob.getvalue()

            class Reply(io.BytesIO):
                headers = {'Content-Length': '0'}

                def __enter__(self):
                    return self

                def __exit__(self, *_exc):
                    self.close()

            failure = [None]

            def serve(req, timeout=30):
                if failure[0]:
                    raise failure[0]
                url = req.full_url
                if url == vp.SGL_API:
                    return Reply(json.dumps({'tag_name': 'v9', 'assets': [{
                        'name': 'w.zip', 'browser_download_url': 'https://stand-in/sgl.zip'
                    }]}).encode())
                if url.endswith('sgl.zip'):
                    return Reply(archive('w/sgl.dll', 'w/readme.txt'))
                return Reply(archive('ddraw.dll'))

            def settled(btn):
                for _ in range(300):
                    pump(10)
                    if not btn.instate(['disabled']):
                        return True
                return False

            urlopen, vp._urlopen = vp._urlopen, serve
            try:
                for name, dll in (('Windowing', 'ddraw.dll'),
                                  ('PowerVR renderer', 'sgl.dll')):
                    btn = row_button(name)
                    dest = os.path.join(pvr_dir, dll)
                    for exc, says, how in (
                            (OSError('no route'), 'Download failed.',
                             'a failed download'),
                            (PermissionError('in use'), 'in use', 'a locked file')):
                        failure[0] = exc
                        btn.invoke()
                        check('%s: %s comes back' % (dll, how), settled(btn))
                        check('%s: %s is said, and nothing written' % (dll, how),
                              not os.path.exists(dest)
                              and text_of(btn) == 'Install'
                              and (how != 'a failed download' or note_says(says)),
                              text_of(btn))
                    failure[0] = None
                    btn.invoke()
                    check('%s: it installs' % dll, settled(btn)
                          and os.path.exists(dest) and text_of(btn) == 'Remove')
                    btn.invoke()
                    pump()
                    check('%s: and removes' % dll, not os.path.exists(dest)
                          and text_of(btn) == 'Install')
                failure[0] = OSError('no route')
                check('--sgl says a failed download',
                      'failed' in str(vp.sgl_cli([pvr_dir])))
                check('--ddraw says a failed download',
                      'failed' in str(vp.ddraw_cli([pvr_dir])))
                failure[0] = None
            finally:
                vp._urlopen = urlopen

            # ---- the offer after Apply, the patching itself stubbed ----
            apply_all = vp.Patcher.apply
            vp.Patcher.apply = lambda _self, _wanted: (True, [])
            try:
                del shown[:]
                root.after(20, answer, 'Not now')
                buttons['Apply patches'][0].invoke()
                check('Apply offers to install sgl.dll, and it can be declined',
                      shown and not os.path.exists(
                          os.path.join(pvr_dir, 'sgl.dll')))
            finally:
                vp.Patcher.apply = apply_all

            # ---- applying it for real needs the real file --------------
            if pvr is not None:
                real_dir = os.path.join(tmp, 'pvr-real')
                os.makedirs(real_dir)
                real = os.path.join(real_dir, 'vonpvr.exe')
                with open(real, 'wb') as fh:
                    fh.write(pvr)
                shutil.copy(os.path.join(game, 'escrgame.bin.bak'),
                            os.path.join(real_dir, 'escrgame.bin'))
                filedialog.askopenfilename = lambda **_kw: real
                buttons['Browse\u2026'][-1].invoke()
                pump()
                del shown[:]
                root.after(20, answer, 'Not now')
                buttons['Apply patches'][0].invoke()
                check('the real file applies, and the offer comes after',
                      shown and not os.path.exists(
                          os.path.join(real_dir, 'sgl.dll')))
        finally:
            filedialog.askopenfilename = pick

    # ---- the layout --------------------------------------------------
    if inner.grid_size()[0] >= 2:
        columns = [c for c in inner.winfo_children() if isinstance(c, ttk.Frame)]
        left, right = columns[0], columns[1]

        def bottom(column):
            card = column.winfo_children()[-1]
            return card.winfo_rooty() + card.winfo_height()

        set_open('ADD-ONS', True)
        set_open('LOG', True)
        set_open('ABOUT', False)
        check('the columns end level whatever is open',
              abs(bottom(left) - bottom(right)) <= 1,
              (bottom(left), bottom(right)))
        check('the two foot headings line up',
              heads['LOG'].winfo_rooty() == heads['ABOUT'].winfo_rooty())
        log_card, about_card = card_of(heads['LOG']), card_of(heads['ABOUT'])
        check('an open card does not inflate a closed one beside it',
              log_card.winfo_height() > about_card.winfo_height(),
              'a heading stretched into an empty box')
        set_open('ABOUT', True)
        check('two open cards match each other',
              log_card.winfo_height() == about_card.winfo_height(),
              (log_card.winfo_height(), about_card.winfo_height()))
        set_open('LOG', False)
        check('and a closed one shrinks back to its heading',
              about_card.winfo_height() > log_card.winfo_height())

    # ---- nothing is wrapped wider than the space it has ---------------
    widest = 0
    for label in everything:
        if not isinstance(label, ttk.Label) or not label.winfo_ismapped():
            continue
        try:
            wrap = int(label.cget('wraplength'))
        except Exception:                                   # noqa: BLE001
            continue
        if wrap:
            widest = max(widest, wrap - (label.master.winfo_width() - 2))
    check('no hint wraps wider than its card', widest <= 0, '%d px over' % widest)

    # ---- the window can still be resized ------------------------------
    low, high = root.minsize(), root.maxsize()
    check('the minimum is not the maximum', low[0] < high[0],
          'the window could not be dragged at all')
    check('the window opens no smaller than its minimum',
          root.winfo_width() >= low[0], (root.winfo_width(), low[0]))

    print()
    if FAILED:
        print('FAILED: %s' % ', '.join(FAILED))
        return 1
    print('window OK')
    return 0


if __name__ == '__main__':
    sys.exit(main())
