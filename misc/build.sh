cd ..
rm -rf out
mkdir out

gcc Discord.c -o Discord.so -shared -fPIC -L. -l:discord_game_sdk.so -Wl,-rpath,'$ORIGIN/..'

mv Discord.so out