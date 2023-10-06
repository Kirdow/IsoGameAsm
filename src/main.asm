default rel
bits 64

section .data
    window_title db 'SDL2 Window', 0
    title db 'SDL2 window', 0
    str_err1 db 'Failed to init SDL2', 0xd, 0xa, 0
    str_err2 db 'Failed to create window', 0xd, 0xa, 0
    str_err3 db 'Failed to create renderer', 0xd, 0xa, 0
    str_err4 db 'Failed to create texture', 0xd, 0xa, 0
    str_err5 db 'Failed to malloc pixels', 0xd, 0xa, 0
    fmt db 'result for "%s" is: 0x%08X', 0xd, 0xa, 0
    fmt2 db 'result: %d', 0xd, 0xa, 0

    str_sdlinit db 'SDL_Init', 0
    strs_sdlinit db 'Initialized SDL2', 0xd, 0xa, 0
    str_sdlcw db 'SDL_CreateWindow', 0
    strs_sdlcw db 'Created Window', 0xd, 0xa, 0
    str_sdlcr db 'SDL_CreateRenderer', 0
    strs_sdlcr db 'Created Renderer', 0xd, 0xa, 0
    str_sdlct db 'SDL_CreateTexture', 0
    strs_sdlct db 'Created Texture', 0xd, 0xa, 0

    str_errcu db 'Cleanup error', 0xd, 0xa, 0
    strs_sdldt db 'Destroying Texture', 0xd, 0xa, 0
    strs_sdldr db 'Destroying Renderer', 0xd, 0xa, 0
    strs_sdldw db 'Destroying Window', 0xd, 0xa, 0
    strs_sdlq db 'Quitting SDL2', 0xd, 0xa, 0

    success db 'Success', 0xd, 0xa, 0
    failed db 'Failed', 0xd, 0xa, 0

    str_logn db 'Number: %llx', 0xd, 0xa, 0
    str_logn2 db 'Number: %lld', 0xd, 0xa, 0
    str_logs db 'String: %s', 0xd, 0xa, 0

    str_looptest db '[LOOP TEST]', 0xd, 0xa, 0
section .text
    global entry
    extern SDL_Init, SDL_CreateWindow, SDL_CreateRenderer, SDL_CreateTexture, SDL_DestroyWindow, SDL_DestroyRenderer, SDL_DestroyTexture, SDL_Quit, SDL_Delay, SDL_PollEvent, SDL_UpdateTexture, SDL_RenderClear, SDL_RenderCopy, SDL_RenderPresent
    extern ExitProcess
    extern _CRT_INIT
    extern printf
    extern malloc
    extern free
    extern wnd_create
    extern wnd_flush
    extern wnd_sync
    extern gfx_fill
    extern gfx_rect
    extern gfx_bmp
    extern gfx_floor_tile
    extern gfx_floor
    extern gfx_wall_tile
    extern gfx_wall
    extern bmp_init
    extern bmp_get

entry:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    call _CRT_INIT

    call main

    mov rcx, rax
    xor rax, rax
    call ExitProcess
    leave
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 176
    
    call bmp_init

    mov rcx, 0x20 ; SDL_INIT_VIDEO
    call SDL_Init
    cmp rax, 0
    jge .cont1
    
    lea rcx, [str_err1]
    xor rax, rax
    call printf
    
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.cont1:
    lea rcx, [strs_sdlinit]
    call printf
    
    lea rcx, [title]
    mov rdx, 320
    mov r8, 240
    call wnd_create

    cmp rax, 0
    jne .cont2

    lea rcx, [failed]
    call printf

    mov rsp, rbp
    pop rbp
    ret
.cont2:
    mov qword [rbp-8], rax ; wnd*
    mov qword [rbp-16], 1 ; running = true
    
    mov qword [rbp-80], 0x0000ff
.while_running_start:
    mov rax, qword [rbp-16] ; running
    cmp rax, 0
    je .while_running_end
.while_pollevent_start:
    lea rcx, [rbp-72]
    call SDL_PollEvent
    cmp rax, 0
    je .while_pollevent_end

    mov eax, dword [rbp-72] ; event.type
    cmp eax, 0x100 ; SDL_QUIT
    jne .while_pollevent_start
    mov qword [rbp-16], 0 ; running = false
    jmp .while_pollevent_start
.while_pollevent_end:
    
    mov rcx, qword [rbp-8] ; wnd*
    mov rdx, qword [rbp-80] ; color
    call gfx_fill

    mov rcx, qword [rbp-8] ; wnd*
    mov rdx, 130 ; x
    mov r8, 55 ; y
    mov r9, 0
    call gfx_bmp

    mov qword [rbp-88], 0           ; y
    jmp .for_y_start
.for_y_cont:
    mov rcx, qword [rbp-88]         ; y
    inc rcx
    mov qword [rbp-88], rcx         ; y
.for_y_start:
    mov rax, qword [rbp-88]         ; y
    cmp rax, 5
    jge .for_y_end

    mov qword [rbp-96], 0           ; x
    jmp .for_x_start
.for_x_cont:
    mov rcx, qword [rbp-96]         ; x
    inc rcx
    mov qword [rbp-96], rcx         ; x
.for_x_start:
    mov rax, qword [rbp-96]         ; x
    cmp rax, 3
    jge .for_x_end

    mov qword [rbp-104], 0          ; z
    cmp rax, 0
    jne .z_skip
    mov qword [rbp-104], 1
.z_skip:

    mov rax, qword [rbp-88]         ; y
    cmp rax, 1
    jl .grass
    cmp rax, 3
    jg .grass

    mov rax, qword [rbp-96]         ; x
    cmp rax, 1
    jne .grass

    mov rax, 1
    mov qword [rsp+24], rax
    jmp .drawtile
.grass:
    mov rax, 5
    mov qword [rsp+24], rax
.drawtile:
    mov rcx, qword [rbp-8] ; wnd*
    mov rdx, qword [rbp-96] ; x
    mov r8, qword [rbp-88] ; y
    mov r9, 0 ; z
    call gfx_floor_tile

    mov rax, qword [rbp-96] ; x
    cmp rax, 0
    jne .leftwall_skip

    mov rcx, qword [rbp-8]
    mov rdx, qword [rbp-96]
    mov r8, qword [rbp-88]
    inc r8
    mov r9, 0
    mov rax, 0
    mov qword [rsp+24], rax
    mov rax, 1
    mov qword [rsp+32], rax
    call gfx_wall_tile
.leftwall_skip:

    mov rax, qword [rbp-88] ; y
    cmp rax, 0
    jne .rightwall_skip

    mov rcx, qword [rbp-8]
    mov rdx, qword [rbp-96]
    mov r8, qword [rbp-88]
    dec r8
    mov r9, 0
    mov rax, 0
    mov qword [rsp+24], rax
    mov rax, 0
    mov qword [rsp+32], rax
    call gfx_wall_tile
.rightwall_skip:

    jmp .for_x_cont
.for_x_end:
    jmp .for_y_cont
.for_y_end:

    mov rcx, qword [rbp-8] ; wnd*
    call wnd_flush

    mov rcx, 60
    call wnd_sync

    mov rcx, qword [rbp-80]
    sub rcx, 0x000001
    mov qword [rbp-80], rcx
    and rcx, 255
    cmp rcx, 0
    jg .while_running_start
    mov qword [rbp-80], 0x0000ff
    jmp .while_running_start
.while_running_end:

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

    ; TODO: Correctly free up memory and handles
    mov rcx, qword [rbp-32] ; uint32_t*
    call free
    
    lea rcx, [strs_sdldt]
    call printf

    mov rcx, qword [rbp-24] ; SDL_Texture*
    call SDL_DestroyTexture

    lea rcx, [strs_sdldr]
    call printf
    
    mov rcx, qword [rbp-16] ; SDL_Renderer*
    call SDL_DestroyRenderer

    lea rcx, [strs_sdldw]
    call printf
    
    mov rcx, qword [rbp-8] ; SDL_Window*
    call SDL_DestroyWindow
    
    lea rcx, [strs_sdlq]
    call printf
    
    call SDL_Quit
    
    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

looptest:
    mov rbx, 0
.loopbeg:
    cmp rbx, 20
    jl .loopcont
    
    mov rsp, rbp
    pop rbp
    ret
.loopcont:
    lea rcx, [str_looptest]
    xor rax, rax
    call printf
    inc rbx
    jmp .loopbeg

