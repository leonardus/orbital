cd "$(dirname "$0")"
moonc -t out .
cd ./out
lua src/main.lua