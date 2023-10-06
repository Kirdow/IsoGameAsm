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

    str_logn db 'Number: %x', 0xd, 0xa, 0
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
    sub rsp, 96 + 64 + 16
    
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

    mov rcx, qword [rbp-8] ; wnd*
    mov rdx, 0 ; x
    mov r8, 0 ; y
    mov r9, 0 ; z
    mov qword [rsp+32], 0
    call gfx_floor_tile

    mov rcx, qword [rbp-8] ; wnd*
    mov rdx, 1 ; x
    mov r8, 0 ; y
    mov r9, 0 ; z
    mov qword [rsp+32], 0
    call gfx_floor_tile

    mov rcx, qword [rbp-8] ; wnd*
    mov rdx, 2 ; x
    mov r8, 0; y
    mov r9, 0 ; z
    mov qword [rsp+32], 0
    call gfx_floor_tile

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

