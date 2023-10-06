default rel
bits 64

section .data
    str_logn db 'Number: %x', 0xd, 0xa, 0
    str_logn2 db 'Number: %d', 0xd, 0xa, 0
    str_logs db 'String: %s', 0xd, 0xa, 0
    str_logdata db 'Data:', 0xd, 0xa, 0

section .text
    global col_clamp
    global col_darken

; uint64_t col_clamp(uint64_t channel);
col_clamp:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    cmp rcx, 0
    jge .else0
    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret
.else0:
    cmp rcx, 255
    jle .else1
    mov rax, 255
    mov rsp, rbp
    pop rbp
    ret
.else1:
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret

; uint64_t col_darken(uint64_t color, uint64_t numerator, uint64_t denominator);
col_darken:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    ; local variables
    ; rbx               -8
    ; col               -16
    ; numerator         -24
    ; denominator       -32
    ; result            -40

    mov qword [rbp-8], rbx          ; backup rbx
    mov qword [rbp-16], rcx         ; col
    mov qword [rbp-24], rdx         ; numerator
    mov qword [rbp-32], r8          ; denominator

    mov rax, rcx                    ; col
    shr rax, 16                     ; (col >> 16)
    and rax, 255                    ; r = (col >> 16) & 0xFF
    mul rdx                         ; r * numerator
    xor rdx, rdx
    div r8                          ; r = r * numerator / denominator
    shl rax, 16                     ; r << 16
    mov qword [rbp-40], rax         ; result = r

    mov rax, qword [rbp-16]         ; col
    shr rax, 8                      ; (col >> 8)
    and rax, 255                    ; g = (col >> 8) & 0xFF
    mul qword [rbp-24]              ; g * numerator
    xor rdx, rdx
    div qword [rbp-32]              ; g = g * numerator / denominator
    shl rax, 8                      ; g << 8
    or rax, qword [rbp-40]          ; g = (g << 8) | result
    mov qword [rbp-40], rax         ; result = g

    mov rax, qword [rbp-16]         ; col
    and rax, 255                    ; b = (col) & 0xFF
    mul qword [rbp-24]              ; b * numerator
    xor rdx, rdx
    div qword [rbp-32]              ; b = b * numerator / denominator
    or rax, qword [rbp-40]          ; return b | result

    ; restore rbx
    mov rbx, qword [rbp-8]

    mov rsp, rbp
    pop rbp
    ret
