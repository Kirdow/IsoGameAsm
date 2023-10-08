default rel
bits 64

section .data
    str_logdata db 'Data:', 0xd, 0xa, 0
    str_logn db 'Number: %llx', 0xd, 0xa, 0
    str_logn2 db 'Number: %lld', 0xd, 0xa, 0
    str_logs db 'String: %s', 0xd, 0xa, 0

section .text
    extern printf
    extern malloc, free
    
    extern gfx_floor_tile
    extern gfx_wall_tile
    
    global level_create
    global level_free
    global level_set_tile
    global level_set_wall
    global level_set_floor
    global level_get_wall
    global level_get_floor

    global level_draw

; level*    level_create(int size);
; void      level_free(level* this);
; void      level_set_tile(level* this, int x, int y, int z, int tileId, int flag);
; void      level_set_wall(level* this, int x, int y, int z, bool right, int tileId);
; void      level_set_floor(level* this, int x, int y, int z, int tileId);
; int       level_get_wall(level* this, int x, int y, int z, bool right);
; int       level_get_floor(level* this, int x, int y, int z);
; void      level_draw(level* this, wnd* window);

; struct level {
;     uint64_t*     floors          +0
;     uint64_t*     wallsR          +8
;     uint64_t*     wallsL          +16
;     uint64_t      size            +24
;     uint64_t      size1           +32
;     uint64_t      stride          +40
;     uint64_t      layer           +48
;     uint8_t       padding[8]      +56
; }

; level* level_create(int size);
level_create:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    ; local variables
    ; rbx               -8
    ; size              -16
    ; level             -24
    ; size3             -32
    ; i                 -40

    ; backup rbx
    mov qword [rbp-8], rbx      ; rbx

    ; copy parameter
    mov qword [rbp-16], rcx     ; size

    ; allocate level memory
    mov rcx, 64                 ; 64 bytes
    call malloc

    cmp rax, 0
    jne .malloc_success_level
    ; malloc returned null, return null

    ; restore rbx
    mov rbx, qword [rbp-8]
    
    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret
.malloc_success_level:
    ; save level*
    mov qword [rbp-24], rax     ; level

    mov rbx, rax                ; level
    ; store size

    mov rcx, qword [rbp-16]     ; size
    mov qword [rbx+24], rcx     ; level->size

    add rcx, 1
    mov qword [rbx+32], rcx     ; level->size1
    mov qword [rbx+40], rcx     ; level->stride
    mov rax, rcx
    mul rcx                     ; level->stride * level->size1
    mov qword [rbx+48], rax     ; level->layer
    mov qword [rbx+56], 0       ; level->padding[8]

    mov rax, qword [rbx+32]     ; level->size1
    mov rcx, rax                ; level->size1
    mul rcx                     ; level->size1 ** 2
    mul rcx                     ; level->size1 ** 3
    mov qword [rbp-32], rax     ; size3
    shl rax, 3                  ; size3 * 8
    
    mov rcx, rax
    call malloc
    cmp rax, 0
    jne .malloc_success_floors
    ; malloc returned null, free and return null
    mov rcx, qword [rbp-24]     ; level
    call free

    ; restore rbx
    mov rbx, qword [rbp-8]

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret
.malloc_success_floors:
    mov qword [rbx+0], rax      ; level->floors

    mov rcx, qword [rbp-32]     ; size3
    shl rcx, 3
    call malloc
    cmp rax, 0
    jne .malloc_success_wallsR
    ; malloc returned null, free and return null
    mov rcx, qword [rbx+0]      ; level->floors
    call free
    mov rcx, qword [rbp-24]     ; level
    call free

    ; restore rbx
    mov rbx, qword [rbp-8]

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret
.malloc_success_wallsR:
    mov qword [rbx+8], rax      ; level->wallsR

    mov rcx, qword [rbp-32]     ; size3
    shl rcx, 3
    call malloc
    cmp rax, 0
    jne .malloc_success_wallsL
    ; malloc returned null, free and return
    mov rcx, qword [rbx+8]      ; level->wallsR
    call free
    mov rcx, qword [rbx+0]      ; level->floors
    call free
    mov rcx, qword [rbp-24]     ; level
    call free

    ; restore rbx
    mov rbx, qword [rbp-8]

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret
.malloc_success_wallsL:
    mov qword [rbx+16], rax     ; level->wallsL

    mov qword [rbp-40], 0       ; i
    jmp .for_i_start
.for_i_cont:
    mov rcx, qword [rbp-40]     ; i
    inc rcx
    mov qword [rbp-40], rcx     ; i
.for_i_start:
    mov rax, qword [rbp-40]     ; i
    mov rcx, qword [rbp-32]     ; size3
    cmp rax, rcx
    jge .for_i_end

    mov rbx, qword [rbp-24]     ; get level->floors
    mov rax, [rbx+0]
    mov rbx, rax
    mov rax, qword [rbp-40]     ; i
    mov qword [rbx+rax*8], 0      ; level->floors[i] = 0

    mov rbx, qword [rbp-24]     ; get level->wallsR
    mov rax, [rbx+8]
    mov rbx, rax
    mov rax, qword [rbp-40]     ; i
    mov qword [rbx+rax*8], 0      ; level->wallsR[i] = 0

    mov rbx, qword [rbp-24]     ; get level->wallsL
    mov rax, [rbx+16]
    mov rbx, rax
    mov rax, qword [rbp-40]     ; i
    mov qword [rbx+rax*8], 0      ; level->wallsL[i] = 0

    jmp .for_i_cont
.for_i_end:
    mov rax, qword [rbp-24]     ; return level

    ; restore rbx
    mov rbx, qword [rbp-8]

    mov rsp, rbp
    pop rbp
    ret

; void level_free(level* this);
level_free:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; local variables
    ; rbx               -8
    ; level             -16
    
    ; backup rbx
    mov qword [rbp-8], rbx          ; rbx

    ; save parameter
    mov qword [rbp-16], rcx         ; level

    ; null check
    cmp rcx, 0
    jne .null_check_skip

    xor rax, rax

    ; restore rbx
    mov rbx, qword [rbp-8]          ; rbx

    mov rsp, rbp
    pop rbp
    ret
.null_check_skip:
    mov rbx, qword [rbp-16]         ; level
    mov rcx, [rbx+0]                ; level->floors
    cmp rcx, 0
    je .floors_null_skip
    call free
.floors_null_skip:
    mov rcx, [rbx+8]                ; level->wallsR
    cmp rcx, 0
    je .wallsR_null_skip
    call free
.wallsR_null_skip:
    mov rcx, [rbx+16]               ; level->wallsL
    cmp rcx, 0
    je .wallsL_null_skip
    call free
.wallsL_null_skip:
    mov rcx, rbx                    ; level
    call free

    xor rax, rax

    ; restore rbx
    mov rbx, qword [rbp-8]

    mov rsp, rbp
    pop rbp
    ret

; void level_set_tile(level* this, int x, int y, int z, int tileId, int flag);
level_set_tile:
    push rbp
    mov rbp, rsp
    sub rsp, 96

    ; local variables
    ; rbx               -8
    ; level             -16
    ; x                 -24
    ; y                 -32
    ; z                 -40
    ; tileId            -48
    ; flag              -56

    ; backup rbx
    mov qword [rbp-8], rbx          ; rbx

    ; save parameters
    mov qword [rbp-16], rcx         ; level
    mov qword [rbp-24], rdx         ; x
    mov qword [rbp-32], r8          ; y
    mov qword [rbp-40], r9          ; z
    mov rax, qword [rbp+40]         ; tileId
    mov qword [rbp-48], rax
    mov rax, qword [rbp+48]         ; flag
    mov qword [rbp-56], rax

    ; check sides
    mov rax, qword [rbp-56]         ; flag
    and rax, 0x01                   ; A_TOP
    cmp rax, 0
    je .next_top
    mov rcx, qword [rbp-16]         ; level
    mov rdx, qword [rbp-24]         ; x
    mov r8, qword [rbp-32]          ; y
    mov r9, qword [rbp-40]          ; z
    inc r9
    mov rax, qword [rbp-48]         ; tileId
    mov qword [rsp+24], rax
    call level_set_floor
.next_top:
    mov rax, qword [rbp-56]         ; flag
    and rax, 0x02                   ; A_RIGHT_INNER
    cmp rax, 0
    je .next_right_inner
    mov rcx, qword [rbp-16]         ; level
    mov rdx, qword [rbp-24]         ; x
    mov r8, qword [rbp-32]          ; y
    mov r9, qword [rbp-40]          ; z
    mov qword [rsp+24], 1           ; right
    mov rax, qword [rbp-48]         ; tileId
    mov qword [rsp+32], rax
    call level_set_wall
.next_right_inner:
    mov rax, qword [rbp-56]         ; flag
    and rax, 0x04                   ; A_LEFT_INNER
    cmp rax, 0
    je .next_left_inner
    mov rcx, qword [rbp-16]         ; level
    mov rdx, qword [rbp-24]         ; x
    mov r8, qword [rbp-32]          ; y
    mov r9, qword [rbp-40]          ; z
    mov qword [rsp+24], 0           ; right
    mov rax, qword [rbp-48]         ; tileId
    mov qword [rsp+32], rax
    call level_set_wall
.next_left_inner:
    mov rax, qword [rbp-56]         ; flag
    and rax, 0x08                   ; A_RIGHT_OUTER
    cmp rax, 0
    je .next_right_outer
    mov rcx, qword [rbp-16]         ; level
    mov rdx, qword [rbp-24]         ; x
    inc rdx
    mov r8, qword [rbp-32]          ; y
    mov r9, qword [rbp-40]          ; z
    mov qword [rsp+24], 0           ; right
    mov rax, qword [rbp-48]         ; tileId
    mov qword [rsp+32], rax
    call level_set_wall
.next_right_outer:
    mov rax, qword [rbp-56]         ; flag
    and rax, 0x10                   ; A_LEFT_OUTER
    cmp rax, 0
    je .next_left_outer
    mov rcx, qword [rbp-16]         ; level
    mov rdx, qword [rbp-24]         ; x
    mov r8, qword [rbp-32]          ; y
    inc r8
    mov r9, qword [rbp-40]          ; z
    mov qword [rsp+24], 1           ; right
    mov rax, qword [rbp-48]         ; tileId
    mov qword [rsp+32], rax
    call level_set_wall
.next_left_outer:
    mov rax, qword [rbp-56]         ; flag
    and rax, 0x20                   ; A_BOTTOM
    cmp rax, 0
    je .next_bottom
    mov rcx, qword [rbp-16]         ; level
    mov rdx, qword [rbp-24]         ; x
    mov r8, qword [rbp-32]          ; y
    mov r9, qword [rbp-40]          ; z
    mov rax, qword [rbp-48]         ; tileId
    mov qword [rsp+24], rax
    call level_set_floor
.next_bottom:
    xor rax, rax
    
    ; restore rbx
    mov rbx, qword [rbp-8]

    mov rsp, rbp
    pop rbp
    ret

; void level_set_wall(level* this, int x, int y, int z, bool right, int tileId);
level_set_wall:
    push rbp
    mov rbp, rsp
    sub rsp, 112

    ; local variables
    ; rbx               -8
    ; level             -16
    ; x                 -24
    ; y                 -32
    ; z                 -40
    ; right             -48
    ; tileId            -56
    ; stride            -64
    ; layer             -72
    ; index             -80

    ; backup rbx
    mov qword [rbp-8], rbx          ; rbx

    ; save parameters
    mov qword [rbp-16], rcx         ; level
    mov qword [rbp-24], rdx         ; x
    mov qword [rbp-32], r8          ; y
    mov qword [rbp-40], r9          ; z
    mov rax, qword [rbp+40]         ; right
    mov qword [rbp-48], rax
    mov rax, qword [rbp+48]         ; tileId
    mov qword [rbp-56], rax
    
    ; get stride and layer
    mov rbx, qword [rbp-16]         ; level
    mov rax, [rbx+48]               ; level->layer
    mov qword [rbp-72], rax         ; layer
    mov rax, [rbx+40]               ; level->stride
    mov qword [rbp-64], rax         ; stride

    ; calculate index
    mov rax, qword [rbp-40]         ; z
    mov rcx, qword [rbp-72]         ; layer
    mul rcx                         ; z * layer
    mov qword [rbp-80], rax         ; index
    mov rax, qword [rbp-32]         ; y
    mov rcx, qword [rbp-64]         ; stride
    mul rcx                         ; y * stride
    add rax, qword [rbp-80]         ; y * stride + z * layer
    add rax, qword [rbp-24]         ; x + y * stride + z * layer
    mov qword [rbp-80], rax         ; index

    mov rcx, qword [rbp-48]         ; right
    mov rdx, 8
    mov rax, 16
    cmp rcx, 0
    cmovne rax, rdx
    mov rbx, qword [rbp-16]         ; level
    mov rcx, [rbx+rax]              ; level->walls(R|L)
    mov rbx, rcx
    mov rax, qword [rbp-80]         ; index
    mov rcx, qword [rbp-56]         ; tileId
    mov qword [rbx+rax*8], rcx      ; walls(R|L)[x + y * level->stride + z * level->layer] = tileId

    xor rax, rax

    ; restore rbx
    mov rbx, qword [rbp-8]           ; rbx
    
    mov rsp, rbp
    pop rbp
    ret

; void level_set_floor(level* this, int x, int y, int z, int tileId);
level_set_floor:
    push rbp
    mov rbp, rsp
    sub rsp, 104

    ; local variables
    ; rbx               -8
    ; level             -16
    ; x                 -24
    ; y                 -32
    ; z                 -40
    ; tileId            -48
    ; stride            -56
    ; layer             -64
    ; index             -72

    ; backup rbx
    mov qword [rbp-8], rbx          ; rbx

    ; save parameters
    mov qword [rbp-16], rcx         ; level
    mov qword [rbp-24], rdx         ; x
    mov qword [rbp-32], r8          ; y
    mov qword [rbp-40], r9          ; z
    mov rax, qword [rbp+40]         ; tileId
    mov qword [rbp-48], rax

    ; get stride and layer
    mov rbx, qword [rbp-16]         ; level
    mov rax, [rbx+48]               ; level->layer
    mov qword [rbp-64], rax         ; layer
    mov rax, [rbx+40]               ; level->stride
    mov qword [rbp-56], rax         ; stride

    ; calculate index
    mov rax, qword [rbp-40]         ; z
    mov rcx, qword [rbp-64]         ; layer
    mul rcx                         ; z * layer
    mov qword [rbp-72], rax         ; index
    mov rax, qword [rbp-32]         ; y
    mov rcx, qword [rbp-56]         ; stride
    mul rcx                         ; y * stride
    add rax, qword [rbp-72]         ; y * stride + z * layer
    add rax, qword [rbp-24]         ; x + y * stride + z * layer
    mov qword [rbp-72], rax         ; index

    mov rbx, qword [rbp-16]         ; level
    mov rcx, [rbx+0]                ; level->floors
    mov rbx, rcx
    mov rax, qword [rbp-72]         ; index
    mov rcx, qword [rbp-48]         ; tileId
    mov qword [rbx+rax*8], rcx      ; level->floors[x + y * level->stride + z * level->layer] = tileId

    ; restore rbx
    mov rbx, qword [rbp-8]          ; rbx
    
    xor rax, rax

    mov rsp, rbp
    pop rbp
    ret

; int level_get_wall(level* this, int x, int y, int z, bool right);
level_get_wall:
    push rbp
    mov rbp, rsp
    sub rsp, 104

    ; local variables
    ; rbx               -8
    ; level             -16
    ; x                 -24
    ; y                 -32
    ; z                 -40
    ; right             -48
    ; stride            -56
    ; layer             -64
    ; index             -72

    ; backup rbx
    mov qword [rbp-8], rbx          ; rbx

    ; save parameters
    mov qword [rbp-16], rcx         ; level
    mov qword [rbp-24], rdx         ; x
    mov qword [rbp-32], r8          ; y
    mov qword [rbp-40], r9          ; z
    mov rax, qword [rbp+40]         ; right
    mov qword [rbp-48], rax

    ; get stride and layer
    mov rbx, qword [rbp-16]         ; level
    mov rax, [rbx+48]               ; level->layer
    mov qword [rbp-64], rax         ; layer
    mov rax, [rbx+40]               ; level->stride
    mov qword [rbp-56], rax         ; stride

    ; calculate index
    mov rax, qword [rbp-40]         ; z
    mov rcx, qword [rbp-64]         ; layer
    mul rcx                         ; z * layer
    mov qword [rbp-72], rax         ; index
    mov rax, qword [rbp-32]         ; y
    mov rcx, qword [rbp-56]         ; stride
    mul rcx                         ; y * stride
    add rax, qword [rbp-72]         ; y * stride + z * layer
    add rax, qword [rbp-24]         ; x + y * stride + z * layer
    mov qword [rbp-72], rax         ; index

    mov rax, qword [rbp-48]         ; right
    cmp rax, 0
    cmovne rax, [rbx+8]             ; right == true
    cmove rax, [rbx+16]             ; right == false
    mov rbx, rax
    mov rax, qword [rbp-72]         ; index
    mov rcx, qword [rbx+rax*8]      ; walls(R|L)[x + y * level->stride + z * level->layer]

    mov rax, rcx                    ; return tileId

    ; restore rbx
    mov rbx, qword [rbp-8]          ; rbx

    mov rsp, rbp
    pop rbp
    ret

; int level_get_floor(level* this, int x, int y, int z);
level_get_floor:
    push rbp
    mov rbp, rsp
    sub rsp, 96

    ; local variables
    ; rbx               -8
    ; level             -16
    ; x                 -24
    ; y                 -32
    ; z                 -40
    ; stride            -48
    ; layer             -56
    ; index             -64

    ; backup rbx
    mov qword [rbp-8], rbx          ; rbx

    ; save parameters
    mov qword [rbp-16], rcx         ; level
    mov qword [rbp-24], rdx         ; x
    mov qword [rbp-32], r8          ; y
    mov qword [rbp-40], r9          ; z

    ; get stride and layer
    mov rbx, qword [rbp-16]         ; level
    mov rax, [rbx+48]               ; level->layer
    mov qword [rbp-56], rax         ; layer
    mov rax, [rbx+40]               ; level->stride
    mov qword [rbp-48], rax         ; stride

    ; calculate index
    mov rax, qword [rbp-40]         ; z
    mov rcx, qword [rbp-56]         ; layer
    mul rcx                         ; z * layer
    mov qword [rbp-64], rax         ; index
    mov rax, qword [rbp-32]         ; y
    mov rcx, qword [rbp-48]         ; stride
    mul rcx                         ; y * stride
    add rax, qword [rbp-64]         ; y * stride + z * layer
    add rax, qword [rbp-24]         ; x + y * stride + z * layer

    mov rbx, qword [rbp-16]
    mov rcx, [rbx+0]                ; level->floors
    mov rbx, rcx
    mov rcx, qword [rbx+rax*8]      ; level->floors[x + y * level->stride + z * level->layer]

    ; return tileId
    mov rax, rcx

    ; restore rbx
    mov rbx, qword [rbp-8]          ; rbx

    mov rsp, rbp
    pop rbp
    ret

; void level_draw(level* this, wnd* window);
level_draw:
    push rbp
    mov rbp, rsp
    sub rsp, 144

    ; local variables
    ; rbx               -8
    ; level             -16
    ; window            -24
    ; z                 -32
    ; y                 -40
    ; x                 -48
    ; w                 -56
    ; t                 -64
    ; c                 -72
    ; size1             -80
    ; stride            -88
    ; stride2           -96

    ; backup rbx
    mov qword [rbp-8], rbx          ; rbx

    ; save parameters
    mov qword [rbp-16], rcx         ; level
    mov qword [rbp-24], rdx         ; window

    ; get size and stride
    mov rbx, rcx                    ; level
    mov rax, [rbx+32]               ; level->size1
    mov qword [rbp-80], rax         ; size1
    mov rax, [rbx+40]               ; level->stride
    mov qword [rbp-88], rax         ; stride
    shl rax, 1                      ; stride * 2
    mov qword [rbp-96], rax         ; stride2

    ; z loop begin
    mov qword [rbp-32], 0           ; z
    jmp .for_z_start
.for_z_cont:
    mov rcx, qword [rbp-32]         ; z
    inc rcx
    mov qword [rbp-32], rcx         ; z
.for_z_start:
    mov rax, qword [rbp-32]         ; z
    mov rcx, qword [rbp-80]         ; size1
    cmp rax, rcx
    jge .for_z_end

    ; y loop begin
    mov qword [rbp-40], 0           ; y
    jmp .for_y_start
.for_y_cont:
    mov rcx, qword [rbp-40]         ; y
    inc rcx
    mov qword [rbp-40], rcx         ; y
.for_y_start:
    mov rax, qword [rbp-40]         ; y
    mov rcx, qword [rbp-96]         ; stride2
    cmp rax, rcx
    jge .for_y_end

    ; x loop begin
    mov qword [rbp-48], 0           ; x
    jmp .for_x_start
.for_x_cont:
    mov rcx, qword [rbp-48]         ; x
    inc rcx
    mov qword [rbp-48], rcx         ; x
.for_x_start:
    mov rax, qword [rbp-48]         ; x
    mov rcx, qword [rbp-40]         ; y
    cmp rax, rcx
    jg .for_x_end
    xchg rax, rcx
    sub rax, rcx                    ; y - x
    mov qword [rbp-56], rax         ; w = y - x
    cmp rax, qword [rbp-88]
    jge .for_x_cont
    cmp rcx, qword [rbp-88]
    jge .for_x_cont
    
    mov rcx, qword [rbp-16]         ; level/this
    mov rdx, qword [rbp-48]         ; x
    mov r8, qword [rbp-56]          ; w
    mov r9, qword [rbp-32]          ; z
    mov qword [rsp+24], 0           ; right = false
    call level_get_wall
    cmp rax, 0
    je .left_wall_start

    mov rcx, qword [rbp-24]         ; window
    mov rdx, qword [rbp-48]         ; x
    mov r8, qword [rbp-56]          ; w
    mov r9, qword [rbp-32]          ; z
    mov qword [rsp+24], rax         ; bmpId/tileId
    mov qword [rsp+32], 0           ; right = false
    call gfx_wall_tile
.left_wall_start:

    mov rcx, qword [rbp-16]         ; level/this
    mov rdx, qword [rbp-48]         ; x
    mov r8, qword [rbp-56]          ; w
    mov r9, qword [rbp-32]          ; z
    mov qword [rsp+24], 1           ; right = true
    call level_get_wall
    cmp rax, 0
    je .floor_start

    mov rcx, qword [rbp-24]         ; window
    mov rdx, qword [rbp-48]         ; x
    mov r8, qword [rbp-56]          ; w
    mov r9, qword [rbp-32]          ; z
    mov qword [rsp+24], rax         ; bmpId/tileId
    mov qword [rsp+32], 1           ; right = true
    call gfx_wall_tile
.floor_start:

    mov rcx, qword [rbp-16]         ; level/this
    mov rdx, qword [rbp-48]         ; x
    mov r8, qword [rbp-56]          ; w
    mov r9, qword [rbp-32]          ; z
    call level_get_floor
    cmp rax, 0
    je .for_x_cont

    mov rcx, qword [rbp-24]         ; window
    mov rdx, qword [rbp-48]         ; x
    mov r8, qword [rbp-56]          ; w
    mov r9, qword [rbp-32]          ; z
    mov qword [rsp+24], rax         ; bmpId/tileId
    call gfx_floor_tile

    jmp .for_x_cont
.for_x_end:
    jmp .for_y_cont
.for_y_end:
    jmp .for_z_cont
.for_z_end:

    ; restore rbx
    mov rbx, qword [rbp-8]          ; rbx

    xor rax, rax

    mov rsp, rbp
    pop rbp
    ret
    
