cd "$(dirname "$0")"
moonc -t out .
cd ./out
luajit src/main.lua