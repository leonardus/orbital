services = require "services"
sqlite3 = require "lsqlite3"

local db
commands = {}

handler = (service, query, user) ->
	unless query.command
		return
	
	command = query.command\upper!
	if commands[command]
		commands[command] service, query, user, db

loader = ->
	filename = "NickServ.sqlite"
	db, errorCode, errorMessage = sqlite3.open "./db/NickServ.sqlite"
	unless db
		error "Could not open database #{filename} (error #{errorCode}): #{errorMessage}"

	services.createService "NickServ", handler

return loader