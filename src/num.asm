default rel
bits 64

section .data
    str_logn db 'Number: %x', 0xd, 0xa, 0
    str_logn2 db 'Number: %d', 0xd, 0xa, 0
    str_logs db 'String: %s', 0xd, 0xa, 0
    str_logdata db 'Data:', 0xd, 0xa, 0

section .text
    extern srand, rand

    global rnd_next
    global rnd_seed
    global rnd_start

; uint64_t rnd_next(uint64_t bound);
rnd_next:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; local variables
    ; bound             -8
    
    mov qword [rbp-8], rcx ; local bound

    call rand                   ; generate random number
    xor rdx, rdx                ; set rdx to 0 (rdx:rax / rcx = quot:rax rem:rdx)
    mov rcx, qword [rbp-8]
    div rcx                     ; rcx = bound, divide by rcx

    mov rax, rdx                ; return remainder

    mov rsp, rbp
    pop rbp
    ret

; void rnd_seed(uint64_t seed);
; this is just a wrapper for srand
rnd_seed:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    call srand

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

; void rnd_start(void);
rnd_start:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    xor rcx, rcx                ; seed 0
    call srand
    call rand                   ;
    mov rcx, rax                ;
    call srand                  ; srand(rand());

    mov rsp, rbp
    pop rbp
    ret