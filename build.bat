@REM CLEANUP
rmdir /S /Q build
rmdir /S /Q dist
@REM CREATION
mkdir build
mkdir dist
@REM ASM FILES
nasm -f win64 -o build\main.obj src\main.asm
nasm -f win64 -o build\wnd.obj src\wnd.asm
nasm -f win64 -o build\gfx.obj src\gfx.asm
nasm -f win64 -o build\bmp.obj src\bmp.asm
nasm -f win64 -o build\col.obj src\col.asm
nasm -f win64 -o build\num.obj src\num.asm
nasm -f win64 -o build\level.obj src\level.asm
@REM LINK FILES
link build\level.obj build\col.obj build\num.obj build\bmp.obj build\gfx.obj build\wnd.obj build\main.obj libs\SDL2.lib kernel32.lib msvcrt.lib legacy_stdio_definitions.lib /subsystem:console /entry:entry /out:dist\isogame.exe
@REM COPY FILES
copy libs\SDL2.dll dist\SDL2.dll