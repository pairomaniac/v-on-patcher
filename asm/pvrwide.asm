bits 32
; Native widescreen on the PowerVR build, 1024x576: what it needs on top of asm/ui.asm,
; which runs here as it does on the other builds. The patcher writes FRAMEFN
; at apply time, since that section is appended last.

extern FSFLAGS                  ; bit 0: Screen=Normal, bit 1: split layout,
                                ; bit 2: low resolution
extern SPLITTYPE                ; the F5 Screen Split radio, Ver 0, Hor 1
extern PLANEB                   ; byte holding the 2D plane's hide bit, 0x80
extern PRE2D                    ; the first of the frame's 2D calls
extern SCENE                    ; the SGL context
extern SCENEFLAGS               ; its flags
extern PIXFMT                   ; the surface's pixel format
extern SURFBASE                 ; the locked surface
extern SURFPITCH                ; and its pitch
extern RENDERING                ; nonzero while a render is owed
extern WAITRENDER               ; waits for it
extern CENTREAX                 ; each renderer's view centre
extern CENTREAY
extern CENTREBX
extern CENTREBY
extern SURF1                    ; 2D surface pointer, first engine
extern SURF2                    ; and second
extern VIEWW                    ; the viewport's width, and the canvas's while
                                ; the 2D code runs
extern VIEWH                    ; and height
extern ORGX2                    ; the second viewport's origin, which this
extern ORGY2                    ; build adds before a record reaches the hook

DISABLEDITHERING equ 0x800000
FORMAT565   equ 0x235               ; PIXFMT with a 565 surface
FRAMEW      equ 1024
FRAMEH      equ 576

; In place of the frame's call to the viewport setup. This build has one
; picture size and no Screen=Normal, and its split radios choose the layout.
frame:
    and     dword [FSFLAGS], 0
    cmp     dword [SPLITTYPE], 0
    je      .go
    or      dword [FSFLAGS], 2
.go:
    push    dword [esp+4]
    call    [framefn]
    add     esp, 4
    ; ui.asm takes the view's centres as the setup left them, at its first 2D
    ; call. Here a frame's HUD passes come between, and put back what it took
    ; last time, so it keeps them for that call.
    mov     eax, [CENTREAX]
    mov     [centres], eax
    mov     eax, [CENTREAY]
    mov     [centres+4], eax
    mov     eax, [CENTREBX]
    mov     [centres+8], eax
    mov     eax, [CENTREBY]
    mov     [centres+12], eax
    ; Its HUD passes restore the viewport's size from ui.asm's copy, which here
    ; would be last frame's until its next 2D call, and then be taken again.
    mov     ecx, [uisize]
    mov     eax, [VIEWW]
    mov     [ecx], eax
    mov     eax, [VIEWH]
    mov     [ecx+4], eax
    xor     eax, eax
    ret

; In place of the pushes of the scene's context for its render. The
; card's dither lifts near-black to a visible checkerboard, where the other builds'
; rasterizers, which do not dither, truncate it to black.
nodither:
    or      dword [SCENEFLAGS], DISABLEDITHERING
    pop     eax
    push    SCENE
    jmp     eax

; In place of the frame's wait for the card: whether it rendered this frame. If it
; did, the one step of green that 565 keeps of a near-black texel goes. The other
; builds' rasterizers bring those to true black, and against it the step shows as
; a seam, around the moon card on the star field in the ending.
waitcard:
    mov     eax, [RENDERING]
    mov     [rendered], eax
    call    WAITRENDER
    cmp     dword [rendered], 0
    je      .out
    cmp     dword [PIXFMT], FORMAT565
    jne     .out
    mov     edx, [SURFBASE]
    test    edx, edx
    je      .out
    push    edi
    push    ebx
    mov     ebx, FRAMEH
.row:
    mov     edi, edx
    mov     ecx, FRAMEW
.px:
    cmp     word [edi], 0x0020
    jne     .next
    mov     word [edi], 0
.next:
    add     edi, 2
    dec     ecx
    jne     .px
    add     edx, [SURFPITCH]
    dec     ebx
    jne     .row
    pop     ebx
    pop     edi
.out:
    ret

; A frame the card did not render, the 2D layer alone draws. Its composite leaves
; alone whatever matches what it sampled, and away from a scale of 1 it does not
; sample every pixel, so what the last screen left on the surface would show
; through in those. The other builds' rasterizers redraw the frame every time.
clearsurface:
    cmp     dword [rendered], 0
    jne     .out
    mov     edx, [SURFBASE]
    test    edx, edx
    je      .out
    push    edi
    push    ebx
    mov     ebx, [VIEWH]
    xor     eax, eax
.row:
    mov     edi, edx
    mov     ecx, [VIEWW]
    shr     ecx, 1
    rep stosd
    add     edx, [SURFPITCH]
    dec     ebx
    jne     .row
    pop     ebx
    pop     edi
.out:
    ret

; In place of the frame's first 2D call. ui.asm's margins ask whether 3D is
; behind the 2D layer; here the plane that covers it says.
drawn3d:
    call    clearsurface
    xor     eax, eax
    test    byte [PLANEB], 0x80
    setne   al
    mov     [drawn], eax
    mov     eax, [centres]
    test    eax, eax
    je      .go                 ; none yet
    mov     [CENTREAX], eax
    mov     eax, [centres+4]
    mov     [CENTREAY], eax
    mov     eax, [centres+8]
    mov     [CENTREBX], eax
    mov     eax, [centres+12]
    mov     [CENTREBY], eax
.go:
    jmp     PRE2D

; The backdrop's fill, in each engine: from the canvas's left edge. The surface
; pointer is at the 640-wide picture; the other builds draw the 3D over what
; the fill leaves of the left margin, and this one has drawn it already.
fill1:
    mov     ebx, [SURF1]
    jmp     fillfrom
fill2:
    mov     ebx, [SURF2]
fillfrom:
    mov     eax, [VIEWW]
    sub     eax, 640
    sub     ebx, eax
    ret

; The second renderer's record inserts. ui.asm's hook takes vertices relative
; to the viewport, so the origin comes off for it and goes back on after.
insert2:
    call    origin_off
    call    [insertfn]
    ; esi holds what the hook loaded
origin_on:
    push    eax
    push    ecx
    mov     eax, [ORGX2]
    mov     ecx, [ORGY2]
    add     [edx+0x10], ax
    add     [edx+0x12], cx
    add     [edx+0x14], ax
    add     [edx+0x16], cx
    add     [edx+0x18], ax
    add     [edx+0x1a], cx
    add     [edx+0x1c], ax
    add     [edx+0x1e], cx
    pop     ecx
    pop     eax
    ret
origin_off:
    push    eax
    push    ecx
    mov     eax, [ORGX2]
    mov     ecx, [ORGY2]
    sub     [edx+0x10], ax
    sub     [edx+0x12], cx
    sub     [edx+0x14], ax
    sub     [edx+0x16], cx
    sub     [edx+0x18], ax
    sub     [edx+0x1a], cx
    sub     [edx+0x1c], ax
    sub     [edx+0x1e], cx
    pop     ecx
    pop     eax
    ret

centres:    dd 0, 0, 0, 0
rendered:   dd 0
framefn:    dd 0
uisize:     dd 0
insertfn:   dd 0
drawn:      dd 0
