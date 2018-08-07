services = require "services"
sqlite3 = require "lsqlite3"
fmt = require "formatting"
dbutils = require "dbutils"

local db
commands =
	HELP: (service, query, user) ->
			service\dispatchMessage user, "NickServ allows users to register nicknames."
			service\dispatchMessage user, "Commands:"
			service\dispatchMessage user, "#{fmt.B}HELP#{fmt.B}: Displays this message."

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