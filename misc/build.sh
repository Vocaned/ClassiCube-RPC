WIN32=i686-w64-mingw32
WIN64=x86_64-w64-mingw32

FLAGS="-shared -fPIC -O1 -s"
FLAGS_NIX64="-Wl,-rpath='$ORIGIN/..'"

WIN64_CLIENT="cc-w64-d3d"
WIN32_CLIENT="cc-w32-d3d"

WIN64_LIBS="-L. -Ldiscord_game_sdk/lib/x86_64 -l$WIN64_CLIENT -ldiscord_game_sdk"
WIN32_LIBS="-L. -Ldiscord_game_sdk/lib/x86 -l$WIN32_CLIENT -ldiscord_game_sdk"
NIX64_LIBS="-Ldiscord_game_sdk/lib/x86_64 -l:discord_game_sdk.so"

cd ..
mkdir -p out

echo "Compiling Nix64 Plugin"
gcc -m64 Discord.c -o Discord.so $FLAGS $FLAGS_NIX64
mv Discord.so out

echo "Compiling Win32 Plugin"
gendef $WIN32_CLIENT.exe
$WIN32-dlltool -d $WIN32_CLIENT.def -l lib$WIN32_CLIENT.a -D $WIN32_CLIENT.exe
$WIN32-gcc Discord.c -o Discord_32.dll $FLAGS $WIN32_LIBS
mv Discord_32.dll out
rm $WIN32_CLIENT.def lib$WIN32_CLIENT.a

echo "Compiling Win64 Plugin"
gendef $WIN64_CLIENT.exe
$WIN64-dlltool -d $WIN64_CLIENT.def -l lib$WIN64_CLIENT.a -D $WIN64_CLIENT.exe
$WIN64-gcc Discord.c -o Discord.dll $FLAGS $WIN64_LIBS
mv Discord.dll out
rm $WIN64_CLIENT.def lib$WIN64_CLIENT.a