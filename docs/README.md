# Documentation map

The root [README](../README.md) is for playing: installing, what each patch
does, internet play, the gamepad, music, resolution. Everything here is for
working on the patcher.

| Read | For |
| --- | --- |
| [MAP.md](MAP.md) | where things are: the repository, the regions of `v-on-patcher.py`, and the executable's layout - stock sections, the game's code and data as far as it is mapped, the sections the patcher appends, the annex blob by blob, sites by patch |
| [DEVELOPING.md](DEVELOPING.md) | setup, the daily loop, the checks and what each catches, adding a blob, a site or a build, netplay development, releasing, signing and the Windows build, troubleshooting |
| [NOTES.md](NOTES.md) | how each patch works inside the game: the patch table with every site, the builds and how their offsets map, and a section per patch on what the game does and why the change is what it is |
| [TEXT.md](TEXT.md) | the three ways the game draws text, where each string the patcher touches lives, and how the title banner and the credit line are made |
| [BOSSES.md](BOSSES.md) | the playable bosses: what a player gets - unlocking, the select, the game - and how it works, the select's palette rows above all |
| [HIRES.md](HIRES.md) | the resolution patch: what it rewrites, the blob, the game's scenes as read off it, the multi-build port and its record, what is queued |
| [../asm/README.md](../asm/README.md) | the assembly sources, how they become bytes in the patcher, and a section per file |
| [../net/README.md](../net/README.md) | the netplay DLL and the rendezvous server |
| [../maps/README.md](../maps/README.md) | the build maps and port tables `tools/maps.sh` generates |

Where something lives, by question:

- *What is at this address, or where does patch X write?* MAP.md.
- *What does patch X change?* NOTES.md's table, then its section.
- *Where is this address / offset from?* NOTES.md for the game's own
  routines, TEXT.md for strings and artwork, HIRES.md for the resolution
  patch's sites and the other builds' addresses.
- *How do I rebuild after editing assembly?* asm/README.md for `asm/`,
  HIRES.md's *Rebuilding* for `asm/ui.asm`.
- *How does the widescreen patch reach the OEM and Japanese builds?*
  HIRES.md, *Porting to other builds* and *What porting actually
  taught*.
- *How do I cut a release?* DEVELOPING.md, *Releasing*.
- *How is the exe signed, and how is signing set up?* DEVELOPING.md,
  *Signing* and *Setting up signing*.
- *How is the Windows release built, and when does the exe change?*
  DEVELOPING.md, *The Windows build* and *The committed launcher*.
