cd "$(dirname "$0")"
rm -rf out/*
cp MOTD.txt out/MOTD.txt
moonc -t out .
cd ./out
luajit src/main.lua