services = require "services"
sqlite3 = require "lsqlite3"
fmt = require "formatting"
dbutils = require "dbutils"
argon2 = require "argon2"
modutils = require "modutils"
users = require "users"
config = require "config"

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

		-- apply cloak
		cloak = user.NickServ.account.cloak
		if cloak and user.NickServ.account.cloak_enabled
			user\applyCloak cloak
	
	CLOAK: (service, query, user) ->
		targetNick = query.args[1]
		action = query.args[2]
		newCloak = query.args[3]
		
		unless user.NickServ.identified
			service\dispatchMessage user, "You must be identified to run this command."
			return

		unless user.NickServ.account.admin == 1
			service\dispatchMessage user, "You must be an administrator to run this command."
			return
		
		usageMessage = "Usage: /msg NickServ CLOAK <target> <ON/OFF> [cloak]"
		unless targetNick and action
			service\dispatchMessage user, usageMessage
			return

		actionCaps = action\upper!
		targetUser = users.userFromNick targetNick
		unless targetUser and targetUser.NickServ.identified
			service\dispatchMessage "That user is not currently identified to NickServ."
			return
		if actionCaps == "OFF"
			disableCloakQ = "UPDATE NickServ SET cloak_enabled=0 WHERE username=:username"
			disableCloakNt = {username:targetNick}
			dbutils.exec_safe db, disableCloakQ, disableCloakNt
			targetUser\applyCloak nil
			targetUser.NickServ.account = getDbUser targetNick
			service\dispatchMessage user, "Disabled cloak for user #{targetNick}."
		elseif actionCaps == "ON"
			-- set the cloak in the NickServ database
			if newCloak
				if newCloak\len! > config.maxHostnameLen
					service\dispatchMessage user, "Cloak exceeds maximum hostname length, ignoring."
					return
				
				setCloakQ = "UPDATE NickServ SET cloak=:cloak WHERE username=:username"
				setCloakNt = {cloak:newCloak, username:targetNick}
				dbutils.exec_safe db, setCloakQ, setCloakNt
			elseif targetUser.NickServ.cloak == nil
				service\dispatchMessage "That user does not have a cloak set."
				return

			-- flag the new cloak as enabled
			enableCloakQ = "UPDATE NickServ SET cloak_enabled=1 WHERE username=:username"
			enableCloakNt = {username:targetNick}
			dbutils.exec_safe db, enableCloakQ, enableCloakNt
			
			-- apply the new cloak
			oldHost = targetUser.cloak or targetUser.hostname
			targetUser\applyCloak newCloak
			targetUser.NickServ.account = getDbUser targetNick
			cloakSetMsg = "Updated hostname of #{targetNick} from #{oldHost} to #{newCloak}"
			service\dispatchMessage user, cloakSetMsg
		else
			service\dispatchMessage user, "Unknown action: \"#{action}\""

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
			activated INTEGER,
			cloak TEXT,
			cloak_enabled INTEGER,
			admin INTEGER
		);
	]]
	dbutils.exec db, tableInit

	services.createService "NickServ", handler

return loader