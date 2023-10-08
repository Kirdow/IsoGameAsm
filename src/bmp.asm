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
    bmp_error       resq    1
    bmp_carpet      resq    1
    bmp_rock        resq    1
    bmp_wood        resq    1
    bmp_dirt        resq    1
    bmp_grass_top   resq    1
    bmp_grass_side  resq    1
    bmp_glass       resq    1
    bmp_leaf        resq    1

section .text
    extern printf
    extern malloc
    extern free
    extern srand
    extern rand
    extern ExitProcess
    extern col_clamp
    extern col_darken
    extern rnd_next
    extern rnd_start

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

; void bmp_init(void);
bmp_init:
    push rbp
    mov rbp, rsp
    sub rsp, 112

    ; local variables
    ; rbx               -8
    ; bmp               -16
    ; i                 -24
    ; x                 -32
    ; y                 -40
    ; xindex            -48
    ; yindex            -56
    ; darken            -64
    ; d                 -72
    ; col               -80

    ; backup rbx
    mov qword [rbp-8], rbx

    ; seed random
    call rnd_start

    ; texture error

    mov rcx, 8                  ; width
    mov rdx, 8                  ; height
    call bmp_alloc
    mov qword [rbp-16], rax     ; bmp*

    mov qword [rbp-40], 0       ; y
    jmp .for_y_start_0
.for_y_cont_0:
    mov rcx, qword [rbp-40]     ; y
    inc rcx
    mov qword [rbp-40], rcx     ; y
.for_y_start_0:
    mov rax, qword [rbp-40]     ; y
    cmp rax, 8
    jge .for_y_end_0
    
    shr rax, 2
    mov qword [rbp-56], rax     ; yindex = y / 4
    
    mov qword [rbp-32], 0       ; x
    jmp .for_x_start_0
.for_x_cont_0:
    mov rcx, qword [rbp-32]     ; x
    inc rcx
    mov qword [rbp-32], rcx     ; x
.for_x_start_0:
    mov rax, qword [rbp-32]     ; x
    cmp rax, 8
    jge .for_x_end_0

    shr rax, 2
    mov qword [rbp-48], rax     ; xindex = x / 4
    add rax, qword [rbp-56]
    xor rdx, rdx
    mov rcx, 2
    div rcx
    cmp rdx, 0
    je .purple_0
    mov r8, 0x00ff00
    jmp .else_0
.purple_0:
    mov r8, 0x7f007f
.else_0:
    mov rax, qword [rbp-40]
    mov rcx, 8
    mul rcx
    add rax, qword [rbp-32]
    mov rbx, qword [rbp-16]
    mov rdx, [rbx]
    mov rbx, rdx
    mov rcx, r8
    mov dword [rbx+rax*4], ecx

    jmp .for_x_cont_0
.for_x_end_0:
    jmp .for_y_cont_0
.for_y_end_0:
    mov rax, qword [rbp-16]
    mov qword [bmp_error], rax
    
    ; texture carpet (1)

    mov rcx, 8
    mov rdx, 8
    call bmp_alloc
    mov qword [rbp-16], rax     ; bmp*

    mov qword [rbp-40], 0       ; y
    jmp .for_y_start_1
.for_y_cont_1:
    mov rcx, qword [rbp-40]     ; y
    inc rcx
    mov qword [rbp-40], rcx     ; y
.for_y_start_1:
    mov rax, qword [rbp-40]     ; y
    cmp rax, 8
    jge .for_y_end_1

    mov qword [rbp-32], 0       ; x
    jmp .for_x_start_1
.for_x_cont_1:
    mov rcx, qword [rbp-32]     ; x
    inc rcx
    mov qword [rbp-32], rcx     ; x
.for_x_start_1:
    mov rax, qword [rbp-32]     ; x
    cmp rax, 8
    jge .for_x_end_1

.start_inner_1:
    mov rax, qword [rbp-32]     ; x
    cmp rax, 2
    jl .start_ring_1
    cmp rax, 5
    jg .start_ring_1
    mov rax, qword [rbp-40]     ; y
    cmp rax, 2
    jl .start_ring_1
    cmp rax, 5
    jl .start_ring_1

    mov rcx, 8
    call rnd_next
    add rax, 24
    mov qword [rbp-64], rax     ; darken
    jmp .skip_1
.start_ring_1:
    mov rax, qword [rbp-32]     ; x
    cmp rax, 1
    jl .start_outer_1
    cmp rax, 6
    jg .start_outer_1
    mov rax, qword [rbp-40]     ; y
    cmp rax, 1
    jl .start_outer_1
    cmp rax, 6
    jg .start_outer_1
    
    mov rcx, 8
    call rnd_next
    add rax, 20
    mov qword [rbp-64], rax     ; darken
    jmp .skip_1
.start_outer_1:
    mov rcx, 8
    call rnd_next
    add rax, 29
    mov qword [rbp-64], rax     ; darken
.skip_1:
    mov rcx, 0xff0000
    mov rdx, qword [rbp-64]
    mov r8, 48
    call col_darken
    mov r8, rax
    mov rax, qword [rbp-40]
    mov rcx, 8
    mul rcx
    add rax, qword [rbp-32]
    mov rbx, qword [rbp-16]
    mov rdx, [rbx]
    mov rbx, rdx
    mov rcx, r8
    mov dword [rbx+rax*4], ecx

    jmp .for_x_cont_1
.for_x_end_1:
    jmp .for_y_cont_1
.for_y_end_1:
    mov rax, qword [rbp-16]
    mov qword [bmp_carpet], rax

    ; texture rock (2)

    mov rcx, 8                  ; width
    mov rdx, 8                  ; height
    call bmp_alloc
    mov qword [rbp-16], rax     ; bmp*

    mov qword [rbp-40], 0       ; y
    jmp .for_y_start_2
.for_y_cont_2:
    mov rcx, qword [rbp-40]     ; y
    inc rcx
    mov qword [rbp-40], rcx     ; y
.for_y_start_2:
    cmp qword [rbp-40], 8       ; y
    jge .for_y_end_2

    mov qword [rbp-32], 0       ; x
    jmp .for_x_start_2
.for_x_cont_2:
    mov rcx, qword [rbp-32]     ; x
    inc rcx
    mov qword [rbp-32], rcx     ; x
.for_x_start_2:
    cmp qword [rbp-32], 8       ; x
    jge .for_x_end_2

    mov rcx, 255
    xor rax, rax
    or rax, rcx                 ; use grayscale
    shl rax, 8                  ;
    or rax, rcx                 ;
    shl rax, 8                  ;
    or rax, rcx                 ;
    mov qword [rbp-80], rax     ; col

    cmp qword [rbp-32], 0       ; x
    je .if_2
    cmp qword [rbp-40], 0       ; y
    je .if_2
    cmp qword [rbp-32], 7       ; x
    je .if_2
    cmp qword [rbp-40], 7       ; y
    jne .if_2_else
.if_2:
    mov rcx, 8
    call rnd_next
    add rax, 32
    jmp .if_2_skip
.if_2_else:
    mov rcx, 8
    call rnd_next
    add rax, 24
.if_2_skip:
    mov rdx, rax
    mov rcx, qword [rbp-80]     ; col
    mov r8, 48
    call col_darken
    mov r10, rax

    mov rax, 8
    mov rcx, qword [rbp-40]
    mul rcx
    add rax, qword [rbp-32]

    mov rbx, qword [rbp-16]
    mov rdx, [rbx]
    mov rbx, rdx
    mov rcx, r10
    mov dword [rbx+rax*4], ecx

    jmp .for_x_cont_2
.for_x_end_2:
    jmp .for_y_cont_2
.for_y_end_2:
    mov rax, qword [rbp-16]
    mov qword [bmp_rock], rax

    ; texture wood (3)

    mov rcx, 8                  ; width
    mov rdx, 8                  ; height
    call bmp_alloc
    mov qword [rbp-16], rax     ; bmp*

    mov qword [rbp-40], 0       ; y
    jmp .for_y_start_3
.for_y_cont_3:
    mov rcx, qword [rbp-40]     ; y
    inc rcx
    mov qword [rbp-40], rcx     ; y
.for_y_start_3:
    cmp qword [rbp-40], 8       ; y
    jge .for_y_end_3

    mov qword [rbp-32], 0       ; x
    jmp .for_x_start_3
.for_x_cont_3:
    mov rcx, qword [rbp-32]     ; x
    inc rcx
    mov qword [rbp-32], rcx     ; x
.for_x_start_3:
    cmp qword [rbp-32], 8       ; x
    jge .for_x_end_3

    mov rax, qword [rbp-32]     ; x
    shr rax, 1
    mov rcx, 2
    xor rdx, rdx
    div rcx
    mov rax, 1
    cmp rdx, 0
    cmove rbx, rax
    mov qword [rbp-48], rbx     ; xIndex

    mov rax, qword [rbp-32]     ; x
    shr rax, 2
    mov rcx, 2
    xor rdx, rdx
    div rcx
    mov rax, 1
    cmp rdx, 0
    cmove rbx, rax
    mov qword [rbp-56], rbx     ; zIndex

    mov r8, 32
    mov r9, 22
    cmp qword [rbp-48], 1       ; xIndex
    cmove r8, r9
    mov qword [rbp-64], r8

    mov r8, 1
    xor r9, r9
    cmp qword [rbp-56], 1       ; zIndex
    cmove r8, r9
    add qword [rbp-64], r8
    mov rcx, 8
    call rnd_next
    add qword [rbp-64], rax

    mov rcx, 0xAF9142
    mov rdx, qword [rbp-64]
    mov r8, 48
    call col_darken
    mov r10, rax

    mov rax, 8
    mov rcx, qword [rbp-40]
    mul rcx
    add rax, qword [rbp-32]

    mov rbx, qword [rbp-16]
    mov rdx, [rbx]
    mov rbx, rdx
    mov rcx, r10
    mov dword [rbx+rax*4], ecx

    jmp .for_x_cont_3
.for_x_end_3:
    jmp .for_y_cont_3
.for_y_end_3:
    mov rax, qword [rbp-16]
    mov qword [bmp_wood], rax

    ; texture dirt (4)

    mov rcx, 8                  ; width
    mov rdx, 8                  ; height
    call bmp_alloc
    mov qword [rbp-16], rax     ; bmp*

    mov qword [rbp-24], 0       ; i
    jmp .for_i_start_4
.for_i_cont_4:
    mov rcx, qword [rbp-24]     ; i
    inc rcx
    mov qword [rbp-24], rcx     ; i
.for_i_start_4:
    cmp qword [rbp-24], 64      ; i
    jge .for_i_end_4

    mov rcx, 8
    call rnd_next
    add rax, 36
    mov rdx, rax
    mov r8, 48
    mov rcx, 0x7A411A
    call col_darken
    mov r10, rax

    mov rbx, qword [rbp-16]     ; bmp*
    mov rax, [rbx]
    mov rbx, rax
    mov rax, qword [rbp-24]     ; i

    mov dword [rbx+rax*4], r10d

    jmp .for_i_cont_4
.for_i_end_4:
    mov rax, qword [rbp-16]
    mov qword [bmp_dirt], rax

    ; texture grass top (5)

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
    mov rax, qword [rbp-16]
    mov qword [bmp_grass_top], rax

    ; texture grass side (6)

    mov rcx, 8                  ; width
    mov rdx, 8                  ; height
    call bmp_alloc
    mov qword [rbp-16], rax     ; bmp*

    mov qword [rbp-32], 0       ; x
    jmp .for_x_start_6
.for_x_cont_6:
    mov rcx, qword [rbp-32]     ; x
    inc rcx
    mov qword [rbp-32], rcx     ; x
.for_x_start_6:
    cmp qword [rbp-32], 8       ; x
    jge .for_x_end_6

    mov rcx, 3
    call rnd_next
    inc rax
    mov qword [rbp-72], rax     ; d

    mov qword [rbp-40], 0       ; y
    jmp .for_y_start_6
.for_y_cont_6:
    mov rcx, qword [rbp-40]     ; y
    inc rcx
    mov qword [rbp-40], rcx     ; y
.for_y_start_6:
    cmp qword [rbp-40], 8       ; y
    jge .for_y_end_6

    mov rax, qword [rbp-72]     ; d
    cmp qword [rbp-40], rax     ; y < d
    jge .else_6
    mov rcx, 8
    call rnd_next
    lea rdx, [rax + 24]
    mov r8, 48
    mov rcx, 0x1CBC26
    call col_darken
    mov rcx, rax
    jmp .skip_6
.else_6:
    mov rbx, qword [bmp_dirt]
    mov rax, [rbx]
    mov rbx, rax
    mov rax, qword [rbp-40]     ; y
    mov rcx, 8
    mul rcx
    add rax, qword [rbp-32]     ; x
    
    xor rcx, rcx
    mov ecx, dword [rbx+rax*4]
.skip_6:
    mov r10, rcx
    mov rax, qword [rbp-40]     ; y
    mov rcx, 8
    mul rcx
    add rax, qword [rbp-32]     ; x
    mov rbx, qword [rbp-16]
    mov rdx, [rbx]
    mov rbx, rdx
    mov rcx, r10
    mov dword [rbx+rax*4], ecx

    jmp .for_y_cont_6
.for_y_end_6:
    jmp .for_x_cont_6
.for_x_end_6:
    mov rax, qword [rbp-16]
    mov qword [bmp_grass_side], rax

    mov rcx, 8                  ; width
    mov rdx, 8                  ; height
    call bmp_alloc
    mov qword [rbp-16], rax     ; bmp*

    mov qword [rbp-40], 0       ; y
    jmp .for_y_start_7
.for_y_cont_7:
    mov rcx, qword [rbp-40]     ; y
    inc rcx
    mov qword [rbp-40], rcx     ; y
.for_y_start_7:
    cmp qword [rbp-40], 8       ; y
    jge .for_y_end_7

    mov qword [rbp-32], 0       ; x
    jmp .for_x_start_7
.for_x_cont_7:
    mov rcx, qword [rbp-32]     ; x
    inc rcx
    mov qword [rbp-32], rcx     ; x
.for_x_start_7:
    cmp qword [rbp-32], 8       ; x
    jge .for_x_end_7

    cmp qword [rbp-32], 0       ; x
    je .and_0_7
    cmp qword [rbp-32], 7       ; x
    je .and_0_7
    cmp qword [rbp-40], 0       ; y
    je .and_0_7
    cmp qword [rbp-40], 7       ; y
    jne .or_1_7
.and_0_7:
    cmp qword [rbp-32], 2       ; x
    je .or_1_7
    cmp qword [rbp-32], 5       ; x
    je .or_1_7
.and_01_7:
    cmp qword [rbp-40], 2       ; y
    je .or_1_7
    cmp qword [rbp-40], 5       ; y
    jne .if_7
.or_1_7:
    cmp qword [rbp-32], 4       ; x
    jne .else_7
    cmp qword [rbp-40], 4       ; y
    jne .else_7
.if_7:
    mov rax, 0xFFFFFF
    jmp .if_7_skip
.else_7:
    mov rax, 0xFF00FF
.if_7_skip:
    mov r10, rax
    
    mov rax, qword [rbp-40]     ; y
    shl rax, 3
    add rax, qword [rbp-32]     ; x

    mov rbx, qword [rbp-16]
    mov rdx, [rbx]
    mov rbx, rdx
    mov rcx, r10
    mov dword [rbx+rax*4], ecx

    jmp .for_x_cont_7
.for_x_end_7:
    jmp .for_y_cont_7
.for_y_end_7:
    mov rax, qword [rbp-16]
    mov qword [bmp_glass], rax

    ; texture leaf (8)

    mov rcx, 8                  ; width
    mov rdx, 8                  ; height
    call bmp_alloc
    mov qword [rbp-16], rax     ; bmp*

    mov qword [rbp-40], 0       ; y
    jmp .for_y_start_8
.for_y_cont_8:
    mov rcx, qword [rbp-40]     ; y
    inc rcx
    mov qword [rbp-40], rcx     ; y
.for_y_start_8:
    cmp qword [rbp-40], 8       ; y
    jge .for_y_end_8

    mov qword [rbp-32], 0       ; x
    jmp .for_x_start_8
.for_x_cont_8:
    mov rcx, qword [rbp-32]     ; x
    inc rcx
    mov qword [rbp-32], rcx     ; x
.for_x_start_8:
    cmp qword [rbp-32], 8       ; x
    jge .for_x_end_8

    mov rcx, 5
    call rnd_next
    cmp rax, 2
    jge .else_8
    mov r10, 0xFF00FF
    jmp .skip_8
.else_8:
    mov rcx, 8
    call rnd_next
    lea rdx, [rax + 24]
    mov r8, 48
    mov rcx, 0x1CBC26
    call col_darken
    mov r10, rax
.skip_8:
    mov rax, qword [rbp-40]     ; y
    shl rax, 3
    add rax, qword [rbp-32]     ; x
    mov rbx, qword [rbp-16]
    mov rdx, [rbx]
    mov rbx, rdx
    mov rcx, r10
    mov dword [rbx+rax*4], ecx

    jmp .for_x_cont_8
.for_x_end_8:
    jmp .for_y_cont_8
.for_y_end_8:
    mov rax, qword [rbp-16]
    mov qword [bmp_leaf], rax

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

; bmp* bmp_get(int id);
bmp_get:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    cmp rcx, 0
    je .get_0
    cmp rcx, 1
    je .get_1
    cmp rcx, 2
    je .get_2
    cmp rcx, 4
    je .get_4
    cmp rcx, 5
    je .get_5
    cmp rcx, 6
    je .get_6
    cmp rcx, 7
    je .get_7
    cmp rcx, 8
    je .get_8
.get_0:
    mov rax, [bmp_dirt]
    jmp .done
.get_1:
    mov rax, [bmp_carpet]
    jmp .done
.get_2:
    mov rax, [bmp_rock]
    jmp .done
.get_3:
    mov rax, [bmp_wood]
    jmp .done
.get_4:
    mov rax, [bmp_dirt]
    jmp .done
.get_5:
    mov rax, [bmp_grass_top]
    jmp .done
.get_6:
    mov rax, [bmp_grass_side]
    jmp .done
.get_7:
    mov rax, [bmp_glass]
    jmp .done
.get_8:
    mov rax, [bmp_leaf]
    jmp .done
.done:
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
