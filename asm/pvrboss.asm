bits 32
; Playable bosses on the PowerVR build: what it needs on top of asm/bosses.asm.
;
; The card's loader lists the machines the select draws and reads each one's select
; file, which the bosses do not have. So a boss stays off that list. asm/bosses.asm
; reads its fight model into a block of its own, as on the other builds, and the
; game's texture routine, which the other machines go through as they load, is run
; on that block here. Without it the model draws flat.

extern PVR_SELDRAW              ; the select's draw of a machine, past its prologue
extern PVR_TEXLOAD              ; (1, machine, the other's, 0): a model's textures
extern PVR_TEXFREE              ; (1, machine): and let go of them
extern PVR_LOADER               ; the loader (list, count, mode), past its prologue
extern PVR_FREEALL              ; what frees every model's textures, past its prologue
extern BOSSID                   ; asm/bosses.asm: the boss the player took
extern SELCURSOR                ; 1P's cursor on the select
extern BS_FREE
extern PVR_FCLOSE               ; the C library's
extern BS_SLOTJ                 ; a boss's slot
extern BS_SLOTZ
extern RBLOAD                   ; asm/bosses.asm's read of a boss's file
extern RBLOADEND                ; and what follows it
extern RBTRY                    ; asm/bosses.asm's reads: tried, per file slot
extern RBBUF                    ; and the block
TEXSLOT1    equ 0x00824d6c      ; the texture routine's two places
TEXSLOT2    equ 0x00824d70
RB_JAG      equ 5               ; its file slots
RB_Z        equ 9
RAIDEN      equ 3
JAG         equ 8
ZGRADT      equ 9

; bosses.asm starts the select's draw with the other builds' frame and carries on
; six bytes in. This build's frame is 0x34 bigger, and carries on here.
selmdl:
    times 6 nop
    sub     esp, 0x34
    jmp     PVR_SELDRAW

; bosses.asm's fclose. When it closes a boss's file, read whole, its block goes
; through the texture routine, with the slot on the block for it. esi the block,
; ebp the file slot, and on the stack the file and what the read returned.
fclose:
    cmp     dword [esp], RBLOAD ; called from its read of a boss's file?
    jb      PVR_FCLOSE
    cmp     dword [esp], RBLOADEND
    jae     PVR_FCLOSE
    cmp     dword [esp+8], 1
    jne     PVR_FCLOSE
    pushad
    mov     ecx, [TEXSLOT1]     ; the routine has two places for a fight's models,
    call    vacate              ; and the attract demo leaves its two in them
    mov     ecx, [TEXSLOT2]
    call    vacate
    mov     eax, JAG
    mov     edi, BS_SLOTJ
    cmp     ebp, RB_JAG
    je      .boss
    mov     eax, ZGRADT
    mov     edi, BS_SLOTZ
.boss:
    mov     byte [ready+eax-JAG], 1
    push    dword [edi]
    mov     [edi], esi
    push    0
    push    JAG                 ; its own textures, as ownside
    push    eax
    push    1
    call    PVR_TEXLOAD
    add     esp, 16
    pop     dword [edi]
    popad
    jmp     PVR_FCLOSE

; ecx the machine in a place, or -1. One of the eight goes.
vacate:
    cmp     ecx, JAG
    jae     .out                ; a boss, or -1 unsigned
    push    ecx
    push    1
    call    PVR_TEXFREE
    add     esp, 8
.out:
    ret

; In place of the loader's prologue. Mode 1 is the select's: a boss comes off its
; list, and Raiden goes on it for Z-Gradt, whose launch's flames are in its file. Any
; other mode is a fight's, and the select is over: its
; boss's textures and block go, to be made again on the next select.
loader:
    cmp     dword [esp+12], 1
    jne     .over
    pushad
    mov     esi, [esp+32+4]     ; the list
    mov     ecx, [esp+32+8]     ; its count
    mov     edi, esi
    xor     edx, edx
    or      ebx, -1             ; Raiden, once Z-Gradt is under the cursor or taken
    mov     eax, [BOSSID]
    test    eax, eax
    jne     .which
    mov     eax, [SELCURSOR]
.which:
    cmp     eax, ZGRADT
    jne     .each
    mov     ebx, RAIDEN
.each:
    test    ecx, ecx
    je      .end
    dec     ecx
    lodsd
    cmp     eax, JAG
    je      .each
    cmp     eax, ZGRADT
    je      .each
    cmp     eax, ebx
    jne     .keep
    or      ebx, -1             ; on it already
.keep:
    stosd
    inc     edx
    jmp     .each
.end:
    cmp     ebx, -1
    je      .count
    mov     eax, ebx
    stosd
    inc     edx
.count:
    mov     [esp+32+8], edx
    popad
    jmp     .go
.over:
    pushad
    call    dropall
    popad
.go:
    push    ebp
    mov     ebp, esp
    sub     esp, 0x124
    jmp     PVR_LOADER

; In place of the prologue of what lets go of every model's textures, as the game
; resets. A boss's block names them, so it goes too.
freeall:
    pushad
    call    dropall
    popad
    push    ebp
    mov     ebp, esp
    sub     esp, 4
    jmp     PVR_FREEALL

; In place of the load of the other machine, which picks Jaguarandi's textures: it
; has a set for each. The player's wears its own.
ownside:
    mov     eax, [ebp-0x120]
    cmp     dword [BOSSID], JAG
    jne     .out
    mov     eax, JAG
.out:
    ret

dropall:
    mov     eax, JAG
    mov     ebx, RB_JAG
    call    drop
    mov     eax, ZGRADT
    mov     ebx, RB_Z
    ; fall through

; eax the boss, ebx its file slot.
drop:
    cmp     byte [ready+eax-JAG], 0
    je      .out
    mov     byte [ready+eax-JAG], 0
    push    eax
    push    1
    call    PVR_TEXFREE
    add     esp, 8
    mov     byte [RBTRY+ebx], 0
    mov     ecx, [RBBUF+ebx*4]
    mov     dword [RBBUF+ebx*4], 0
    test    ecx, ecx
    je      .out
    push    ecx
    call    BS_FREE
    add     esp, 4
.out:
    ret

ready:  db 0, 0

; asm/bosses.asm's table of the fight models' files, by the slots its names have on
; the other builds: name, size. Here the game's own goes by machine id.
rbnames:
    times 5 dd 0, 0
    dd      0x00825360, 0xd838
    times 3 dd 0, 0
    dd      0x00825354, 0x65fa4

; asm/bosses.asm's table of a machine's booster flames, a frame's three meshes. Here
; a frame has a fourth, for the other mode, so Raiden's are given in its shape.
flames:
    times 3 dd 0
    dd      flames3
flames3:
    dd      0x40001358, 0x400015e8, 0x4000fd94
    dd      0x400010b8, 0x40001348, 0x4000f6c0
    dd      0x40000e18, 0x400010a8, 0x4000efec
    dd      0x40000b78, 0x40000e08, 0x4000e918
