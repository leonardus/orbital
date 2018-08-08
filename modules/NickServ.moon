services = require "services"
sqlite3 = require "lsqlite3"
fmt = require "formatting"
dbutils = require "dbutils"
argon2 = require "argon2"
modutils = require "modutils"
users = require "users"

math.randomseed os.time!
saltRange = {min: 33, max: 126}
genSalt = (len) ->
	salt = ""
	for i = 1, len do
		salt ..= string.char math.random saltRange.min, saltRange.max
	return salt

local db
getDbUser = (username) ->
		nsUserQ = "SELECT * FROM NickServ WHERE username=:username"
		nsUserNt = {:username}
		nsUser = dbutils.exec_safe db, nsUserQ, nsUserNt, 1
		return nsUser

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
		userExists = dbutils.exec_safe db, userExistsQ, userExistsNt, 1
		if userExists
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

	IDENTIFY: (service, query, user) ->
		local username, password
		if query.args[2]
			username = query.args[1]
			password = query.args[2]
		elseif query.args[1]
			username = user.nick
			password = query.args[1]
		else
			service\dispatchMessage user, "Usage: /msg NickServ IDENTIFY [username] <password>"
			return

		nsUser = getDbUser user.nick

		if (not nsUser) or (not argon2.verify nsUser.password, password)
			service\dispatchMessage user, "Username and password do not match."
			return
		user.NickServ.identified = true
		user.NickServ.account = nsUser
		loginMessage = "You have been logged in as #{fmt.B}#{nsUser.username}#{fmt.B}."
		service\dispatchMessage user, loginMessage
		if nsUser.activated == 0
			service\dispatchMessage user, "Notice: Your account is not yet activated."

handler = (service, query, user) ->
	unless query.command
		return
	
	command = query.command\upper!
	if commands[command]
		commands[command] service, query, user, db

userInit = (user) ->
	user.NickServ =
		identified: false

loader = ->
	modutils.hookAction "newUser", userInit

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