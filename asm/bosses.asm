bits 32
; Playable bosses: Jaguarandi (VR id 8) and Z-Gradt (9) for one player.
;
; Unlocked, not given: beating Jaguarandi on Very Hard without a lost match
; in the run unlocks it, and finishing the game the same way after that
; unlocks Z-Gradt. Each is shown on a screen of its own in the report's
; state, and the unlocks are kept in bosses.bin beside the game (a dword:
; 0 none, 1 Jaguarandi, 2 both; the patcher's Pre-unlock the bosses
; writes 2).
;
; On the 1P select an unlocked boss stands in the row after Raiden, cursor
; 8 and 9: two more scene objects, the row and its marks moved left to
; make room, the countdown 20 seconds longer, and the boss drawn in
; palette rows of its own - so far on player 1's side (B) only, so a game
; started from player 2's side has the eight alone. Confirming on a boss
; stores its id in the player's machine global, and the game spawns that.
; The initials demo already fights 8 against 9, so the objects themselves
; work as a player's; what does not is everything the game only ever did
; with the eight, which is the rest of this file.
;
; Every hook comes in two, one per copy of the game: A is the machine at
; 0x1ef8xxxx, player 2's side of the cabinet, and B the one at 0x1ae0xxxx,
; player 1's. A one-player game runs on the side it was started from.
;
; One player only: in two-player and network play (GAMEMODE not 0) the
; row stays the eight and confirm stores what it always did, so the hooks
; further down never meet a boss there.
;
; Colour. With Machine Color Select on, up and down on the select cycle the
; machine under the cursor through eight colours, 0 being its own. Each
; machine's eight are pairs of palettes from one shared pool - the other
; colours are mostly other machines' palettes - so a boss can wear any of
; them, chosen on it in the row. The palette loaders (0x4c2026 A,
; 0x4f358b B) give the boss that pair in place of its own when it is not
; 0. A boss has no colours of its own: the loaders send ids above 7 to a
; fixed table without reading one.
;
; Which side of the palette slots a player's machine uses depends on the
; copy and its mode, and the select writes the colour into the array that
; side reads - 0x69fff0 for slots 1/3, 0x6a0010 for 5/7. Confirm records
; which, and only a load from that side is recoloured, which keeps a CPU
; boss of the same id (Z-Gradt on the last stage) in its own colours.
;
; Z-Gradt against Z-Gradt, the last stage, needs the most: both share one
; model header and one block of AI state, so the player's gets a copy of
; each, and its fly-in is skipped so the CPU's descent is not ticked twice.

extern GAMEMODE                 ; 0 one player, 1 two, 2 network
extern BS_IDLE                  ; the loop's idle call, both sites
extern BS_SFX                   ; play a sound effect, cdecl (id)
extern BS_SCENEA                ; scene words: [0x20, 0x30) is the
extern BS_SCENEB                ; select and the encounter
extern BS_G1PA                  ; the player's machine id, A and B
extern BS_G1PB
extern BS_MODEB                 ; B's mode: 0 puts its player on slots 1/3
extern BS_COL0                  ; colour per machine for slots 1/3
extern BS_COL1                  ; and for 5/7, the one A's select writes

; The player's object and its fields
extern BS_OBJA                  ; the player's object, A and B
extern BS_OBJB
extern BS_CPUA                  ; and the CPU's
extern BS_CPUB
extern BS_IDA                   ; object + 0x64: its machine id
extern BS_IDB
extern BS_MDLA                  ; object + 0x6c: its model header
extern BS_MDLB
extern BS_JAGA                  ; the bosses' model headers, per copy
extern BS_ZGA
extern BS_JAGB
extern BS_ZGB
extern BS_STAGEA                ; the stage, 0 Temjin to 9 Z-Gradt
extern BS_STAGEB

; Palettes
extern BS_PALA                  ; per palette id: a machine's eight pairs
extern BS_PALB
extern BS_PALSETA               ; (slot, palette): expand it into the bank
extern BS_PALSETB
extern BS_PALFIXA               ; the loader's own path for ids above 7
extern BS_PALFIXB
extern BS_PALRETA               ; and its epilogue
extern BS_PALRETB

; PLAYER DATA, after stage 5
extern BS_RPARTA                ; its rotating model's parts, (machine)
extern BS_RPARTB
extern BS_MPUSHA                ; the matrix stack: push, pop, scale (x,
extern BS_MPOPA                 ; y, z), per copy
extern BS_MSCALEA
extern BS_MPUSHB
extern BS_MPOPB
extern BS_MSCALEB
extern BS_RFLAG                 ; the renderer flag a machine's draw sets
extern BS_MATA                  ; the current matrix, per copy
extern BS_MATB
extern BS_IDENTA                ; load identity, past its prologue
extern BS_IDENTB
extern BS_LIGHTA                ; a machine's shadow: the light it reads,
extern BS_LIGHTB                ; where it carries on, and past it
extern BS_SHADEA
extern BS_SHADEB
extern BS_NOSHADEA
extern BS_NOSHADEB
extern BS_ZSHTA                 ; Z-Gradt's shadow: the timer it tests,
extern BS_ZSHTB                 ; where it carries on, and past it
extern BS_ZSHADEA
extern BS_ZSHADEB
extern BS_ZNOSHADEA
extern BS_ZNOSHADEB
extern BS_ETRA                  ; the ending's camera: the move it builds
extern BS_ETRB                  ; the view with, and its block
extern BS_ECBLKA
extern BS_ECBLKB
extern BS_ESTEPA                ; and the ending's step
extern BS_ESTEPB
extern BS_WALLA                 ; the floor's height, from a beam segment
extern BS_WALLB
extern BS_SPDA                  ; Z-Gradt's beam's speed
extern BS_SPDB
extern BS_SCANA                 ; the ending camera's slot scan, after its
extern BS_SCANB                 ; start, and where it takes a slot found
extern BS_FOUNDA
extern BS_FOUNDB
extern BS_ZTAB0                 ; Z-Gradt's tables, per side
extern BS_ZTAB1
extern BS_ZINITA                ; Z-Gradt's setup
extern BS_ZINITB
extern BS_PH0A                   ; the ending's phase 0
extern BS_PH0B
extern BS_ZDRAWA                ; Z-Gradt's draw, without its moves
extern BS_SCRPTR                ; the scene script being read
extern BS_SELSCRB               ; the select's, B's
extern BS_SELCUR                ; a player's cursor on the select
extern BS_SELINVB               ; the cursor of a machine
extern BS_COLSEL                ; Machine Color Select
extern BS_SELMDLB               ; the select's model of a machine
extern BS_SELINFOB              ; and its text for a cursor
extern BS_FRAMEB                ; the frame counter
extern BS_SELMODE
extern BS_PRINTAB               ; text: print on one plane or the other,
extern BS_PRINTBB               ; place, clear a block, a block of tiles
extern BS_TXTPOSB
extern BS_TCLEARB
extern BS_TBLOCKB
extern BS_LOGOJ                 ; the bosses' names, as tiles
extern BS_LOGOZ
extern BS_ROW                   ; the eight's portraits, a block of tiles
extern BS_SELROWS               ; the select's models, a row a machine
extern BS_SELSWAP               ; per machine, the bone given spare
extern BS_SELSPEC               ; meshes and the one drawn apart
extern BS_SELLCAM               ; the launch's camera, a machine's
extern BS_SELAHEAD              ; how far ahead a machine is drawn
extern BS_MFRAMEA               ; the frame a machine's motion is drawn
extern BS_MFRAMEB               ; at, each copy's
extern BS_SELPADS               ; the pads' presses this frame, two
extern BS_SELFLAME              ; a machine's booster flames, per frame
extern BS_SELSKY                ; the hangar's outside shown,
extern BS_SELIN                 ; and its inside
extern BS_SELTICKS
extern BS_SLOTS                 ; files loaded: where, how much
extern BS_MALLOC                ; the C library's
extern BS_TXTX                  ; the text cursor's column
extern BS_PLANE                 ; the plane the portraits' marks are on
extern BS_SLOTSZ
extern BS_POOL                  ; and the end of what is loaded
extern BS_RBNAMES               ; the fight models' files: name, size
extern BS_RBDIR                 ; the folder they are read from
extern BS_PATHFMT               ; "%s%s", as the loader joins them
extern BS_RBMODE                ; "rb"
extern BS_SPRINTF               ; the C library's
extern BS_FOPEN
extern BS_FREAD
extern BS_FCLOSE
extern BS_PALLOADB              ; B's palette load (slot, palette)
extern BS_PALRAMB               ; and B's palettes
extern BS_POLYCOL               ; the polygon being queued's light
extern BS_COLTAB                ; the polygons' colours, a row a plane
extern BS_SELOBJ                ; the scene's objects
extern BS_HSITE                 ; the hangar's draw of a machine, and
extern BS_HDOFF                 ; where the widescreen one is in its blob
extern BS_SELRET2               ; and the returns of its other two
extern BS_SELRET3
extern BS_MESHB                 ; a part's meshes (the three, 0)
extern BS_TRANSB                ; translate the matrix (x, y, z)
extern BS_ROTXB                 ; turn it about x (the angle)
extern BS_POSEB                 ; a fight model posed by a motion
extern BS_ROTYB                 ; turn the matrix about y (the angle)
extern BS_ROTZB                 ; and about z
extern BS_CREATEF               ; IAT: CreateFileA, SetFilePointer,
extern BS_SEEKF                 ; ReadFile, CloseHandle
extern BS_READF
extern BS_CLOSEF
extern BS_ZPARTS                ; Z-Gradt's parts its draw places
extern BS_ZRINGS
extern BS_ZCROWN
extern BS_ZSIDES
extern BS_MSETB                 ; and hand it to the renderer
extern BS_MDRAWA                ; the eight's draw, from their per-frame
extern BS_MDRAWB                ; routine
extern BS_ZDRAWB
extern BS_FXA                   ; the effects tables: 24 of 0x24, 24 of 0x38
extern BS_FXB
extern BS_FX2A
extern BS_FX2B
extern SEMUTE                   ; nonzero: no sound effects
extern BS_NAMEA                 ; its machine names, 15 bytes each
extern BS_NAMEB

; The round's animation loads
extern BS_LDA                   ; resume, past mov eax, [id]
extern BS_LDB

; Unlocking
extern BS_STATEB                ; B's state machine, the one a 1P game runs
extern BS_DIFF                  ; the difficulty: 2 Very Hard
extern BS_LOSSB                 ; B's lost matches with this machine
extern BS_REPLOGICB             ; PLAYER DATA's state 0x1e, its text,
extern BS_REPTEXTB              ; its turning model (scale), the frame
extern BS_REPMODELB             ; it counts
extern BS_REPCNT
extern BS_TCLRALL               ; text: clear the planes, reset the cursor,
extern BS_TRESET                ; print in the large white font
extern BS_PRINTBIG
extern BS_PADEDGE               ; the buttons pressed this frame
extern BS_FADE                  ; fade (level), and a scene's end
extern BS_SCNEND
extern BS_FWRITE                ; the C library's, and "wb"
extern BS_WBMODE
extern BS_ARTPOOL               ; the 2D art: tile n at + n * 0x80, n
extern BS_ARTPOOL2              ; below the count; with 0x4000, the other
extern BS_ARTCOUNT              ; bank's; and where .data ends
extern BS_ARTEND
extern BS_LOADSCN               ; load a scene's file (n), the one in, and a
extern BS_SCNNOW                ; texture bank (bank, half)
extern BS_LOADTEX
extern BS_FCBUF                 ; the scene's floor texture and model, as
extern BS_FLDBUF                ; loaded, and three of its glow's states
extern BS_GLOW1
extern BS_GLOW2
extern BS_GLOW3
extern BS_MTSELMEM              ; where MT_sel.bin is read to, when its
extern BS_SEGA                  ; segment (0xa) is empty, and that segment
extern BS_LDXA                  ; the extras that follow the loads
extern BS_LDXB
extern BS_DRFA                  ; the deref: fall through, its je, and past
extern BS_DRJA                  ; the stand overlay
extern BS_DRSA
extern BS_DRFB
extern BS_DRJB
extern BS_DRSB
extern BS_C2A                   ; mode 0xa: resume
extern BS_C2B
%include "frames.inc"           ; DR_FLAG: the deref's local; CAM_PTR: the
                                ; live camera's; PAL_CPU: the palette
                                ; events' side flag. A recompile moves them

; The ending
extern BS_TIMEA                 ; the ending's frame counter
extern BS_TIMEB
extern BS_PHASEA                ; and its phase
extern BS_PHASEB
extern BS_ENDA                  ; resume, phase 1, epilogue, button wait
extern BS_END1A
extern BS_ENDEA
extern BS_ENDWA
extern BS_ENDB
extern BS_END1B
extern BS_ENDEB
extern BS_ENDWB

; Z-Gradt's chase camera
extern BS_VIEWA                 ; view translate, and its sin and cos
extern BS_SINA
extern BS_COSA
extern BS_VIEWB
extern BS_SINB
extern BS_COSB
extern BS_YAW1                  ; the yaw each call placed its eye by
extern BS_YAW2
extern BS_YAW4
extern BS_YAW5
extern BS_LIVEA                 ; resume past the live camera's load
extern BS_LIVEB

; Z-Gradt against Z-Gradt
extern BS_READYA                ; frames since GET READY
extern BS_READYB
extern BS_INITA                 ; Z-Gradt's init, resume
extern BS_INITB
extern BS_FLYA                  ; fly-in: resume, after landing, epilogue
extern BS_FLYPA
extern BS_FLYEA
extern BS_FLYB
extern BS_FLYPB
extern BS_FLYEB
extern BS_ZMODA                 ; the model header Z-Gradt's code reads
extern BS_ZMODB
extern BS_ZTIMA                 ; the fly-in timer
extern BS_ZTIMB
extern BS_TM1                   ; four timer locks: resume and skip each
extern BS_TM1S
extern BS_TM2
extern BS_TM2S
extern BS_TM3
extern BS_TM3S
extern BS_TM4
extern BS_TM4S
extern BS_CLIP0A                ; the clip bank: 0 the pad's, 3 the AI's
extern BS_CLIP3A
extern BS_CLIP0B
extern BS_CLIP3B
extern BS_CLONEA                ; resume
extern BS_CLONEB
extern BS_BSSA                  ; Z-Gradt's AI state
extern BS_BSSB
extern BS_TICKA                 ; its tick, resume
extern BS_TICKB

; Z-Gradt's gold
extern BS_EVA                   ; the palette event each copy's handler
extern BS_EVB                   ; takes, 0xff none
extern BS_ZEVA                  ; the one Z-Gradt's AI state asks for
extern BS_ZEVB
extern BS_LOADA                 ; (slot, palette id): the loaders
extern BS_LOADB
extern BS_ZRA5                  ; event 0x200, its own palettes back:
extern BS_ZRA1                  ; slots 5/7, slots 1/3, and the end
extern BS_ZRAX
extern BS_ZGA5                  ; event 0x21f, gold: slots 5/7, 1/3
extern BS_ZGA1
extern BS_ZRB5
extern BS_ZRB1
extern BS_ZRBX
extern BS_ZGB5
extern BS_ZGB1

; The KO replay and the win and lose screens
extern BS_WIND1                 ; the win camera's distance, per copy
extern BS_WIND2
extern BS_RPITCH1               ; the replay camera's pitch and yaw
extern BS_RYAW1
extern BS_RPITCH2
extern BS_RYAW2

JAG         equ 8
ZGRADT      equ 9
SELECT_LO   equ 0x20                ; scene: select and encounter
SELECT_HI   equ 0x30
ATTRACT_LO  equ 0x10                ; scene: title and attract, the demo
ATTRACT_HI  equ 0x20                ; included
LAST_STAGE  equ 9
READY_GO    equ 5                   ; frames after GET READY before the
                                    ; player's Z-Gradt moves
MODEL_COPY  equ 0x800
OBJECT      equ 0x600               ; a fight object, 0x1ae0c40 to 0x1ae1240
AI_STATE    equ 0x1e0
FX          equ 24 * 0x24           ; the effects tables, BS_FX and BS_FX2
FX2         equ 24 * 0x38

%macro COPYN 3                      ; dst, src, bytes
        mov     esi, %2
        mov     edi, %1
        mov     ecx, %3 / 4
        cld
        rep movsd
%endmacro

; The standing copy: the player's boss object and its AI state, the first
; time the tick sees GET READY over in a round - for Z-Gradt, ZSTAND frames
; later, its flight in being over by then. From the tick, pushad'd.
ZSTAND      equ 90
%macro STAND 6                      ; the object, frames since GET READY,
        cmp     dword [%2], 0       ; AI state, the copies, taken flag
        jne     %%run
        mov     byte [%6], 0        ; a round still to start
        jmp     %%out
%%run:  cmp     byte [%6], 0
        jne     %%out
        mov     eax, [%1 + 0x64]
        cmp     eax, JAG
        je      %%take
        cmp     eax, ZGRADT
        jne     %%out
        cmp     dword [%2], ZSTAND  ; Z-Gradt is still flying in
        jb      %%out
%%take: mov     byte [%6], 1
        COPYN   %4, %1, OBJECT
        COPYN   %5, %3, AI_STATE
%%out:
%endmacro

; --- the select ------------------------------------------------------------

; In place of the idle call at both its sites. Entering the select puts a
; leftover boss id back to Temjin so the cursor wraps; the title and the
; demo forget the boss's colour. Then, on the select in one player, the
; bosses' palettes and Z-Gradt's lift.
tick:
        pushad
        call    unl_load
        call    unl_tick
        call    selframex
        call    selpalguard
        mov     dword [win_tries], 0
        xor     edx, edx
        movzx   eax, word [BS_SCENEA]
        cmp     eax, SELECT_LO
        jb      .b
        cmp     eax, SELECT_HI
        jb      .in
.b:     movzx   eax, word [BS_SCENEB]
        cmp     eax, SELECT_LO
        jb      .out
        cmp     eax, SELECT_HI
        jae     .out
.in:    inc     edx
.out:   mov     ecx, [was]
        mov     [was], edx
        test    ecx, ecx
        jz      .enter
        test    edx, edx
        jnz     .attract
        call    selpalback          ; left: the bosses' rows the game's
        jmp     .attract
.enter: test    edx, edx
        jz      .attract
        call    selrow_make
        mov     dword [boss], 0     ; no boss taken yet
        mov     dword [sel_ztilt], 0 ; Z-Gradt upright
        mov     dword [sel_zhead], 0
        mov     dword [sel_zspin], 0
        mov     dword [end_g1p], 0
        mov     dword [banked_a], 0 ; a new fight's Z-Gradt starts from the
        mov     dword [banked_b], 0 ; CPU's state just initialised again
        mov     byte [zfly_on], 0   ; and a player's Z-Gradt on the ground
        call    zbeam_off
        cmp     dword [BS_G1PA], 7
        jbe     .g1
        mov     dword [BS_G1PA], 0
.g1:    cmp     dword [BS_G1PB], 7
        jbe     .attract
        mov     dword [BS_G1PB], 0
.attract:
        movzx   eax, word [BS_SCENEA]
        sub     eax, ATTRACT_LO
        cmp     eax, ATTRACT_HI - ATTRACT_LO
        jb      .forget
        movzx   eax, word [BS_SCENEB]
        sub     eax, ATTRACT_LO
        cmp     eax, ATTRACT_HI - ATTRACT_LO
        jae     .mode
.forget:
        mov     dword [boss], 0
.mode:  STAND   BS_OBJA, BS_READYA, BS_BSSA, stand_a, standai_a, stood_a
        STAND   BS_OBJB, BS_READYB, BS_BSSB, stand_b, standai_b, stood_b
        cmp     dword [GAMEMODE], 0
        jne     .done
        test    edx, edx
        jz      .done
        call    seljagpal
        call    selzlift
.done:  popad
        jmp     BS_IDLE

; In place of `mov [player], eax; mov eax, [player]`, five nops after the
; call. eax is the machine under the cursor; a boss of the lineup is
; noted, with the colour it was given here.
confirm_a:
        mov     ecx, BS_COL1        ; A's select always writes this one
        mov     edx, BS_G1PA
        jmp     confirm
confirm_b:
        mov     ecx, BS_COL0        ; B's picks by its mode, as 0x5a0149 does
        cmp     dword [BS_MODEB], 0
        je      .c
        mov     ecx, BS_COL1
.c:     mov     edx, BS_G1PB
confirm:
        mov     dword [boss], 0
        cmp     dword [GAMEMODE], 0
        jne     .store
        cmp     eax, JAG            ; the cursor on a boss of the lineup
        jb      .store
        mov     [bside], ecx        ; in the colours it was given here
        push    eax
        push    edx
        call    selbcol             ; eax the machine, edx the colour
        mov     [bsrc], eax
        mov     [bcolor], edx
        pop     edx
        pop     eax
        mov     [boss], eax
.store: mov     [edx], eax
        ret

; --- the lineup ------------------------------------------------------------

; The select's lineup is a scene script: the camera, then the eight in a
; row 20 apart, Temjin to Raiden, then the hangar. The cursor runs 0 to 7
; and a table turns it into a machine. In one player the lineup goes on
; past Raiden to Jaguarandi and Z-Gradt, cursor 8 and 9: two more records
; after Raiden's, the cursor's limit 9, and the tables (0x621870, the
; machine of an object, and 0x621878, of the cursor, two on) ten long, in
; place of the game's at every read. A machine's object is the cursor's
; plus two, so the two go in before the hangar's.
;
; Only B's select so far.
SEL_REC     equ 0x30                ; a script record
SEL_EIGHT   equ 10                  ; the camera, its own, and the eight
SEL_REST    equ 14                  ; the hangar's, to the end marker
SEL_Y       equ 0x18                ; a record's height,
SEL_Z       equ 0x1c                ; its place along the row
SEL_FLAGS   equ 0x10                ; and its flags, the machine twice

; In place of `mov [script], select's`, five nops after the call.
selscr_b:
        pushad
        cmp     byte [selbuilt], 0
        jne     .set
        COPYN   selscript, BS_SELSCRB, SEL_EIGHT * SEL_REC
        COPYN   selscript + SEL_EIGHT * SEL_REC, BS_SELSCRB + (SEL_EIGHT - 1) * SEL_REC, SEL_REC
        COPYN   selscript + (SEL_EIGHT + 1) * SEL_REC, BS_SELSCRB + (SEL_EIGHT - 1) * SEL_REC, SEL_REC
        COPYN   selscript + (SEL_EIGHT + 2) * SEL_REC, BS_SELSCRB + SEL_EIGHT * SEL_REC, SEL_REST * SEL_REC
        mov     ebx, selscript + SEL_EIGHT * SEL_REC
        mov     dword [ebx + SEL_FLAGS], JAG * 2
        fld     dword [ebx + SEL_Z]
        fadd    dword [sel_step]
        fst     dword [ebx + SEL_Z]
        fadd    dword [sel_zgap]
        fstp    dword [ebx + SEL_REC + SEL_Z]
        fld     dword [ebx + SEL_REC + SEL_Y] ; Z-Gradt on the lip
        fadd    dword [sel_zy]
        fstp    dword [ebx + SEL_REC + SEL_Y]
        mov     dword [ebx + SEL_REC + SEL_FLAGS], ZGRADT * 2
        COPYN   selrows, BS_SELROWS, 8 * SEL_ROWS ; and the models' rows,
        COPYN   selrows + JAG * SEL_ROWS + 8, BS_SELROWS + SEL_RAIDEN * SEL_ROWS + 8, 16
        COPYN   seld68, BS_SELSWAP, 8 * 4       ; the bone given spare
        COPYN   selda8, BS_SELSPEC, 8 * 4       ; meshes, and the one drawn
        mov     eax, -1                         ; apart: none for a boss
        mov     [seld68 + JAG * 4], eax
        mov     [seld68 + ZGRADT * 4], eax
        mov     [selda8 + JAG * 4], eax
        mov     [selda8 + ZGRADT * 4], eax
        COPYN   sellcam, BS_SELLCAM, 8 * SEL_LCAM ; the launch's camera:
        COPYN   sellcam + JAG * SEL_LCAM, sel_jagcam, SEL_LCAM ; Raiden's,
        COPYN   sellcam + ZGRADT * SEL_LCAM, sel_jagcam, SEL_LCAM ; further
        mov     eax, [BS_JAGB + SEL_PARTS]      ; Jaguarandi's with them
        mov     [selrows + JAG * SEL_ROWS], eax
        mov     eax, [BS_JAGB + SEL_POSED]
        mov     [selrows + JAG * SEL_ROWS + 4], eax
        mov     byte [selbuilt], 1
.set:   mov     dword [BS_SCRPTR], selscript
        popad
        ret

; In place of `cmp [cursor], 7`, three nops after the call; the flags as
; it leaves them. eax the player times 21, as the game indexes.
selmax_b:
        push    ecx
        mov     ecx, 7
        cmp     dword [GAMEMODE], 0
        jne     .c
        add     ecx, [unl_level]    ; as far as the bosses unlocked
.c:     cmp     [eax * 4 + BS_SELCUR], ecx
        pop     ecx
        ret

; In place of `mov eax, [eax*4 + cursor of machine]` for the cursor the
; select starts on, the last machine taken: a boss's own in one player,
; Raiden's otherwise. Two nops after the call.
selinit_b:
        cmp     eax, JAG
        jb      .eight
        cmp     dword [GAMEMODE], 0
        jne     .raiden
        ret
.raiden:
        mov     eax, 7
        ret
.eight: mov     eax, [eax * 4 + BS_SELINVB]
        ret

; In place of `cmp [colour select], 0`, two nops after the call; the flags
; as it leaves them. Up and down cycle the eight's colours, eight each; on
; a boss, with the option on, they cycle its own here instead - its own,
; then each of the eight's but their first (SEL_BCOLS in all) - and to the
; game it is as if the option were off. ebp the select's frame, [ebp+8]
; the player.
SEL_BCOLS   equ 1 + 8 * 7           ; its own, the eight's but their own
SEL_UP      equ 0x20                ; the pads' bits
SEL_DOWN    equ 0x10
selcol_b:
        push    eax
        mov     eax, [ebp + 8]
        imul    eax, eax, 0x54
        mov     eax, [eax + BS_SELCUR]
        cmp     eax, JAG
        jae     .boss
        pop     eax
        cmp     dword [BS_COLSEL], 0
        ret
.boss:  cmp     dword [BS_COLSEL], 0
        je      .off
        push    ecx
        lea     ecx, [sel_bcol + (eax - JAG) * 4]
        mov     al, [BS_SELPADS]
        or      al, [BS_SELPADS + 1]
        test    al, SEL_UP
        jz      .down
        dec     dword [ecx]
        jns     .moved
        mov     dword [ecx], SEL_BCOLS - 1
        jmp     .moved
.down:  test    al, SEL_DOWN
        jz      .kept
        inc     dword [ecx]
        cmp     dword [ecx], SEL_BCOLS
        jb      .moved
        mov     dword [ecx], 0
.moved: pushad
        push    1                   ; the select's own tick
        call    BS_SFX
        add     esp, 4
        popad
.kept:  pop     ecx
.off:   pop     eax
        cmp     eax, eax
        ret

; The select draws a machine as a list of parts, three meshes each, posed
; by one of its motions; its row in a table (0x621708) names the parts and
; the motions. Jaguarandi has no select model, but its fight model's body
; is such a list (its header's ninth field, and the eighth, as the posed
; draw reads it, a part for the root first), with Raiden's parts, so its
; row is that posed by Raiden's motions. Its meshes are in RB_jag.bin,
; which nothing loads on the select: the first time it is drawn there it
; is read into its file slot as the loader would, at the pool's end.
;
; Z-Gradt has neither: it is drawn as its fight draws its body, at its
; size in a fight, posed by its battle stance, the one motion of its that
; loops (MT_zig.bin's, read on the select into selzmotion; failing that,
; one frame of another, selzpose, as it has it); its meshes are in
; RB_zig.bin, loaded as Jaguarandi's.
;
; In place of the prologue of the select's model of a machine (cdecl, the
; machine first).
SEL_ROWS    equ 0x18                ; a machine's row
SEL_LCAM    equ 0xc                 ; its launch camera: out, up, turn a frame
SEL_RAIDEN  equ 3
SEL_JAGFILE equ 5                   ; Jaguarandi's file slot
SEL_PARTS   equ 0x20                ; a fight model's body, the two ways
SEL_POSED   equ 0x1c                ; a select row has it
SEL_ZFILE   equ 9                   ; Z-Gradt's file slot
selmdl_b:
        cmp     dword [esp + 4], JAG
        jae     .boss
.draw:  push    ebp
        mov     ebp, esp
        sub     esp, 0x30
        jmp     BS_SELMDLB + 6
.none:  jmp     sel_slotsout
.boss:  mov     eax, [esp + 4]      ; a boss still locked: not there
        sub     eax, 7
        cmp     eax, [unl_level]
        ja      .none
        mov     eax, [sel_launch]   ; the other boss launching: not there
        test    eax, eax            ; (out of sight; its rows lent)
        jle     .mine
        cmp     eax, [esp + 4]
        jne     .none
.mine:  mov     eax, [esp + 4]      ; its shade at the hangar's right edge
        call    selfade
        mov     eax, SEL_JAGFILE
        cmp     dword [esp + 4], ZGRADT
        jne     .load
        mov     eax, SEL_ZFILE
.load:  call    sel_loadrb
        call    sel_slotsin
        mov     eax, [esp + 4]      ; its palettes, in rows of its own,
        call    selremap
        call    seldrawpal          ; there again as it is drawn
        cmp     dword [esp + 4], ZGRADT
        jne     .jag
        call    selzdraw
        jmp     .done
.jag:   mov     byte [seljagdraw], 1 ; drawn with its head (selpart_b)
%rep 4
        push    dword [esp + 16]
%endrep
        call    .draw
        add     esp, 16
        mov     byte [seljagdraw], 0
.done:  mov     byte [sel_remap], 0
        jmp     sel_slotsout

; Jaguarandi's head is a group of its own in its fight model, posed apart
; from its body; Raiden's select model, whose motions it takes, has the
; head in its chest. So after the chest, the head, at the neck: its fight
; model's head joint as its chest's mesh sees it (bone 10 and 7 of its
; upper body: the chest's mesh at (0, 16.4, 1.39) turned -3778 about x,
; the head at (0, 18.39, 2.12) turned -3775), handed to the renderer as
; the posed draw does each part. In place of the posed draw's
; call of a part's meshes (cdecl, the three and 0); ebp the select model's
; frame, [ebp-0x18] the bone.
SEL_CHEST   equ 7
SEL_HEAD    equ 0x18                ; a fight model's head, its first group
SEL_NECKX   equ -3775 + 3778        ; the head's turn from the chest's
selpart_b:
        cmp     byte [seljagdraw], 0
        je      BS_MESHB
        cmp     dword [ebp - 0x18], SEL_CHEST
        jne     BS_MESHB
%rep 4
        push    dword [esp + 16]
%endrep
        call    BS_MESHB
        add     esp, 16
        call    BS_MPUSHB
        push    dword [sel_neck + 8]
        push    dword [sel_neck + 4]
        push    dword [sel_neck]
        call    BS_TRANSB
        add     esp, 12
        push    SEL_NECKX
        call    BS_ROTXB
        add     esp, 4
        call    BS_MSETB
        mov     eax, [BS_JAGB + SEL_HEAD]
        push    0
        push    dword [eax + 0xc + 8]
        push    dword [eax + 0xc + 4]
        push    dword [eax + 0xc]
        call    BS_MESHB
        add     esp, 16
        call    BS_MPOPB
        call    BS_MSETB
        ret

; Z-Gradt's body, on the matrix the hangar puts a machine on (cdecl, as
; the select's model); then the parts its fight draws by hand, at its
; root bone, as its idle has them (selzparts).
SEL_ZBONES  equ 26
SEL_ZPART   equ 20                  ; a part: its meshes, place, turn
SEL_ZROOT   equ 25                  ; its root bone,
SEL_ZPODS   equ 4                   ; its parts before its head
SEL_ZREC    equ 0x14                ; a bone's turn and place in a frame
selzdraw:
        pushad
        call    BS_MPUSHB
        cmp     dword [boss], ZGRADT ; flying out: leant and turning
        jne     .pose
        cmp     dword [BS_SELOBJ + SEL_ZOBJ * SEL_OBJ + SEL_OBJST], 2
        jne     .pose
        push    0
        push    dword [sel_zpivot]
        push    0
        call    BS_TRANSB
        add     esp, 12
        sub     esp, 4
        fld     dword [sel_ztilt]
        fistp   dword [esp]
        call    BS_ROTXB
        push    dword [sel_zspin]
        call    BS_ROTYB
        add     esp, 8
        push    0
        push    dword [sel_zpivotn]
        push    0
        call    BS_TRANSB
        add     esp, 12
.pose:
%rep 3
        push    dword [sel_zscale]
%endrep
        call    BS_MSCALEB
        add     esp, 12
        call    sel_loadzmot        ; its motion (esi) and frame (edi):
        mov     esi, selzmot        ; standing still till taken,
        xor     edi, edi
        cmp     dword [boss], ZGRADT
        jne     .posed
        cmp     dword [BS_SELOBJ + SEL_ZOBJ * SEL_OBJ + SEL_OBJST], 2
        jne     .posed
        mov     eax, [BS_SELOBJ + SEL_ZOBJ * SEL_OBJ]
        lea     ecx, [eax - SEL_LAUNCH]
        test    ecx, ecx            ; then in its stance;
        jl      .stance
        cmp     ecx, SEL_ZDIPN
        jge     .rec
        lea     edi, [ecx + ecx]    ; as its thrusters light, its jump's
        mov     esi, selzdip        ; dip, twice as fast,
        jmp     .clamp
.rec:   cmp     ecx, 2 * SEL_ZDIPN
        jge     .stance
        lea     edi, [ecx - SEL_ZDIPN] ; and its spring as it lifts off;
        add     edi, edi
        mov     esi, selzrec
        jmp     .clamp
.stance:
        movzx   ecx, word [esi + 4] ; then its stance again
        xor     edx, edx
        div     ecx
        mov     edi, edx
.clamp: movzx   ecx, word [esi + 4] ; (a motion of one frame if they
        cmp     edi, ecx            ; could not be read)
        jb      .posed
        lea     edi, [ecx - 1]
.posed: push    0                   ; its meshes as a fight has them,
        push    1                   ; drawn,
        push    edi                 ; at that frame
        push    selzvar
        push    selzout
        push    dword [BS_ZGB + 0x10] ; its bones
        push    esi
        call    BS_POSEB
        add     esp, 28
        imul    edi, edi, SEL_ZBONES ; the root bone, as the frame has it
        add     edi, SEL_ZROOT
        imul    edi, edi, SEL_ZREC
        add     edi, [esi]
        push    dword [edi + 0x10]
        push    dword [edi + 0xc]
        push    dword [edi + 8]
        call    BS_TRANSB
        add     esp, 12
        movsx   eax, word [edi + 4]
        push    eax
        call    BS_ROTZB
        movsx   eax, word [edi + 2]
        mov     [esp], eax
        call    BS_ROTYB
        movsx   eax, word [edi]
        mov     [esp], eax
        call    BS_ROTXB
        add     esp, 4
        mov     esi, selzparts
.part:  cmp     dword [esi], 0
        je      .parts
        cmp     esi, selzparts + SEL_ZPODS * SEL_ZPART
        jne     .draw
        call    BS_MPUSHB           ; past its pods, the rest bounced
        call    selzbounce
.draw:
        call    BS_MPUSHB
        push    dword [esi + 12]
        push    dword [esi + 8]
        push    dword [esi + 4]
        call    BS_TRANSB
        add     esp, 12
        push    dword [esi + 16]
        call    BS_ROTYB
        add     esp, 4
        call    BS_MSETB
        mov     eax, [esi]
        push    0
        push    dword [eax + 8]
        push    dword [eax + 4]
        push    dword [eax]
        call    BS_MESHB
        add     esp, 16
        call    BS_MPOPB
        add     esi, SEL_ZPART
        jmp     .part
.parts: call    BS_MPOPB
        cmp     dword [boss], ZGRADT ; flying out: its thruster lit,
        jne     .done
        mov     eax, [BS_SELOBJ + SEL_ZOBJ * SEL_OBJ]
        cmp     dword [BS_SELOBJ + SEL_ZOBJ * SEL_OBJ + SEL_OBJST], 2
        jne     .done
        cmp     eax, SEL_LAUNCH
        jle     .done
        xor     ebx, ebx            ; Raiden's booster's, larger, under
.flame: call    BS_MPUSHB           ; it, twice, a quarter turn apart:
        push    0                   ; four jets
        push    dword [sel_zflamey]
        push    0
        call    BS_TRANSB
        add     esp, 12
        push    ebx
        call    BS_ROTYB
        add     esp, 4
        mov     eax, [BS_SELOBJ + SEL_ZOBJ * SEL_OBJ]
        sub     eax, SEL_LAUNCH     ; lighting: the jets grow out of it,
        cmp     eax, SEL_ZJET       ; down, over the first frames
        jbe     .grow
        mov     eax, SEL_ZJET
.grow:  push    dword [sel_one]
        push    eax
        fild    dword [esp]
        fidiv   dword [sel_zjet]
        fstp    dword [esp]
        push    dword [sel_one]
        call    BS_MSCALEB
        add     esp, 12
        push    dword [sel_zflamerx]
        call    BS_ROTXB
        add     esp, 4
%rep 3
        push    dword [sel_zflames]
%endrep
        call    BS_MSCALEB
        add     esp, 12
        call    BS_MSETB
        mov     eax, [BS_SELOBJ + SEL_ZOBJ * SEL_OBJ]
        dec     eax                 ; its flicker, four frames
        and     eax, 3
        lea     eax, [eax + eax * 2]
        shl     eax, 2
        add     eax, [BS_SELFLAME + SEL_RAIDEN * 4]
        push    0
        push    dword [eax + 8]
        push    dword [eax + 4]
        push    dword [eax]
        call    BS_MESHB
        add     esp, 16
        call    BS_MPOPB
        add     ebx, 0x4000
        cmp     ebx, 0x8000
        jb      .flame
.done:  call    BS_MPOPB
        call    BS_MSETB
        popad
        ret

; Z-Gradt's head - its core, crown, rings and the rest past its pods -
; bouncing, as its fight's jump bounces it: for sel_zhead frames, about z
; and y while more than SEL_ZSHAKE are left, about x, and up and down, by
; as much as are left, with the frame.
SEL_ZSHAKE  equ 0x18
selzbounce:
        mov     ecx, [sel_zhead]
        test    ecx, ecx
        jz      .out
        sub     esp, 4
        mov     eax, [BS_FRAMEB]
        sub     ecx, SEL_ZSHAKE
        jle     .nod
        mov     edx, eax            ; about z
        shl     edx, 11
        lea     edx, [edx + edx * 2]
        mov     [esp], ecx
        fild    dword [esp]
        fmul    dword [sel_eight]
        call    .sin
        fistp   dword [esp]
        call    BS_ROTZB
        mov     eax, [BS_FRAMEB]    ; and y
        mov     edx, eax
        shl     edx, 12
        mov     ecx, [sel_zhead]
        sub     ecx, SEL_ZSHAKE
        mov     [esp], ecx
        fild    dword [esp]
        fmul    dword [sel_four]
        call    .sin
        fistp   dword [esp]
        call    BS_ROTYB
.nod:   mov     eax, [BS_FRAMEB]    ; about x
        mov     edx, eax
        shl     edx, 10
        lea     edx, [edx + edx * 2]
        fild    dword [sel_zhead]
        fmul    dword [sel_four]
        call    .sin
        fistp   dword [esp]
        call    BS_ROTXB
        add     esp, 4
        mov     eax, [BS_FRAMEB]    ; and up and down
        add     eax, 10
        lea     edx, [eax * 8]
        sub     edx, eax
        shl     edx, 10
        push    0
        fild    dword [sel_zhead]
        fmul    dword [sel_zbob]
        call    .sin
        sub     esp, 4
        fstp    dword [esp]
        push    0
        call    BS_TRANSB
        add     esp, 12
.out:   ret
; st0 times the sine of the angle dx (a word); eax, edx spent.
.sin:   push    edx
        fild    word [esp]
        fmul    dword [sel_zturn]
        fsin
        fmulp   st1, st0
        pop     edx
        ret

; Z-Gradt's motions from MT_zig.bin, the first time it is drawn: its
; battle stance (the one that loops) and its jump - the dip as it is
; pressed, the spring back as it is let go - each read into its own buffer
; and its motion pointed at it (selzmots).
SEL_ZFRAMES equ 120                 ; the stance's frames,
SEL_ZJUMPF  equ 60                  ; the dip's and the spring's
SEL_ZDIPN   equ SEL_ZJUMPF / 2      ; frames, played twice as fast
%define ZMOTSZ(n) ((n) * SEL_ZBONES * SEL_ZREC)
sel_loadzmot:
        cmp     byte [selzmotok], 0
        jne     .out
        mov     byte [selzmotok], 1 ; tried, once
        pushad
        push    selzmtname
        push    BS_RBDIR
        push    BS_PATHFMT
        push    selpath
        call    BS_SPRINTF
        add     esp, 16
        push    0
        push    0x80                ; normal
        push    3                   ; existing
        push    0
        push    1                   ; shared for reading
        push    0x80000000          ; reading
        push    selpath
        call    [BS_CREATEF]
        cmp     eax, -1
        je      .done
        mov     ebx, eax
        mov     esi, selzmots
.next:  cmp     dword [esi], 0
        je      .shut
        push    0                   ; from the start
        push    0
        push    dword [esi]
        push    ebx
        call    [BS_SEEKF]
        push    0
        push    selzgot
        push    dword [esi + 4]
        push    dword [esi + 8]
        push    ebx
        call    [BS_READF]
        mov     eax, [esi + 4]
        cmp     [selzgot], eax
        jne     .shut
        mov     edi, [esi + 12]     ; read: the motion is these frames
        mov     eax, [esi + 8]
        mov     [edi], eax
        mov     eax, [esi + 16]
        mov     [edi + 4], ax
        add     esi, 20
        jmp     .next
.shut:  push    ebx
        call    [BS_CLOSEF]
.done:  popad
.out:   ret

; The hangar draws a machine only within 28.43 ahead of the camera along
; the row; Z-Gradt, far past Jaguarandi and so large, is in sight from
; Jaguarandi's place too (drawn black: its palettes are not in). In place
; of `fadd qword [28.43]`, a nop after; [ebp+0xc] the scene object.
SEL_ZOBJ    equ SEL_EIGHT + 1       ; Z-Gradt's scene object
selcull_b:
        fadd    qword [BS_SELAHEAD]
        cmp     dword [ebp + 0xc], SEL_ZOBJ
        jne     .out
        fadd    dword [sel_zsight]
.out:   ret

; The launch's sled, under the machine taken as it goes, is for the eight
; and Jaguarandi: Z-Gradt flies. In place of `cmp [the player's state], 0`
; in the sled's draw, a nop after; eax the player times 0x15, and the
; cursor, once taken, the machine's scene object.
selsled_b:
        cmp     dword [eax * 4 + BS_SELCUR + SEL_STATE], 0
        je      .out                ; nothing taken: no sled
        cmp     dword [eax * 4 + BS_SELCUR], SEL_ZOBJ ; Z-Gradt: as if
.out:   ret                         ; nothing

; Z-Gradt's launch: the launch carries it along the row and out of the
; hangar as it does the eight, but in the air - it lifts off the deck as
; the launch sets off (SEL_ZRISE frames, sel_zup a frame), flies at that
; height through the hangar and its tunnel, and once past the tunnel's
; mouth (sel_zexit, where the camera waits outside) speeds up, drops to
; skim the water as the eight do, and far out climbs away. Its height is set from its frame and place each
; tick, the launch's own (its hop, its arc) not stored (selzy_b). It leans
; into its flight, its thruster underneath trailing (sel_ztilt, eased
; towards the way it moved this frame), and outside it turns about itself
; (sel_zspin); selzdraw applies both. The camera of the player who
; took it looks up as it rises, by sel_zeye of each step. From the tick,
; on the select in one player.
SEL_STATE   equ 0x8 - 0x44          ; a player's state, from its cursor
SEL_OBJST   equ 0xc                 ; a scene object's state: 2 launching
SEL_OBJY    equ 0x34                ; its height
SEL_LAUNCH  equ 0xb0                ; its frame as the launch moves it
SEL_ZRISE   equ 40
SEL_ZOUT    equ 236                 ; the frame the camera cuts outside
SEL_ZHIT    equ 0x14                ; its sounds (the sound test's names):
SEL_ZFSE    equ 0x1c                ; SDE_hit_03 and SDE_fse_05,
SEL_ZJUMP   equ 0x19                ; SDE_jump_02, SDE_bom_12 - common
SEL_ZBLAST  equ 7                   ; ones (its own aren't loaded here)
SEL_ZHEAD   equ 0x20                ; its head's bounce, frames (its jump's)
SEL_ZCHARGE equ 40                  ; the first two, frames before it lifts
                                    ; (any sooner and the select's end,
                                    ; 128 frames in, cuts it off)
SEL_ZJET    equ 20                  ; the frames its thruster takes to light
SEL_ZSPIN   equ 0x200               ; its turn a frame out there
SEL_TGTZ    equ 0x20 - 0x44         ; what a player's camera looks at's place
selzlift:
        cmp     dword [boss], ZGRADT
        jne     .out
        mov     edx, BS_SELOBJ + SEL_ZOBJ * SEL_OBJ
        cmp     dword [edx + SEL_OBJST], 2
        jne     .out
        cmp     dword [sel_zhead], 0 ; its head's bounce running down
        je      .headed
        dec     dword [sel_zhead]
.headed:
        mov     eax, [edx]
        sub     eax, SEL_LAUNCH
        jg      .fly
        cmp     eax, -SEL_ZCHARGE   ; not off yet: just before, its
        jne     .wait               ; thrusters charging, its head
        mov     dword [sel_zhead], SEL_ZHEAD ; bouncing
        push    edx
        push    SEL_ZHIT
        call    BS_SFX
        push    SEL_ZFSE
        call    BS_SFX
        add     esp, 8
        pop     edx
.wait:  mov     eax, [edx + SEL_OBJZ] ; and where it starts from
        mov     [sel_zprevz], eax
        ret
.fly:   cmp     eax, 1              ; its thrusters lighting: a jet's
        jne     .lit                ; lift
        push    eax
        push    edx
        push    SEL_ZJUMP
        call    BS_SFX
        add     esp, 4
        pop     edx
        pop     eax
.lit:   cmp     eax, SEL_ZRISE + 1  ; off, setting off along: a blast
        jne     .go
        push    eax
        push    edx
        push    SEL_ZBLAST
        call    BS_SFX
        add     esp, 4
        pop     edx
        pop     eax
.go:   fld     dword [sel_zy]      ; the deck,
        mov     ecx, eax
        cmp     ecx, SEL_ZRISE
        jbe     .rise
        mov     ecx, SEL_ZRISE
.rise:  push    ecx
        fild    dword [esp]
        pop     ecx
        fmul    dword [sel_zup]     ; lifted off it,
        faddp   st1, st0
        cmp     eax, SEL_ZRISE      ; and, off, flying faster than the
        jbe     .lifting            ; sled would carry it
        fld     dword [sel_zthrust]
        call    .ahead
.lifting:
        fld     dword [sel_zexit]   ; and, past the tunnel's mouth,
        fsub    dword [edx + SEL_OBJZ]
        fldz
        fcomip  st0, st1
        jb      .out2
        fstp    st0
        jmp     .set
.out2:  add     dword [sel_zspin], SEL_ZSPIN ; turning,
        fld     dword [sel_zfast]   ; faster again,
        call    .ahead
        fld     st0                 ; down over the water,
        fmul    dword [sel_zdive]
        fld     dword [sel_zdivemax]
        fcomi   st0, st1
        jb      .deep
        fstp    st0
        jmp     .dive
.deep:  fstp    st1
.dive:  fsubp   st2, st0
        fsub    dword [sel_zskim]   ; and, far out, climbing away
        fldz
        fcomip  st0, st1
        jb      .climb
        fstp    st0
        jmp     .set
.climb: fmul    st0, st0
        fmul    dword [sel_zclimb]
        faddp   st1, st0
.set:   fld     st0                 ; the step up,
        fsub    dword [edx + SEL_OBJY]
        fxch    st1
        fstp    dword [edx + SEL_OBJY]
        fld     dword [edx + SEL_OBJZ] ; and along
        fld     st0
        fsub    dword [sel_zprevz]
        fxch    st1
        fstp    dword [sel_zprevz]
        fld     st1                 ; the way it went: its lean
        fpatan
        fmul    dword [sel_zrad]
        fsub    dword [sel_ztilt]
        fmul    dword [sel_zease]
        fadd    dword [sel_ztilt]
        fstp    dword [sel_ztilt]
        fmul    dword [sel_zeye]
        xor     ecx, ecx            ; the camera of whichever player took it
.cam:   cmp     dword [BS_SELCUR + ecx], SEL_ZOBJ
        jne     .next
        fld     dword [BS_SELCUR + ecx + SEL_TGTY]
        fadd    st0, st1
        fstp    dword [BS_SELCUR + ecx + SEL_TGTY]
.next:  add     ecx, 0x54
        cmp     ecx, 2 * 0x54
        jb      .cam
        fstp    st0
.out:   ret
; Z-Gradt st0 further along its way this frame, and the camera of the
; player who took it looking as much further; st0 popped.
.ahead: fld     dword [edx + SEL_OBJZ]
        fsub    st0, st1
        fstp    dword [edx + SEL_OBJZ]
        xor     ecx, ecx
.tgt:   cmp     dword [BS_SELCUR + ecx], SEL_ZOBJ
        jne     .tnext
        fld     dword [BS_SELCUR + ecx + SEL_TGTZ]
        fsub    st0, st1
        fstp    dword [BS_SELCUR + ecx + SEL_TGTZ]
.tnext: add     ecx, 0x54
        cmp     ecx, 2 * 0x54
        jb      .tgt
        fstp    st0
        ret

; The launch shows the hangar's outside - the dock, the sea - and hides its
; inside, whose grey hides the sky, by its floor's timetable, from the
; frames a machine gets there; Z-Gradt, flying, gets there sooner. Outside
; from just before the camera cuts there, inside gone as it comes to the
; tunnel's mouth. In place of `mov eax, [ticks]` after the timetable;
; [ebp-4] the launch's frame.
SEL_ZSKY    equ 224
selsky_b:
        cmp     dword [BS_G1PB], ZGRADT
        jne     .out
        cmp     dword [ebp - 4], SEL_ZSKY
        jl      .out
        mov     dword [BS_SELSKY], 1
        fld     dword [sel_zexit]
        fsub    dword [sel_zclear]
        fcomp   dword [BS_SELOBJ + SEL_ZOBJ * SEL_OBJ + SEL_OBJZ]
        fnstsw  ax
        test    ah, 1               ; Z-Gradt short of it: still inside
        jnz     .out
        mov     dword [BS_SELIN], 0
.out:   mov     eax, [BS_SELTICKS]
        ret

; Out over the sea a launch throws up spray under the machine, every fourth
; frame from a frame that has the eight past the camera; Z-Gradt is far out
; by then. Its spray starts by its place instead - well past the tunnel's
; mouth - while it skims, below the deck. In place of
; `cmp [the spray's frame], [the machine's frame]`, the next `jge` skipping
; it; ecx the machine's scene object times 0x15.
selspray_b:
        cmp     ecx, SEL_ZOBJ * 0x15
        je      .z
        cmp     eax, [ecx * 4 + BS_SELOBJ]
        ret
.z:     push    eax
        fld     dword [sel_zexit]
        fsub    dword [sel_zclear2]
        fcomp   dword [ecx * 4 + BS_SELOBJ + SEL_OBJZ]
        fnstsw  ax
        test    ah, 1               ; short of it
        jnz     .skip
        fldz
        fcomp   dword [ecx * 4 + BS_SELOBJ + SEL_OBJY]
        fnstsw  ax
        test    ah, 1               ; or climbing away
        jnz     .skip
        xor     eax, eax            ; spray: less
        cmp     eax, 1
        pop     eax
        ret
.skip:  xor     eax, eax            ; none: not less
        cmp     eax, eax
        pop     eax
        ret

; In place of the launch's `fstp [a scene object's height]` (its hop off
; the conveyor, its arc out of the hangar), two nops after; eax the object
; times 0x15. Z-Gradt's is selzlift's.
selzy_b:
        cmp     eax, SEL_ZOBJ * 0x15
        je      .z
        fstp    dword [eax * 4 + BS_SELOBJ + SEL_OBJY]
        ret
.z:     fstp    st0
        ret

; Entering the select asks for the palettes about the cursor (event 0x18
; and the cursor); the game's events stop at the eighth, so on a boss it
; would load none and Raiden show what the slots last held: on a boss,
; Raiden's. And it has just put the camera 20 along the row a machine; on
; a boss it is put where the moves there leave it - further along, and at
; Z-Gradt up, looking up and back (selstep_*). In place of
; `mov eax, [eax*4 + the cursor]`, two nops after; eax the player times
; 0x15.
SEL_LAST    equ 7                   ; Raiden's cursor, the last
selpalev_b:
        push    edx
        lea     edx, [eax * 4 + BS_SELCUR]
        mov     eax, [edx]
        cmp     eax, JAG
        jb      .out
        fld     dword [sel_bstep]   ; Raiden to Jaguarandi, past 20
        fmul    dword [sel_twenty]
        fsub    dword [sel_twenty]
        cmp     eax, ZGRADT
        jne     .along
        fld     dword [sel_zstep]   ; and on to Z-Gradt, past 20 again
        fmul    dword [sel_twenty]
        fsub    dword [sel_twenty]
        faddp   st1, st0
%macro SELUP 2                      ; the field, its step a frame
        fld     dword [%2]
        fmul    dword [sel_twenty]
        fadd    dword [edx + %1]
        fstp    dword [edx + %1]
%endmacro
        SELUP   SEL_EYEY, sel_zrise
        SELUP   SEL_TGTY, sel_zlook
        SELUP   SEL_DIST, sel_zback
.along: fld     st0
        fadd    dword [edx + SEL_CAM]
        fstp    dword [edx + SEL_CAM]
        fadd    dword [edx + SEL_TGTZ]
        fstp    dword [edx + SEL_TGTZ]
        mov     eax, SEL_LAST
.out:   pop     edx
        ret

; The launch shows the hangar's floor a section at a time, as the machine
; goes by, by a timetable a machine; one past the eight's shows none. A
; boss goes by Raiden's, whose launch Jaguarandi's is. In place of
; `mov eax, [the player's machine]`.
selfloor_b:
        mov     eax, [BS_G1PB]
        cmp     eax, JAG
        jb      .out
        mov     eax, SEL_RAIDEN
.out:   ret

; The bosses' meshes read palette rows 1 and 3 (5 and 7 as the CPU's),
; which the select fills with the eight's (1 to 11, about the cursor). So
; on the select each boss has two rows of its own, sel_bslots, of those
; the game sets once and the select does not use (its thrust is 17 and
; 19), their own kept while it shows and put back after (selpalback); its
; palettes kept in them; and while it is drawn the rows its polygons name
; are turned to those (selremap, selcol). It is lit, then, wherever
; it is, and the widescreen hangar fades it at the right edge as it does
; the eight. From the tick, on the select in one player, pushad'd.
SEL_PALRAM  equ 0x200               ; a row, in each of its three planes
SEL_PLANE   equ 0x4000
SEL_OBJ     equ 0x54                ; a scene object, and its place
SEL_OBJZ    equ 0x38                ; along the row
SEL_CAM     equ 0x34 - 0x44         ; a player's camera, from its cursor
seljagpal:
        cmp     byte [selbuilt], 0
        je      .out
        call    selstate
        jne     .out
        mov     ebx, [sel_launch]   ; one of the eight launching: the
        cmp     ebx, SEL_LREG       ; rows the game's (its water)
        je      .out
        test    ebx, ebx            ; a boss: so too, it in rows 1 and 3,
        jz      .look               ; the cursor's, which the game leaves
        mov     esi, sel_lpair      ; on a boss
        jmp     selbosspal
.look:
        cmp     byte [sel_rowsin], 0 ; the rows' own, kept till it ends
        jne     .kept
        mov     byte [sel_rowsin], 1
        xor     esi, esi
        mov     edi, sel_rowskept
        call    selrows_each
.kept:  mov     ebx, JAG
        mov     esi, sel_bslots
.boss:  lea     eax, [ebx - 7]
        cmp     eax, [unl_level]
        ja      .out
        push    ebx
        push    esi
        call    selbosspal
        pop     esi
        pop     ebx
        add     esi, 8
        inc     ebx
        cmp     ebx, ZGRADT
        jbe     .boss
.out:   ret

SEL_LREG    equ -1
SEL_GOES    equ 2                   ; a scene object's state: launching
; ZF set on the select or a launch from it (B's state).
SEL_STSEL   equ 4
SEL_STLAUNCH equ 5
selstate:
        cmp     dword [BS_STATEB], SEL_STSEL
        je      .out
        cmp     dword [BS_STATEB], SEL_STLAUNCH
.out:   ret

; Off them, from the tick: the rows as they were (pushad'd).
selpalguard:
        call    selstate
        jne     .off
        mov     eax, [sel_launch]
        test    eax, eax
        jnz     .have
        xor     eax, eax            ; set off: a machine's object (two
.obj:   imul    ecx, eax, SEL_OBJ   ; on) to 2, the rest 1 as the row
        cmp     dword [ecx + BS_SELOBJ + 2 * SEL_OBJ + SEL_OBJST], SEL_GOES
        je      .moving             ; moves aside; kept from then till
        inc     eax                 ; the select is left (as it opens
        cmp     eax, ZGRADT         ; one is 2 too; the cursor is its
        jbe     .obj                ; object as it goes)
        mov     dword [sel_objst], 0
        ret
.moving:
        mov     edx, [sel_objst]
        mov     dword [sel_objst], 1
        test    edx, edx
        jnz     .out
        cmp     eax, JAG
        jae     .set
        mov     eax, SEL_LREG
.set:   mov     [sel_launch], eax
.have:  jmp     selpalback          ; all the game's (its water's)
.out:   ret
.off:   mov     dword [sel_launch], 0
        mov     dword [sel_objst], -1
        jmp     selpalback

; eax the boss: its two rows (esi); 1 and 3 while it launches.
selpair:
        cmp     eax, [sel_launch]
        je      .launch
        lea     esi, [sel_bslots + (eax - JAG) * 8]
        ret
.launch:
        mov     esi, sel_lpair
        ret

; The rows as they were.
selpalback:
        cmp     byte [sel_rowsin], 0
        je      .out
        mov     byte [sel_rowsin], 0
        mov     esi, sel_rowskept
        call    selrows_each
.out:   ret

; Each of the bosses' rows, each plane: copied to edi, or from esi.
selrows_each:
        cld
        mov     ebx, sel_bslots
.row:   mov     edx, [ebx]
        shl     edx, 9              ; a row
        add     edx, BS_PALRAMB
        xor     eax, eax
.plane: push    esi
        push    edi
        mov     ecx, SEL_PALRAM / 4
        test    esi, esi
        jz      .out
        mov     edi, edx            ; back
        jmp     .copy
.out:   mov     esi, edx            ; out
.copy:  rep movsd
        pop     edi
        pop     esi
        test    esi, esi
        jz      .on
        add     esi, SEL_PALRAM
        jmp     .next
.on:    add     edi, SEL_PALRAM
.next:  add     edx, SEL_PLANE
        inc     eax
        cmp     eax, 3
        jb      .plane
        add     ebx, 4
        cmp     ebx, sel_bslots + 4 * 4
        jb      .row
        ret

; A palette load fills a row's entries 0 to 63 and 128 to 191; the rest,
; read as a machine is shaded dark (the widescreen hangar's fade), the
; select's rows hold the game's own, which the bosses' rows are given too
; (row 1's).
SEL_PALHALF equ 0x80                ; bytes, 64 entries: a quarter row
selrest:
        cld
        xor     eax, eax
.plane: mov     ecx, eax
        shl     ecx, 14             ; a plane
        lea     edx, [ecx + BS_PALRAMB + SEL_PALRAM + SEL_PALHALF] ; row 1's
        lea     esi, [ecx + BS_PALRAMB]
        mov     ecx, [ebx]
        shl     ecx, 9
        lea     edi, [esi + ecx + SEL_PALHALF]
        mov     esi, edx
        mov     ecx, SEL_PALHALF / 4
        rep movsd                   ; entries 64 to 127
        add     esi, SEL_PALHALF
        add     edi, SEL_PALHALF
        mov     ecx, SEL_PALHALF / 4
        rep movsd                   ; and 192 to 255
        inc     eax
        cmp     eax, 3
        jb      .plane
        ret

; The game sets row 21 for a frame as the cursor arrives at a machine,
; after the tick and before the draws, and the frame is rastered after
; them; so a boss's palettes go in again as it is drawn. eax the boss.
seldrawpal:
        cmp     dword [sel_launch], 0 ; launching (in rows 1 and 3)
        jg      .go
        cmp     byte [sel_rowsin], 0
        je      .out
.go:    pushad
        mov     ebx, eax
        call    selpair
        call    selbosspal
        popad
.out:   ret

; ebx the boss, esi its two rows: its palettes into them, in the colours
; it was given here.
selbosspal:
        push    ebx
        mov     ebx, esi
        call    selrest
        add     ebx, 4
        call    selrest
        sub     ebx, 4
        mov     esi, ebx
        pop     ebx
        mov     edi, [esi]
        mov     esi, [esi + 4]
        mov     eax, ebx
        call    selbcol
        test    edx, edx
        jnz     .worn
        shl     ebx, 2              ; its own
        push    ebx
        push    edi
        call    BS_PALLOADB
        add     esp, 8
        inc     ebx
        push    ebx
        push    esi
        call    BS_PALLOADB
        add     esp, 8
        ret
.worn:  push    esi                 ; or one of the eight's: its pair, from
        xor     ecx, ecx            ; the side this select's player is on
        cmp     dword [BS_MODEB], 0
        je      .side
        mov     ecx, 2
.side:  lea     esi, [ecx + eax * 4]
        lea     esi, [BS_PALB + esi * 4]
        lea     ebx, [edx * 2]
        mov     eax, [esi]
        push    dword [eax + ebx * 4]
        push    edi
        call    BS_PALSETB
        add     esp, 8
        mov     eax, [esi + 4]
        pop     edi                 ; the second row
        push    dword [eax + ebx * 4 + 4]
        push    edi
        call    BS_PALSETB
        add     esp, 8
        ret

; The widescreen hangar shades a machine by how far right of the camera
; it is, black past 28.43, a machine and a half at the eight's 20 apart.
; A boss is further on - Jaguarandi 30 past Raiden, Z-Gradt 98 past it,
; and the camera stops 30 short of Z-Gradt - so it is shaded again here by
; that distance in the eight's measure: each gap to the camera counted as
; 20 (sel_fjag, sel_fz; past the list as it is). From selmdl_b, eax the
; boss, ebp the hangar's frame: [ebp+8] the camera's object, [ebp+0xc]
; the machine's; only when called from the widescreen hangar_draw (the
; return in its blob).
SEL_HDIM    equ 0x1e64              ; ui.asm's D_DIM, from its blob's start
SEL_UISIZE  equ 0x1c00              ; its code
SEL_CAMZ    equ 0xac8               ; the camera's place, from the objects
selfade:
        pushad
        mov     ecx, [BS_HSITE + 1] ; the hangar's call: the widescreen's?
        lea     ecx, [ecx + BS_HSITE + 5]
        cmp     ecx, BS_SELMDLB
        je      .out
        sub     ecx, BS_HDOFF
        mov     edx, [esp + 32 + 4] ; and it the caller
        sub     edx, ecx
        cmp     edx, SEL_UISIZE
        jae     .out
        mov     esi, sel_fjag
        cmp     eax, ZGRADT
        jne     .go
        mov     esi, sel_fz
.go:    mov     eax, [ebp + 8]
        imul    eax, eax, SEL_OBJ
        fld     dword [eax + BS_SELOBJ + SEL_CAMZ]
        mov     eax, [ebp + 0xc]
        imul    eax, eax, SEL_OBJ
        fsubr   dword [eax + BS_SELOBJ + SEL_OBJZ] ; how far right
        fldz                        ; the eight's measure of it
.gap:   mov     edx, [esi]
        test    edx, edx
        jz      .rest
        fld     dword [edx]         ; the gap, the measure, the distance
        fcomi   st0, st2
        jae     .part
        fsub    st2, st0            ; past it: a whole one
        fstp    st0
        fadd    dword [sel_twenty]
        add     esi, 4
        jmp     .gap
.part:  fdivp   st2, st0            ; into it: its share of one
        fxch
        fmul    dword [sel_twenty]
.rest:  faddp   st1, st0
        fsubr   dword [sel_fedge]   ; short of the edge, over the fade
        fmul    dword [sel_fslope]
        fld1
        fcomip  st0, st1
        jbe     .full               ; 1 or more: left alone
        fld     dword [sel_ffloor]  ; at least the floor (0 would be none)
        fcomi   st0, st1
        jb      .over
        fstp    st1
        jmp     .set
.over:  fstp    st0
.set:   fmul    dword [sel_f65536]
        fistp   dword [ecx + SEL_HDIM]
        jmp     .out
.full:  fstp    st0
        mov     dword [ecx + SEL_HDIM], 0
.out:   popad
        ret

; eax the boss being drawn: its slots for the ones its polygons name.
selremap:
        pushad
        call    selpair
        mov     ebx, [esi]
        mov     edi, sel_remapto
        call    .find
        mov     ebx, [esi + 4]
        add     edi, 4
        call    .find
        mov     byte [sel_remap], 1
        popad
        ret
.find:  imul    eax, ebx, SEL_GREY  ; row ebx's grey, its first entry
        mov     ecx, SEL_FIXED      ; of those the game leaves as they are
.look:  cmp     [BS_COLTAB + ecx * 4], eax
        je      .found
        inc     ecx
        cmp     ecx, SEL_COLS
        jb      .look
        pop     eax                 ; none: not turned
        popad
        ret
.found: mov     [edi], ecx
        ret

; A polygon's palette rows are its colour word's top ten bits (at +6 in
; its mesh) through a table of colours (BS_COLTAB), a byte a plane whose
; top five bits are the row; the raster reads the word from the mesh as
; it draws, later in the frame. The bosses' name the greys of rows 1 and 3
; (5 and 7). So while a boss is drawn on the select, each of its polygons
; queued that names one of those is turned, in its mesh, to the table's
; grey of its own row (selremap finds them). Its meshes there are copies
; of its own (sel_loadrb), drawn only here and on the unlock screen,
; which puts its palettes in both. In place of `mov esi, [polygon's
; light]` where the renderers queue a polygon, edx the record, its mesh
; polygon at +4; the flags kept.
SEL_PCOL    equ 6                   ; a mesh polygon's colour word
SEL_GREY    equ 0x080808            ; row 1 in each plane, a step a row
SEL_COLS    equ 1024                ; the table's entries, the game
SEL_FIXED   equ 32                  ; rewriting those below
selcol:
        mov     esi, [BS_POLYCOL]
        cmp     byte [sel_remap], 0
        jne     .map
        ret
.map:   pushfd
        push    eax
        push    ecx
        mov     ecx, [edx + 4]
        movzx   eax, word [ecx + SEL_PCOL]
        shr     eax, 6
        mov     eax, [BS_COLTAB + eax * 4]
        cmp     eax, SEL_GREY
        je      .first
        cmp     eax, SEL_GREY * 5
        je      .first
        cmp     eax, SEL_GREY * 3
        je      .second
        cmp     eax, SEL_GREY * 7
        je      .second
        push    edx                 ; or a boss's rows, turned before:
        xor     ecx, ecx            ; first or second as in its pair
.pair:  imul    edx, [sel_bslots + ecx * 4], SEL_GREY
        cmp     eax, edx
        je      .found
        inc     ecx
        cmp     ecx, 4
        jb      .pair
        pop     edx
        jmp     .out
.found: pop     edx
        test    ecx, 1
        mov     ecx, [edx + 4]      ; the polygon again
        jz      .first
.second:
        mov     eax, [sel_remapto + 4]
        jmp     .set
.first: mov     eax, [sel_remapto]
.set:   shl     eax, 6
        and     word [ecx + SEL_PCOL], 0x3f
        or      [ecx + SEL_PCOL], ax
.out:   pop     ecx
        pop     eax
        popfd
        ret

; eax a boss: the colours it was given on the select, eax the machine
; they are and edx which of its (0: its own, eax 0).
selbcol:
        mov     eax, [sel_bcol + (eax - JAG) * 4]
        xor     edx, edx
        test    eax, eax
        jz      .own
        dec     eax
        mov     ecx, 7
        div     ecx
        inc     edx
        ret
.own:   ret

; The camera slides 20 between machines, a unit a frame; to Jaguarandi
; and back, 30 - it is larger - 1.5 a frame; to Z-Gradt and back,
; sel_zgap, and up onto the hangar's lip and back to take in Z-Gradt's
; size. In place of `fsub` and `fadd qword [1.0]`, a nop after the call,
; at the camera's place along the row and at what it looks at (the same
; with an e: the place, which carries both their heights); [ebp+8] the
; player.
SEL_EYEY    equ 0x30 - 0x44         ; a player's camera's height, and what
SEL_TGTY    equ 0x1c - 0x44         ; it looks at's, and its distance,
SEL_DIST    equ 0x40 - 0x44         ; from its cursor
selstep_sube:
        push    eax
        call    selcur
        cmp     eax, JAG            ; arrived at Jaguarandi from Z-Gradt:
        jne     .row                ; down
        push    eax
        mov     eax, [ebp + 8]
        imul    eax, eax, 0x54
        fld     dword [eax + BS_SELCUR + SEL_EYEY]
        fsub    dword [sel_zrise]
        fstp    dword [eax + BS_SELCUR + SEL_EYEY]
        fld     dword [eax + BS_SELCUR + SEL_TGTY]
        fsub    dword [sel_zlook]
        fstp    dword [eax + BS_SELCUR + SEL_TGTY]
        fld     dword [eax + BS_SELCUR + SEL_DIST]
        fsub    dword [sel_zback]
        fstp    dword [eax + BS_SELCUR + SEL_DIST]
        pop     eax
.row:   pop     eax
selstep_sub:
        push    eax
        call    selcur
        cmp     eax, JAG            ; arrived at Jaguarandi from Z-Gradt
        je      .z
        cmp     eax, 7              ; at Raiden from Jaguarandi
        je      .b
        fsub    dword [sel_one]
        pop     eax
        ret
.z:     fsub    dword [sel_zstep]
        pop     eax
        ret
.b:     fsub    dword [sel_bstep]
        pop     eax
        ret
selstep_adde:
        push    eax
        call    selcur
        cmp     eax, ZGRADT         ; arrived at Z-Gradt: up
        jne     .row
        push    eax
        mov     eax, [ebp + 8]
        imul    eax, eax, 0x54
        fld     dword [eax + BS_SELCUR + SEL_EYEY]
        fadd    dword [sel_zrise]
        fstp    dword [eax + BS_SELCUR + SEL_EYEY]
        fld     dword [eax + BS_SELCUR + SEL_TGTY]
        fadd    dword [sel_zlook]
        fstp    dword [eax + BS_SELCUR + SEL_TGTY]
        fld     dword [eax + BS_SELCUR + SEL_DIST]
        fadd    dword [sel_zback]
        fstp    dword [eax + BS_SELCUR + SEL_DIST]
        pop     eax
.row:   pop     eax
selstep_add:
        push    eax
        call    selcur
        cmp     eax, ZGRADT         ; arrived at Z-Gradt
        je      .z
        cmp     eax, JAG            ; at Jaguarandi
        je      .b
        fadd    dword [sel_one]
        pop     eax
        ret
.z:     fadd    dword [sel_zstep]
        pop     eax
        ret
.b:     fadd    dword [sel_bstep]
        pop     eax
        ret
selcur:
        mov     eax, [ebp + 8]
        imul    eax, eax, 0x54
        mov     eax, [eax + BS_SELCUR]
        ret

; A boss's fight model, for drawing it outside a fight. Its meshes are
; found through the file slot its name has (SEL_JAGFILE, SEL_ZFILE), the
; game's loader putting files one after another in an 8 MB pool; the
; game's own copy is used when it has one. Otherwise the file is read once
; into a block of its own (sel_loadrb), and the slot points there only
; while a boss is drawn (sel_slotsin, sel_slotsout): appended to the pool,
; it could run past its end into what follows - the C library's heap
; list, at the select after a game's end.
; eax the file slot, which is also its name's place.
sel_loadrb:
        pushad
        mov     ebp, eax
        cmp     dword [BS_SLOTS + ebp * 4], 0
        jne     .out                ; the game's copy
        cmp     byte [sel_rbtry + ebp], 0
        jne     .out                ; or ours, read already (or tried)
        mov     byte [sel_rbtry + ebp], 1
        push    dword [BS_RBNAMES + ebp * 8 + 4]
        call    BS_MALLOC
        add     esp, 4
        test    eax, eax
        jz      .out
        mov     esi, eax
        push    dword [BS_RBNAMES + ebp * 8]
        push    BS_RBDIR
        push    BS_PATHFMT
        push    selpath
        call    BS_SPRINTF
        add     esp, 16
        push    BS_RBMODE
        push    selpath
        call    BS_FOPEN
        add     esp, 8
        test    eax, eax
        jz      .out
        mov     ebx, eax
        push    ebx
        push    1
        push    dword [BS_RBNAMES + ebp * 8 + 4]
        push    esi
        call    BS_FREAD
        add     esp, 16
        push    ebx
        call    BS_FCLOSE
        add     esp, 4
        mov     [sel_rbbuf + ebp * 4], esi
.out:   popad
        ret

; Both bosses' slots to their blocks where the game has no copy, and back.
sel_slotsin:
        pushad
%assign k 0
%rep 2
  %if k
    %define SLOT SEL_ZFILE
  %else
    %define SLOT SEL_JAGFILE
  %endif
        cmp     dword [BS_SLOTS + SLOT * 4], 0
        jne     .k%[k]
        mov     eax, [sel_rbbuf + SLOT * 4]
        test    eax, eax
        jz      .k%[k]
        mov     [BS_SLOTS + SLOT * 4], eax
        mov     byte [sel_rbin + k], 1
.k%[k]:
  %undef SLOT
%assign k k + 1
%endrep
        popad
        ret

sel_slotsout:
        cmp     byte [sel_rbin], 0
        je      .z
        mov     byte [sel_rbin], 0
        mov     dword [BS_SLOTS + SEL_JAGFILE * 4], 0
.z:     cmp     byte [sel_rbin + 1], 0
        je      .out
        mov     byte [sel_rbin + 1], 0
        mov     dword [BS_SLOTS + SEL_ZFILE * 4], 0
.out:   ret

; In place of the calls to the select's text for the cursor (cdecl, the
; cursor): for a boss, its weapons, its name and its model, as the game
; writes the eight's - the weapons on the plane its frame's parity picks,
; the name a block of tiles.
; Z-Gradt has a fourth, a line under the others', and the bosses' lines
; are longer than the eight's: on one of the eight, all four are blanked
; first on the plane it writes.
SEL_TXT     equ 0x68                ; per boss: four weapons of 0x14, its
SEL_CODE    equ 0x50                ; model, and its name: tiles, width,
SEL_LOGO    equ 0x5c                ; height
SEL_LINES   equ 4
selinfo_b:
        mov     eax, [esp + 4]
        cmp     eax, JAG
        jge     .boss
        test    eax, eax
        jl      BS_SELINFOB
        push    esi
        call    selplane
        mov     edx, selblank
        call    sellines
        pop     esi
        jmp     BS_SELINFOB
.boss:  push    ebx
        push    esi
        lea     ebx, [eax - JAG]
        imul    ebx, ebx, SEL_TXT
        add     ebx, seltxt
        call    selplane
        mov     edx, ebx
        call    sellines
        push    0x10
        push    7
        call    BS_TXTPOSB
        add     esp, 8
        push    3
        push    0x26
        call    BS_TCLEARB
        add     esp, 8
        push    dword [ebx + SEL_LOGO + 8]
        push    dword [ebx + SEL_LOGO + 4]
        push    dword [ebx + SEL_LOGO]
        call    BS_TBLOCKB
        add     esp, 12
        push    0xe
        push    8
        call    BS_TXTPOSB
        add     esp, 8
        lea     eax, [ebx + SEL_CODE]
        push    eax
        call    BS_PRINTBB
        add     esp, 4
        pop     esi
        pop     ebx
        ret

; esi the print for the plane this frame writes, as the game picks it.
selplane:
        mov     eax, [BS_FRAMEB]
        cmp     dword [BS_SELMODE], 2
        jne     .p
        shr     eax, 1
.p:     mov     esi, BS_PRINTBB
        test    eax, 1
        jz      .out
        mov     esi, BS_PRINTAB
.out:   ret

; The weapon lines, from edx, 0x14 apart (or one line again, selblank's),
; through esi.
sellines:
        push    ebx
        mov     ebx, edx
%assign i 0
%rep SEL_LINES
        push    0x14 + 2 * i
        push    8
        call    BS_TXTPOSB
        add     esp, 8
        push    ebx
        call    esi
        add     esp, 4
        cmp     ebx, selblank
        je      .same%[i]
        add     ebx, 0x14
.same%[i]:
%assign i i + 1
%endrep
        pop     ebx
        ret

; The portraits along the bottom are one block of tiles, eight of 6 by 8
; a column apart; the marker over the cursor's goes a portrait further for
; each, so the bosses' are two more after Raiden's. Theirs are portraits
; drawn for the patch (assets/portrait_*.png), framed and backed as the
; eight's and written by the patcher into spare tiles of the artwork
; (boss_icon_tiles), 48 each in reading order, 0x80 apart as the select
; loads them. Made on entering the select: a boss's is blank in two
; players and while it is locked. Where the row is drawn is selshift's.
SEL_ROW     equ 0x37                ; the eight's, wide
SEL_ROWW    equ SEL_ROW + 2 * 7     ; and with the bosses'
SEL_ICON    equ 6
SEL_ICONW   equ 0x137a              ; the first tile's map entry
selrow_make:
        cld
        xor     ebx, ebx
.row:   imul    esi, ebx, SEL_ROW * 2
        add     esi, BS_ROW
        mov     dx, [esi + SEL_ICON * 2] ; the column between two
        imul    edi, ebx, SEL_ROWW * 2
        add     edi, selrow
        mov     ecx, SEL_ROW
        rep movsw
        imul    esi, ebx, SEL_ICON
        add     esi, SEL_ICONW
        xor     ebp, ebp            ; the boss, 0 Jaguarandi
        call    .icon
        add     esi, 0x80
        inc     ebp
        call    .icon
        inc     ebx
        cmp     ebx, 8
        jb      .row
        ret
.icon:  mov     ax, dx              ; esi the row's first tile
        stosw
        mov     ecx, SEL_ICON
        cmp     dword [GAMEMODE], 0
        jne     .blank
        cmp     ebp, [unl_level]    ; or a boss still locked
        jae     .blank
        mov     eax, esi
.tile:  stosw
        inc     eax
        loop    .tile
        ret
.blank: mov     ax, dx
        rep stosw
        ret

; The row of ten portraits fits a standard-definition screen only once
; it is moved left; as the game has it, Z-Gradt's runs off the right. So
; in one player, with both bosses unlocked, it goes SEL_SHIFT2 columns
; left, and with Jaguarandi alone SEL_SHIFT1, which centres its nine; with
; it the 1P/2P marks over a portrait and the frame around it. With neither
; unlocked all of it is where the game puts it. In place of the column
; steps either side of the row, `add [column], 2` before it and `add
; [column], 0xc` after (the title back where it was), and of the four
; `lea eax, [eax*2 + place]` that put a mark or the frame; two nops after
; each call.
SEL_SHIFT1  equ 4
SEL_SHIFT2  equ 7
selshift:                           ; eax the shift, in columns
        xor     eax, eax
        cmp     dword [GAMEMODE], 0
        jne     .out
        cmp     dword [unl_level], 1
        jb      .out
        mov     eax, SEL_SHIFT1
        je      .out
        mov     eax, SEL_SHIFT2
.out:   ret

selrowx:
        push    eax
        call    selshift
        neg     eax
        add     eax, 2
        add     [BS_TXTX], eax
        pop     eax
        ret

seltitlex:
        push    eax
        call    selshift
        add     eax, 0xc
        add     [BS_TXTX], eax
        pop     eax
        ret

%macro SELMARK 2                    ; label, its place on the plane
%1:
        push    ecx
        lea     ecx, [eax * 2 + %2]
        call    selshift
        add     eax, eax
        sub     ecx, eax
        mov     eax, ecx
        pop     ecx
        ret
%endmacro

        SELMARK selmark1, BS_PLANE + 0x17bc
        SELMARK selmark2, BS_PLANE + 0x17c4
        SELMARK selframe1, BS_PLANE + 0x8
        SELMARK selframe2, BS_PLANE + 0x10

; The select's countdown, seconds left = (SEL_TIME - frames) / 60 - 1:
; SEL_MORE seconds longer with a boss unlocked, in one player, for the
; walk to it and its colours. In place of `mov eax, SEL_TIME`.
SEL_TIME    equ 0x4eb
SEL_MORE    equ 20
seltime:
        mov     eax, SEL_TIME
        cmp     dword [GAMEMODE], 0
        jne     .out
        cmp     dword [unl_level], 0
        je      .out
        add     eax, SEL_MORE * 60
.out:   ret

; The frame round the portrait under a cursor is a sprite, at the
; portrait's place in pixels plus two doubles, read-only data the game's
; reads of are pointed at sel_frxw instead; from the tick, set for the
; shift each frame.
selframex:
        call    selshift
        shl     eax, 3              ; 8 pixels a column
        push    eax
        fild    dword [esp]
        add     esp, 4
        fld     qword [sel_frx]
        fsub    st1
        fstp    qword [sel_frxw]
        fld     qword [sel_frx + 8]
        fsubrp  st1
        fstp    qword [sel_frxw + 8]
        ret

; --- colour ----------------------------------------------------------------

; The loaders' `jg` for an id above 7 comes here. [ebp+8] is the slot,
; [ebp+0xc] the palette id: machine * 4 + side * 2 + which of the pair.
pal_a:
        mov     edx, BS_PALA
        call    bosspal
        test    eax, eax
        jz      BS_PALFIXA
        push    eax
        push    dword [ebp + 8]
        call    BS_PALSETA
        add     esp, 8
        jmp     BS_PALRETA
pal_b:
        mov     edx, BS_PALB
        call    bosspal
        test    eax, eax
        jz      BS_PALFIXB
        push    eax
        push    dword [ebp + 8]
        call    BS_PALSETB
        add     esp, 8
        jmp     BS_PALRETB

; edx the copy's palette table. eax the palette the player's boss wears
; for this id, or 0 to load its own.
bosspal:
        xor     eax, eax
        mov     ecx, [ebp + 0xc]
        mov     ebx, ecx
        shr     ebx, 2
        cmp     ebx, [boss]
        jne     .out                ; not the player's boss, or none
        mov     ebx, BS_COL0
        test    cl, 2
        jz      .side
        mov     ebx, BS_COL1
.side:  cmp     ebx, [bside]
        jne     .out                ; the other side: a CPU of the same id
        mov     ebx, [bcolor]
        test    ebx, ebx
        jz      .out                ; its own colour, so the boss keeps its
        and     ecx, 3
        mov     eax, [bsrc]
        lea     eax, [ecx + eax * 4]
        mov     eax, [edx + eax * 4]
        and     ecx, 1
        lea     ecx, [ecx + ebx * 2]
        mov     eax, [eax + ecx * 4]
.out:   ret

; Jaguarandi's win and lose poses (its model's routines at +0x43c and
; +0x440) take the frame as the round's count past the pose's start modulo
; the pose's length, so through the win's camera it plays its pose over
; and over; the eight's hold its last frame, and so does it now. In place
; of `cdq; idiv ecx; mov [frame], dx`, five nops after; eax the count, ecx
; the pose's frames.
%macro POSE 2                       ; label, the copy's frame
%1:
        cmp     eax, ecx
        jl      %%in
        lea     eax, [ecx - 1]
%%in:   mov     [%2], ax
        ret
%endmacro

        POSE    pose_a, BS_MFRAMEA
        POSE    pose_b, BS_MFRAMEB

; --- PLAYER DATA -----------------------------------------------------------

; The report after stage 5 turns a model of the player's machine, drawn
; from per-machine tables only the eight have rows in (0x5fb9f8, 0x5fbab8):
; a boss read past them and crashed. A boss is drawn by its own fight
; object instead, the way the win screen draws it: its per-frame routine
; at [object+4], which ticks and draws it. The object is the one taken
; standing at the start of its last round (STAND, below), put at the
; turntable's middle; afterwards the real one, its AI state and what else
; the routine writes are put back, so nothing moves on. Sound effects are
; off while it runs, and the effects it spawns - Jaguarandi's exhaust,
; placed by the turntable's matrix - are undone before they are drawn.
; Z-Gradt's moves would carry it round its arena, off the turntable, so it
; gets its draw alone.
;
; A machine draws its lower body on the matrix it finds - in a fight the
; identity, the camera being applied later, at the submit - and then loads
; the identity to place the upper body in the world. While the report
; draws a boss, the identity it loads is the turntable's matrix instead.
;
; In place of the call to the parts draw, (machine), at the end of the
; report's model routine.

%macro BOSSMODEL 17                 ; label, the parts draw, the object,
%1:                                 ; push, pop, scale, AI state, its
        mov     eax, [esp + 4]      ; save area, the current matrix, the
        cmp     eax, JAG            ; standing object and its AI state,
        jae     %%boss              ; Z-Gradt's draw, the effects tables
        jmp     %2
%%boss: pushad
        COPYN   objsave, %3, OBJECT
        COPYN   %8, %7, AI_STATE
        COPYN   fxsave, %13, FX
        COPYN   fx2save, %14, FX2
        cmp     dword [%10 + 0x64], eax
        jne     %%now               ; no standing copy of this machine
        COPYN   %3, %10, OBJECT
        COPYN   %7, %11, AI_STATE
%%now:  push    dword [BS_RFLAG]
        push    dword [SEMUTE]
        push    dword [BS_ZMODA]
        push    dword [BS_ZMODB]
        mov     dword [SEMUTE], 1
        call    %4
        mov     esi, %15            ; Jaguarandi's size, or Z-Gradt's
        cmp     dword [%3 + 0x64], ZGRADT
        jne     %%size
        mov     esi, %16
%%size: push    dword [esi]
        push    dword [esi]
        push    dword [esi]
        call    %6
        add     esp, 12
        mov     eax, [%9]           ; moved across the screen, before the
        fld     dword [eax + 0x24]  ; turntable turns it
        fadd    dword [esi + 8]
        fstp    dword [eax + 0x24]
        push    esi
        COPYN   rmbase, [%9], 0x30
        pop     esi
        mov     byte [rmbase_on], 1
        mov     ebx, %3
        xor     eax, eax
        mov     [ebx + 8], eax      ; at the origin, at the height that
        mov     [ebx + 0x10], eax   ; puts it in the turntable's middle
        mov     eax, [esi + 4]
        mov     [ebx + 0xc], eax
        push    ebx
        cmp     dword [ebx + 0x64], ZGRADT
        jne     %%tick
        mov     word [ebx + 0x34], 0 ; level: its draw pitches it by this
        call    %12                 ; Z-Gradt's moves would carry it off
        jmp     %%drawn             ; round its arena: the draw alone
%%tick: call    %17                 ; its per-frame routine, or its draw
%%drawn:
        add     esp, 4
        mov     byte [rmbase_on], 0
        call    %5
        pop     dword [BS_ZMODB]
        pop     dword [BS_ZMODA]
        pop     dword [SEMUTE]
        pop     dword [BS_RFLAG]
        COPYN   %14, fx2save, FX2   ; what the draw spawned - exhaust,
        COPYN   %13, fxsave, FX     ; placed by the turntable - is undone
        COPYN   %7, %8, AI_STATE
        COPYN   %3, objsave, OBJECT
        popad
        ret
%endmacro

        BOSSMODEL model_ra, BS_RPARTA, BS_OBJA, BS_MPUSHA, BS_MPOPA,                   BS_MSCALEA, BS_BSSA, aisave_a, BS_MATA, stand_a,                   standai_a, BS_ZDRAWA, BS_FXA, BS_FX2A, rm_jag, rm_z, [ebx + 4]
; While an unlock shows, the model is the boss unlocked, the CPU's: its
; standing copy (unl_tick) at the CPU's object, drawn alone - its
; per-frame routine runs the CPU's moves, which twitched it now and then.
; The player's Jaguarandi stands as on the unlock: its select pose, at
; the unlock's size and place.
model_rb:
        cmp     dword [unl_on], 0
        jne     model_ub
        cmp     dword [esp + 4], JAG
        je      model_rbj
        jmp     model_rbp
        BOSSMODEL model_ub, BS_RPARTB, BS_CPUB, BS_MPUSHB, BS_MPOPB,                   BS_MSCALEB, BS_BSSB, aisave_b, BS_MATB, stand_cb,                   standai_cb, unl_zdraw, BS_FXB, BS_FX2B, urm_jag, urm_z, unl_jdraw
        BOSSMODEL model_rbp, BS_RPARTB, BS_OBJB, BS_MPUSHB, BS_MPOPB,                   BS_MSCALEB, BS_BSSB, aisave_b, BS_MATB, stand_b,                   standai_b, BS_ZDRAWB, BS_FXB, BS_FX2B, rm_jag, rm_z, [ebx + 4]
        BOSSMODEL model_rbj, BS_RPARTB, BS_OBJB, BS_MPUSHB, BS_MPOPB,                   BS_MSCALEB, BS_BSSB, aisave_b, BS_MATB, stand_b,                   standai_b, BS_ZDRAWB, BS_FXB, BS_FX2B, rrm_jag, rm_z, unl_jdraw

; The unlock's model, as the select stands it: Z-Gradt still in its
; stance's first frame, Jaguarandi posed by Raiden's select motions (the
; select's motions stay loaded). cdecl, the object, placed: its place is
; all they take from it.
unl_zdraw:
        push    ebx
        mov     ebx, [esp + 8]
        mov     eax, SEL_ZFILE
        call    sel_loadrb
        call    sel_slotsin
        call    BS_MPUSHB
        push    dword [ebx + 0x10]
        push    dword [ebx + 0xc]
        push    dword [ebx + 8]
        call    BS_TRANSB
        add     esp, 12
        call    selzdraw
        call    BS_MPOPB
        call    sel_slotsout
        pop     ebx
        ret

unl_jdraw:
        cmp     dword [unl_on], ZGRADT
        je      unl_zdraw
        push    ebx
        mov     ebx, [esp + 8]
        mov     eax, SEL_JAGFILE
        call    sel_loadrb
        call    sel_slotsin
        call    BS_MPUSHB
        push    dword [ebx + 0x10]
        push    dword [ebx + 0xc]
        push    dword [ebx + 8]
        call    BS_TRANSB
        add     esp, 12
        mov     byte [seljagdraw], 1 ; with its head (selpart_b)
        push    0
        push    0
        push    0
        push    JAG
        call    selmdl_b.draw
        add     esp, 16
        mov     byte [seljagdraw], 0
        call    BS_MPOPB
        call    sel_slotsout
        pop     ebx
        ret

; In place of load identity's prologue, five bytes and a nop.
%macro IDENT 3                      ; label, past the prologue, the matrix
%1:
        cmp     byte [rmbase_on], 0
        jne     %%base
        push    ebp
        mov     ebp, esp
        push    ebx
        push    esi
        push    edi
        jmp     %2
%%base: push    esi
        push    edi
        push    ecx
        COPYN   [%3], rmbase, 0x30
        pop     ecx
        pop     edi
        pop     esi
        ret
%endmacro

        IDENT   ident_a, BS_IDENTA, BS_MATA
        IDENT   ident_b, BS_IDENTB, BS_MATB

; A machine's shadow is the machine again, flattened onto the ground below
; it; on the report the ground is wherever the turntable puts it. While the
; report draws a boss, the shadow is skipped.
;
; In place of the shadow's first instruction, mov eax, [light].
%macro NOSHADE 4                    ; label, the light, past it, the skip
%1:
        cmp     byte [rmbase_on], 0
        jne     %%skip
        mov     eax, [%2]
        jmp     %3
%%skip: jmp     %4
%endmacro

        NOSHADE noshade_a, BS_LIGHTA, BS_SHADEA, BS_NOSHADEA
        NOSHADE noshade_b, BS_LIGHTB, BS_SHADEB, BS_NOSHADEB

; Z-Gradt's shadow, the same: in place of its first test, cmp [timer], 0x9a.
%macro NOZSHADE 4                   ; label, the timer, past it, the skip
%1:
        cmp     byte [rmbase_on], 0
        jne     %%skip
        cmp     dword [%2], 0x9a
        jmp     %3
%%skip: jmp     %4
%endmacro

        NOZSHADE nozshade_a, BS_ZSHTA, BS_ZSHADEA, BS_ZNOSHADEA
        NOZSHADE nozshade_b, BS_ZSHTB, BS_ZSHADEB, BS_ZNOSHADEB


; Its machine name comes from a table of the eight as well. In place of
; `mov eax, [id]` and the three that index the table: eax the name.
%macro NAME 3                       ; label, the player's id, the table
%1:
        mov     eax, [%2]
        cmp     eax, JAG
        je      %%jag
        cmp     eax, ZGRADT
        je      %%z
        lea     eax, [eax + eax * 2]
        lea     eax, [eax + eax * 4]
        add     eax, %3
        ret
%%jag:  mov     eax, name_jag
        ret
%%z:    mov     eax, name_z
        ret
%endmacro

        NAME    name_a, BS_G1PA, BS_NAMEA
        NAME    name_b, BS_G1PB, BS_NAMEB

; --- unlocking -------------------------------------------------------------

; The bosses start locked. Jaguarandi is unlocked by beating it, and
; Z-Gradt, with Jaguarandi unlocked, by finishing the game - each in one
; player on Very Hard without a match lost since the game began. What is
; unlocked is kept in bosses.bin beside the game: a dword, 0 neither, 1
; Jaguarandi, 2 both; the select offers the machines up to it.
;
; The unlock shows on PLAYER DATA's black screen, the game's own report
; run in place: its state 0x1e (the report proper; 0x1c and 0x1d before it
; set the screen up) does the unlock's frames instead while unl_on names
; the boss, and the report's text is not drawn. The model is the report's
; turning one, the boss's standing copy from its last round drawn at the
; CPU's object (model_ub); the text is YOU UNLOCKED and the boss's name as
; the select shows it. SDB_title plays under it. After it, Jaguarandi's
; goes on to the report, and Z-Gradt's to the initials.
;
; Only B, the copy a one-player game is played on.
UNL_TITLE   equ 0x101a              ; SDB_title
UNL_TXT1    equ 30                  ; frames: YOU UNLOCKED, the name,
UNL_TXT2    equ 60
UNL_PROMPT  equ 300                 ; near SDB_title's end: PRESS BUTTON TO
UNL_FLASH   equ 32                  ; CONTINUE, on and off for this many
UNL_PROMPTW equ 0x34                ; frames, a button ending it; what it
UNL_PROMPTH equ 2                   ; covers, cleared
UNL_NJ      equ 0x22 * 2            ; the names' tiles, Jaguarandi's
UNL_NZ      equ 0x1a * 3            ; and Z-Gradt's
UNL_TILE    equ 0x80                ; a tile's bytes
ST_SELECT   equ 4                   ; B's state on the select
UNL_BUTTONS equ 0x10110             ; the buttons that end the report, as
                                    ; held (BS_PADEDGE is held, not pressed)
ST_REPORT   equ 0x1c                ; B's states: the report's start,
ST_INITIALS equ 0x16                ; the initials, the last fight won,
ST_ZWON     equ 0x1f                ; and the rounds
ST_ROUND    equ 0x0a
ST_ROUNDZ   equ 0x0b
VERY_HARD   equ 2
UNL_TEXB    equ 4                   ; the fights' texture bank, half 1

; The unlocks, read the first time the tick runs.
unl_load:
        cmp     byte [unl_read], 0
        jne     .out
        pushad
        mov     byte [unl_read], 1
        push    BS_RBMODE
        push    unl_file
        call    BS_FOPEN
        add     esp, 8
        test    eax, eax
        jz      .done
        mov     ebx, eax
        push    ebx
        push    1
        push    4
        push    unl_level
        call    BS_FREAD
        add     esp, 16
        push    ebx
        call    BS_FCLOSE
        add     esp, 4
        cmp     dword [unl_level], 2
        jbe     .done
        mov     dword [unl_level], 0
.done:  popad
.out:   ret

unl_save:
        pushad
        push    BS_WBMODE
        push    unl_file
        call    BS_FOPEN
        add     esp, 8
        test    eax, eax
        jz      .done
        mov     ebx, eax
        push    ebx
        push    1
        push    4
        push    unl_level
        call    BS_FWRITE
        add     esp, 16
        push    ebx
        call    BS_FCLOSE
        add     esp, 4
.done:  popad
        ret

; Each frame, from the tick. A new game (B through states 0 and 1, which a
; continue does not pass) starts clean; anything but Very Hard, or two
; players, spoils it, as a lost match does (unl_lost). The last fight won
; is noted for the initials' hook. And in a round the CPU's boss is taken
; standing, as the player's is, for the unlock's model.
unl_tick:
        pushad
        cmp     dword [BS_STATEB], 1
        ja      .play
        mov     dword [unl_clean], 1
        mov     dword [unl_zwon], 0
.play:  cmp     byte [BS_DIFF], VERY_HARD
        jne     .dirty
        cmp     dword [GAMEMODE], 0
        je      .won
.dirty: mov     dword [unl_clean], 0
.won:   cmp     dword [BS_STATEB], ST_ZWON
        jne     .round
        cmp     dword [BS_STAGEB], LAST_STAGE
        jne     .round
        mov     dword [unl_zwon], 1
.round:
        mov     eax, [BS_STATEB]
        cmp     eax, ST_SELECT
        jne     .notsel
        movzx   ecx, word [BS_SCENEB]
        sub     ecx, SELECT_LO
        cmp     ecx, SELECT_HI - SELECT_LO
        jae     .out
        call    unl_grab
        jmp     .out
.notsel:
        cmp     eax, ST_ROUND
        je      .stand
        cmp     eax, ST_ROUNDZ
        jne     .out
.stand: STAND   BS_CPUB, BS_READYB, BS_BSSB, stand_cb, standai_cb, stood_cb
.out:   popad
        ret

; The names are the select's art, which other screens load other art in
; the place of; on the report, a name's tiles are past its art's end. So
; on the select they are taken (unl_grab), each as the plane's draw finds
; it, and for the unlock put where the report's art reaches, at a whole
; tile from its start (unl_place), the name drawn from a map of its own.
; k, 0 to UNL_NJ + UNL_NZ: Jaguarandi's map, then Z-Gradt's.

; eax k -> ecx its map entry, esi its tile (0 none or out of reach).
unl_tileat:
        lea     esi, [BS_LOGOJ + eax * 2]
        cmp     eax, UNL_NJ
        jb      .j
        lea     esi, [BS_LOGOZ + (eax - UNL_NJ) * 2]
.j:     movzx   ecx, word [esi]
        xor     esi, esi
        test    ecx, 0x3fff
        jz      .out
        mov     esi, ecx
        test    ecx, 0x4000
        jz      .one
        and     esi, 0x3fff
        shl     esi, 7
        add     esi, [BS_ARTPOOL2]
        jmp     .in
.one:   and     esi, 0x7fff
        shl     esi, 7
        add     esi, [BS_ARTPOOL]
.in:    cmp     esi, BS_ARTEND - UNL_TILE
        ja      .none
        cmp     esi, 0x401000
        jae     .out
.none:  xor     esi, esi
.out:   ret

; From the tick, on the select.
unl_grab:
        pushad
        cld
        xor     ebx, ebx
.k:     mov     eax, ebx
        call    unl_tileat
        test    esi, esi
        jz      .next
        mov     edi, ebx
        shl     edi, 7
        add     edi, unl_tiles
        mov     ecx, UNL_TILE / 4
        rep movsd
.next:  inc     ebx
        cmp     ebx, UNL_NJ + UNL_NZ
        jb      .k
        mov     byte [unl_got], 1
        popad
        ret

; The names' tiles in unl_area, at a whole tile from the start of the
; report's art and so numbered as its tiles are; the plane's draw takes no
; tile past the art's count, so the count is raised over them, and put
; back by unl_unplace. Nothing of the game's is written: the memory just
; past the art holds textures, which, the tiles written there, kept them
; (seen on the ground behind the initials). unl_map the boss's name's map
; there. CF set if they are out of the art's reach.
unl_place:
        pushad
        cld
        cmp     byte [unl_got], 0
        je      .no
        cmp     byte [unl_placed], 0
        jne     .map
        mov     edi, unl_area       ; a whole tile on from the art's start
        mov     eax, [BS_ARTPOOL]
        sub     eax, edi
        and     eax, UNL_TILE - 1
        add     edi, eax
        mov     ebp, edi
        sub     ebp, [BS_ARTPOOL]
        jb      .no
        shr     ebp, 7              ; its first tile's number
        lea     eax, [ebp + UNL_NJ + UNL_NZ]
        cmp     eax, 0x4000
        jae     .no
        mov     esi, unl_tiles
        mov     ecx, (UNL_NJ + UNL_NZ) * UNL_TILE / 4
        rep movsd
        mov     [unl_first], ebp
        mov     ecx, [BS_ARTCOUNT]
        mov     [unl_count], ecx
        cmp     eax, ecx
        jbe     .in
        mov     [BS_ARTCOUNT], eax
.in:    mov     byte [unl_placed], 1
.map:   mov     ebp, [unl_first]
        xor     ebx, ebx            ; the map: the name's own entries,
        mov     edx, UNL_NJ         ; renumbered
        cmp     dword [unl_on], JAG
        je      .m
        mov     ebx, UNL_NJ
        mov     edx, UNL_NJ + UNL_NZ
.m:     mov     edi, unl_map
.e:     mov     eax, ebx
        call    unl_tileat
        xor     eax, eax
        test    ecx, 0x3fff
        jz      .put
        lea     eax, [ebp + ebx]
.put:   stosw
        inc     ebx
        cmp     ebx, edx
        jb      .e
        popad
        clc
        ret
.no:    popad
        stc
        ret

unl_unplace:
        cmp     byte [unl_placed], 0
        je      .out
        push    eax
        mov     eax, [unl_count]
        mov     [BS_ARTCOUNT], eax
        mov     byte [unl_placed], 0
        pop     eax
.out:   ret

; The palettes, all of them (three planes of 0x4000), kept from before the
; unlock and put back after it: what follows reads them as they were - the
; initials' ground went the boss's colours, and its glowing orbs black.
UNL_PALS    equ 3 * 0x4000
unl_palsave:
        cmp     byte [unl_palin], 0
        jne     .out
        pushad
        cld
        mov     esi, BS_PALRAMB
        mov     edi, unl_pals
        mov     ecx, UNL_PALS / 4
        rep movsd
        mov     byte [unl_palin], 1
        popad
.out:   ret

unl_palback:
        cmp     byte [unl_palin], 0
        je      .out
        pushad
        cld
        mov     esi, unl_pals
        mov     edi, BS_PALRAMB
        mov     ecx, UNL_PALS / 4
        rep movsd
        mov     byte [unl_palin], 0
        popad
.out:   ret

; The scene the report replaces, kept for the initials after Z-Gradt's
; unlock: its floor texture and model as they are, not read again - the
; scene once loaded is worked on, its glowing orbs among it, which a fresh
; read leaves black - and its glow's state.
UNL_FC      equ 0x40600             ; the largest floor texture,
UNL_FLD     equ 0x86440             ; and model, and the select's motions
UNL_MTSEL   equ 0x2cdc4             ; read in over whatever is there
unl_scnsave:
        pushad
        cld
        cmp     dword [unl_scnmem], 0
        jne     .have
        push    UNL_FC + UNL_FLD + UNL_MTSEL
        call    BS_MALLOC
        add     esp, 4
        mov     [unl_scnmem], eax
        test    eax, eax
        jz      .out
.have:  mov     edi, [unl_scnmem]
        mov     esi, BS_FCBUF
        mov     ecx, UNL_FC / 4
        rep movsd
        mov     esi, BS_FLDBUF
        mov     ecx, UNL_FLD / 4
        rep movsd
        mov     esi, BS_MTSELMEM
        mov     ecx, UNL_MTSEL / 4
        rep movsd
        mov     eax, [BS_SEGA]
        mov     [unl_sega], eax
        mov     eax, [BS_GLOW1]
        mov     [unl_glow], eax
        mov     eax, [BS_GLOW2]
        mov     [unl_glow + 4], eax
        mov     eax, [BS_GLOW3]
        mov     [unl_glow + 8], eax
        mov     byte [unl_scnin], 1
.out:   popad
        ret

unl_scnback:
        cmp     byte [unl_scnin], 0
        je      .out
        pushad
        cld
        mov     esi, [unl_scnmem]
        mov     edi, BS_FCBUF
        mov     ecx, UNL_FC / 4
        rep movsd
        mov     edi, BS_FLDBUF
        mov     ecx, UNL_FLD / 4
        rep movsd
        mov     edi, BS_MTSELMEM
        mov     ecx, UNL_MTSEL / 4
        rep movsd
        mov     eax, [unl_sega]
        mov     [BS_SEGA], eax
        mov     eax, [unl_glow]
        mov     [BS_GLOW1], eax
        mov     eax, [unl_glow + 4]
        mov     [BS_GLOW2], eax
        mov     eax, [unl_glow + 8]
        mov     [BS_GLOW3], eax
        mov     eax, [unl_scn]      ; and the scene in, as far as the
        mov     [BS_SCNNOW], eax    ; loader knows
        mov     byte [unl_scnin], 0
        popad
.out:   ret

; In place of the calls that load a texture bank (bank, half): the bank in
; half 1 noted, for what the report's replaces to be loaded again.
unl_ldtex:
        cmp     dword [esp + 8], 1
        jne     .load
        push    eax
        mov     eax, [esp + 8]
        mov     [unl_texnow], eax
        pop     eax
.load:  jmp     BS_LOADTEX

; ZF set if this game can unlock: one player, Very Hard, nothing lost.
unl_ok:
        cmp     dword [GAMEMODE], 0
        jne     .out
        cmp     byte [BS_DIFF], VERY_HARD
        jne     .out
        cmp     dword [unl_clean], 1
.out:   ret

; In place of `inc [lost matches]`, a nop after the call.
unl_lost:
        inc     dword [BS_LOSSB]
        mov     dword [unl_clean], 0
        ret

; In place of `mov [state], 0x1c` once stage 5, Jaguarandi's, is won;
; five nops after the call.
unl_jag:
        mov     dword [BS_STATEB], ST_REPORT
        call    unl_ok
        jne     .out
        cmp     dword [unl_level], 0
        jne     .out
        cmp     dword [BS_CPUB + 0x64], JAG
        jne     .out
        mov     dword [unl_level], 1
        call    unl_save
        mov     dword [unl_on], JAG
        mov     dword [unl_t], 0
.out:   ret

; In place of `mov [state], 0x16` at the credits' end, five nops after the
; call: a game finished that unlocks Z-Gradt runs the report first.
unl_z:
        cmp     dword [unl_zwon], 0
        je      .initials
        mov     dword [unl_zwon], 0
        call    unl_ok
        jne     .initials
        cmp     dword [unl_level], 1
        jne     .initials
        mov     dword [unl_level], 2
        call    unl_save
        mov     eax, [BS_SCNNOW]    ; the scene and textures in, for
        mov     [unl_scn], eax      ; after
        mov     eax, [unl_texnow]
        mov     [unl_texb], eax
        call    unl_scnsave
        mov     dword [unl_on], ZGRADT
        mov     dword [unl_t], 0
        mov     dword [BS_STATEB], ST_REPORT
        ret
.initials:
        mov     dword [BS_STATEB], ST_INITIALS
        ret

; In place of the call of the report's text: none while an unlock shows.
unl_text:
        cmp     dword [unl_on], 0
        jne     .out
        jmp     BS_REPTEXTB
.out:   ret

; B's state 0x1e, from its table.
unl_logic:
        cmp     dword [unl_on], 0
        jne     .unlock
        jmp     BS_REPLOGICB
.unlock:
        pushad
        cmp     dword [unl_t], 0
        jne     .text
        push    UNL_TITLE
        call    BS_SFX
        add     esp, 4
        mov     dword [unl_prev], UNL_BUTTONS ; one held from before: not
        mov     byte [unl_go], 0    ; a press
        call    unl_palsave         ; what the palettes held, kept, and
        mov     ebx, [unl_on]       ; the boss's in, both sides'
        shl     ebx, 2
%assign i 0
%rep 4
        lea     eax, [ebx + i]
        push    eax
        push    1 + 2 * i
        call    BS_PALLOADB
        add     esp, 8
%assign i i + 1
%endrep
        mov     eax, [unl_on]       ; and in its rows on the select, which
        lea     edi, [sel_bslots + (eax - JAG) * 8] ; its meshes may name
%assign i 0
%rep 2
        lea     eax, [ebx + i]
        push    eax
        push    dword [edi + 4 * i]
        call    BS_PALLOADB
        add     esp, 8
%assign i i + 1
%endrep
        push    0
        call    BS_TCLRALL
        add     esp, 4
        call    BS_TRESET
.text:  cmp     dword [unl_t], UNL_TXT1
        jne     .name
        push    0
        call    BS_TCLRALL
        add     esp, 4
        call    BS_TRESET
        push    dword [unl_y1]
        push    dword [unl_x1]
        call    BS_TXTPOSB
        add     esp, 8
        push    unl_you
        call    BS_PRINTBIG
        add     esp, 4
.name:  cmp     dword [unl_t], UNL_TXT2
        jne     .model
        call    unl_place
        jc      .model              ; out of the art's reach: no name
        mov     ebx, [unl_on]
        sub     ebx, JAG
        push    dword [unl_y2]
        push    dword [unl_x2 + ebx * 4]
        call    BS_TXTPOSB
        add     esp, 8
        imul    ebx, ebx, SEL_TXT
        add     ebx, seltxt
        push    dword [ebx + SEL_LOGO + 8]
        push    dword [ebx + SEL_LOGO + 4]
        push    unl_map
        call    BS_TBLOCKB
        add     esp, 12
.model: fild    dword [unl_t]       ; growing to the report's size
        fmul    dword [unl_grow]
        fld     dword [unl_size]
        fcomi   st0, st1
        fcmovnb st0, st1
        fstp    st1
        sub     esp, 4
        fstp    dword [esp]
        push    dword [BS_G1PB]     ; the model is the player's machine's:
        mov     eax, [unl_on]       ; the boss's for it
        mov     [BS_G1PB], eax
        push    dword [esp + 4]
        call    BS_REPMODELB
        add     esp, 4
        pop     dword [BS_G1PB]
        add     esp, 4
        mov     eax, [unl_t]
        sub     eax, UNL_PROMPT
        jb      .next
        test    eax, UNL_FLASH - 1
        jnz     .button
        mov     ebx, eax
        push    dword [unl_py]      ; on, or off
        push    dword [unl_px]
        call    BS_TXTPOSB
        add     esp, 8
        test    ebx, UNL_FLASH
        jnz     .off
        push    unl_press
        call    BS_PRINTBIG
        add     esp, 4
        jmp     .button
.off:   push    UNL_PROMPTH
        push    UNL_PROMPTW
        call    BS_TCLEARB
        add     esp, 8
.button:                            ; a press made since, then let go:
        mov     eax, [BS_PADEDGE]   ; the buttons are held ones, and the
        and     eax, UNL_BUTTONS    ; report after skips itself while one
        cmp     byte [unl_go], 0    ; is down
        jne     .release
        mov     ecx, [unl_prev]
        mov     [unl_prev], eax
        not     ecx
        test    eax, ecx
        jz      .next
        mov     byte [unl_go], 1
        jmp     .next
.release:
        test    eax, eax
        jz      .end
.next:  inc     dword [unl_t]
        popad
        ret
.end:   push    0                   ; as the report ends
        call    BS_TCLRALL
        add     esp, 4
        call    BS_TRESET
        call    unl_unplace
        call    unl_palback
        push    0
        call    BS_FADE
        add     esp, 4
        mov     dword [BS_REPCNT], -1
        push    1
        push    -1
        push    0xa
        call    BS_SCNEND
        add     esp, 12
        mov     dword [unl_t], 0
        mov     eax, [unl_on]
        mov     dword [unl_on], 0
        mov     dword [BS_STATEB], ST_REPORT ; Jaguarandi's: the report
        cmp     eax, JAG
        je      .out
        call    unl_scnback         ; Z-Gradt's: the fight's scene and
        push    1                   ; textures back, which the report's
                                    ; replaced and the initials draw their
                                    ; ground from,
        push    dword [unl_texb]
        call    BS_LOADTEX
        add     esp, 8
        mov     word [BS_SCENEB], 0x91 ; and the initials, as the
        mov     dword [BS_EVB], 0x81 ; credits go to them
        mov     dword [BS_STATEB], ST_INITIALS
.out:   popad
        ret

; --- the round's animations ------------------------------------------------

; Mode 0x80 loads clips from tables the bosses have no rows in. Skip to
; the extras after them.
loads_a:
        mov     eax, [BS_IDA]
        cmp     eax, JAG
        jae     BS_LDXA
        jmp     BS_LDA
loads_b:
        mov     eax, [BS_IDB]
        cmp     eax, JAG
        jae     BS_LDXB
        jmp     BS_LDB

; After those, a deref of the same tables and the looping stand overlay.
deref_a:
        cmp     dword [BS_IDA], JAG
        jae     BS_DRSA
        cmp     dword [ebp + DR_FLAG], 0
        je      BS_DRJA
        jmp     BS_DRFA
deref_b:
        cmp     dword [BS_IDB], JAG
        jae     BS_DRSB
        cmp     dword [ebp + DR_FLAG], 0
        je      BS_DRJB
        jmp     BS_DRFB

; Mode 0xa: the same extras as 0x80 rather than the deref.
case2_a:
        mov     eax, [BS_IDA]
        cmp     eax, JAG
        jae     BS_LDXA
        jmp     BS_C2A
case2_b:
        mov     eax, [BS_IDB]
        cmp     eax, JAG
        jae     BS_LDXB
        jmp     BS_C2B

; --- the ending ------------------------------------------------------------

; The final win runs the player's machine through a script (mode 5, from
; its per-frame routine): Z-Gradt falls, the machine turns to the moon gate
; and its charge is set going. Phase 0 runs the charge and the shot by the
; machine number in the player's global, 0 to 7, then the gate's fall, and
; the dash back. Phase 1 is the text, VR-OPERATION SYSTEM to FREEZE; phase 2
; the staff roll, which shows the machine battle-damaged, a model the
; bosses do not have, so a boss goes from phase 1 to the button wait.
;
; A boss plays it as Raiden, whose charge runs a set length rather than
; reading the machine's motions, which for a boss are not loaded. Jaguarandi
; fires its own right weapon; Z-Gradt's charge and laser are its own (ZEND,
; below).
;
; The flag and the player's global are both gone by the ending; the
; object's id and model are what is left, so they decide.
RAIDEN      equ 3

%macro ENDING 12    ; label, id, model, jag, zgradt, phase, time,
                    ; resume, phase 1, epilogue, button wait, global
%1:
        mov     eax, [%2]
        sub     eax, JAG
        cmp     eax, ZGRADT - JAG
        jbe     %%boss
        cmp     dword [%3], %4
        je      %%boss
        cmp     dword [%3], %5
        je      %%boss
        cmp     dword [%6], 0
        jne     %9
        jmp     %8
%%boss:
        mov     eax, [%12]          ; Raiden's for phase 0's animation,
        cmp     eax, JAG            ; the boss's own again after it, for
        jb      %%lent              ; the ranking and the name entry
        mov     [end_g1p], eax
%%lent: cmp     dword [%6], 0
        jne     %%own
        mov     dword [%12], RAIDEN
        jmp     %8
%%own:  mov     eax, [end_g1p]
        test    eax, eax
        jz      %%phase
        mov     [%12], eax
%%phase:
        cmp     dword [%6], 2
        jb      %9
        je      %11
        jmp     %10
%endmacro

        ENDING  end_a, BS_IDA, BS_MDLA, BS_JAGA, BS_ZGA, BS_PHASEA, \
                BS_TIMEA, BS_ENDA, BS_END1A, BS_ENDEA, BS_ENDWA, BS_G1PA
        ENDING  end_b, BS_IDB, BS_MDLB, BS_JAGB, BS_ZGB, BS_PHASEB, \
                BS_TIMEB, BS_ENDB, BS_END1B, BS_ENDEB, BS_ENDWB, BS_G1PB

; Z-Gradt's part. Its per-frame routine runs the script as the others' do,
; and the script sets the charge going (the timer at 1). Z-Gradt's goes:
;
;   0  its super laser is started as its crouch button would (attack 6,
;      its state from -1 to 0, the gold glow), and its cannon comes out
;      over ZLASER_OUT frames, the charge held back meanwhile (phase 0 run
;      with the timer at 0);
;   1  the charge: the particles and the camera turning about the machine,
;      the cannon held out short of firing. The charge runs on the
;      machine's own charge code, which for Z-Gradt is not there, so its
;      counter is given as full, and what the charge writes into the
;      machine's joint frames (which Z-Gradt's draw reads), and a flag of
;      Raiden's, is put back;
;   2  after ZCHARGE frames the laser fires and the ending moves on as the
;      charge code would. From here the ending runs Z-Gradt as Bal-Bas-Bow,
;      whose shot code keeps to its own kind of weapon slot: Raiden's would
;      take the beam, in the weapon slots, for Raiden's, Viper's turn it
;      into homing beams.
;
; Through 0 and 1 Z-Gradt turns gold, its palette events posted from here:
; its own ramp to gold is not to be counted on, outside a fight. The laser
; puts it back as it goes in.
;
; The script's setup for the charge and its last step, the dash back, set
; moves that on Z-Gradt mean other things, so both steps are passed. The
; laser fires till ZFIRE_END - the shot's camera then on its way back - not
; for its usual 0x78 frames, and its beam's segments, which would end at the
; arena's edge, go on to the gate, as phase 0 has the eight's shots do; and in place of the dash, Z-Gradt leaves as it came, its
; fly-in run backwards over ZFLY_N frames from ZFLY_T0, with phase 0 - its
; camera with it - given Z-Gradt where it is drawn.
;
; On the last stage the player's Z-Gradt keeps its AI state in a bank of
; its own (AI, above); the live block is then the CPU's.
;
; In place of the call to phase 0.
ZCHARGE     equ 240
ZLASER_OUT  equ 0x102               ; the laser's state, cannon out: it
                                    ; fires on reaching 0x104
ESTEP_SETUP equ 0x29e
ZFIRE_END   equ 0xe0                ; before phase 0 clears the weapon slots
ZFIRE_HOLD  equ 0x70                ; of the laser's 0x78
ZFLY_N      equ 252
ZFLY_T0     equ 0x38b - ZFLY_N - 80 ; phase 0 ends at 0x38b
ZBEAM_SLOT  equ 0xcb                ; the laser's weapon slots
ZBEAM_END   equ 0xe6                ; when phase 0 clears them
ZSLOW_N     equ 3
ESTEP_DASH  equ 0x5b0
ZPOSE       equ 0xb0                ; the joint frames, to 0x100
ZPOSE_N     equ 0x50
BALBAS      equ 7                   ; whose shot code takes only its own slots

%macro ZEND 13                      ; label, phase 0, the player, its id,
%1:                                 ; the step, the timer, its AI state, its
        cmp     dword [%4], ZGRADT  ; bank, banked, the laser's state, the
        je      %%z                 ; player's global, the palette event,
                                    ; the beam's speed
        jmp     %2
%%z:    cmp     dword [%5], ESTEP_SETUP ; its setup for the charge,
        jne     %%dash              ; which sets moves on Z-Gradt, passed
        inc     dword [%5]
        mov     dword [%6], 1
%%dash: cmp     dword [%5], ESTEP_DASH
        jne     %%fly
        inc     dword [%5]
%%fly:
%%which:
        push    eax
        mov     eax, %7             ; eax: the laser's state
        cmp     dword [%9], 0
        je      %%live
        mov     eax, %8
%%live: add     eax, %10
        cmp     dword [%6], 1
        je      %%charge
        cmp     dword [%6], 2
        jb      %%run
        mov     dword [%11], BALBAS
        cmp     dword [eax], 0x104  ; firing: held on till ZFIRE_END
        jne     %%away
        cmp     dword [%6], ZFIRE_END
        jae     %%away
        cmp     word [%3 + 0x178], ZFIRE_HOLD
        jl      %%away
        mov     word [%3 + 0x178], ZFIRE_HOLD
%%away: cmp     dword [%6], ZBEAM_END ; the beam on through the arena's
        jae     %%stop              ; edge to the gate (ZWALL, below)
        cmp     byte [zbeam_free], 0
        jne     %%slow
        mov     byte [zbeam_free], 1
        mov     dword [zspd_at], %13
        push    dword [%13]
        pop     dword [zspd]
        fld     dword [%13]
        fmul    dword [zspd_k]
        fstp    dword [%13]
%%slow: inc     dword [zslow]       ; and, a frame in ZSLOW_N, its segments
        cmp     dword [zslow], ZSLOW_N ; held where they are: as far, but
        jb      %%flyc              ; not so fast
        mov     dword [zslow], 0
        push    ecx
        push    edx
        lea     ecx, [%3 + 0x200]
        mov     edx, 32
%%seg:  cmp     byte [ecx], ZBEAM_SLOT
        jne     %%next
        test    byte [ecx + 3], 0x80 ; not once it has hit
        jnz     %%next
        dec     word [ecx + 4]
%%next: add     ecx, 0x20
        dec     edx
        jnz     %%seg
        pop     edx
        pop     ecx
        jmp     %%flyc
%%stop: call    zbeam_off
%%flyc: mov     ecx, [%6]           ; the fly-in backwards (ZFLY, below)
        sub     ecx, ZFLY_T0
        jge     %%up
        pop     eax
        jmp     %2
%%up:
        call    zflyout
        mov     byte [zstage], 0    ; phase 0 - its camera with it - sees
        mov     dword [zcharge], 0  ; Z-Gradt where it is drawn
        mov     dword [zgold], 0
        pop     eax
        push    dword [%3 + 0xc]
        push    dword [%3 + 0x10]
        fld     dword [%3 + 0xc]
        fadd    dword [zfly_y]
        fstp    dword [%3 + 0xc]
        fld     dword [%3 + 0x10]
        fadd    dword [zfly_z]
        fstp    dword [%3 + 0x10]
        call    %2
        pop     dword [%3 + 0x10]
        pop     dword [%3 + 0xc]
        ret
%%charge:
        cmp     dword [zgold], 0x1f ; the gold, a step a frame the handler
        jae     %%gold              ; is free
        cmp     dword [%12], 0xff
        jne     %%gold
        inc     dword [zgold]
        push    eax
        mov     eax, [zgold]
        add     eax, 0x200
        mov     [%12], eax
        pop     eax
        mov     byte [zmine], 1
%%gold: cmp     byte [zstage], 0
        jne     %%held
        cmp     dword [zcharge], 0  ; 0: start the laser, run with the
        jne     %%out               ; timer at 0 till the cannon is out
        mov     dword [zcharge], 1
        mov     word [%3 + 0x170], 6
        mov     word [%3 + 0x17c], 0
        mov     word [%3 + 0x178], 0
        mov     dword [eax], 0
%%out:  cmp     dword [eax], ZLASER_OUT
        jl      %%quiet
        mov     byte [zstage], 1
        mov     dword [zcharge], 0
%%held: mov     dword [eax], ZLASER_OUT ; 1: the charge, the cannon held
        inc     dword [zcharge]
        pop     eax
        pushad
        COPYN   zpose, %3 + ZPOSE, ZPOSE_N
        mov     ax, [%3 + 0x178]
        mov     [zpose + ZPOSE_N], ax
        mov     ax, [%3 + 0x1a4]
        mov     [zpose + ZPOSE_N + 2], ax
        mov     word [%3 + 0x178], 0x7fff
        call    %2
        mov     ax, [zpose + ZPOSE_N]
        mov     [%3 + 0x178], ax
        mov     ax, [zpose + ZPOSE_N + 2]
        mov     [%3 + 0x1a4], ax
        COPYN   %3 + ZPOSE, zpose, ZPOSE_N
        popad
        cmp     dword [zcharge], ZCHARGE
        jb      %%ret
        mov     byte [zstage], 0    ; 2: fire, the ending on
        mov     dword [zcharge], 0
        inc     dword [%5]
        mov     dword [%6], 2
%%ret:  ret
%%quiet:
        pop     eax
        mov     dword [%6], 0
        call    %2
        mov     dword [%6], 1
        ret
%%run:  mov     byte [zfly_on], 0
        call    zbeam_off
        mov     byte [zstage], 0
        mov     dword [zcharge], 0
        mov     dword [zgold], 0
        pop     eax
        jmp     %2
%endmacro

        ZEND    zend_a, BS_PH0A, BS_OBJA, BS_IDA, BS_ESTEPA, BS_TIMEA, \
                BS_BSSA, bank_a, banked_a, 0x1cc, BS_G1PA, BS_EVA, BS_SPDA
        ZEND    zend_b, BS_PH0B, BS_OBJB, BS_IDB, BS_ESTEPB, BS_TIMEB, \
                BS_BSSB, bank_b, banked_b, 0x1c4, BS_G1PB, BS_EVB, BS_SPDB

; Each segment of Z-Gradt's beam, a step at a time, asks the arena how high
; its floor is where it has got to, and stops there if under it: outside
; the arena the floor is its wall. During the ending's shot (ZEND) the
; answer is far below, so the beam reaches the gate.
;
; In place of that call, in the beam segment's routine; the answer in st0.
%macro ZWALL 2                      ; label, the call
%1:
        cmp     byte [zbeam_free], 0
        je      %2
        fld     dword [zbeam_far]
        ret
%endmacro

        ZWALL   zwall_a, BS_WALLA
        ZWALL   zwall_b, BS_WALLB

; The beam's segments go out a step a frame for so many frames, their step
; the speed of their kind of weapon slot; ZEND makes it ZSPD_K times as
; long through the ending's shot, enough for the gate, and this puts it back.
zbeam_off:
        cmp     byte [zbeam_free], 0
        je      .r
        mov     byte [zbeam_free], 0
        push    eax
        push    ecx
        mov     eax, [zspd_at]
        mov     ecx, [zspd]
        mov     [eax], ecx
        pop     ecx
        pop     eax
.r:     ret

; From the shot on, the ending's camera follows the player's last live
; weapon slot - for the eight, its shot on the way to the gate - and, once
; it has hit, comes back from where it last was. Z-Gradt's beam stands at
; its cannon, so for Z-Gradt the camera is given a slot of its own instead:
; a point leaving the cannon for the gate at ZBEAM_V a frame.
;
; In place of `mov eax, [ebp-0x10]; add eax, 0x600`, the scan's start.
%macro ZBEAM 6                      ; label, the player, its id, the timer,
%1:                                 ; the scan, the slot found
        cmp     dword [%3], ZGRADT
        je      %%z
        mov     eax, [ebp - 0x10]
        add     eax, 0x600
        jmp     %5
%%z:    mov     eax, [%4]
        sub     eax, 2
        mov     [zbeam_n], eax
        fild    dword [zbeam_n]
        fmul    dword [zbeam_v]
        fadd    dword [%2 + 0x10]
        fadd    dword [zbeam_z]
        fstp    dword [zfake + 0x18]
        fld     dword [%2 + 0xc]
        fadd    dword [zbeam_y]
        fstp    dword [zfake + 0x14]
        mov     eax, [%2 + 8]
        mov     [zfake + 0x10], eax
        mov     dword [ebp - 0x1c], zfake
        jmp     %6
%endmacro

        ZBEAM   zbeam_a, BS_OBJA, BS_IDA, BS_TIMEA, BS_SCANA, BS_FOUNDA
        ZBEAM   zbeam_b, BS_OBJB, BS_IDB, BS_TIMEB, BS_SCANB, BS_FOUNDB

; The ending's camera puts the eye a set way from what it looks at, sized
; for the eight, and builds the view from the two: turned to look from the
; eye at the target, then moved by minus the eye. For a boss that last move
; puts the eye further back along the same line, eye' = target + s (eye -
; target); as moved by, -eye' = s (-eye + target) - target, with s = k.
; While the other machine falls the camera eases in from the fight's, which
; for Z-Gradt is far out already, so s is held to k ECAP_D over the
; distance; and the eye goes off to one side as well, so the boss is not in
; front of it. The camera's own state is left alone, so its easing goes
; on as it was.
;
; In place of the call to the move, the three floats on the stack.
%macro ETRANS 6                     ; label, the move, the camera's block,
%1:                                 ; the player's id, the ending's step,
        cmp     dword [%4], JAG     ; its timer
        jae     %%boss
        jmp     %2
%%boss: push    esi
        mov     esi, ecam_jag
        cmp     dword [%4], ZGRADT
        jne     %%k
        cmp     dword [%6], ZFLY_T0 ; Z-Gradt flying out, further back
        jge     %%flyk
        cmp     dword [%6], 2       ; from its shot on as the other,
        jge     %%k                 ; following a shot
        mov     esi, ecam_z
        jmp     %%k
%%flyk: mov     esi, ecam_zfly
%%k:    fld     dword [esi]         ; s, the scale; until the turn, no
        cmp     dword [%5], ESTEP_TURN ; more than k ECAP_D from the target
        jge     %%s
%assign i 0
%rep 3
        fld     dword [esp + 8 + 4 * i]
        fadd    dword [%3 + 0x24 + 4 * i]
        fmul    st0, st0
  %if i
        faddp   st1, st0
  %endif
%assign i i + 1
%endrep
        fsqrt                       ; d, then k ECAP_D / d
        fdivr   dword [ecap_d]
        fmul    st0, st1
        fcomi   st0, st1
        jae     %%big
        fxch    st1
%%big:  fstp    st0                 ; the smaller
%%s:
%assign i 0
%rep 3
        fld     dword [esp + 8 + 4 * i] ; -t + s (a + t)
        fadd    dword [%3 + 0x24 + 4 * i]
        fmul    st0, st1
        fsub    dword [%3 + 0x24 + 4 * i]
        fstp    dword [esp + 8 + 4 * i]
%assign i i + 1
%endrep
        fstp    st0
        mov     eax, ESTEP_TURN     ; until the turn, the eye off to the
        sub     eax, [%5]           ; right as well, by ESIDE of the way
        jle     %%done              ; to the target, fading out over the
        cmp     eax, ESTEP_FADE     ; last ESTEP_FADE steps
        jbe     %%fade
        mov     eax, ESTEP_FADE
%%fade: mov     [eside_n], eax
        fild    dword [eside_n]
        fmul    dword [eside]       ; c
        fld     dword [%3 + 0x2c]
        fadd    dword [esp + 0x10]  ; fz, target less eye
        fmul    st0, st1
        fld     dword [%3 + 0x24]
        fadd    dword [esp + 8]     ; fx
        fmul    st0, st2
        fadd    dword [esp + 0x10]  ; -eye.z + c fx
        fstp    dword [esp + 0x10]
        fsubr   dword [esp + 8]     ; -eye.x - c fz
        fstp    dword [esp + 8]
        fstp    st0
%%done: pop     esi
        jmp     %2
%endmacro

ESTEP_TURN  equ 0x23a               ; the ending's step the turn starts at
ESTEP_FADE  equ 64

        ETRANS  etrans_a, BS_ETRA, BS_ECBLKA, BS_IDA, BS_ESTEPA, BS_TIMEA
        ETRANS  etrans_b, BS_ETRB, BS_ECBLKB, BS_IDB, BS_ESTEPB, BS_TIMEB

; --- Z-Gradt's chase camera ------------------------------------------------

; Z-Gradt is several times the size of the eight, and the chase camera
; puts the eye inside it. Is the player one, by any of the places that say?
; ZF set if so.
is_zgradt:
        cmp     dword [BS_IDA], ZGRADT
        je      .out
        cmp     dword [BS_G1PA], ZGRADT
        je      .out
        cmp     dword [BS_IDB], ZGRADT
        je      .out
        cmp     dword [BS_G1PB], ZGRADT
.out:   ret

; In place of a call to the view translate: [esp+4..0xc] are the eye's
; negated X, Y and Z. Pull it back along the yaw it was placed by.
%macro PULL 5                       ; label, view, sin, cos, yaw
%1:
        call    is_zgradt
        jne     %2
        movsx   ecx, word [%5]
        push    ecx
        call    %3
        add     esp, 4
        fmul    dword [pull]
        fadd    dword [esp + 4]
        fstp    dword [esp + 4]
        movsx   ecx, word [%5]
        push    ecx
        call    %4
        add     esp, 4
        fmul    dword [pull]
        fsubr   dword [esp + 0xc]
        fstp    dword [esp + 0xc]
        jmp     %2
%endmacro

; One stub per yaw: the first two sites share one, as do the last two.
; The replay's call is not one of them: REPLAY below aims it properly.
        PULL    cam_1, BS_VIEWA, BS_SINA, BS_COSA, BS_YAW1
        PULL    cam_2, BS_VIEWA, BS_SINA, BS_COSA, BS_YAW2
        PULL    cam_4, BS_VIEWB, BS_SINB, BS_COSB, BS_YAW4
        PULL    cam_5, BS_VIEWB, BS_SINB, BS_COSB, BS_YAW5

; The live camera, once its distance at 0x40 is final: four times it for
; Z-Gradt. In place of `mov eax, [ebp+CAM_PTR]; movsx eax, word [eax+0x1e]`.
%macro LIVE 2                       ; label, resume
%1:
        call    is_zgradt
        jne     %%stock
        mov     eax, [ebp + CAM_PTR]
        fld     dword [eax + 0x3c]
        fmul    dword [scale]
        fstp    dword [eax + 0x3c]
        fld     dword [eax + 0x3c]
        fstp    dword [eax + 0x40]
%%stock:
        mov     eax, [ebp + CAM_PTR]
        movsx   eax, word [eax + 0x1e]
        jmp     %2
%endmacro

        LIVE    live_a, BS_LIVEA
        LIVE    live_b, BS_LIVEB

; --- Z-Gradt against Z-Gradt -----------------------------------------------

; Falls through on the last stage, else jumps to %1.
%macro LAST 1
        cmp     dword [BS_STAGEA], LAST_STAGE
        je      %%last
        cmp     dword [BS_STAGEB], LAST_STAGE
        jne     %1
%%last:
%endmacro

; Jumps to %2 if %1 is the player's object, in either copy.
%macro IF_PLAYER 2
        cmp     %1, BS_OBJA
        je      %2
        cmp     %1, BS_OBJB
        je      %2
%endmacro

; Jumps to %1 once GET READY has been up READY_GO frames, in either copy.
%macro IF_READY 1
        cmp     dword [BS_READYA], READY_GO
        jge     %1
        cmp     dword [BS_READYB], READY_GO
        jge     %1
%endmacro

; Z-Gradt's init wipes the boss globals the CPU's has just set. The
; player's returns before it does.
%macro INIT 2                       ; label, resume
%1:
        LAST    %%stock
        IF_PLAYER dword [esp + 4], %%skip
%%stock:
        push    ebp
        mov     ebp, esp
        push    ebx
        push    esi
        push    edi
        jmp     %2
%%skip: ret
%endmacro

        INIT    init_a, BS_INITA
        INIT    init_b, BS_INITB

; The fly-in runs on a global timer and an absolute height, so a second
; Z-Gradt ticks the CPU's descent twice and drives it into the floor. The
; player's skips it: standing still until GET READY is done, then on from
; after the landing.
%macro FLY 5                        ; label, resume, after landing,
%1:                                 ; epilogue, Z-Gradt's model global
        LAST    %%stock
        IF_PLAYER dword [esp + 4], %%skip
%%stock:
        push    ebp
        mov     ebp, esp
        sub     esp, 0xc
        push    ebx
        push    esi
        push    edi
        jmp     %2
%%skip:
        push    ebp
        mov     ebp, esp
        sub     esp, 0xc
        push    ebx
        push    esi
        push    edi
        mov     eax, [ebp + 8]
        IF_READY %%live
        mov     byte [eax + 0x137], 0xff    ; no pose 4 on the first tick
        mov     word [eax + 0x10e], 0       ; and no speed left from the
        mov     word [eax + 0x172], 0       ; fly-in
        mov     word [eax + 0x186], 0
        mov     dword [eax + 0x1c4], 0
        mov     eax, [eax + 0x6c]
        mov     [%5], eax
        jmp     %4
%%live:
        mov     eax, [eax + 0x6c]
        mov     [%5], eax
        jmp     %3
%endmacro

        FLY     fly_a, BS_FLYA, BS_FLYPA, BS_FLYEA, BS_ZMODA
        FLY     fly_b, BS_FLYB, BS_FLYPB, BS_FLYEB, BS_ZMODB

; The fly-in timer locks the machine until it runs out. The player's waits
; for GET READY instead. In place of `cmp dword [timer], 0; jge skip`.
%macro TIMER 4                      ; label, timer, resume, skip
%1:
        LAST    %%stock
        IF_PLAYER dword [ebp + 8], %%player
%%stock:
        cmp     dword [%2], 0
        jge     %4
        jmp     %3
%%player:
        IF_READY %3
        jmp     %4
%endmacro

        TIMER   tm_1, BS_ZTIMA, BS_TM1, BS_TM1S
        TIMER   tm_2, BS_ZTIMB, BS_TM2, BS_TM2S
        TIMER   tm_3, BS_ZTIMA, BS_TM3, BS_TM3S
        TIMER   tm_4, BS_ZTIMB, BS_TM4, BS_TM4S

; Which clip bank an object animates from: the pad's for the player, the
; AI's for a Z-Gradt that is not. eax is the object.
%macro CLIP 3                       ; label, bank 0, bank 3
%1:
        LAST    %%stock
        IF_PLAYER eax, %2
        cmp     dword [eax + 0x64], ZGRADT
        je      %3
%%stock:
        movsx   eax, word [eax + 0x30]
        test    eax, eax
        jne     %3
        jmp     %2
%endmacro

        CLIP    clip_a, BS_CLIP0A, BS_CLIP3A
        CLIP    clip_b, BS_CLIP0B, BS_CLIP3B

; The player's Z-Gradt gets its own copy of the model header, made once,
; so the CPU's writes to it do not move both.
%macro CLONE 4                      ; label, resume, copy, copied flag
%1:
        push    ebp
        mov     ebp, esp
        sub     esp, 0x44
        push    ebx
        push    esi
        push    edi
        LAST    %2
        mov     eax, [ebp + 8]
        IF_PLAYER eax, %%player
        jmp     %2
%%player:
        mov     ecx, [eax + 0x6c]
        test    ecx, ecx
        jz      %2
        cmp     ecx, %3
        je      %2
        cmp     ecx, BS_ZGA
        je      %%z
        cmp     ecx, BS_ZGB
        jne     %2
%%z:    cmp     dword [%4], 0
        jne     %%point
        mov     esi, ecx
        mov     edi, %3
        mov     ecx, MODEL_COPY / 4
        cld
        rep movsd
        mov     dword [%4], 1
%%point:                            ; esi and edi are the function's to
        mov     esi, [eax + 0x6c]   ; set, after the pushes above
        mov     edi, [eax + 0x70]
        sub     edi, esi
        mov     dword [eax + 0x6c], %3
        lea     edi, [edi + %3]
        mov     [eax + 0x70], edi
        jmp     %2
%endmacro

        CLONE   clone_a, BS_CLONEA, copy_a, copied_a
        CLONE   clone_b, BS_CLONEB, copy_b, copied_b

; dst, src: one block of Z-Gradt's AI state.
%macro COPYAI 2
        push    esi
        push    edi
        push    ecx
        mov     esi, %2
        mov     edi, %1
        mov     ecx, AI_STATE / 4
        cld
        rep movsd
        pop     ecx
        pop     edi
        pop     esi
%endmacro

; Z-Gradt's setup points four words of the AI state at its side's tables:
; the meshes of its upper parts, and with them the palette slots they draw
; in. ZTAB0 for side 0 ([object+0x68]), ZTAB1 otherwise, each at ZTAB_2..4
; on. The copy below is the CPU's, so the player's are put back in it.
ZTAB_2      equ 0x58
ZTAB_3      equ 0x248
ZTAB_4      equ 0x260

; The player's Z-Gradt ticks against its own copy of the AI state, swapped
; in around the call. The copy starts as the CPU's, just initialised - a
; zero one sends 0x1ad01c4 through a NULL - with the three timers the init
; sets to -1 set again.
%macro AI 13        ; label, resume, live state, bank, scratch, flag,
                    ; three offsets set to -1, and the offsets of the
                    ; four words the side's tables go in
%1:
        LAST    %%stock
        IF_PLAYER dword [esp + 4], %%wrap
%%stock:
        push    ebp
        mov     ebp, esp
        sub     esp, 4
        push    ebx
        push    esi
        push    edi
        jmp     %2
%%wrap:
        cmp     dword [%6], 0
        jne     %%have
        COPYAI  %4, %3
        mov     dword [%4 + %7], -1
        mov     dword [%4 + %8], -1
        mov     dword [%4 + %9], -1
        mov     dword [%6], 1
        push    eax                 ; the player's side's tables (ZTABLE)
        mov     eax, [esp + 8]
        cmp     dword [eax + 0x68], 0
        mov     eax, BS_ZTAB0
        je      %%side
        mov     eax, BS_ZTAB1
%%side: mov     [%4 + %10], eax
        add     eax, ZTAB_2
        mov     [%4 + %11], eax
        add     eax, ZTAB_3 - ZTAB_2
        mov     [%4 + %12], eax
        add     eax, ZTAB_4 - ZTAB_3
        mov     [%4 + %13], eax
        pop     eax
%%have:
        COPYAI  %5, %3
        COPYAI  %3, %4
        push    dword [esp + 4]
        call    %%stock
        add     esp, 4
        COPYAI  %4, %3
        COPYAI  %3, %5
        ret
%endmacro

        AI      ai_a, BS_TICKA, BS_BSSA, bank_a, scratch_a, banked_a, \
                0x24, 0x1c0, 0x1cc, 0x1c4, 0x1c8, 0xc, 0xd8
        AI      ai_b, BS_TICKB, BS_BSSB, bank_b, scratch_b, banked_b, \
                0x1c, 0x1b8, 0x1c4, 0x1bc, 0x1c0, 0x4, 0xd0

; In place of each `mov eax, [model global]` in Z-Gradt's code: on the last
; stage, the model of whichever fight object the function was given.
%macro MODEL 2                      ; label, the global
%1:
        LAST    %%global
        mov     eax, [ebp + 8]
        IF_PLAYER eax, %%own
        cmp     eax, BS_CPUA
        je      %%own
        cmp     eax, BS_CPUB
        je      %%own
%%global:
        mov     eax, [%2]
        ret
%%own:
        mov     eax, [eax + 0x6c]
        test    eax, eax
        jz      %%global
        ret
%endmacro

        MODEL   model_a, BS_ZMODA
        MODEL   model_b, BS_ZMODB

; Every machine's object is set up with attack 1, a weapon's at rest; for
; Z-Gradt, attack 1 fires its ring lasers. The CPU's has its AI to take
; over; a player's Z-Gradt, ticked by its stick, opened every fight with
; them. After Z-Gradt's own setup, a player's is put at no attack.
;
; In place of the call to Z-Gradt's setup, both sites per copy.
%macro ZINIT 2                      ; label, the setup
%1:
        push    dword [esp + 4]
        call    %2
        add     esp, 4
        mov     eax, [esp + 4]
        IF_PLAYER eax, %%player
        ret
%%player:
        mov     word [eax + 0x170], 0
        ret
%endmacro

        ZINIT   zinit_a, BS_ZINITA
        ZINIT   zinit_b, BS_ZINITB

; Z-Gradt's fly-in (0x407dd1, its counter f in the AI state), backwards,
; as offsets from where it stands: f from 0 it comes 20 a frame from far
; off, at 70 up, pitched 0x4000; from 0x78, 4.8 a frame, the pitch easing by
; 0x80 a frame; from 0xc8 it drops the 70 under 0.05 a frame. Backwards, r
; frames in, ecx:
;   r <  53   up from the ground, y 70 - 0.025 (53 - r)^2, pitching up
;             once 0x1800 - 0x80 (53 - r) is over 0
;   r < 133   back at 4.8 a frame, the pitch from 0x1800 by 0x80 a frame
;   r < 252   back at 20 a frame, pitched 0x4000
; Its movement sets its place each frame, so these go in around its draw
; only (ZFLY): up and back by so much, pitched so, drawn, and put back.
zflyout:
        cmp     ecx, ZFLY_N - 1
        jle     .r
        mov     ecx, ZFLY_N - 1
.r:     mov     byte [zfly_on], 1
        cmp     ecx, 53
        jge     .back
        mov     eax, 53             ; y = 70 - 0.025 d^2, d = 53 - r
        sub     eax, ecx
        mov     [zfly_n], eax
        fild    dword [zfly_n]
        fmul    st0, st0
        fmul    dword [zfly_g]
        fsubr   dword [zfly_h]
        fstp    dword [zfly_y]
        mov     dword [zfly_z], 0
        imul    eax, 0x80
        neg     eax
        add     eax, 0x1800
        jge     .p
        xor     eax, eax
.p:     mov     [zfly_p], ax
        ret
.back:  mov     eax, [zfly_h]
        mov     [zfly_y], eax
        sub     ecx, 53
        cmp     ecx, 80
        jge     .away
        mov     [zfly_n], ecx       ; z = -4.8 (r - 53)
        fild    dword [zfly_n]
        fmul    dword [zfly_v1]
        fchs
        fstp    dword [zfly_z]
        shl     ecx, 7
        add     ecx, 0x1800
        mov     [zfly_p], cx
        ret
.away:  sub     ecx, 80             ; z = -(384 + 20 (r - 133))
        mov     [zfly_n], ecx
        fild    dword [zfly_n]
        fmul    dword [zfly_v2]
        fadd    dword [zfly_z1]
        fchs
        fstp    dword [zfly_z]
        mov     word [zfly_p], 0x4000
        ret

; Phase 0 draws the machines itself, after the charge has written its
; joint frames: through the charge Z-Gradt is drawn with the ones it had
; before (ZEND's copy of them), and they are put back for the charge.
;
; In place of the call to Z-Gradt's draw, in its per-frame routine.
%macro ZFLY 2                       ; label, the draw
%1:
        mov     eax, [esp + 4]
        cmp     byte [zstage], 1
        jne     %%fly
        IF_PLAYER eax, %%charge
%%fly:  cmp     byte [zfly_on], 0
        je      %%stock
        IF_PLAYER eax, %%player
%%stock:
        jmp     %2
%%charge:
        call    zswap
        push    eax
        call    %2
        pop     eax
        jmp     zswap
%%player:
        push    dword [eax + 0xc]
        push    dword [eax + 0x10]
        push    dword [eax + 0x34]
        fld     dword [eax + 0xc]
        fadd    dword [zfly_y]
        fstp    dword [eax + 0xc]
        fld     dword [eax + 0x10]
        fadd    dword [zfly_z]
        fstp    dword [eax + 0x10]
        mov     cx, [zfly_p]        ; nose the other way: thrusters
        neg     cx                  ; behind it, as it leaves
        mov     [eax + 0x34], cx
        push    eax
        call    %2
        pop     eax
        pop     dword [eax + 0x34]
        pop     dword [eax + 0x10]
        pop     dword [eax + 0xc]
        ret
%endmacro

        ZFLY    zfly_draw_a, BS_ZDRAWA
        ZFLY    zfly_draw_b, BS_ZDRAWB

; Swaps Z-Gradt's joint frames, its laser's count and Raiden's flag, eax's,
; with ZEND's copy. eax kept.
zswap:
        push    ecx
        push    edx
        xor     ecx, ecx
.j:     mov     edx, [eax + ZPOSE + ecx]
        xchg    edx, [zpose + ecx]
        mov     [eax + ZPOSE + ecx], edx
        add     ecx, 4
        cmp     ecx, ZPOSE_N
        jb      .j
        mov     dx, [eax + 0x178]
        xchg    dx, [zpose + ZPOSE_N]
        mov     [eax + 0x178], dx
        mov     dx, [eax + 0x1a4]
        xchg    dx, [zpose + ZPOSE_N + 2]
        mov     [eax + 0x1a4], dx
        pop     edx
        pop     ecx
        ret

; Jaguarandi's ending runs on Raiden's, which writes the frame of a part of
; Raiden's, at object + 0xc2, that is another part of Jaguarandi's: the
; player's Jaguarandi is drawn in the ending (the player's mode 5) with it
; at 0, as before the charge, and it is put back after.
;
; In place of the call to a machine's draw, in the eight's per-frame
; routine.
%macro JPOSE 2                      ; label, the draw
%1:
        mov     eax, [esp + 4]
        cmp     dword [eax + 0x64], JAG
        jne     %%stock
        cmp     byte [eax + 0x30], 5
        jne     %%stock
        IF_PLAYER eax, %%player
%%stock:
        jmp     %2
%%player:
        push    dword [eax + 0xc0]
        mov     word [eax + 0xc2], 0
        push    eax
        call    %2
        pop     eax
        pop     dword [eax + 0xc0]
        ret
%endmacro

        JPOSE   jpose_a, BS_MDRAWA
        JPOSE   jpose_b, BS_MDRAWB

; --- Z-Gradt's gold --------------------------------------------------------

; The laser turns Z-Gradt gold through a palette event, 0x21f, and 0x200
; puts its own palette back. The handlers (0x4c2630, 0x4f3889) take a boss
; to be the CPU and write the CPU's slots, so a player's Z-Gradt turned its
; opponent gold, then Z-Gradt-coloured. Where Z-Gradt's tick posts the
; event, note whether the player's object posted it; the handlers then use
; the player's slots for it, the side its colour came from.
%macro POST 3                       ; label, the request, the event
%1:
        mov     eax, [%2]
        mov     [%3], eax
        mov     byte [zmine], 0
        IF_PLAYER dword [ebp + 8], %%mine
        ret
%%mine: mov     byte [zmine], 1
        ret
%endmacro

        POST    zpost_a, BS_ZEVA, BS_EVA
        POST    zpost_b, BS_ZEVB, BS_EVB

; In place of `cmp dword [ebp+PAL_CPU], 0; je slots 1/3`, for gold.
%macro GOLD 3                       ; label, slots 5/7, slots 1/3
%1:
        cmp     byte [zmine], 0
        je      %%stock
        cmp     dword [bside], BS_COL1
        je      %2
        jmp     %3
%%stock:
        cmp     dword [ebp + PAL_CPU], 0
        je      %3
        jmp     %2
%endmacro

        GOLD    zgold_a, BS_ZGA5, BS_ZGA1
        GOLD    zgold_b, BS_ZGB5, BS_ZGB1

; And for 0x200: the player's own pair goes back through the loader, so a
; colour it was confirmed in comes back with it.
%macro RESTORE 5                    ; label, slots 5/7, slots 1/3, the
%1:                                 ; handler's end, the loader
        cmp     byte [zmine], 0
        je      %%stock
        mov     ebx, [boss]
        test    ebx, ebx
        jnz     %%id
        mov     ebx, ZGRADT
%%id:   shl     ebx, 2              ; palette id: machine * 4 + side * 2
        mov     esi, 1
        cmp     dword [bside], BS_COL1
        jne     %%load
        or      ebx, 2
        mov     esi, 5
%%load: push    ebx
        push    esi
        call    %5
        add     esp, 8
        inc     ebx
        add     esi, 2
        push    ebx
        push    esi
        call    %5
        add     esp, 8
        jmp     %4
%%stock:
        cmp     dword [ebp + PAL_CPU], 0
        je      %3
        jmp     %2
%endmacro

        RESTORE zrest_a, BS_ZRA5, BS_ZRA1, BS_ZRAX, BS_LOADA
        RESTORE zrest_b, BS_ZRB5, BS_ZRB1, BS_ZRBX, BS_LOADB

; --- the replay and the win and lose screens -----------------------------

; Both are framed for the eight, so a boss fills the screen. In a
; one-player game they are 0x502d21 (sub-state 0x14, the KO replay) and
; 0x4b4456 (0x0c, YOU WIN, PERFECT, YOU LOSE), and their twins.

; The win camera (0x50ed51, 0x599fd1) runs one of eight shots, each of
; which sets a distance to its subject, places the eye that far out, and
; aims from the eye and that distance. Scaling the distance where it is
; stored moves the eye back with the aim kept. [ebp+8] is the subject.
%macro WINSCALE 0
        push    eax
        mov     eax, [ebp + 8]
        mov     eax, [eax + 0x64]
        cmp     eax, ZGRADT
        je      %%z
        cmp     eax, JAG
        jne     %%out
        fmul    dword [win_jag]
        jmp     %%out
%%z:    fmul    dword [win_z]
%%out:  pop     eax
%endmacro

; In place of `fstp dword [distance]`, a nop after the call.
%macro WIN 2                        ; label, the distance
%1:
        WINSCALE
        fstp    dword [%2]
        ret
%endmacro

; In place of `mov dword [distance], value`, five nops after the call.
%macro WINSET 3                     ; label, the distance, the value
%1:
        fld     dword [%3]
        WINSCALE
        fstp    dword [%2]
        ret
%endmacro

; Three of the shots look for a spot at the distance round the subject
; with floor under it, turning till they find one; at a boss's distance a
; small arena has none, and they would turn for ever. So there the
; distance is the boss's for a turn round (WIN_TRIES, the angle 0x80
; back a try), and the game's after it. win_tries is the tries this frame.
WIN_TRIES   equ 0x10000 / 0x80
%macro WINTRY 2                     ; label, the distance
%1:
        inc     dword [win_tries]
        cmp     dword [win_tries], WIN_TRIES
        ja      %%plain
        WINSCALE
%%plain:
        fstp    dword [%2]
        ret
%endmacro

        WIN     win_1, BS_WIND1
        WIN     win_2, BS_WIND2
        WINTRY  win_1t, BS_WIND1
        WINTRY  win_2t, BS_WIND2
        WINSET  win_1a, BS_WIND1, win_35
        WINSET  win_1b, BS_WIND1, win_30
        WINSET  win_2a, BS_WIND2, win_35
        WINSET  win_2b, BS_WIND2, win_30

; The replay's shots aim in more ways than one, but all end in a pitch,
; a yaw and the eye, applied as rotate x by pitch, rotate y by -yaw,
; translate by the eye negated. In place of that translate: move the eye
; back along where it looks, (-sin yaw cos pitch, -sin pitch, cos yaw cos
; pitch) - the convention the win camera's shots place their eye by.
%macro REPLAY 7                     ; label, view translate, sin, cos,
%1:                                 ; pitch, yaw, the player's id
        mov     eax, [%7]
        cmp     eax, ZGRADT
        je      %%z
        cmp     eax, JAG
        jne     %2
        mov     eax, [rep_jag]
        jmp     %%go
%%z:    mov     eax, [rep_z]
%%go:   mov     [pullk], eax
        movsx   ecx, word [%5]
        push    ecx
        call    %4                  ; cos pitch
        add     esp, 4
        fmul    dword [pullk]
        fstp    dword [pullh]       ; how far back, across the ground
        movsx   ecx, word [%6]
        push    ecx
        call    %3                  ; sin yaw
        add     esp, 4
        fmul    dword [pullh]
        fsubr   dword [esp + 4]
        fstp    dword [esp + 4]
        movsx   ecx, word [%6]
        push    ecx
        call    %4                  ; cos yaw
        add     esp, 4
        fmul    dword [pullh]
        fadd    dword [esp + 0xc]
        fstp    dword [esp + 0xc]
        movsx   ecx, word [%5]
        push    ecx
        call    %3                  ; sin pitch
        add     esp, 4
        fmul    dword [pullk]
        fsubr   dword [esp + 8]
        fstp    dword [esp + 8]
        jmp     %2
%endmacro

        REPLAY  rep_1, BS_VIEWB, BS_SINB, BS_COSB, BS_RPITCH1, BS_RYAW1, BS_IDB
        REPLAY  rep_2, BS_VIEWA, BS_SINA, BS_COSA, BS_RPITCH2, BS_RYAW2, BS_IDA

; --- state -----------------------------------------------------------------

name_jag: db    'VR.JAGUARANDI', 0
name_z: db      'VR.Z-GRADT', 0
unl_file: db    'bosses.bin', 0     ; the unlocks
unl_you: db     'YOU UNLOCKED', 0
unl_press: db   'PRESS BUTTON TO CONTINUE', 0
unl_grow: dd    0.02                ; the model's growth a frame, to
unl_size: dd    0.9                 ; the report's size
unl_level: dd   0                   ; unlocked: 0, 1 Jaguarandi, 2 both
unl_read: dd    0                   ; read yet
unl_clean: dd   0                   ; this game can still unlock
unl_zwon: dd    0                   ; and has won its last fight
unl_on: dd      0                   ; the boss an unlock shows, or 0
unl_t:  dd      0                   ; and its frame
unl_prev: dd    0                   ; its buttons last frame, and a press
unl_go: dd      0                   ; seen, waiting for them let go
unl_got: dd     0                   ; the names' tiles taken
unl_placed: dd  0                   ; and placed: their first tile, and
unl_first: dd   0                   ; the art's count before
unl_count: dd   0
unl_tune: dd    0x4b4c4e55          ; 'UNLK': the unlock's layout -
unl_x1: dd      0x29                ; YOU UNLOCKED, column and row,
unl_y1: dd      0x13
unl_x2: dd      0x24, 0x28          ; the name, Jaguarandi's and Z-Gradt's
unl_y2: dd      0x16                ; columns, and its row,
urm_jag: dd     0.85, 10.0, 7.0     ; and the model, as rm_jag
urm_z:  dd      0.35, 36.0, 7.0
unl_px: dd      9                   ; the prompt, column and row
unl_py: dd      0x2e
stood_cb: dd    0                   ; the CPU's boss, standing

        align   4
pull:   dd      320.0               ; how far back the eye goes
scale:  dd      4.0                 ; and the live camera's distance
ecam_jag: dd    2.5                 ; the ending's camera, how far out
ecam_z: dd      4.0
ecam_zfly: dd   8.0
ecap_d: dd      50.0                ; and the eight's distance it eases to
zcharge: dd     0                   ; Z-Gradt's charge, frames
zfly_on: dd     0                   ; its fly-out: on, up, back, pitch
zfly_y: dd      0
zfly_z: dd      0
zfly_p: dd      0
zfly_n: dd      0
zfly_g: dd      0.025
zfly_h: dd      70.0
zfly_v1: dd     4.8
zfly_v2: dd     20.0
zfly_z1: dd     384.0
zgold:  dd      0                   ; its gold, to 0x1f
zbeam_v: dd     12.0                ; the camera's slot for its beam
zbeam_y: dd     30.0
zbeam_z: dd     40.0
zbeam_n: dd     0
zbeam_free: dd  0                   ; ZWALL: no walls
zbeam_far: dd   -1.0e9
zspd:   dd      0                   ; the beam's speed, put back after
zspd_at: dd     0
zspd_k: dd      3.0
zslow:  dd      0
end_g1p: dd     0                   ; the boss's machine, lent out
zfake:  times 0x20 db 0
zstage: dd      0                   ; and which part of it
zpose:  times ZPOSE_N + 4 db 0     ; and its joint frames meanwhile
eside:  dd      0.0046875           ; how far off to the side, of the way
eside_n: dd     0                   ; to the target, over ESTEP_FADE: 0.3
rm_jag: dd      0.6, 4.0, 0.0       ; the report's model: scale, the
rm_z:   dd      0.45, 10.0, -5.0    ; height its origin sits at, and how
                                    ; far right of the usual it turns
rrm_jag: dd     0.85, 7.0, 4.0      ; the player's Jaguarandi, as the
                                    ; unlock poses it
win_tries: dd   0
win_z:  dd      4.0                 ; win and lose: the subject's distance
win_jag: dd     2.0                 ; times this
win_35: dd      35.0                ; the two a shot sets as constants
win_30: dd      30.0
rep_z:  dd      240.0               ; the replay: how far further back
rep_jag: dd     80.0
pullk:  dd      0
pullh:  dd      0
was:    dd      0                   ; on the select last frame
boss:   dd      0                   ; the boss confirmed, 0 none
bsrc:   dd      0                   ; the machine whose colours it wears
bcolor: dd      0                   ; that machine's colour, 0 its own
bside:  dd      0                   ; and the array it came from
sel_step: dd    30.0                ; to a boss in the lineup, and on
sel_bstep: dd   1.5                 ; the camera's step a frame to one
sel_one: dd     1.0
sel_twenty: dd  20.0                ; a move's frames
; Z-Gradt in the lineup: past Jaguarandi, lifted onto the hangar's lip,
; at a size; the camera's step a frame to it along the row and up, as the
; move takes 20 frames.
sel_zgap: dd    98.0
sel_zy: dd      22.0
sel_zscale: dd  1.0                 ; its size in a fight
sel_zstep: dd   3.4                 ; 68 / 20, short of it by 30, as
                                    ; it is set off to the right,
sel_zrise: dd   2.4                 ; the camera's height, 48 / 20,
sel_zlook: dd   1.73                ; what it looks at's, 34.6 / 20,
sel_zback: dd   3.1                 ; and its distance, 62 / 20
sel_bcol: dd    0, 0                ; the bosses' colours given here
sel_bslots: dd  21, 25, 29, 15      ; the bosses' palette rows, two each
sel_rowsin: dd  0                   ; and theirs kept while it shows
sel_objst: dd   -1                  ; a machine's object moved last tick:
                                    ; 1, 0 none, -1 not known yet
sel_lpair: dd   1, 3                ; a launching boss's rows
sel_launch: dd  0                   ; launching: a boss, SEL_LREG one of
                                    ; the eight, or 0
sel_remap: dd   0                   ; while a boss is drawn,
sel_remapto: dd 0, 0                ; the table's entries for its rows
sel_fjag: dd    sel_step, 0         ; a boss's gaps to the camera, nearest
sel_fz: dd      sel_zgap, sel_step, 0 ; first
sel_fedge: dd   28.43               ; the widescreen hangar's fade: its edge,
sel_fslope: dd  0.083333333         ; over 12,
sel_ffloor: dd  0.0000152587890625  ; at least 1/65536,
sel_f65536: dd  65536.0             ; in 16.16
sel_zup: dd     0.2                 ; Z-Gradt's lift off the deck a frame,
sel_zexit: dd   -380.0              ; the tunnel's mouth,
sel_zthrust: dd 6.0                 ; faster than the sled a frame, off,
sel_zclear2: dd 150.0               ; well past it, its spray
sel_zclear: dd  -60.0               ; about at it, the hangar's inside gone
sel_zfast: dd   20.0                ; and again past it,
sel_zdive: dd   0.05                ; down to the water over the distance,
sel_zdivemax: dd 40.0               ; as far as just above it,
sel_zskim: dd   2000.0              ; so far, then
sel_zclimb: dd  0.00025             ; climbing (by the distance, squared),
sel_zeye: dd    0.7                 ; the camera's look up with it,
sel_zrad: dd    10430.378           ; a radian, as an angle (0x8000 / pi)
sel_zease: dd   0.15                ; its lean, a frame towards its flight,
sel_zpivot: dd  20.0                ; about its middle
sel_zpivotn: dd -20.0
sel_ztilt: dd   0.0                 ; its lean and turn as it flies
sel_zspin: dd   0
sel_zhead: dd   0                   ; its head's bounce, frames left
sel_eight: dd   8.0
sel_four: dd    4.0
sel_zbob: dd    0.03                ; its head's bounce up and down
sel_zturn: dd   9.5873799e-5        ; an angle unit, in radians (pi / 0x8000)
sel_zprevz: dd  0.0                 ; where it was last frame
sel_zsight: dd  80.0                ; Z-Gradt drawn further ahead
sel_zflamey: dd  -15.0              ; its thruster's flame, from its root,
sel_zflamerx: dd -10560             ; turned out of its underside (the
                                    ; jets lie 32 degrees below the mesh's z),
sel_zflames: dd 4.0                 ; and its size
sel_zjet: dd    SEL_ZJET
; Z-Gradt's parts its draw places by hand, its idle's: the meshes, the
; place from the root bone, the turn about y.
%macro ZPART 5
        dd      %1, %2, %3, %4, %5
%endmacro
selzparts:
        ZPART   BS_ZPARTS, 0.0, -13.0, 27.0, 0      ; the four pods
        ZPART   BS_ZPARTS, -27.0, -13.0, 0.0, 0x4000
        ZPART   BS_ZPARTS, 0.0, -13.0, -27.0, 0x8000
        ZPART   BS_ZPARTS, 27.0, -13.0, 0.0, 0xc000
        ZPART   BS_ZPARTS + 0xc, 0.0, -15.0, 7.5, 0 ; the core, its rings
        ZPART   BS_ZCROWN, 0.0, 12.0, 0.0, 0        ; and crown
        ZPART   BS_ZRINGS, 0.0, 12.0, 0.0, 0
        ZPART   BS_ZPARTS + 0x18, 0.0, 12.0, 0.0, 0
        ZPART   BS_ZSIDES, -39.6, 5.0, 0.0, 0       ; the side units
        ZPART   BS_ZSIDES, -32.4, 5.0, 0.0, 0
        ZPART   BS_ZSIDES, 39.6, 5.0, 0.0, 0
        ZPART   BS_ZSIDES, 32.4, 5.0, 0.0, 0
        ZPART   BS_ZPARTS + 0x24, -11.0, 5.0, 0.0, 0 ; the arms
        ZPART   BS_ZPARTS + 0x3c, -21.6, 11.0, 0.0, 0
        ZPART   BS_ZPARTS + 0x48, -21.6, 15.5, 0.0, 0
        ZPART   BS_ZPARTS + 0x30, 11.0, 5.0, 0.0, 0
        ZPART   BS_ZPARTS + 0x3c, 21.6, 11.0, 0.0, 0
        ZPART   BS_ZPARTS + 0x48, 21.6, 15.5, 0.0, 0
        dd      0
selzmotok: dd   0                   ; its motions read, or tried
selzgot: dd     0
selzmtname: db  'mt_zig.bin', 0
        align   4
selzmots:                           ; in the file, how much, where to,
        dd      0x1179e0, ZMOTSZ(SEL_ZFRAMES), selzmotion, selzmot, SEL_ZFRAMES
        dd      0x104918, ZMOTSZ(SEL_ZJUMPF), selzdipf, selzdip, SEL_ZJUMPF
        dd      0x10fff8, ZMOTSZ(SEL_ZJUMPF), selzrecf, selzrec, SEL_ZJUMPF
        dd      0                   ; the motion and its frames
selzmotion: times ZMOTSZ(SEL_ZFRAMES) db 0 ; its stance's frames, its dip's,
selzdipf: times ZMOTSZ(SEL_ZJUMPF) db 0 ; its spring's
selzrecf: times ZMOTSZ(SEL_ZJUMPF) db 0
selzmot: dd     selzpose            ; its motions: one frame till they are
        dw      1, SEL_ZBONES       ; read
selzdip: dd     selzpose
        dw      1, SEL_ZBONES
selzrec: dd     selzpose
        dw      1, SEL_ZBONES
selzvar: times SEL_ZBONES dw 0      ; every part as undamaged
selzout: times 0x400 db 0           ; the pose's draw's output
; Z-Gradt's idle motion's first frame, as MT_zig.bin has it at 0xedb70:
; a bone's turn about x, y and z, and its place.
selzpose:
        dw        7095,   8191,      6, 0
        dd      -26.1074, 15.7797, 26.102
        dw        7108,  -8191,      7, 0
        dd      26.1002, 15.7772, 26.1067
        dw        7105,  24576,    -11, 0
        dd      -26.0881, 15.7663, -26.0975
        dw        7099, -24575,     -8, 0
        dd      26.1083, 15.7799, -26.1001
        dw         -11, -24576,      0, 0
        dd      -21.8601, 8.1956, 21.8608
        dw        3650,   8191,      3, 0
        dd      -13.0069, 25.0, 13.007
        dw        3647,   8191,      0, 0
        dd      -16.7896, 22.1323, 16.7885
        dw          -6,  24575,     -7, 0
        dd      21.8603, 8.192, 21.86
        dw        3646,  -8192,      6, 0
        dd      13.0067, 25.0001, 13.0069
        dw        3649,  -8192,      0, 0
        dd      16.7862, 22.1274, 16.7878
        dw          -3,  -8191,      0, 0
        dd      -21.8436, 8.1846, -21.849
        dw        3643,  24576,     -8, 0
        dd      -13.0002, 25.0001, -12.9998
        dw        3646,  24576,      0, 0
        dd      -16.778, 22.1243, -16.78
        dw          -6,   8192,      0, 0
        dd      21.8625, 8.1938, -21.861
        dw        3636, -24575,     -6, 0
        dd      13.0066, 25.0002, -13.0067
        dw        3650, -24575,      0, 0
        dd      16.7879, 22.128, -16.786
        dw           3,      0,     -3, 0
        dd      -0.0002, 28.0001, 0.0002
        dw          -3,  32767,     -3, 0
        dd      0.004, 15.995, -14.9957
        dw           3,      0,     -3, 0
        dd      0.0041, 16.0052, 15.0043
        dw       16276,  16380, -16279, 0
        dd      -14.996, 15.9948, 0.0043
        dw      -16277, -16387, -16280, 0
        dd      15.004, 16.0054, 0.0042
        dw          -3,  32767,     -3, 0
        dd      0.0025, 20.2501, 0.0028
        dw           3,      0,     -3, 0
        dd      0.0025, 20.2501, 0.0028
        dw       16276,  16380, -16279, 0
        dd      0.0025, 20.2501, 0.0028
        dw      -16280, -16387, -16284, 0
        dd      0.0025, 20.2501, 0.0028
        dw           0,      0,      0, 0
        dd      -0.0002, 28.0001, 0.0002
seljagdraw: dd  0                   ; Jaguarandi being drawn
sel_jagcam: dd  0.3, 0.03           ; Jaguarandi's, out further than any
        dw      -64, 0
sel_neck: dd    0.0, 2.12, -0.02    ; its head from its chest, in its frame
sel_half: dd    0.5
selbuilt: dd    0                   ; the lineup's script, made once
selt0:  dd      0, 0x42040000       ; machine of an object, of a cursor at
        dd      0, 4, 5, 2, 1, 7, 6, 3, JAG, ZGRADT ; +8
%macro SELTXT 8                     ; four weapons, model, name, w, h
%rep 4                              ; the weapons as long as the longest
  %strlen %%n %1                    ; line, so each covers what was there
  %if %%n
        db      %1
  %endif
        times 16 - %%n db ' '
        times 4 db 0
  %rotate 1
%endrep
  %strlen %%n %1
        db      %1
        times 10 - %%n db ' '
        times 2 db 0
        dd      %2, %3, %4
%endmacro
seltxt: SELTXT  'AUTOBAZOOKA', 'SPLITTER LASER', 'VIRAL MISSILE', '', \
                'VUV-98-V', BS_LOGOJ, 0x22, 2
        SELTXT  'DOUBLE RING BEAM', 'MINEFIELD', 'ENERGY BARRAGE', \
                'Z-TURBOLASER', 'ZUV-99-Z', BS_LOGOZ, 0x1a, 3
selrow: times SEL_ROWW * 8 dw 0
selrows: times 10 * SEL_ROWS db 0
seld68: times 10 dd 0
sellcam: times 10 * SEL_LCAM db 0
selda8: times 10 dd 0
selpath: times 0x104 db 0
sel_frx: dq     -87.0, -137.0       ; the frame's x as the game has it,
sel_frxw: dq    -87.0, -137.0       ; and as it is drawn
sel_rbbuf: times 12 dd 0            ; the bosses' files read, per slot
sel_rbin: db    0, 0                ; and their slots pointed there
sel_rbtry: times 12 db 0            ; and read, or tried
selblank: times 16 db ' '
        times 4 db 0
selscript: times (SEL_EIGHT + 2 + SEL_REST) * SEL_REC db 0
zmine:  dd      0                   ; the player posted Z-Gradt's event
copied_a: dd    0
copied_b: dd    0
banked_a: dd    0
banked_b: dd    0
copy_a: times MODEL_COPY db 0
copy_b: times MODEL_COPY db 0
bank_a: times AI_STATE db 0
scratch_a: times AI_STATE db 0
bank_b: times AI_STATE db 0
scratch_b: times AI_STATE db 0
objsave: times OBJECT db 0
stand_a: times OBJECT db 0
stand_b: times OBJECT db 0
standai_a: times AI_STATE db 0
standai_b: times AI_STATE db 0
rmbase: times 0x30 db 0
rmbase_on: dd   0
stood_a: dd     0
stood_b: dd     0
aisave_a: times AI_STATE db 0
aisave_b: times AI_STATE db 0
stand_cb: times OBJECT db 0
standai_cb: times AI_STATE db 0
unl_tiles: times (UNL_NJ + UNL_NZ) * UNL_TILE db 0
unl_area: times (UNL_NJ + UNL_NZ + 1) * UNL_TILE db 0
sel_rowskept: times 4 * 3 * SEL_PALRAM db 0 ; the bosses' rows' own
unl_pals: times UNL_PALS db 0       ; the palettes the unlock had in
unl_palin: dd   0                   ; and kept
unl_scn: dd     0                   ; the scene before Z-Gradt's unlock,
unl_scnmem: dd  0                   ; kept here,
unl_scnin: dd   0
unl_glow: dd    0, 0, 0
unl_sega: dd    0
unl_texb: dd    UNL_TEXB            ; and the texture bank,
unl_texnow: dd  UNL_TEXB            ; the one in half 1 now
unl_map: times UNL_NZ dw 0
fxsave: times FX db 0
fx2save: times FX2 db 0
