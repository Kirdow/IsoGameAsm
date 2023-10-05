default rel
bits 64

section .data
    str_logn db 'Number: %x', 0xd, 0xa, 0
    str_logn2 db 'Number: %d', 0xd, 0xa, 0
    str_logs db 'String: %s', 0xd, 0xa, 0
    str_logdata db 'Data:', 0xd, 0xa, 0

section .text
    extern printf
    extern malloc
    
    global gfx_fill
    global gfx_rect

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


