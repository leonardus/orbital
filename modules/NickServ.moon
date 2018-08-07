services = require "services"
sqlite3 = require "lsqlite3"
fmt = require "formatting"
dbutils = require "dbutils"
argon2 = require "argon2"

math.randomseed os.time!
saltRange = {min: 33, max: 126}
genSalt = (len) ->
	salt = ""
	for i = 1, len do
		salt ..= string.char math.random saltRange.min, saltRange.max
	return salt

local db
commands =
	HELP: (service, query, user) ->
			service\dispatchMessage user, "NickServ allows users to register nicknames."
			service\dispatchMessage user, "Commands:"
			service\dispatchMessage user, "#{fmt.B}HELP#{fmt.B}: Displays this message."

	REGISTER: (service, query, user) ->
		password = query.args[1]
		unless password
			service\dispatchMessage user, "Usage: /msg NickServ REGISTER <password>"
			return

		userExistsQ = "SELECT 1 FROM NickServ WHERE username=:username"
		userExistsNt = username: user.nick
		userExists = dbutils.exec_safe db, userExistsQ, userExistsNt
		if userExists == 1
			service\dispatchMessage user, "An account already exists with that nickname."
			return

		newUserQ = [[
			INSERT INTO NickServ (username, password, activated)
			VALUES (
				:username,
				:password,
				0
			)
		]]
		newUserNt = {
			username: user.nick
			password: argon2.hash_encoded password, genSalt 8
		}
		dbutils.exec_safe db, newUserQ, newUserNt

		service\dispatchMessage user, "Your account has been created."

handler = (service, query, user) ->
	unless query.command
		return
	
	command = query.command\upper!
	if commands[command]
		commands[command] service, query, user, db

loader = ->
	filename = "NickServ.sqlite"
	db, errorCode, errorMessage = sqlite3.open "../db/#{filename}"
	unless db
		error "Could not open database #{filename} (error #{errorCode}): #{errorMessage}"

	tableInit = [[
		CREATE TABLE IF NOT EXISTS NickServ (
			username TEXT COLLATE NOCASE,
			password TEXT,
			activated INTEGER
		);
	]]
	dbutils.exec db, tableInit

	services.createService "NickServ", handler

return loader