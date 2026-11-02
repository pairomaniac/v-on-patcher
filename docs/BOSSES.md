# Playable bosses

Jaguarandi and Z-Gradt as player machines in a one-player game. You earn
them by beating them, then pick them on the machine select like the
eight. The patch is **Playable bosses** in the patcher's extras, unticked
by default. **Pre-unlock the bosses** beside it skips the earning. The
source is [`asm/bosses.asm`](../asm/bosses.asm). This page says what the
patch does, then how.

## For players

### Unlocking

- **Jaguarandi** - beat Jaguarandi on **Very Hard** without losing a match
  earlier in the run.
- **Z-Gradt** - finish the game with any machine on Very Hard without
  losing a match.

The two are earned apart.

A continue counts as a lost match. Changing the difficulty spoils the run.
Only a new game from the title starts a clean one.

Each unlock gets a screen of its own. The boss turns on the left of a
black screen. YOU UNLOCKED and its name stand on the right in the select's
lettering, and the title jingle plays. PRESS BUTTON TO CONTINUE flashes at
the bottom after five seconds. Only a fresh press moves on; a button held
from the fight does not skip it. The press is answered with the select's
cursor sound, and the boss leaves the screen with it. The buttons are the
report's own (Start and the two triggers) and the ones that skip the
credits: A and Space, Select and the camera key. The twin-stick profile's
triggers do not reach the screen, since outside a round the pad tick does
not read them; its A does.

Jaguarandi's screen comes straight after it falls, before the Player Data
Report. Z-Gradt's comes after the credits, before the initials. The game
then carries on as it would have.

Unlocks are kept in `bosses.bin` beside the game, a dword: 0 none, 1
Jaguarandi, 2 both, 3 Z-Gradt alone. They survive restarts and
re-patching. **Pre-unlock the bosses** writes the file with both unlocked.
It never takes progress away. **Restore original** leaves the file alone,
since the unpatched game never reads it.

### The machine select

- An unlocked boss stands in the row after Raiden: Jaguarandi first, then
  Z-Gradt raised on the hangar's lip. A locked boss is not there at all.
  With Z-Gradt alone, Jaguarandi's bay between stands empty and the
  cursor steps over it, the walk taking both gaps in one.
- Each boss has a portrait of its own in the row along the bottom, after
  Raiden's. The portraits are pixel art drawn after SEGA's renders of the
  two machines, Z-Gradt's mirrored, in the eight's style: framed and
  backed the same way, at the same 48 by 64. A locked boss's place stays
  blank.
- The portraits, the 1P/2P marks and the red frame move left to make
  room: four columns with Jaguarandi, seven with both. The row stays on a
  4:3 screen. With nothing unlocked the select is exactly the original.
- The Quick VR Select, the game's option, has the bosses too. It gets the
  same row, cursor and colours, and a boss's name and weapons where it
  writes the eight's.
- The countdown runs 20 seconds longer with a boss unlocked. The walk to
  the end of the row and the extra colours need the time.
- The bosses are lit in their own colours like the eight. The widescreen
  hangar fades them at the right edge as it does the others.
- **Machine Color Select**: up and down on a boss cycle it through its
  own colours and the eight colours of each of the others. It can wear any
  of them.
- Each boss launches from the hangar. Jaguarandi takes Raiden's launch
  animation. Z-Gradt lifts off the lip and out through the tunnel. The
  water, the splash and every machine's thrust keep their own colours
  throughout.

### In the game

- Both bosses play as player machines on every stage, including Z-Gradt
  against Z-Gradt on the last one.
- The KO replay and the win and lose shots pull back to fit a boss's
  size. The replay's never pulls downwards. Jaguarandi grows through its
  win pose, as the game has it, so its win shots stop 250 units out where
  the game's stop at 15. On a small arena the win shots that need floor
  under the camera try a turn at the boss's distance, then four turns
  each a quarter nearer the usual, then the usual.
- The bosses' chase camera is the game's own, with its modes, its glide
  between them and its pan as the opponent jumps. It stands further out:
  two and a half times as far for Z-Gradt, half as far again for
  Jaguarandi. Neither closes in as the opponent comes near. Z-Gradt's
  never levels out below its high angle as it turns on the spot, and it
  turns with Z-Gradt.
- Jaguarandi's red segments, on its legs and back, stay in view. The
  game's own draw let the faces beside them cover them at some depths, so
  they flickered as it walked and went out as it turned.
- Z-Gradt's fly-in starts part of the way in rather than beyond the
  arena's backdrop. Indoors (Deathtrap, the Spaceport, the Secret Base)
  it only drops into place. Outdoors it comes in from 784 units out, and
  nearer still over the Green Hills. GET READY's count waits for it to
  land before the round starts, 600 frames at the most. On the last
  stage the CPU's Z-Gradt flies in instead, and the round starts as it
  always did.
- Z-Gradt's super laser fires on Dash. On the twin-stick profile either
  turbo button does. The game had it on Guard, both levers pulled in.
  Z-Gradt has no dash, so the button was free, and Guard now does nothing
  on it. It fires on the press, not while the button is held.
- The laser has a gauge of its own: a fourth strip under the three, named
  CANNON (the hangar's LASER CANNON). While the cannon deploys and charges
  the bar is drawn as the game draws a close-combat weapon's bar with the
  opponent in reach: full, in its third colour, pulsing in height. The
  beam empties it. It climbs back as the game's bars refill, and is blue
  again as the cannon finishes folding away. Dash held on the empty bar
  gets what a weapon's button gets on an empty bar: CHARGING over the
  name, the refusal sound once, and the bar swollen until half a second
  after the button is up.
- Z-Gradt's three strips stay full, since the game does not count its
  shots. While a weapon's button is held its strip turns to the live
  colour, so a press has a tell.
- A boss keeps its colours through a continue.
- The KO replay plays Z-Gradt's super laser as it was fired, its beams
  and particles in step with the pose. A laser KO goes on to the win or
  lose screen, pose and call included, as any other KO does.
- Z-Gradt has no jump. The jump, both levers out or the jump key, turns it
  to face the opponent instead: a half turn in 64 frames, with the camera.
  Not while its super laser is out.
- Z-Gradt moves on the arena it is on. It stops at the arena's edge and at
  the walls and obstacles the eight stop at, and its height follows the
  ground. On the last stage it keeps the game's own bounds, a square 280
  units each way from the middle. The CPU's Z-Gradt keeps them everywhere.
- Z-Gradt's laser turns the right Z-Gradt gold when both are on the field.
  A Z-Gradt that falls darkens alone; the player's keeps the colours it
  was given.
- The Player Data Report after stage 5 turns the boss itself: Jaguarandi
  in its select pose, as on its unlock screen, and Z-Gradt standing.
- The scoreboard names them Z-GRADT and JAGUARANDI. The game's own table
  has them as Z-GRAT and JAGARANDI, which no one saw while they could not
  be played. The attract's TODAY'S TOP OF WINS list takes the name from
  the machine's model header, which had Z-Gradt as ZIG-RAHT. It reads
  Z-GRADT too.
- The ending plays for a boss. Jaguarandi fires its own weapon at the moon
  gate, and Z-Gradt its own charge and laser. Then the text and the
  button wait follow. The staff roll is skipped, since its battle-damaged
  model is one the bosses do not have.

### Limits

- One player only, by design. The bosses are far stronger than the eight,
  so two-player and internet play keep the select to the eight for a fair
  fight. Nothing here runs there. The two-player hangar is the game's own
  lineup.
- The bosses' weapons have no ammo to speak of, as the game's own code has
  them. Z-Gradt's shots are made outside the charge counting, and
  Jaguarandi's refill faster than it can fire.
- `bosses.bin` is written beside the game when a boss is unlocked. Where
  the folder cannot be written, the unlock screen still shows but the
  unlock is lost at exit.
- The bosses' model files, `RB_jag.bin` and `RB_zig.bin`, are read into
  blocks of the patch's own when the select first draws each. If a read
  fails, that boss is drawn from whatever the model pool holds in its
  slot until a fight loads it.

## How it works

The game already knows the bosses as fight objects. The initials demo
fights 8 against 9, so the objects work as a player's. What does not work
is everything the game only ever did with the eight: tables eight rows
long, loaders that send ids above 7 elsewhere, screens framed for their
size. `asm/bosses.asm` is one hook per such place.

The game keeps a copy of its fight machine per player. A, at
`0x1ae0xxxx`, is player 1's and B, at `0x1ef8xxxx`, player 2's; the
letters are the ones `docs/HIRES.md` gives their renderers. B's tick
(`0x40f528`) is only called from the frame loop's two-player branch, so a
one-player game never runs it. Every hook is A's. Whether the player is a
boss is one flag, `boss`, which confirm sets in one player only. The
sections below follow the file.

The blob has a section of its own, `.vobs`. The patcher appends it only
when the box is ticked, so unticked it leaves the executable as the other
patches alone would. The blob's buffers are gathered at its end: the
bosses' motions, the model and AI copies, the replay's ring, the saved
palettes and the rest, 263,217 bytes. The file carries the blob only as
far as its last byte that is not zero, 16,871 bytes. The rest is the
section's virtual size, which Windows zeroes at load (`OWN_SECTIONS`).

### The select's row

The select is a scene script: the camera, the eight 20 apart, the hangar.
The patch builds a longer copy with two records after Raiden's and points
the game at it. It extends the tables that turn a cursor into a machine
and an object into a machine to ten, and raises the cursor's limit by the
unlock level (`selmax_a`). The camera's step is 30 to Jaguarandi and 98 on
to Z-Gradt, which also rises onto the lip (`selstep_*`).

The bosses' models are their fight models posed by the select's motions.
Jaguarandi is posed through Raiden's, with its head put back on. Z-Gradt
stands in its stance's first frame. Each file is read once into a block
of its own (`sel_loadrb`); a file that is missing or short is not
installed, and its block is freed. The game's model slot points there
only while the boss is drawn (`sel_slotsin`, `sel_slotsout`), and the
game's own pointer is kept and put back. The files are not appended to the game's
8 MB model pool, because after a full game that runs into the C runtime's
heap. The game's own copy of the file, present on a continue's select, is
never drawn here. `selcol` turns the colour words of the polygons it
draws to the select's rows and never back, and the game fights on with
its copy.

The portraits are `assets/portrait_jaguarandi.png` and
`assets/portrait_z-gradt.png`, 48 by 64 and framed like the eight's.
`tools/portraits.py` bakes them into the patcher as the select's 16-bit
colour. Pure black, the tiles' transparent colour, becomes the eight's
near-black backing. The patcher writes them into `escrgame.bin`, backed
up first, in the 80 empty tiles after two of the eight's portraits
(`BOSS_ICON_TILES`). `selrow_make` builds the row with them on entering
the select, blank for a boss still locked.

The row's portraits, the marks and the frame are shifted per unlock level
(`selshift`). The frame sprite reads its x from two doubles in the game's
read-only data (`BS_FRX`), so the patcher makes that section writable and
the select sets them. The countdown's start is `seltime`.

### Colours on the select

How the game picks a palette:

- Palette RAM (`0x1cb5500`) is three planes of 32 rows of 256 entries. A
  polygon names its row per plane through its colour word in the mesh
  (`+6`). The word's top ten bits index a table of colours (`0x66c2c8`),
  and each colour byte's top five bits are that plane's row. The raster
  reads the word from the mesh later in the frame, not when the polygon
  is queued.
- The bosses' meshes name the greys of rows 1 and 3 (5 and 7 as the
  CPU's). Those are the rows the select fills with the machine under the
  cursor and its neighbours, 1 to 11 as the cursor moves. A boss drawn
  through them takes the colours of whatever the cursor is on, or none.
- The odd rows from 13 are set once at boot. 13, 17 and 19 are the launch
  thrust. The select rewrites 21 for a frame on each move and 23 as it
  opens. The launch water reads 21 and 25, and the fight re-animates 21 to
  29.

So on the select each boss borrows two rows the select itself leaves
alone: Jaguarandi 21 and 25, Z-Gradt 29 and 15 (`sel_bslots`). Their own
contents are kept when the select opens. They are put back the moment a
launch starts and when the select ends (`selpalguard`, `selpalback`). The
boss's palettes go in each tick and again as it is drawn, after the
game's one-frame write to 21 (`seljagpal`, `seldrawpal`). The entries a
palette load leaves untouched are copied from row 1, since the widescreen
fade reads them as the boss goes dark (`selrest`). While a boss is drawn,
each of its polygons queued that names rows 1, 3, 5 or 7, or another boss
row, is turned in its copy of the mesh to the table's grey of its own row
(`selremap`, `selcol`).

A launch shows on the scene objects. Every machine's goes to 1 as the row
moves aside, the launching one's to 2, and the cursor field turns into
the object's number. A launching boss is drawn through rows 1 and 3,
which the game leaves alone on a boss, so all four borrowed rows are the
game's again for the water.

The widescreen hangar shades a machine by how far right of the camera it
is, black past 28.43, a machine and a half at the eight's spacing.
`selfade` recomputes that shade for a boss, counting each gap between it
and the camera as one of the eight's 20. `selcull_a` draws a boss out to
where that count reaches 28.43: 38.43 for Jaguarandi, 110.65 for Z-Gradt.
So each comes into view black, as the eight do. The camera's place is
read where the hangar reads it (`BS_SELCAM`): 0xac8 past the scene's
objects on three builds, 0xc58 on the Japanese rerelease.

### Unlocking

`unl_tick` follows the run. It is clean at the start of a game. A
difficulty other than Very Hard, two players or a lost match spoils it
(`unl_lost`, at the game's own count). Beating Jaguarandi clean replaces
the report's `mov [state], 0x1c` with the unlock (`unl_jag`). A clean
final win replaces the initials' `mov [state], 0x16` (`unl_z`). The
unlock screen is the report's own state, 0x1e, driven by `unl_logic` in
place of its handler. The turning model is the report's (`model_ra` with
the CPU's standing copy). The text is the report's big font. The name is
the select's logo tiles carried over (`unl_grab`, `unl_place`). The
palettes are saved and given back whole.

Z-Gradt's screen comes after the credits, which load the dock's scene and
texture bank. The name entry's arena, glowing orbs included, is a snapshot
taken before and put back after (`unl_scnsave`, `unl_scnback`), and the
texture bank the fights had loaded is reloaded.

### Elsewhere in the game

- **Palettes** - the loader (`0x4f358b`; `0x4c2026` is the other copy's)
  sends ids above 7 to a fixed table. For a player's boss it gives the
  colour pair the boss was given on the select instead, from the side its
  player's machine uses.
- **PLAYER DATA** - the report's turntable reads per-machine tables only
  the eight have rows in. A boss is drawn by its fight object, or its
  select pose for Jaguarandi, from a standing copy taken at the start of
  its last round. Everything the draw touches is put back.
- **Round animations, the ending, Z-Gradt's camera, Z-Gradt against
  Z-Gradt, Z-Gradt's gold, the replay and the win shots** - each is
  rerouted for ids 8 and 9, as its section in the source explains.
- **The player's Z-Gradt** - its fly-in starts by the arena loaded
  (`zflyin_a`, `zf_start`). GET READY's count is held at its end till it
  lands (`zready_a`). Its facing goes to the chase camera each frame. The
  jump turns the facing to the CPU at the CPU's own aim (`zlock`), and
  Z-Gradt's own code turns its model with it.
- **Z-Gradt's floor** - its moves ask `zfloor_a` where the ground is at
  the place they go. For the CPU's Z-Gradt, and the player's on the last
  stage, that is the game's own box (`BS_ZBOXA`); elsewhere it is the
  arena's floor as the eight read it (`BS_FLOORA`). The test is the stage
  number, not the arena id: the last stage's field is id 8, and id 6 is
  MOON BASE, a regular stage. A wall comes back as the query gives it. A rise over 4
  units above the floor under it comes back as a wall facing the way it
  moves. A smaller rise comes back as its height now plus the rise, so
  it never sticks on a floor it landed below.
- **Z-Gradt's super laser** - the trigger in its tick reads the guard
  gesture's byte, 0xff once both levers have been held in. For the
  player's it reads the two turbo bytes instead (`zfire_a`). They are
  0xff on the frame a turbo goes down, and the Dash bind sets both.
- **The KO replay** - the game copies both objects into a ring of 30
  slots every fourth frame. The replay rewinds them from it and runs the
  recorded levers on. Z-Gradt's laser keeps its state in the AI globals,
  outside the object, so a rewound object was behind its laser. `zring_a`
  keeps those globals, the player's bank and the lock-on in a ring of its
  own, filled and read in step with the game's, at the twelve places
  object A is copied to or from the ring.
- **Z-Gradt's laser gauge** - the HUD's three weapon strips are drawn by
  one routine from the HUD pass. Each is a bar quad on the matrix scaled
  by its fill, with its name in tiles. `zgauge_a`, at that routine's end,
  stands a fourth at the middle strip's column one row down. It is filled
  from the laser's state as a strip fills from its weapon's heat word.
- **How a strip fills** - a weapon's shot adds its cost to the heat word
  on the frame its motion launches the shot. The heat runs down one a
  frame. The bar is the heat's shortfall from the weapon's maximum in
  whole percent, and the weapon is ready while a shot's cost still fits.
  The laser's shot launches at its beam, state 0x104. Its cost is the
  rest of the cycle, 261 frames to idle, so the bar is the frames since
  the beam as a percent, red until idle. Through the deploy and the
  charge it is drawn as a strip whose ready byte has bit 2, a
  close-combat weapon with the opponent in reach: full, in the third
  material, its height 6 plus 3 sin (frame << 12) in place of 5, and
  ready.
- **The laser's button** - while both turbo bytes are down with the bar
  not ready, the gauge puts the strips' CHARGING block over the name
  through the game's own routine for the three. It plays the refusal
  sound once per hold and swells the bar for thirty frames, cleared the
  moment the laser is ready. With the button up it clears the block and
  prints the name.
- **Z-Gradt's strips** - `zbar_ra`, `zbar_la` and `zbar_ba` stand in
  place of each strip's push of the ready material before its draw. They
  push the live material instead while the weapon's button byte (+0x138,
  +0x139, +0x13a; nonzero while the button is down) is set on the
  player's Z-Gradt.
- **Jaguarandi's red segments** - the renderer draws a frame's polygons
  nearest first, and each keeps the pixels it covers. The key is a
  polygon's nearest vertex's depth, in buckets 1/256th of the depth wide;
  within a bucket the polygon queued later is drawn first. The segments
  are the model's luminous light group, each in the plane of a face of a
  neighbouring part, and the two swap buckets as the legs move. `jlum_a`,
  at the mesh draw's store of the key, moves a luminous polygon one
  bucket nearer when the polygon lies in Jaguarandi's file. The file is
  found through the loader's slot table wherever it is, the select's own
  copy included. The eight use the group too and are left alone.
- **The Quick VR Select** - its own cursor limit, colour select and hiding
  before a launch go to the hangar's hooks. Its texts for a boss go to
  `selqinfo_a`, over the ones it writes for no machine.
- **The 1P and 2P marks** - the row they sit on is cleared before they
  are drawn, 62 tiles from its start. With the row shifted, the clear
  starts the shift earlier and goes that much further (`selclr_a`).
  Without that, a mark on the first portrait stayed.
- **Z-Gradt's death** - it darkens through palette events 0x401 to 0x43f,
  which the handler takes to be the CPU's. The player's are passed over
  (`zdark_a`, `zfade_a`).
- **Z-Gradt's launch flames** - Raiden's booster meshes come from
  Raiden's fight model, which the select loads only when the cursor
  passes Raiden. After a continue the cursor starts on Z-Gradt, so the
  launch loads the file as the select would (`BS_LOADFILE`).

## The PowerVR build

The bosses work on this build as on the others, with the differences below. Its
machines' colours and textures go through the card, so its select does more of the work
itself.

The fight code, the palette RAM (`0x1e159a0`) and its expansion (`0x5753a1`) work as
on the other builds. Addresses come from retail, checked against the rerelease, whose
stack frames and AI state (at `0xd68910`) this build shares. Its clone's frame is
retail's, 0x44.

How its select differs:

- **The slots.** A mesh pointer's top nibble goes through `0x825514`, the same scheme
  as retail's, but by machine id: Jaguarandi's slot is `0x825538`, Z-Gradt's
  `0x82553c`. Retail's go by the file's name.
- **The loader.** The select's loader (`0x57f03f`, mode 1) reads each machine's
  `BSel_*.bin`, which the bosses do not have, so `loader` takes them off its list.
- **The textures.** A model's polygons differ from its file once loaded, in paired
  fields, which look like texture references being rewritten. So `fclose`, when
  `sel_loadrb` closes a boss's file, runs the game's routine (`0x57d7c0`) on the block.
  `drop` lets the textures and block go at the next load that is not the select's, and
  when the game frees every model's textures (`0x57e29d`, `freeall`). The routine has two
  places for these models (`0x824d6c`, `0x824d70`), and the attract demo leaves its two
  machines in them, so `vacate` frees any of the eight first. Without that the bosses
  drew flat after a reset, which runs the demo.
- **Jaguarandi's colours.** This build keeps them in texture files, not palettes:
  `RJAG.VRB` and one per opponent, `RJAGTEM.VRB` and so on, picked in `0x56d4f0` by the
  other machine's id. The player's and the select's use `RJAG.VRB` (`ownside`). The
  CPU's keeps the stock choice.
- **The launch camera.** Its table is at `0x6428a8`, and this build reads it before the
  player's field where the others read the field first, so its sites are not the others'
  order.
- **Z-Gradt's launch flames.** They are in Raiden's select file, so `loader` keeps that
  listed with the cursor on Z-Gradt or Z-Gradt taken, and `BS_LOADFILE` does nothing
  here. `0x580865`, which a map gave for it, loads a scene: given Raiden's 3, it loaded
  Green Hills' (`FC_Fore.bin`, `FFOR.VRB`) and broke the hangar's textures. A flame record
  here has a fourth field, for the other mode, so `flames` gives Raiden's in the other
  builds' shape.
- **The draw.** `0x5c9ba3` has a bigger frame than the other builds', which `selmdl`
  makes up, and its bone is at `SEL_BONE`, -0x10.

Not done:

- **The hangar's picture.** Played, it shows polygon pop-in or fighting and looks
  unstable. In the rig, parked on Temjin, Jaguarandi and Z-Gradt, nothing flips but the
  ceiling lights, weapon edges, text and cursor frame, and the bosses add nothing on
  Temjin. Not looked at while the camera moves, and not compared with retail. The cause
  is not known.
- **Stand-ins.** `BS_MTSELMEM` and `BS_LOADTEX` hold stand-ins, for Z-Gradt's unlock
  screen, which has not been run.
- **`jlum_a`** is wired since the red segments flickered in the hangar, though not in a
  fight, without it. Whether it cures that has not been played.

Played: the portraits, both bosses in fights, their models, launches and cameras, their
textures after a reset, and Z-Gradt's flames. Jaguarandi has no launch flames, by design.
Neither boss shows on the continue screen, as on retail.

Seen in the rig, with a hidden display and the debug kill:

- Both bosses through the row with their models, the launch, a round, a KO, its
  replay, a loss, the continue screen and `GAME OVER`.
- Both bosses back on the select after a continue, textured, and Z-Gradt after a game
  over and a new game, and after the reset (writing -1 to the mode word) and the attract
  demo. Jaguarandi in `RJAG.VRB`'s colours, on the select and in a round.
- Before the models were in: a whole game as Jaguarandi to its ending, name entry and
  the scoreboard, then a normal game with Temjin to the credits.
- Before the models were in: Z-Gradt through the stages and the report, and on the last
  stage against the CPU's Z-Gradt to its charge, laser and ending, reached by writing
  the stage.

Seen and not explained:

- A whole game as Z-Gradt stopped at the last stage's ending. The kill came on the
  round's first frame, and the state then went between `0x1f` and `0x20`. A player
  cannot win that early, but the cause has not been confirmed.
- The screen went solid red for some seconds in that last round as Z-Gradt. The other
  builds have not been compared.

Not tried: the unlock screens, Z-Gradt's laser on Dash, its gauge and turn, arena edges,
and Jaguarandi on the report with the models in.

## Testing it

- `bosses.bin` beside the game: delete it to start locked, or write the
  dword 1 (Jaguarandi), 3 (Z-Gradt) or 2 (both).
- `python3 tools/selftest.py v_on.exe` checks every site and 437
  combinations of patches, including the two boss boxes with and without
  each other. `python3 tools/portraittest.py` on the game folder reads
  the portraits back out of `escrgame.bin`. `tools/check.py` runs both.
- The per-frame tick runs from the loop's idle call. The loop's message
  check (`0x5c6783`) skips the call on a frame with F10, F3 or Alt
  queued. The unlock screen's state is cleared only by its own button
  press.
