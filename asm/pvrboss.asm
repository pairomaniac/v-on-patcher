bits 32
; Playable bosses on the PowerVR build: what it needs on top of asm/bosses.asm.
; Its select lists a machine for the card's texture loader, where the other
; builds' loads the file, so that draw does not run for a boss yet.

extern BS_MODEA                 ; A's mode, which the displaced compare reads
extern PVR_SELDRAWEND           ; the select's draw of a machine: its exit

; In place of the compare after the draw's prologue. A boss is not drawn.
selskip:
    cmp     dword [ebp+8], 8
    jae     .boss
    cmp     dword [BS_MODEA], 0
    ret
.boss:
    add     esp, 4
    jmp     PVR_SELDRAWEND
