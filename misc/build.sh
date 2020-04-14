WIN32=i686-w64-mingw32
WIN64=x86_64-w64-mingw32
NIX64=gcc

FLAGS="-shared -fPIC -O1 -s"

WIN64_LIBS="-L. -Ldiscord_game_sdk/lib/x86_64 -lClassiCube -ldiscord_game_sdk"
WIN32_LIBS="-L. -Ldiscord_game_sdk/lib/x86 -lClassiCube -ldiscord_game_sdk"
NIX64_LIBS="-Ldiscord_game_sdk/lib/x86_64 -l:discord_game_sdk.so"

cd ..
mkdir -p out

echo "Compiling Nix64 Plugin"
$NIX64 -m64 Discord.c -o Discord.so $FLAGS $NIX64_LIBS -Wl,-rpath='$ORIGIN/..'
mv Discord.so out

echo "Compiling Win32 Plugin"
cp cc-w32-d3d.exe ClassiCube.exe
gendef ClassiCube.exe
$WIN32-dlltool -d ClassiCube.def -l libClassiCube.a -D ClassiCube.exe
$WIN32-gcc Discord.c -o Discord_32.dll $FLAGS $WIN32_LIBS
mv Discord_32.dll out
rm ClassiCube.def libClassiCube.a ClassiCube.exe

echo "Compiling Win64 Plugin"
cp cc-w64-d3d.exe ClassiCube.exe
gendef ClassiCube.exe
$WIN64-dlltool -d ClassiCube.def -l libClassiCube.a -D ClassiCube.exe
$WIN64-gcc Discord.c -o Discord.dll $FLAGS $WIN64_LIBS
mv Discord.dll out
rm ClassiCube.def libClassiCube.a ClassiCube.exe