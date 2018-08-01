services = require "services"

commands = {}

handler = (service, query, user) ->
	unless query.command
		return
	
	command = query.command\upper!
	if commands[command]
		commands[command] service, query, user

loader = ->
	services.createService "NickServ", handler

return loader