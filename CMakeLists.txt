cmake_minimum_required(VERSION 3.14)
project(asm_isogame LANGUAGES ASM_NASM)

# include(FetchContent)

set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL2_DISABLE_SDL2MAIN OFF CACHE BOOL "" FORCE)

# FetchContent_Declare(sdl GIT_REPOSITORY https://github.com/libsdl-org/SDL.git GIT_TAG release-2.24.2)
# FetchContent_MakeAvailable(sdl)

if (CMAKE_SYSTEM_PROCESSOR MATCHES AMD64)
    add_subdirectory(src)
endif()
