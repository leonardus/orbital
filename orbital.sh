cd "$(dirname "$0")"
moonc -t out .
cd ./out
lua main.lua