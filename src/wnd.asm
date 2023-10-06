default rel
bits 64

section .data
    title db 'SDL2 window', 0
    str_err_window db 'Failed to create window', 0xd, 0xa, 0
    str_create_of_name db 'Creating %dx%d window named "%s"', 0xd, 0xa, 0

    str_create_renderer db 'Creating renderer', 0xd, 0xa, 0
    str_err_renderer db 'Failed to create renderer', 0xd, 0xa, 0

    str_create_texture db 'Creating texture', 0xd, 0xa, 0
    str_err_texture db 'Failed to create texture', 0xd, 0xa, 0

    str_create_pixels db 'Creating 4x%dx%d array of pixel bytes.', 0xd, 0xa, 0
    str_err_pixels db 'Failed to created pixel array', 0xd, 0xa, 0

    str_create_wnd db 'Creating wnd* instance', 0xd, 0xa, 0
    str_err_wnd_malloc db 'Faied to create wnd* instance', 0xd, 0xa, 0

    str_logn db 'Number: %x', 0xd, 0xa, 0
    str_logs db 'String: %s', 0xd, 0xa, 0

section .text
    extern SDL_Init, SDL_CreateWindow, SDL_CreateRenderer, SDL_CreateTexture
    extern SDL_DestroyWindow
    extern SDL_UpdateTexture, SDL_RenderClear, SDL_RenderCopy, SDL_RenderPresent
    extern SDL_Quit, SDL_Delay
    extern printf
    extern malloc

    global wnd_create
    global wnd_flush
    global wnd_sync

; wnd* wnd_create(char* title, int width, int height);
; void wnd_flush(wnd* this);
; void wnd_sync(uint64_t rate);

; struct wnd {
;     uint32_t* pixels          +0
;     uint64_t width            +8
;     uint64_t height           +16
;     SDL_Window* window        +24
;     SDL_Renderer* renderer    +32
;     SDL_Texture* texture      +40
;     char* title               +48
;     uint8_t padding[8];       +56
; }

; wnd* wnd_create(char* title, int width, int height);
wnd_create:
    push rbp
    mov rbp, rsp
    sub rsp, 96

    ; title -8
    ; width -16
    ; height -24
    ; window -32
    ; renderer -40
    ; texture -48
    ; pixels -56
    
    ; print window creation
    mov qword [rbp-8], rcx              ; title
    mov qword [rbp-16], rdx             ; width
    mov qword [rbp-24], r8              ; height
    lea rcx, [rel str_create_of_name]
    mov rdx, qword [rbp-16]             ; width
    mov r8, qword [rbp-24]              ; height
    mov r9, qword [rbp-8]               ; title
    call printf
    
    ; create window
    mov rdx, 0x2FFF0000
    mov r8, 0x2FFF0000
    mov rax, qword [rbp-16]              ; width
    mov rcx, 2
    mul rcx
    mov r9, rax
    mov rax, qword [rbp-24]             ; height
    mov rcx, 2
    mul rcx
    mov qword [rsp+32], rax             ;
    mov qword [rsp+40], 4
    mov rcx, qword [rbp-8]              ; title

    call SDL_CreateWindow

    cmp rax, 0
    jne .cont_window

    ; print window creation error
    lea rcx, [str_err_window]
    xor rax, rax
    call printf

    mov rax, 0 ; return nullptr

    mov rsp, rbp
    pop rbp
    ret
.cont_window: ; window creation success
    mov qword [rbp-32], rax             ; window
    
    ; print renderer creation
    lea rcx, [str_create_renderer]
    xor rax, rax
    call printf

    ; create renderer
    mov rcx, qword [rbp-32]        ; window
    mov rdx, -1
    mov r8, 2 ; SDL_RENDERER_ACCELERATED
    call SDL_CreateRenderer

    cmp rax, 0
    jne .cont_renderer

    ; print renderer creation error
    lea rcx, [str_err_renderer]
    xor rax, rax
    call printf

    mov rax, 0 ; return nullptr

    mov rsp, rbp
    pop rbp
    ret
.cont_renderer: ; renderer creation success
    mov qword [rbp-40], rax             ; renderer
    
    ; print texture creation
    lea rcx, [str_create_texture]
    xor rax, rax
    call printf

    ; create texture
    mov rcx, qword [rbp-40]             ; renderer
    mov rdx, 372645892 ; SDL_PIXELFORMAT_ARGB8888
    mov r8, 1 ; SDL_TEXTUREACCESS_STREAMING
    mov r9, qword [rbp-16]              ; width
    mov rax, qword [rbp-24]             ; height
    mov qword [rsp+32], rax             ;
    call SDL_CreateTexture

    cmp rax, 0
    jne .cont_texture

    ; print texture creation error
    lea rcx, [str_err_texture]
    xor rax, rax
    call printf

    mov rax, 0 ; return nullptr

    mov rsp, rbp
    pop rbp
    ret
.cont_texture: ; texture creation success
    mov qword [rbp-48], rax             ; texture

    ; print pixel array creation
    lea rcx, [str_create_pixels]
    xor rax, rax
    mov rdx, qword [rbp-16]             ; width
    mov r8, qword [rbp-24]              ; height
    call printf

    ; create pixel array
    mov rax, qword [rbp-16]             ; width
    mov rbx, qword [rbp-24]             ; height
    mul rbx ; rax *= rbx
    mov rbx, 4
    mul rbx ; rax *= 4
            ; results in 4 * width * height
    mov rcx, rax
    call malloc

    cmp rax, 0
    jne .cont_pixels

    ; print pixel array creation error
    lea rcx, [str_err_pixels]
    xor rax, rax
    call printf

    mov rax, 0 ; return nullptr

    mov rsp, rbp
    pop rbp
    ret
.cont_pixels: ; pixel array creation success
    mov qword [rbp-56], rax             ; pixels

    ; print wnd creation
    lea rcx, [str_create_wnd]
    xor rax, rax
    call printf

    ; allocate memory for wnd struct
    mov rcx, 64
    call malloc

    cmp rax, 0
    jne .cont_wnd_malloc

    ; print wnd struct creation error
    lea rcx, [str_err_wnd_malloc]
    xor rax, rax
    call printf

    mov rax, 0 ; return nullptr

    mov rsp, rbp
    pop rbp
    ret
.cont_wnd_malloc: ; struct malloc success
    
    ; copy local variables to struct
    mov rbx, rax
    mov rax, qword [rbp-56]             ; pixels
    mov qword [rbx+0], rax
    mov rax, qword [rbp-16]             ; width
    mov qword [rbx+8], rax
    mov rax, qword [rbp-24]             ; height
    mov qword [rbx+16], rax
    mov rax, qword [rbp-32]             ; window
    mov qword [rbx+24], rax
    mov rax, qword [rbp-40]             ; renderer
    mov qword [rbx+32], rax
    mov rax, qword [rbp-48]             ; texture
    mov qword [rbx+40], rax
    mov rax, qword [rbp-8]              ; title
    mov qword [rbx+48], rax
    xor rax, rax                        ; padding
    mov qword [rbx+56], rax
    
    mov rax, rbx ; return wnd* ptr
    
    mov rsp, rbp
    pop rbp
    ret

; void wnd_flush(wnd* this);
wnd_flush:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov qword [rbp-16], rbx             ; backup rbx
    mov qword [rbp-8], rcx              ; wnd*

    mov rbx, rcx
    mov rcx, qword [rbx+40]             ; wnd->texture
    mov rdx, 0
    mov r8, qword [rbx+0]               ; wnd->pixels
    mov rax, qword [rbx+8]              ; wnd->width
    imul r9, rax, 4
    call SDL_UpdateTexture

    mov rcx, qword [rbx+32]             ; wnd->renderer
    call SDL_RenderClear

    mov rcx, qword [rbx+32]             ; wnd->renderer
    mov rdx, qword [rbx+40]             ; wnd->texture
    xor r8, r8
    xor r9, r9
    call SDL_RenderCopy

    mov rcx, qword [rbx+32]             ; wnd->renderer
    call SDL_RenderPresent

    mov rbx, qword [rbp-16]             ; restore rbx

    xor rax, rax

    mov rsp, rbp
    pop rbp
    ret

; void wnd_sync(uint64_t rate);
wnd_sync:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; rax = 1000 / ms
    xor rdx, rdx
    mov rax, 1000
    div rcx
    
    mov rcx, rax
    call SDL_Delay

    xor rax, rax

    mov rsp, rbp
    pop rbp
    ret