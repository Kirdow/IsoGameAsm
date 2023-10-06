default rel
bits 64

section .data
    str_logn db 'Number: %x', 0xd, 0xa, 0
    str_logn2 db 'Number: %d', 0xd, 0xa, 0
    str_logs db 'String: %s', 0xd, 0xa, 0
    str_logdata db 'Data:', 0xd, 0xa, 0

    str_input db 'Input : %x', 0xd, 0xa, 0
    str_num db 'Numerator: %d', 0xd, 0xa, 0
    str_den db 'Denomiator: %d', 0xd, 0xa, 0
    str_output db 'Output: %x', 0xd, 0xa, 0

    str_bmp_alloc db 'Allocating %d bytes.', 0xd, 0xa, 0
    str_bmp_writing db 'Writing index %d.', 0xd, 0xa, 0

section .bss
    bmp_test    resq    1

section .text
    extern printf
    extern malloc
    extern free
    extern srand
    extern rand
    extern ExitProcess

    global bmp_init
    global bmp_get

; void bmp_init(void);
; bmp* bmp_alloc(uint64_t width, uint64_t height);
; bmp* bmp_get(int id);
; void bmp_free(bmp* this);

; struct bmp {
;     uint32_t* pixels          +0
;     uint64_t width            +8
;     uint64_t height           +16
;     uint8_t padding[8]        +24
; }

; uint64_t rnd_next(uint64_t bound);
rnd_next:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    mov qword [rbp-8], rcx

    call rand       ; generate random number
    xor rdx, rdx    ; set rdx to 0 (rdx:rax / rcx = quot:rax rem:rdx)
    mov rcx, qword [rbp-8]
    div rcx         ; rcx = bound, divide by rcx

    mov rax, rdx    ; return remainder

    mov rsp, rbp
    pop rbp
    ret

; uint64_t col_clamp(uint64_t ch);
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

; uint64_t col_darken(uint64_t col, uint64_t n, uint64_t d);
col_darken:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    mov qword [rbp-8], rbx          ; backup rbx
    mov qword [rbp-16], rcx         ; col
    mov qword [rbp-24], rdx         ; n
    mov qword [rbp-32], r8          ; d
    mov rax, qword [rbp-16]
    shr rax, 16
    and rax, 255
    mul rdx
    xor rdx, rdx
    div r8
    shl rax, 16
    mov qword [rbp-40], rax
    mov rax, qword [rbp-16]
    shr rax, 8
    and rax, 255
    mul qword [rbp-24]
    xor rdx, rdx
    div qword [rbp-32]
    shl rax, 8
    or rax, qword [rbp-40]
    mov qword [rbp-40], rax
    mov rax, qword [rbp-16]
    and rax, 255
    mul qword [rbp-24]
    xor rdx, rdx
    div qword [rbp-32]
    or rax, qword [rbp-40]
    mov rsp, rbp
    pop rbp
    ret

; void bmp_init(void);
bmp_init:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    ; seed rand with a random integer (based on seed 0)
    xor rcx, rcx
    call srand
    call rand
    mov rcx, rax
    call srand

    mov qword [rbp-8], rbx      ; backup rbx
    mov rcx, 8                 ; width
    mov rdx, 8                 ; height
    call bmp_alloc
    mov qword [rbp-16], rax     ; bmp*

    xor rcx, rcx
    jmp .for_i_start
.for_i_cont:
    inc rcx
.for_i_start:
    cmp rcx, 8*8
    jge .for_i_end
    mov qword [rbp-24], rcx     ; i
    mov rcx, 8
    xor rax, rax
    call rnd_next
    add rax, 28
    mov rdx, rax
    mov r8, 48
    mov rcx, 0x1CBC26
    call col_darken
    mov rdx, rax
    mov rbx, qword [rbp-16]
    mov rax, [rbx+0]
    mov rbx, rax
    mov rax, qword [rbp-24]
    mov dword [rbx+rax*4], edx
    mov rcx, qword [rbp-24]
    jmp .for_i_cont
.for_i_end:
    lea rcx, [str_bmp_writing]
    mov rdx, -1
    xor rax, rax
    call printf
    mov rax, qword [rbp-16]
    mov qword [bmp_test], rax

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

; bmp* bmp_get(int id);
bmp_get:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    cmp rcx, 0
    je .ret_0

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

.ret_0:
    mov rax, [bmp_test]
    mov rsp, rbp
    pop rbp
    ret

; void bmp_free(bmp* this);
bmp_free:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    mov rbx, rcx ; bmp*
    mov rcx, qword [rbx+0] ; bmp->pixels
    call free
    mov rcx, rbx ; bmp*
    call free

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

; bmp* bmp_alloc(uint64_t width, uint64_t height);
bmp_alloc:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    mov qword [rbp-8], rbx      ; backup rbx
    mov qword [rbp-16], rcx     ; width 
    mov qword [rbp-24], rdx     ; height

    mov rax, rdx
    mul rcx
    shl rax, 2
    mov rcx, rax
    call malloc
    mov qword [rbp-32], rax ; pixels
    
    mov rcx, 32
    call malloc
    mov rbx, rax            ; bmp*
    mov rax, qword [rbp-32]
    mov qword [rbx+0], rax  ; bmp->pixels = pixels
    mov rax, qword [rbp-16]
    mov qword [rbx+8], rax  ; bmp->width = width
    mov rax, qword [rbp-24]
    mov qword [rbx+16], rax ; bmp->height = height

    mov rax, rbx            ; return bmp*
    mov rbx, qword [rbp-8]  ; restore rbx

    mov rsp, rbp
    pop rbp
    ret
