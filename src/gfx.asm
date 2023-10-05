default rel
bits 64

section .data
    str_logn db 'Number: %x', 0xd, 0xa, 0
    str_logs db 'String: %s', 0xd, 0xa, 0

section .text
    extern printf
    extern malloc
    
    global gfx_fill

; void gfx_fill(wnd* window, int color);
gfx_fill:
    push rbp,
    mov rbp, rsp
    sub rsp, 64

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
