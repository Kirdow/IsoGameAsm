default rel
bits 64

section .data
    str_logn db 'Number: %llx', 0xd, 0xa, 0
    str_logn2 db 'Number: %lld', 0xd, 0xa, 0
    str_logs db 'String: %s', 0xd, 0xa, 0
    str_logdata db 'Data:', 0xd, 0xa, 0

section .text
    extern printf
    extern malloc
    extern bmp_get
    extern col_darken
    
    global gfx_fill
    global gfx_rect
    global gfx_bmp
    global gfx_floor_tile
    global gfx_floor
    global gfx_wall_tile
    global gfx_wall

; void gfx_fill(wnd* window, int color);
gfx_fill:
    push rbp,
    mov rbp, rsp
    sub rsp, 80

    mov qword [rbp-32], rbx ; backup rbx
    mov qword [rbp-8], rdx  ; color

    mov rbx, rcx
    mov rax, [rbx+8]
    mov rdx, [rbx+16]
    mul rdx
    mov qword [rbp-16], rax ; length
    mov rax, [rbx+0]
    mov qword [rbp-24], rax ; pixels

    mov rcx, 0
.for_i_start:
    mov rax, qword [rbp-16]
    cmp rcx, rax
    jge .for_i_end

    mov rbx, qword [rbp-24] ; pixels
    mov rax, rcx ; index
    mov rdx, qword [rbp-8] ; color
    mov dword [rbx+rax*4], edx

    inc rcx
    jmp .for_i_start
.for_i_end:

    mov rbx, qword [rbp-32] ; restore rbx
    xor rax, rax

    mov rsp, rbp
    pop rbp
    ret

; void gfx_rect(wnd* window, int x, int y, int w, int h, int color);
gfx_rect:
    push rbp
    mov rbp, rsp
    sub rsp, 160

    ; local variables
    ; color             -8
    ; window            -16
    ; x                 -24
    ; y                 -32
    ; w                 -40
    ; h                 -48
    ; yy                -56
    ; xx                -64
    ; yo                -72
    ; xo                -80
    ; pixels            -88
    ; width             -96
    ; height            -104
    ; rbx               -112

    ; backup rbx
    mov qword [rbp-112], rbx

    ; copy arguments to locals
    mov qword [rbp-16], rcx ; window local = window argument
    mov qword [rbp-24], rdx ; x local = x argument
    mov qword [rbp-32], r8 ; y local = y argument
    mov qword [rbp-40], r9 ; w local = w argument

    ; copy stack arguments to locals
    mov rax, qword [rbp+48] ; h argument
    mov qword [rbp-48], rax ; h local
    mov rax, qword [rbp+56] ; color argument
    mov qword [rbp-8], rax ; color local

    ; copy window properties to locals
    mov rbx, qword [rbp-16]
    mov rax, [rbx+0] ; window->pixels
    mov qword [rbp-88], rax
    mov rax, [rbx+8] ; window->width
    mov qword [rbp-96], rax
    mov rax, [rbx+16] ; window->height
    mov qword [rbp-104], rax

    mov qword [rbp-56], 0   ; yy
    jmp .for_yy_start
.for_yy_cont:
    mov rcx, qword [rbp-56] ; yy
    inc rcx
    mov qword [rbp-56], rcx ; yy
.for_yy_start:
    mov rcx, qword [rbp-56] ; yy
    mov rax, qword [rbp-48] ; h
    cmp rcx, rax
    jge .for_yy_end
    mov rax, qword [rbp-32] ; y
    add rax, rcx
    cmp rax, 0
    jl .for_yy_cont
    mov rcx, qword [rbp-104] ; height
    cmp rax, rcx
    jge .for_yy_cont
    mov qword [rbp-72], rax ; yo

    mov qword [rbp-64], 0 ; xx
    jmp .for_xx_start
.for_xx_cont:
    mov rcx, qword [rbp-64] ; xx
    inc rcx
    mov qword [rbp-64], rcx ; xx
.for_xx_start:
    mov rcx, qword [rbp-64] ; xx
    mov rax, qword [rbp-40] ; w
    cmp rcx, rax
    jge .for_xx_end
    mov rax, qword [rbp-24] ; x
    add rax, rcx
    cmp rax, 0
    jl .for_xx_cont
    mov rcx, qword [rbp-96] ; width
    cmp rax, rcx
    jge .for_xx_cont
    mov qword [rbp-80], rax ; xo

    mov qword [rbp-128], rax            ; xo
    mov rcx, qword [rbp-72] ; rcx = yo
    mov rax, qword [rbp-96] ; rax = width
    mul rcx                 ; rax = yo * width
    mov rdx, qword [rbp-128]
    add rax, rdx            ; rax += xo ; (xo + yo * width)
                            ; rax = index
    mov rbx, qword [rbp-88] ; rbx = pixels
    mov rcx, qword [rbp-8] ; rcx = color
    mov dword [rbx+rax*4], ecx ; pixels[index] = color

    jmp .for_xx_cont
.for_xx_end:
    jmp .for_yy_cont
.for_yy_end:
    xor rax, rax
    
    mov rsp, rbp
    pop rbp
    ret

; void gfx_bmp(wnd* window, int x, int y, int bmpId);
gfx_bmp:
    push rbp
    mov rbp, rsp
    sub rsp, 144

    ; local variables
    ; rbx               -8
    ; window            -16
    ; x                 -24
    ; y                 -32
    ; bmp               -40
    ; w                 -48
    ; h                 -56
    ; pixels            -64
    ; wpixels           -72
    ; wwidth            -80
    ; wheight           -88
    ; xx                -96
    ; yy                -104
    ; xo                -112
    ; yo                -120


    ; backup rbx
    mov qword [rbp-8], rbx

    ; copy arguments to locals
    mov qword [rbp-16], rcx     ; window
    mov qword [rbp-24], rdx     ; x
    mov qword [rbp-32], r8      ; y

    ; get bitmap
    mov rcx, r9
    call bmp_get
    mov qword [rbp-40], rax     ; bmp*

    ; get bitmap values
    mov rbx, rax                ; bmp*
    mov rax, qword [rbx+8]      ; bmp->width
    mov qword [rbp-48], rax     ; w
    mov rax, qword [rbx+16]      ; bmp->height
    mov qword [rbp-56], rax     ; h
    mov rax, qword [rbx+0]      ; bmp->pixels
    mov qword [rbp-64], rax     ; pixels

    ; get window values
    mov rbx, qword [rbp-16]
    mov rax, qword [rbx+0]      ; wnd->pixels
    mov qword [rbp-72], rax     ; wpixels
    mov rax, qword [rbx+8]      ; wnd->width
    mov qword [rbp-80], rax     ; wwidth
    mov rax, qword [rbx+16]     ; wnd->height
    mov qword [rbp-88], rax     ; wheight

    ; for y in 0..8:
    mov qword [rbp-104], 0      ; yy
    jmp .for_yy_start
.for_yy_cont:
    mov rcx, qword [rbp-104]    ; yy
    inc rcx
    mov qword [rbp-104], rcx    ; yy
.for_yy_start:
    mov rcx, qword [rbp-104]    ; yy
    mov rax, qword [rbp-56]     ; h
    cmp rcx, rax
    jge .for_yy_end
    mov rax, qword [rbp-32]      ; y
    add rax, rcx
    cmp rax, 0
    jl .for_yy_cont
    mov rcx, qword [rbp-88]     ; wheight
    cmp rax, rcx
    jge .for_yy_cont
    mov qword [rbp-120], rax    ; yo

    mov qword [rbp-96], 0       ; xx
    jmp .for_xx_start
.for_xx_cont:
    mov rcx, qword [rbp-96]     ; xx
    inc rcx
    mov qword [rbp-96], rcx     ; xx
.for_xx_start:
    mov rcx, qword [rbp-96]     ; xx
    mov rax, qword [rbp-48]     ; w
    cmp rcx, rax
    jge .for_xx_end
    mov rax, qword [rbp-24]     ; x
    add rax, rcx
    cmp rax, 0
    jl .for_xx_cont
    mov rcx, qword [rbp-80]     ; wwidth
    cmp rax, rcx
    jge .for_xx_cont
    mov qword [rbp-112], rax    ; xo

    mov qword [rbp-128], rax    ; xo
    mov rcx, qword [rbp-120]    ; yo
    mov rax, qword [rbp-80]     ; wwidth
    mul rcx                     ; rax = yo * wwidth
    mov rdx, qword [rbp-128]
    add rax, rdx                ; rax += xo ; (xo + yo * wwidth)
                                ; rax = index
    mov qword [rbp-128], rax    ; index
    mov rcx, qword [rbp-104]    ; yy
    mov rax, qword [rbp-48]     ; w
    mul rcx                     ; rx = yy * w
    mov rdx, qword [rbp-96]     ; xx
    add rax, rdx                ; rax += xx ; (xx + yy * w)
    mov qword [rbp-136], rax    ; index_bmp

    mov rbx, qword [rbp-64]     ; pixels
    xor rdx, rdx
    mov edx, dword [rbx+rax*4]  ; rdx = pixels[index_bmp]

    mov rbx, qword [rbp-72]     ; wpixels
    mov rax, qword [rbp-128]    ; index
    mov dword [rbx+rax*4], edx

    jmp .for_xx_cont
.for_xx_end:
    jmp .for_yy_cont
.for_yy_end:
    xor rax, rax

    mov rbx, qword [rbp-8]

    mov rsp, rbp
    pop rbp
    ret

; void gfx_floor_tile(wnd* window, int x, int y, int z, int bmpId);
gfx_floor_tile:
    push rbp
    mov rbp, rsp
    sub rsp, 96

    ; local variables
    ; rbx               -8
    ; window            -16
    ; x                 -24
    ; y                 -32
    ; z                 -40
    ; bmpId             -48
    ; tmp               -56
    ; wx                -64
    ; wy                -72

    ; backup rbx
    mov qword [rbp-8], rbx

    ; copy parameters
    mov qword [rbp-16], rcx     ; window
    mov qword [rbp-24], rdx     ; x
    mov qword [rbp-32], r8     ; y
    mov qword [rbp-40], r9      ; z
    mov rax, qword [rbp+40]     ; bmpId
    mov qword [rbp-48], rax          ; 

    mov rax, rdx
    sub rax, r9
    mov qword [rbp-24], rax

    mov rax, r8
    sub rax, r9
    mov qword [rbp-32], rax

    mov rax, qword [rbp-24]
    sub rax, qword [rbp-32]
    ; TODO: Do not hard-core 16 (which is zoom / 2)
    mov rcx, 16
    mul rcx
    mov qword [rbp-56], rax

    mov rbx, qword [rbp-16]
    mov rax, [rbx+8]
    shr rax, 1
    add rax, qword [rbp-56]
    mov rcx, 0x7FFFFFFFFFFFFFFF
    and rax, rcx
    mov qword [rbp-64], rax

    mov rax, qword [rbp-24]
    add rax, qword [rbp-32]
    ; TODO: Do not hard-core 8 (which is zoom / 4)
    mov rcx, 8
    mul rcx
    mov qword [rbp-56], rax

    mov rbx, qword [rbp-16]
    mov rax, [rbx+16]
    shr rax, 1
    add rax, qword [rbp-56]
    mov rcx, 0x7FFFFFFFFFFFFFFF
    and rax, rcx
    mov qword [rbp-72], rax

    mov rcx, qword [rbp-16]
    mov rdx, qword [rbp-64]
    mov r8, qword [rbp-72]
    mov r9, qword [rbp-48]

    call gfx_floor

    ; restore rbx
    mov rbx, qword [rbp-8]

    xor rax, rax

    mov rsp, rbp
    pop rbp
    ret

; void gfx_floor(wnd* window, int x, int y, int bmpId);
gfx_floor:
    push rbp
    mov rbp, rsp
    sub rsp, 224

    ; local variables
    ; rbx               -8
    ; window            -16
    ; x                 -24
    ; y                 -32
    ; bmp               -40
    ; width             -48
    ; height            -56
    ; pixels            -64
    ; wpixels           -72
    ; wwidth            -80
    ; wheight           -88
    ; size              -96
    ; halfsize          -104
    ; startX            -112
    ; startY            -120
    ; yo                -128
    ; xo                -136
    ; yt                -144
    ; xt                -152
    ; xPix              -160
    ; yPix              -168
    ; xtd               -176
    ; ytd               -184
    ; rawPixel          -192

    ; backup rbx
    mov qword [rbp-8], rbx

    ; copy parameters
    mov qword [rbp-16], rcx     ; window
    mov qword [rbp-24], rdx     ; x
    mov qword [rbp-32], r8      ; y
    
    ; get bitmap
    mov rcx, r9
    call bmp_get
    mov qword [rbp-40], rax     ; bmp*

    ; get bitmap values
    mov rbx, rax                ; bmp*
    mov rax, qword [rbx+8]      ; bmp->width
    mov qword [rbp-48], rax     ; width
    mov rax, qword [rbx+16]     ; bmp->height
    mov qword [rbp-56], rax     ; height
    mov rax, qword [rbx+0]      ; bmp->pixels
    mov qword [rbp-64], rax     ; pixels

    ; get window values
    mov rbx, qword [rbp-16]     ; wnd*
    mov rax, qword [rbx+0]      ; wnd->pixels
    mov qword [rbp-72], rax     ; wpixels
    mov rax, qword [rbx+8]      ; wnd->width
    mov qword [rbp-80], rax     ; wwidth
    mov rax, qword [rbx+16]     ; wnd->height
    mov qword [rbp-88], rax     ; wheight

    mov rax, 32      ; take this as input later
    mov qword [rbp-96], rax     ; size
    shr rax, 1
    mov qword [rbp-104], rax    ; size / 2

    mov rax, qword [rbp-24]     ; x
    mov qword [rbp-112], rax    ; startX
    mov rax, qword [rbp-32]     ; y
    mov rcx, qword [rbp-104]    ; halfsize
    shr rcx, 1                  ; halfsize / 2
    sub rax, rcx                ; y - halfsize / 2
    mov qword [rbp-120], rax    ; startY = y - halfsize / 2

    mov qword [rbp-128], 0      ; yo
    jmp .for_yo_start
.for_yo_cont:
    mov rcx, qword [rbp-128]    ; yo
    inc rcx
    mov qword [rbp-128], rcx    ; yo
.for_yo_start:
    mov rcx, qword [rbp-128]    ; yo
    mov rax, qword [rbp-104]    ; halfsize
    shl rax, 1                  ; halfsize * 2
    cmp rcx, rax
    jg .for_yo_end
    mov rax, qword [rbp-128]    ; yo
    mov rcx, qword [rbp-56]     ; bmp->height (height)
    mul rcx
    xor rdx, rdx
    mov rcx, qword [rbp-104]    ; halfsize
    div rcx                     ; yo * bmp->height / halfsize
    mov qword [rbp-144], rax    ; yt
    shr rax, 1
    mov rcx, qword [rbp-56]     ; bmp->height
    cmp rax, rcx
    jl .yt_skip
    sub rcx, 1
    mov rax, rcx
.yt_skip:
    mov qword [rbp-184], rax    ; ytd = yt / 2

    mov qword [rbp-136], 0      ; xo
    jmp .for_xo_start
.for_xo_cont:
    mov rcx, qword [rbp-136]    ; xo
    inc rcx
    mov qword [rbp-136], rcx    ; xo
.for_xo_start:
    mov rcx, qword [rbp-136]    ; xo
    mov rax, qword [rbp-96]     ; size
    cmp rcx, rax
    jg .for_xo_end
    mov rax, qword [rbp-136]    ; xo
    mov rcx, qword [rbp-48]     ; bmp->width (width)
    mul rcx
    xor rdx, rdx
    mov rcx, qword [rbp-104]    ; halfsize
    div rcx                     ; xo * bmp->width / [halfsize (size / 2)]
    mov qword [rbp-152], rax    ; xt
    shr rax, 1
    mov rcx, qword [rbp-48]     ; bmp->width
    cmp rax, rcx
    jl .xt_skip
    sub rcx, 1
    mov rax, rcx
.xt_skip:
    mov qword [rbp-176], rax    ; xtd = tx / 2

    xor rax, rax                ; xPix = 0
    mov rcx, qword [rbp-136]    ; xo
    add rax, rcx                ; xPix += xo
    mov rcx, qword [rbp-128]    ; yo
    sub rax, rcx                ; xPix -= yo

    shr rax, 1                  ; xPix / 2
    mov rcx, qword [rbp-112]    ; startX
    add rax, rcx                ; xPix = startX + xPix / 2

    mov rcx, 0x7FFFFFFFFFFFFFFF
    and rax, rcx
    mov qword [rbp-160], rax    ; xPix

    xor rax, rax                ; yPix = 0
    mov rcx, qword [rbp-136]    ; xo
    shr rcx, 1                  ; xo / 2
    add rax, rcx                ; yPix += xo / 2
    mov rcx, qword [rbp-128]    ; yo
    shr rcx, 1                  ; yo / 2
    add rax, rcx                ; yPix += yo / 2

    shr rax, 1                  ; yPix / 2
    mov rcx, qword [rbp-120]    ; startY
    add rax, rcx                ; yPix = startY + yPix / 2

    mov qword [rbp-168], rax    ; yPix

    cmp rax, 0
    jl .for_xo_cont             ; yPix < 0
    mov rcx, qword [rbp-88]     ; wnd->height (wheight)
    cmp rax, rcx
    jge .for_xo_cont            ; yPix >= wnd->height

    mov rax, qword [rbp-160]    ; xPix
    cmp rax, 0
    jl .for_xo_cont             ; xPix < 0
    mov rcx, qword [rbp-80]     ; wnd->width (wwidth)
    cmp rax, rcx
    jge .for_xo_cont            ; yPix >= wnd->width

    
    mov rax, qword [rbp-184]    ; ytd
    mov rcx, qword [rbp-48]     ; bmp->width
    mul rcx                     ; ytd * bmp->width
    mov rcx, qword [rbp-176]    ; xtd
    add rax, rcx
    mov rbx, qword [rbp-64]     ; bmp->pixels
    xor rdx, rdx
    mov edx, dword [rbx+rax*4]  ; bmp->pixels[xtd + ytd * bmp->width]
    cmp rdx, 0xff00ff
    je .for_xo_cont
    mov qword [rbp-192], rdx    ; rawPixel
    mov rax, qword [rbp-168]    ; yPix
    mov rcx, qword [rbp-80]     ; wnd->width
    mul rcx                     ; yPix * wnd->width
    mov rcx, qword [rbp-160]    ; xPix
    add rax, rcx
    mov rbx, qword [rbp-72]     ; wnd->pixels
    mov rdx, qword [rbp-192]    ; rawPixel
    mov dword [rbx+rax*4], edx  ; wnd->pixels[xPix + yPix * wnd->width]

    jmp .for_xo_cont
.for_xo_end:
    jmp .for_yo_cont
.for_yo_end:
    xor rax, rax

    ; restore rbx
    mov rbx, qword [rbp-8]

    mov rsp, rbp
    pop rbp
    ret

; void gfx_wall_tile(wnd* window, int x, int y, int z, int bmpId, int right);
gfx_wall_tile:
    push rbp
    mov rbp, rsp
    sub rsp, 112

    ; local variables
    ; rbx               -8
    ; window            -16
    ; x                 -24
    ; y                 -32
    ; z                 -40
    ; bmpId             -48
    ; right             -56
    ; tmp               -64
    ; wx                -72
    ; wy                -80

    ; backup rbx
    mov qword [rbp-8], rbx

    ; copy parameters
    mov qword [rbp-16], rcx         ; window
    mov qword [rbp-24], rdx         ; x
    mov qword [rbp-32], r8          ; y
    mov qword [rbp-40], r9          ; z
    mov rax, qword [rbp+40]         ; bmpId
    mov qword [rbp-48], rax
    mov rax, qword [rbp+48]         ; right
    mov qword [rbp-56], rax

    mov rax, rdx
    sub rax, r9
    mov qword [rbp-24], rax

    mov rax, r8
    sub rax, r9
    mov qword [rbp-32], rax

    mov rax, qword [rbp-24]
    sub rax, qword [rbp-32]
    ; TODO: Do not hard-code 16 (which is zoom / 2)
    mov rcx, 16
    mul rcx
    mov qword [rbp-64], rax

    mov rbx, qword [rbp-16]
    mov rax, [rbx+8]
    shr rax, 1
    add rax, qword [rbp-64]
    mov rcx, 0x7FFFFFFFFFFFFFFF
    and rax, rcx
    mov qword [rbp-72], rax

    mov rax, qword [rbp-24]
    add rax, qword [rbp-32]
    ; TODO: Do not hard-code 8 (which is zoom / 4)
    mov rcx, 8
    mul rcx
    mov qword [rbp-64], rax

    mov rbx, qword [rbp-16]
    mov rax, [rbx+16]
    shr rax, 1
    add rax, qword [rbp-64]
    mov rcx, 0x7FFFFFFFFFFFFFFF
    and rax, rcx
    mov qword [rbp-80], rax

    mov rcx, qword [rbp-16]
    mov rdx, qword [rbp-72]
    mov r8, qword [rbp-80]
    mov r9, qword [rbp-48]
    mov rax, qword [rbp-56]
    mov qword [rsp+24], rax

    call gfx_wall

    ; restore rbx
    mov rbx, qword [rbp-8]

    xor rax, rax

    mov rsp, rbp
    pop rbp
    ret

; void gfx_wall(wnd* window, int x, int y, int bmpId, int right);
gfx_wall:
    push rbp
    mov rbp, rsp
    sub rsp, 224

    ; local variables
    ; rbx               -8
    ; window            -16
    ; x                 -24
    ; y                 -32
    ; bmp               -40
    ; width             -48
    ; height            -56
    ; pixels            -64
    ; wpixels           -72
    ; wwidth            -80
    ; wheight           -88
    ; size              -96
    ; startX            -104
    ; startY            -112
    ; xo                -120
    ; yo                -128
    ; xt                -136
    ; yt                -144
    ; xPix              -152
    ; yPix              -160
    ; xtd               -168
    ; ytd               -176
    ; rawPixel          -184
    ; right             -192

    ; backup rbx
    mov qword [rbp-8], rbx

    ; copy parameters
    mov qword [rbp-16], rcx         ; window
    mov qword [rbp-24], rdx         ; x
    mov qword [rbp-32], r8          ; y
    mov rax, qword [rbp+40]         ; right
    mov qword [rbp-192], rax        ;

    ; get bitmap
    mov rcx, r9
    call bmp_get
    mov qword [rbp-40], rax         ; bmp*

    ; get bitmap values
    mov rbx, rax                    ; bmp*
    mov rax, qword [rbx+8]          ; bmp->width
    mov qword [rbp-48], rax         ; width
    mov rax, qword [rbx+16]         ; bmp->height
    mov qword [rbp-56], rax         ; height
    mov rax, qword [rbx+0]          ; bmp->pixels
    mov qword [rbp-64], rax         ; pixels

    ; get window values
    mov rbx, qword [rbp-16]         ; wnd*
    mov rax, qword [rbx+0]          ; wnd->pixels
    mov qword [rbp-72], rax         ; wpixels
    mov rax, qword [rbx+8]          ; wnd->width
    mov qword [rbp-80], rax         ; wwidth
    mov rax, qword [rbx+16]         ; wnd->height
    mov qword [rbp-88], rax         ; wheight

    mov rax, 32     ; take this as input later
    mov qword [rbp-96], rax         ; size

    mov rax, qword [rbp-24]         ; x
    mov qword [rbp-104], rax        ; startX
    mov rax, qword [rbp-96]         ; size
    mov rcx, 3
    mul rcx                         ; size * 3
    xor rdx, rdx
    mov rcx, 4
    div rcx                         ; size * 3 / 4
    mov rcx, qword [rbp-32]
    sub rcx, rax                    ; y - size * 3 / 4
    mov qword [rbp-112], rcx        ; startY
    mov rax, qword [rbp-192]
    cmp rax, 0
    jne .skip_nright                ; right == true
    ; right == false
    mov rax, qword [rbp-104]
    mov rcx, qword [rbp-96]
    shr rcx, 1
    sub rax, rcx
    mov qword [rbp-104], rax
    mov rax, qword [rbp-112]
    shr rcx, 1
    add rax, rcx
    mov qword [rbp-112], rax
.skip_nright:

    mov qword [rbp-128], 0          ; yo
    jmp .for_yo_start
.for_yo_cont:
    mov rcx, qword [rbp-128]        ; yo
    inc rcx
    mov qword [rbp-128], rcx        ; yo
.for_yo_start:
    mov rax, qword [rbp-128]        ; yo
    mov rcx, qword [rbp-96]         ; size
    shl rcx, 1                      ; size * 2
    cmp rax, rcx                    ; yo <= size * 2
    jg .for_yo_end                  

    mov rax, qword [rbp-128]        ; yo
    mov rcx, qword [rbp-56]         ; bmp->height
    mul rcx                         ; yo * bmp->height
    mov rcx, qword [rbp-96]         ; size
    xor rdx, rdx
    div rcx                         ; yo * bmp->height / size

    mov qword [rbp-144], rax        ; yt
    shr rax, 1                      ; yt / 2
    mov rcx, qword [rbp-56]         ; bmp->height
    cmp rax, rcx
    jl .ytd_skip
    sub rcx, 1
    mov rax, rcx
.ytd_skip:
    mov qword [rbp-176], rax        ; ytd = yt / 2

    mov qword [rbp-120], 0          ; xo
    jmp .for_xo_start
.for_xo_cont:
    mov rcx, qword [rbp-120]        ; xo
    inc rcx
    mov qword [rbp-120], rcx        ; xo
.for_xo_start:
    mov rax, qword [rbp-120]        ; xo
    mov rcx, qword [rbp-96]         ; size
    cmp rax, rcx
    jg .for_xo_end

    mov rax, qword [rbp-120]        ; xo
    mov rcx, qword [rbp-48]         ; bmp->width
    mul rcx                         ; xo * bmp->width
    mov rcx, qword [rbp-96]         ; size
    shr rcx, 1                      ; size / 2
    xor rdx, rdx
    div rcx                         ; xo * bmp->width / (size / 2)

    mov qword [rbp-136], rax        ; xt
    shr rax, 1                      ; xt / 2
    mov rcx, qword [rbp-48]         ; bmp->width
    cmp rax, rcx
    jl .xtd_skip
    sub rcx, 1
    mov rax, rcx
.xtd_skip:
    mov qword [rbp-168], rax        ; xtd = xt / 2

    xor rax, rax                    ; xPix = 0
    mov rcx, qword [rbp-120]        ; xo
    add rax, rcx                    ; xPix += xo

    shr rax, 1                      ; xPix / 2
    mov rcx, qword [rbp-104]        ; startX
    add rax, rcx                    ; xPix = startX + xPix / 2

    mov rcx, 0x7FFFFFFFFFFFFFFF
    and rax, rcx
    mov qword [rbp-152], rax        ; xPix

    mov rcx, qword [rbp-120]        ; xo
    shr rcx, 1                      ; xo / 2

    mov rax, qword [rbp-192]        ; right
    cmp rax, 0                      ; right == true
    je .right_false
    xor rax, rax
    sub rax, rcx                    ; yPix = -(xo / 2)
    jmp .right_skip
.right_false:
    mov rax, rcx                    ; yPix = xo / 2
.right_skip:
    mov rcx, qword [rbp-128]        ; yo
    shr rcx, 1                      ; yo / 2
    add rax, rcx                    ; yPix += yo / 2

    shr rax, 1                      ; yPix / 2
    mov rcx, qword [rbp-112]        ; startY
    add rax, rcx                    ; yPix = startY + yPix / 2

    mov rcx, 0x7FFFFFFFFFFFFFFF
    and rax, rcx
    mov qword [rbp-160], rax        ; yPix

    cmp rax, 0
    jl .for_xo_cont                 ; yPix < 0
    mov rcx, qword [rbp-88]         ; wnd->height
    cmp rax, rcx
    jge .for_xo_cont                ; yPix >= wnd->height

    mov rax, qword [rbp-152]        ; xPix
    cmp rax, 0
    jl .for_xo_cont                 ; xPix < 0
    mov rcx, qword [rbp-80]         ; wnd->width
    cmp rax, rcx
    jge .for_xo_cont                ; xPix >= wnd->width

    mov rax, qword [rbp-176]        ; ytd
    mov rcx, qword [rbp-48]         ; bmp->width
    mul rcx                         ; ytd * bmp->width
    mov rcx, qword [rbp-168]        ; xtd
    add rax, rcx
    mov rbx, qword [rbp-64]         ; bmp->pixels
    xor rdx, rdx
    mov edx, dword [rbx+rax*4]      ; bmp->pixels[xtd + ytd * bmp->width]
    cmp rdx, 0xff00ff
    je .for_xo_cont
    mov qword [rbp-184], rdx        ; rawPixel
    
    mov rax, qword [rbp-192]        ; right
    cmp rax, 0
    je .darken_right_false
    mov rdx, 28
    jmp .darken_right_skip
.darken_right_false:
    mov rdx, 25
.darken_right_skip:
    mov r8, 32
    mov rcx, qword [rbp-184]
    call col_darken
    mov qword [rbp-184], rax

    mov rax, qword [rbp-160]        ; yPix
    mov rcx, qword [rbp-80]         ; wnd->width
    mul rcx                         ; yPix * wnd->width
    mov rcx, qword [rbp-152]        ; xPix
    add rax, rcx
    mov rbx, qword [rbp-72]         ; wnd->pixels
    mov rdx, qword [rbp-184]        ; rawPixel
    mov dword [rbx+rax*4], edx      ; wnd->pixels[xPix + yPix * wnd->width]

    jmp .for_xo_cont
.for_xo_end:
    jmp .for_yo_cont
.for_yo_end:
    xor rax, rax

    ; restore rbx
    mov rbx, qword [rbp-8]

    mov rsp, rbp
    pop rbp
    ret