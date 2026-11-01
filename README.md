<p align="center">
  <img src="assets/VONPatcherLogo1.png" alt="V-On Patcher" width="640" />
</p>

# V-On Patcher

Gets *Cyber Troopers Virtual-On* (PC, 1997) running properly on a modern system.
It installs the game from a disc image and fixes the crashes, the frame rate and
the keyboard. The extras:

- 1920x1080 rendering
- XInput gamepads for both players
- The soundtrack from files instead of the disc
- Two-player versus over the internet, with a code to share and no port forwarding
- The two bosses, Jaguarandi and Z-Gradt, as machines you can earn and play

<p align="center">
  <img src="assets/readme/widescreen-match.png" alt="Widescreen match" width="49.5%" />
  <img src="assets/readme/widescreen-title.png" alt="Widescreen title screen" width="49.5%" />
</p>

<img src="assets/readme/widescreen-ending.png" alt="Widescreen ending cutscene: Temjin over the Earth and the Moon" width="100%" />

<p align="center">
  ...in a nutshell - the patch makes the game <i>just work ™️</i>
</p>

<p align="center">
  <img src="assets/readme/patcher-window.png" alt="The patcher window" height="700" />
</p>

<table>
  <tr>
    <td><b>Get started</b></td>
    <td><a href="#quick-start">Quick start</a> · <a href="#virus-warnings">Virus warnings</a> · <a href="#installing-from-a-disc-image">Installing</a></td>
  </tr>
  <tr>
    <td><b>Features</b></td>
    <td><a href="#what-the-patches-do">Patches</a> · <a href="#native-widescreen">Widescreen</a> · <a href="#playable-bosses">Bosses</a> · <a href="#gamepad">Gamepad</a> · <a href="#internet-play">Internet play</a> · <a href="#music">Music</a></td>
  </tr>
  <tr>
    <td><b>If something is wrong</b></td>
    <td><a href="#known-issues">Known issues</a> · <a href="#troubleshooting-internet-play">Troubleshooting internet play</a></td>
  </tr>
  <tr>
    <td><b>Reference</b></td>
    <td><a href="#builds">Builds</a> · <a href="#the-powervr-version">PowerVR version</a> · <a href="#windowing-and-scaling-cnc-ddraw">Windowing</a> · <a href="#what-gets-written">What gets written</a> · <a href="#running-the-python-script">Python script</a></td>
  </tr>
</table>

## Quick start

**Download** `v-on-patcher-*-win.zip` from the
[latest release](https://github.com/pairomaniac/v-on-patcher/releases/latest),
unzip it anywhere and run `v-on-patcher.exe`. The `_internal` folder beside it has
to stay. On Linux, see [Running the Python script](#running-the-python-script).

Then work through the window's numbered sections:

| Section | What to do |
| --- | --- |
| **1 INSTALL** | Put your `.cue` or `.mds` in **Source**, choose a folder in **Install to**, and press **Install game**. Then press **Rip soundtrack**, unless you plan to keep a disc in the drive. Already installed? Start at 2. See [Installing](#installing-from-a-disc-image) and [Music](#music). |
| **2 GAME FILE** | Installing fills this in. Otherwise browse to your `v_on.exe`. Only an unmodified disc copy is accepted; if yours is refused, see [Builds](#builds). |
| **3 ESSENTIAL PATCHES** | Always applied, no tick boxes. |
| **4 EXTRA PATCHES** | Change any you like. The ⓘ beside a patch says what it does. Then press **Apply patches**. |
| **5 ADD-ONS** | Press **Install** on the rows you want. See [Add-ons](#add-ons). |

Then play. **Restore original** puts the game back if you change your mind. Add-ons
put files beside the game rather than editing it, so Apply and Restore leave them
alone.

## Virus warnings

> [!NOTE]
> The exe is signed with a Certum open-source code signing certificate (Properties
> → Digital Signatures), and every release is built on GitHub from this repository.
> Scanners can still object, since a program that edits another program is what they
> look for.

- **SmartScreen** may warn until the exe has built up a reputation: **More info** →
  **Run anyway**.
- **A detection ending in `!ml`**, such as Defender's `Trojan:Win32/Wacatac.B!ml`, is
  a machine-learning guess, not a match for anything known. To allow it: Windows
  Security → Virus & threat protection → Protection history → the entry → **Allow**.
- **Rather not run the exe?** `v-on-patcher.py` does everything it does; see
  [Running the Python script](#running-the-python-script).

## Installing from a disc image

The patcher reads the image itself, so there is nothing to mount.

<p align="center">
  <img src="assets/readme/install-section.png" alt="INSTALL section" height="280" />
</p>

1. Put the image in **Source**: the **`.cue`** beside the `.bin` files, or for an
   Alcohol 120% image the **`.mds`** beside the `.mdf`.
2. Choose a folder in **Install to**. The game is about 95 MB.
3. Pick the **Manual** language and press **Install game**.

The **Manual** box only picks which `readme.txt`, `von.hlp` and `von.cnt` are
copied. The game itself is the same language in every pressing. The readme is the one
you can open on a modern system.

The install copies the game directory and the chosen manual, nothing else. The game
makes its own `v_on.ini` on first run, and with **Better defaults** applied it is a
good one. [The PowerVR version](#the-powervr-version) is the exception.

### If you have the disc, not an image

The patcher needs a `bin`/`cue` pair or an Alcohol 120% `mds`/`mdf` one. It does not
read a drive directly, and a plain ISO drops the audio tracks. Image the disc once:

- **Windows** - [ImgBurn](https://www.imgburn.com) in *Read* mode, with the output
  set to **BIN/CUE** rather than ISO.
- **Linux** - `cdrdao`, then its own `toc2cue`:

  ```bash
  cdrdao read-cd --driver generic-mmc-raw --datafile VIRTUAL-ON.bin \
      VIRTUAL-ON.toc /dev/sr0
  toc2cue VIRTUAL-ON.toc VIRTUAL-ON.cue
  ```

On Linux a drive can also go straight in **Source** for the soundtrack rip, though
not for the install; see [Music](#music).

## What the patches do

Every patch works with every other, on all four [builds](#builds) of `v_on.exe`, and
with cnc-ddraw. [The PowerVR version](#the-powervr-version) takes most of them. How
each works inside the game is in [NOTES.md](docs/NOTES.md).

### Essential

Always applied.

| Patch | What it fixes |
| --- | --- |
| **Skip processor check** | The game refuses to start on a modern CPU. |
| **Fix frame rate (60 FPS)** | The game ran at about 70% speed on Windows 2000 and later, and ignored the `Motion=` line in `v_on.ini`. The *Motion Type* radios on F5, which only offered 1/3 and 1/2 speed, now read **30 FPS** and **60 FPS**. |
| **Fix crash on round loss** | The game crashes when you lose as Temjin, Viper II, Apharmd or Raiden. |
| **Fix the lock-on line** | The line from the enemy to the distance readout flashed across the screen as a grey band when the enemy was far off to one side. |
| **Fix keyboard input after ALT+TAB** | Alt-tabbing away, or opening an F-key dialog, killed the keyboard for the rest of the session. Keys pressed in another window now still reach the game while it is running. |
| **Fix crash on ALT+TAB** | Switching away during the intro movie crashed the game on the way back. |

### Extra

Down to taste. All start ticked except the two boss patches.

| Patch | What it does |
| --- | --- |
| **[Native widescreen](#native-widescreen)** | Renders at 1920x1080 instead of 640x480, with menus and text redrawn and more of the arena at the sides. |
| **[XInput gamepad support](#gamepad)** | A modern controller for both players: twelve bindable actions, plus the arcade twin-stick scheme. |
| **[No disc required](#music)** | Removes the disc check and plays the soundtrack from `music\trackNN.wav` beside the game. |
| **Disable menu bar (Extras menu on F11)** | Hides the menu bar and moves its Debug options to a new [F11 dialog](#menus-on-the-f-keys). |
| **Better defaults with no v_on.ini** | What the game falls back on for any setting `v_on.ini` lacks, which on a first run is all of them: Sky on, all three Texture boxes on, Field Graphic Rich, Screen Large. |
| **Sound fixes** | Removes the built-in delay before each sound effect, raises the output from 22050 to 44100 Hz, and gives an enemy Fei-Yen back the hypermode sound a bug left silent. |
| **Intro, loading and ending screens** | The intro movie fills the window, with the black bars inside its frames cropped off. "Now Loading . . ." is hidden. Hold **A**, **Select** or Space for a second to skip the ending credits. The initials screen after them takes those buttons and either weapon trigger too, so 2P skips with **RT**. |
| **[Playable bosses](#playable-bosses)** | Jaguarandi and Z-Gradt as machines you can pick in a one-player game, once earned. Unticked by default. |
| **Pre-unlock the bosses** | Both bosses selectable from the start, without the earning. Needs Playable bosses. Unticked by default. |

### Menus on the F keys

The F11 dialog holds No shot, SE, CD, Kill 1P, Kill 2P, Scorekeeping and Quit Game.
**Credits** is new: it jumps to the credit roll from any match. With the gamepad
patch on, it also sets each player's [stick deadzone](#stick-deadzone). Like the
other F keys, it does nothing during an internet match or the intro.

| Key | Opens |
| --- | --- |
| **F1** | Help |
| **F3** | Pause |
| **F4** | High / low resolution (1080p / 720p with Native widescreen on) |
| **F5** | Graphic Settings |
| **F6** | Mode Settings |
| **F7** | Device Settings |
| **F8** | Sound Test |
| **F11** | Extras, the new dialog |

### About

**Version and credit in the game** is on by default. It prints the patcher's version
in the bottom right of the title screen and adds two lines under the title of the
ending credits. If either of the two files it rewrites is missing, the whole box is
skipped and everything else still applies.

### Add-ons

Open the collapsed **ADD-ONS** header and press **Install** on a row; the same button
reads **Remove** once installed.

| Row | What it is for |
| --- | --- |
| **[Internet play](#internet-play)** | Two-player versus over the internet. Both players need it. |
| **[Windowing and scaling](#windowing-and-scaling-cnc-ddraw)** | Windowed and borderless play through cnc-ddraw. |
| **[PowerVR renderer](#powervr-renderer-pvr-sgl-wrapper)** | Needed by the PowerVR version unless you have the card. **Apply patches** offers to install it. |

<p align="center">
  <img src="assets/readme/add-ons-section.png" alt="ADD-ONS section" height="360" />
</p>

## Native widescreen

**On by default.** The game renders at 1920x1080 itself, with the 3D view, menus, HUD
and text all drawn at that size and more of the arena at the sides, not a stretched
middle. Untick it for the original 640x480. The game still asks for exclusive
fullscreen, so for a window add
[cnc-ddraw](#windowing-and-scaling-cnc-ddraw).

| Area | What changes |
| --- | --- |
| **Resolution** | **F4** switches between 1920x1080 and 1280x720, in place of the stock 640x480 / 320x240. The **Screen** row on F5 offers the same as **1080p** / **720p**. The choice is saved to `v_on.ini`. |
| **HUD** | In a match the timer stays at the top left and the health bars are centred. The photo backdrops of the two-player machine select and waiting screens fill the screen. |
| **Split screen** | **Screen Split** on F5 offers **Ver** (side by side) and **Hor** (top and bottom). Side by side, the timer and health bars sit at the top of each half. The machine select is drawn once at full size. |
| **Text** | The pause, loading and credits text scales with the picture. The ending credits lose their black bands and roll across the whole screen. |

<details>
<summary>Screenshots</summary>

<p align="center">
  <img src="assets/readme/widescreen-match-1p.png" alt="Widescreen match, 1P" width="49.5%" />
  <img src="assets/readme/widescreen-machine-select.png" alt="Widescreen machine select" width="49.5%" />
  <br />
  <img src="assets/readme/widescreen-split-screen.png" alt="Widescreen split screen" width="49.5%" />
  <img src="assets/readme/widescreen-menu.png" alt="Widescreen menu" width="49.5%" />
  <br />
  <img src="assets/readme/widescreen-next-enemy.png" alt="Widescreen NEXT ENEMY screen" width="49.5%" />
  <img src="assets/readme/widescreen-2p-machine-select.png" alt="Widescreen two-player machine select" width="49.5%" />
</p>

</details>

## Playable bosses

**Off by default**, because it changes the game rather than fixes it. Jaguarandi and
Z-Gradt become playable in a one-player game. The patch adds them to the machine
select, fits the camera and the hangar to their size, and fixes every screen the game
drew for the eight only.

It is one player only, on purpose: the bosses are far stronger than the eight, so
two-player and internet play keep the select to the eight.
[BOSSES.md](docs/BOSSES.md) has the full account.

<p align="center">
  <img src="assets/readme/select-jaguarandi.png" alt="Machine select with Jaguarandi chosen, both bosses in the row" width="49.5%" />
  <img src="assets/readme/select-z-gradt.png" alt="Machine select with Z-Gradt chosen" width="49.5%" />
</p>

### Unlocking

| Boss | How to earn it |
| --- | --- |
| **Jaguarandi** | Beat it on Very Hard without losing a match earlier in the run. |
| **Z-Gradt** | Finish the game with any machine on Very Hard without losing a match. |

A continue counts as a lost match. **Pre-unlock the bosses** skips the earning. Each
unlock gets a screen of its own, and both are saved in `bosses.bin` next to the game,
which survives restarts, re-patching and **Restore original**.

### What changes

| Where | What changes |
| --- | --- |
| **Machine select** | An unlocked boss stands in the row after Raiden with its own portrait, and the countdown gives 20 seconds more to reach it. The Quick VR Select and Machine Color Select work on them too. |
| **In a match** | Each boss fights with its own weapons. Z-Gradt fires its super laser with Dash and has a fourth gauge for it under the other three. It cannot jump, so the jump button turns it to face the opponent. The chase camera, the KO replay and the win shots stand further back to fit them. |
| **Elsewhere** | The Player Data Report shows the boss itself, and the ending plays with it. |

<details>
<summary>Screenshots</summary>

<p align="center">
  <img src="assets/readme/unlock-jaguarandi.png" alt="The unlock screen for Jaguarandi" width="49.5%" />
  <img src="assets/readme/unlock-z-gradt.png" alt="The unlock screen for Z-Gradt" width="49.5%" />
  <br />
  <img src="assets/readme/match-jaguarandi.png" alt="Jaguarandi in a match against Z-Gradt" width="49.5%" />
  <img src="assets/readme/laser-z-gradt.png" alt="Z-Gradt firing its laser cannon, the fourth gauge under the three" width="49.5%" />
</p>

</details>

## Gamepad

**XInput gamepad support** rebuilds the F7 device list. The legacy joystick profiles
are hidden and four remain, available to both players.

| Profile | What it is |
| --- | --- |
| **[Gamepad (XInput)](#gamepad-xinput)** | twelve named actions, bound from the F7 screen |
| **[Twin-stick (XInput)](#twin-stick-xinput)** | the arcade levers, nothing to bind |
| **[Keyboard (Simple)](#keyboard-simple)** | every action on a bindable key |
| **[Keyboard (Real)](#keyboard-real)** | the game's own two-lever keyboard scheme, bindable |

Players on a pad profile take the connected pads in order, 1P first. With two pads,
the first drives 1P and the second 2P. With one pad and 1P on the keyboard, that pad
drives 2P.

Applying the patch moves `v_on.ini` aside, since the old binds do not fit the new
device list; see [What gets written](#what-gets-written).

<p align="center">
  <img src="assets/readme/f7-device-list.png" alt="F7 device list with the four profiles" width="350" />
  <img src="assets/readme/f7-bind-page.png" alt="F7 bind page for Gamepad (XInput)" width="350" />
</p>

### Buttons that work everywhere

| Button | Does |
| --- | --- |
| **A** | Accept - confirms menus, skips the win and lose screens, and skips the intro movie, the same as Space |
| **Select** | Camera, and skips the win and lose screens too |
| **Start** | Pause |
| **D-pad** | Moves, so it also drives the menus. Not bindable. |

The on-screen prompts follow the pad: the pause screen reads **PRESS START TO
UNPAUSE**, and the title and scoreboard screens read **Press A Button**.

<details>
<summary>Screenshots</summary>

<p align="center">
  <img src="assets/readme/pause-prompt.png" alt="Pause screen prompt" height="270" />
  <img src="assets/readme/title-prompt.png" alt="Title screen prompt" height="270" />
</p>

</details>

### Gamepad (XInput)

Sticks, triggers, bumpers and face buttons are all in the bind list, and the sticks
are read as eight directions.

Defaults for both players: left stick moves, right stick turns, LT and RB fire left
and right, RT fires both, LB dashes, A jumps, X guards. **Default** on the F7 page
puts them back.

**Soft reset:** hold **LB + RB + LT + RT + Start** together and the game returns to
the title screen from wherever it is, on either player's pad. Like the F keys, it
does nothing during an internet match.

### Twin-stick (XInput)

Each thumbstick *is* a lever, the way the cabinet worked, so nothing is bindable.

| Input | Does |
| --- | --- |
| Both sticks the same way | walk, strafe |
| Left down + right up, or the reverse | turn |
| Sticks apart | jump, and auto-face the opponent |
| Sticks together | crouch, which is the guard |
| **LT**, **RT** | left and right weapon; both at once is the centre weapon |
| **LB**, **RB** | the turbo buttons - dash in the direction you are moving |

### Keyboard (Simple)

The game's original all-keys profile. It shares the bind page with the gamepad, but
each sees only its own inputs and keeps its own saved set in `v_on.ini`, so switching
between them costs nothing.

### Keyboard (Real)

Keeps its own bind page. Two keyboard players cannot share a key: if 2P wants one 1P
already has, rebind 1P first. If 1P is on a pad, 2P can take 1P's keys. **Default**
resets whichever side you are editing.

### Stick deadzone

How far a stick has to move before it counts. It is 40% out of the box, set per
player in the *Stick Deadzone % [ XInput ]* box of the F11 Extras dialog (with
**Disable menu bar** on). **Defaults** puts both back to 40. Lower is more sensitive;
higher rides out a worn stick's drift.

<p align="center">
  <img src="assets/readme/f11-extras.png" alt="F11 Extras dialog" height="270" />
</p>

Closing the dialog saves each to its own `v_on.ini` line, which you can also edit by
hand. Two digits, `05` to `95`:

```ini
1P Deadzone=25
2P Deadzone=40
```

## Internet play

**Internet play**, under ADD-ONS, replaces the game's Link mode network layer with
plain UDP. One player hosts and gets a short code, the other types it in. No port
forwarding, no VPN. Direct IP is still there for LAN play.

<p align="center">
  <img src="assets/readme/internet-play.png" alt="Internet play dialog" height="360" />
</p>

### Before you start

> [!IMPORTANT]
> **Both players install the add-on.** Select `v_on.exe`, open **ADD-ONS** and press
> **Install** on the *Internet play* row. Nothing downloads; the DLL is inside the
> patcher. If the row says an older netplay DLL is installed, press **Install** to
> update it. **Remove** puts the stock file back, and you are on LAN-and-VPN play
> again.

Both players also need **Fix frame rate** and **Fix crash on round loss**. Both are
Essential, so only a copy from an older patcher can lack them, and a mismatch is
refused with a note saying so. Nothing else has to match.

### Playing with a code

This is the default, and nobody forwards anything.

1. **Host:** leave the connection on **Matchcode** and pick the **Region** nearest to
   you. Choose **Host a game** and press **OK**.
2. The dialog shows a code like `EU-ABCDE`, with a **Copy** button. Send it to the
   other player.
3. **Guest:** choose **Join a game**, type or paste the code in, and press **OK**.

The guest keeps trying until you cancel, so there is no rush to press things at the
same moment. Hyphens, spaces and case do not matter in the code.

| Region | Code | Server | Where |
| --- | --- | --- | --- |
| **Europe** | `EU-` | `segaonline.net` | Helsinki |
| **America** | `US-` | `us.segaonline.net` | New York |
| **Asia** | `JP-` | `jp.segaonline.net` | Tokyo |

<details>
<summary>How it connects</summary>

The letters in front say which server the code lives on, so the code is all the guest
needs. The two machines talk directly where the routers allow it and through the
server where they do not, so it works from anywhere with UDP.

All three servers listen on UDP 47625. **Custom** points both players at a server that
is not one of ours; its codes read `XX-ABCDE`. Once a match is running, a player who
quits or crashes is noticed within a few seconds.

</details>

### Playing by IP

For a LAN, or when you would rather not depend on the server. The host forwards
**UDP 47624**, picks *Host a game* and reads out their address; the dialog shows the
local one and looks up the public one on request. The guest types it in and needs
nothing forwarded.

## Music

The BGM is CD audio, so unpatched the game needs a disc or a virtual drive with the
audio tracks; a data-only ISO plays nothing. **No disc required** reads the music from
WAV files beside the game instead. With `music\` missing or empty it reads the drive as
before. This also works under Wine with no extra setup.

### Ripping the tracks

1. Use the same **Source** box as the install: one cue sheet holds the game and the
   soundtrack both.
2. Press **Rip soundtrack**. The tracks go beside whichever `v_on.exe` you pick, and
   the note under the buttons names the folder.

On Linux a drive works in **Source** too, a cdemu one like a physical drive. Windows
drives are not read; [image the disc first](#if-you-have-the-disc-not-an-image).

<details>
<summary>What it writes</summary>

The files go in `music\` inside the directory holding `v_on.exe`. About 320 MB: 26
tracks, roughly 30 minutes, uncompressed.

```
VIRTUAL-ON\
    v_on.exe
    music\
        track02.wav ... track27.wav
```

Track 1 is the data track and has no file. The numbering must match the disc, because
the game asks for tracks by number.

</details>

## Known issues

| Where | Issue |
| --- | --- |
| **Widescreen machine select** | Cosmetic only. The hangar floor does not reach the bottom left corner. After a continue on a space stage in one player, the gap shows a slice of stars. On 2P's full machine select it is black, on every version. |
| **Widescreen machine select** | Cosmetic only. On 2P's full machine select, machines pop in at the edges of the view on the four `v_on.exe` versions. |
| **PowerVR version** | 60 FPS at 1024x576 needs a fast CPU; see [The PowerVR version](#the-powervr-version). It has not been tried on Windows or on a real PowerVR card. |
| **Playable bosses** | The CPU's Z-Gradt may get stuck at the arena's edge, and its movement and attacks can differ from the unpatched game. Under investigation. |

## Troubleshooting internet play

Both of these are set beside `v_on.exe`, on your own machine.

### If a match freezes or plays badly

Force the relay: the match then goes through the server instead of connecting
directly, which is often steadier over a long distance. Open `vo-net.ini` beside
`v_on.exe`, creating it if it is not there, and add `relay=1` under `[net]`:

```ini
[net]
relay=1
```

One side setting it is enough. Take the line out again for a nearby opponent, since
direct is faster when it works. Matchcode games only.

### If it will not connect at all

Create an empty file called `vo-net.log` beside `v_on.exe` and try again. The DLL
writes what it did into that file, and it is what to send with a bug report.

## Builds

The patcher knows five builds of the game, and
[one more is wanted](#wanted-the-japanese-powervr-version). The window names the build
it is looking at; say which in a bug report, since the English retail build has had by
far the most play.

| Build | Size | MD5 |
| --- | --- | --- |
| English retail | 6,650,880 | `a464b0ff32d5bab499f265e45658504e` |
| USA OEM | 6,649,344 | `4c70f780a7f0d98d74be62304fb99021` |
| Japanese rerelease | 6,621,696 | `d19320bdc3381a48228990907910a391` |
| Japanese original | 6,644,224 | `9764d946ffc8cee94788707c91753478` |
| PowerVR | 8,412,672 | `383d3bff66504954f84924a0b41dc3fa` |

- **English retail:** the USA, USA Alt and European discs all carry the same
  `v_on.exe`, so any of them will do.
- **[Japanese original](https://redump.info/disc/133978):** the 1997 1.04J pressing,
  also found in the Sega PC Greatest Hits Vol. 3 bundle.
- **Anything else:** a repack, a bad rip or a copy already modified is refused, with
  its size and MD5 shown beside a supported build's. Installing and ripping work
  whichever build the disc holds; only patching needs one from the table.

## The PowerVR version

This version is a separate program, `vonpvr.exe`, made for PowerVR PCX1 and PCX2
cards. Redump has not verified its disc. The only known dump is on the Internet
Archive.

| Feature | `v_on.exe` versions | PowerVR version |
| --- | --- | --- |
| **Renderer** | Built in | Needs the [add-on](#powervr-renderer-pvr-sgl-wrapper), unless you have the card |
| **Native widescreen** | 1920x1080, on by default | 1024x576, off by default, needs a fast CPU |
| **Playable bosses**, **Pre-unlock the bosses** | Yes | No |
| **Version and credit in the game** | Yes | No |
| **HOLD TO SKIP** prompt | Yes | No; the ending credits can still be skipped |
| **Fix the lock-on line** | Yes | Not needed |
| **Internet play** | Yes | Yes, including against the other versions |

Rows it does not take are greyed out in the window.

### Native widescreen on this version

The card stops at 1024 pixels wide, so the game renders at 1024x576. **Screen Split**
on F5 offers **Ver** and **Hor**. F5 has no **Screen** row, and F4 stays the game's PVR
Settings.

> [!WARNING]
> 60 FPS at this size needs a fast CPU: a
> [PassMark single-thread rating](https://www.cpubenchmark.net/singleThread.html) of
> about 4,000 or higher, estimated from the few CPUs tried. Below that, set 30 FPS on
> F5 or leave the patch off. Its row starts unticked and warns you when ticked.

<img src="assets/readme/powervr-widescreen-warning.png" alt="The warning shown when ticking Native widescreen on the PowerVR version" height="258" />

It runs on Proton without [cnc-ddraw](#windowing-and-scaling-cnc-ddraw); if the game
cannot set the mode, add cnc-ddraw.

### PowerVR renderer (pvr-sgl-wrapper)

The game draws through `sgl.dll`, which came with the card's driver and is not on the
disc. Without it, the game does not start.
[pvr-sgl-wrapper](https://github.com/z2k-retro/pvr-sgl-wrapper) replaces it and
emulates the card on the CPU. The row is greyed out for the other versions.

**Apply patches** offers to install it, and **Install** under ADD-ONS does the same. It
downloads the current release from
[its releases page](https://github.com/z2k-retro/pvr-sgl-wrapper/releases) and puts its
`sgl.dll` beside `vonpvr.exe`. The same button then reads **Remove**, which deletes it
again.

<img src="assets/readme/powervr-renderer-prompt.png" alt="The prompt offering to install the PowerVR renderer" height="189" />

Wine has no `sgl.dll` of its own, so nothing needs setting in `winecfg`. With
cnc-ddraw, keep `singlecpu=false` in `ddraw.ini`. Tested with release 0.1 under Wine and
Proton.

### Texture=7

Without a Texture value in `v_on.ini` the machines are black, and this version's F5 page
cannot set one. The installer writes a `v_on.ini` with only `Texture=7`, and the gamepad
patch keeps that value when it moves the file aside.

### Wanted: the Japanese PowerVR version

One known release has no dump yet: NEC's Japanese release of the PowerVR version, seen
packed with the manual of its PC 3DEngine2 card. Look for `VRNHE706` and the NEC logo on
the disc. `SPB-016` is on the English disc too, so it does not tell them apart. The
English disc reads *O.E.M. Product, Made in USA*.

If you have this disc, please write to
[pairo@segaonline.net](mailto:pairo@segaonline.net) so it can be preserved and supported.

## Windowing and scaling (cnc-ddraw)

The game asks for exclusive fullscreen at its render size, which on a modern panel can
mean a stretched picture or no windowed mode.
[cnc-ddraw](https://github.com/FunkyFr3sh/cnc-ddraw) replaces the DirectDraw the game
renders through, adding windowed and borderless modes, correct aspect ratio and
upscaling. Every patch here works with it.

<p align="center">
  <img src="assets/readme/cnc-ddraw-row.png" alt="cnc-ddraw row under ADD-ONS" height="360" />
</p>

### Installing

**Install** under ADD-ONS downloads the current release from
[its releases page](https://github.com/FunkyFr3sh/cnc-ddraw/releases) and unpacks it
beside `v_on.exe`: `ddraw.dll`, `ddraw.ini`, `cnc-ddraw config.exe` and the shaders.
The same button then reads **Remove**, which deletes the files again but keeps `ddraw.ini`, so re-running to update leaves
your settings alone. Close the game first: Windows will not replace a DLL that is
loaded.

> [!IMPORTANT]
> **On Linux there is a second step.** Set `ddraw` to native in `winecfg` for that
> prefix, or run `cnc-ddraw config.exe` once. Without it Wine keeps using its own
> DirectDraw and nothing changes.

The intro movie does not go through DirectDraw, so upscaling leaves it small and in the
corner. **Intro, loading and ending screens** under Extra fits it to the window; without
that, skip it with Space, Enter, Escape or pad A.

<details>
<summary>The settings it ships with</summary>

A fresh `ddraw.ini` is cnc-ddraw's own file with `fullscreen`, `windowed`, `maintas`,
`noactivateapp`, `toggle_borderless`, `devmode` and `game_handles_close` set to `true`,
`singlecpu` set to `false`, and scaling set to nearest neighbour
(`shader=Nearest neighbor`, `d3d9_filter=0`). That gives a borderless window at the
right aspect ratio, with hard pixels, that does not trap the cursor. Change any of it
with `cnc-ddraw config.exe`.

`game_handles_close` is the one that is not about the picture: without it, closing the
window loses your settings and records for that session. If you already have a
`ddraw.ini`, add the line by hand:

```ini
[ddraw]
game_handles_close=true
```

The PowerVR version needs `singlecpu=false`. With cnc-ddraw's default of `true`, the
`sgl.dll` replacement is held to one CPU core and the game runs in slow motion. Set it
in an existing `ddraw.ini` the same way.

</details>

### gamescope

gamescope handles the scaling without a DLL, if you would rather:

```bash
gamescope -W 1920 -H 1080 -w 640 -h 480 -f -S integer -- %command%
```

`-S fit` fills more of the screen without whole-number scaling.

## What gets written

The original is copied to `v_on.exe.bak` first, and nothing is written unless every
selected patch applied, so a failure leaves the game as it was.

Some patches touch more files:

| Patch | What else it writes |
| --- | --- |
| **XInput gamepad support** | `v_on.ini` is moved to `v_on.ini.bak` and the game writes a fresh one, because binds saved by the unpatched game do not fit the new device list. The title artwork, `escrgame.bin` or `jscrgame.bin` on the Japanese builds, gets the new title prompt, after a copy is kept as `.bak`. |
| **Playable bosses** | The bosses' portraits go into the same artwork file, backed up the same way. |
| **Version and credit in the game** | Backs up and rewrites the two credit roll files. |
| **Pre-unlock the bosses** | Writes `bosses.bin` beside the game, which **Restore original** leaves alone. |

> [!WARNING]
> Use **Restore original** rather than copying a `.bak` over by hand. It puts every
> backed-up file back, keeping whatever the patched game wrote as `v_on.ini.patched`.
> The artwork and `v_on.exe` have to match, and restoring one alone draws the title
> prompt as scrambled letters.

## Running the Python script

The patcher is one Python script, `v-on-patcher.py`; the Windows download is that script
with Python beside it. `v-on-patcher-*-python.zip` from the
[latest release](https://github.com/pairomaniac/v-on-patcher/releases/latest) is the
script with the netplay DLL beside it in `net/`, nothing else.

| System | How to run it |
| --- | --- |
| **Windows** | `py v-on-patcher.py`, with Python from python.org, which ships Tk |
| **Linux** | `python3 v-on-patcher.py`, after installing Tk |

```bash
sudo apt install python3-tk        # Debian, Ubuntu, Mint
sudo dnf install python3-tkinter   # Fedora, RHEL
sudo pacman -S tk                  # Arch, EndeavourOS
```

Everything the patcher does is also available without a window:

```bash
python3 v-on-patcher.py --install IMAGE DIR  # the game, out of a .cue or .mds
python3 v-on-patcher.py --install IMAGE DIR --language GERMAN  # with that manual
python3 v-on-patcher.py --rip SOURCE DIR     # soundtrack, from a .cue, .mds or drive
python3 v-on-patcher.py --rip /dev/sr0 DIR   # from a drive (Linux)
python3 v-on-patcher.py --rip                # list drives (Linux)
python3 v-on-patcher.py --ddraw DIR          # fetch and install cnc-ddraw
python3 v-on-patcher.py --sgl DIR            # fetch the PowerVR sgl.dll replacement
python3 v-on-patcher.py --netplay DIR        # install the UDP netplay DLL
python3 v-on-patcher.py --netplay DIR --remove  # put the stock one back
```

## Working on the patcher

[docs/README.md](docs/README.md) maps the developer documentation:
[DEVELOPING.md](docs/DEVELOPING.md) for the checks, the release and the Windows build,
[NOTES.md](docs/NOTES.md) for what each patch does inside the game, and [asm/](asm/) for
the machine code the patches install.

## AI disclaimer

<details>
<summary>How LLMs are used here</summary>

LLMs are part of the toolchain here: much of the assembly and the documentation was
written with one. The reverse engineering was not. The addresses and the behaviour each
patch relies on come from tracing and debugging the running game with Ghidra, gdb,
winedbg, Cheat Engine and Unicorn, and the LLM writes to that brief. The scope, the disc
dumps, the testing and the debugging are human. The patcher edits the game's own files
and adds its code beside them; it is not a reimplementation of the game.

Every change is read line by line before it goes in, and every patch is played on all
four builds before it ships. Offsets and bytes are verified against the originals before
anything is written, and the patcher refuses any file that is not an unmodified build it
has tables for. It is still a hobby project poking at a nearly 30-year-old binary, so
expect bugs.

</details>

## Credits and licence

The logo, the icon and the in-game shots above are the work of SirRockEmSockEm.
**Playable bosses** is the work of [Vortyne](https://github.com/Vortyne). Some of the
byte edits go back to VO_Patch 0.43 (2008) by
[UE2A-GEL](https://jaguarandi.xxxxxxxx.jp/).

The game and everything in it belong to SEGA. `LICENSE` (MIT) covers the patcher, its
tools and its documentation. It does not cover the game, the bytes quoted from it, the
letterforms traced from its artwork, or the two boss portraits, which are pixel art
after SEGA's renders of the machines.

Bug reports and patches are welcome as issues and pull requests. For anything else, such
as a disc image of a build the patcher does not know, write to pairo@segaonline.net.
