bits 32
; The PowerVR build's half of HOLD TO SKIP. overlay.asm starts by making the call
; its hook replaced. Retail's call has no match here that runs every frame:
; 0x498178 runs only behind a toggle. So the hook replaces the store of the time
; at 0x498186, after the frame is drawn and ahead of the flip at 0x4981a9. This
; routine does that store. overlay.asm has not changed eax when it calls this.

extern FLIPTIME                 ; where the displaced store writes

store:
    mov     [FLIPTIME], eax
    ret
