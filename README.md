# Orbital
Orbital promotes the decentralizaton of IRC by making it easy to run and maintain a private IRC server.

## Installation
### Ubuntu
1. Install git, luarocks, and sqlite3 development files: `sudo apt install git luarocks libsqlite3-dev`
2. Install luarocks dependencies:
	* `luarocks install moonscript --local`
	* `luarocks install lsqlite3 --local`
	* `luarocks install argon2-ffi --local`
3. Download Orbital: `git clone https://github.com/leonardus//orbital.git`
4. Run Orbital: `bash orbital/orbital.sh`

## Support
**IRC**: `#orbital` @ `chat.freenode.net`