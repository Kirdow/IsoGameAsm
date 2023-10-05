@REM CLEANUP
rmdir /S /Q build
rmdir /S /Q dist
@REM CREATION
mkdir build
mkdir dist
@REM ASM FILES
nasm -f win64 -o build\main.obj src\main.asm
nasm -f win64 -o build\wnd.obj src\wnd.asm
@REM LINK FILES
link build\wnd.obj build\main.obj libs\SDL2.lib kernel32.lib msvcrt.lib legacy_stdio_definitions.lib /subsystem:console /entry:entry /out:dist\isogame.exe
@REM COPY FILES
copy libs\SDL2.dll dist\SDL2.dll