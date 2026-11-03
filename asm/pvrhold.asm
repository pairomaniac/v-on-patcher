bits 32
; The PowerVR build's call for HOLD TO SKIP to make first. overlay.asm makes a
; displaced call before it draws, and retail's has no counterpart here: 0x498178
; runs only behind a toggle. The hook there is the store of the time at
; 0x498186, after the frame is drawn and ahead of the flip at 0x4981a9, so this
; is that store. Nothing before it changes eax.

extern FLIPTIME                 ; where the displaced store writes

store:
    mov     [FLIPTIME], eax
    ret
