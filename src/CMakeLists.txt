set(CMAKE_ASM_NASM_OBJECT_FORMAT win64)

enable_language(ASM_NASM)

set(SOURCE_FILES
    gfx.asm
    main.asm
)
set_source_files_properties(${SOURCE_FILES} PROPERTIES LANGUAGE ASM_NASM)
set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <INCLUDES> <FLAGS> -f ${CMAKE_ASM_NASM_OBJECT_FORMAT} -o <OBJECT> <SOURCE>")
set(CMAKE_ASM_NASM_LINK_EXECUTABLE "gcc <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>")

include_directories(${CMAKE_SOURCE_DIR}/include)
link_directories(${CMAKE_SOURCE_DIR}/libs)

find_package(SDL2 REQUIRED)
add_executable(isogame
    ${SOURCE_FILES}
)
target_link_libraries(isogame PRIVATE SDL2::SDL2)
