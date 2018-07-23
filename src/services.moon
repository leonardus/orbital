users = require "users"
parse = require "ircserverparse"
User = users.userClass

module = {}

class Service extends User
	new: (name, handler) =>
		super\new!
		@isService = true
		@handler = handler
		@registered = true
		@nick = name
		@username = name
		@hostname = "services."
		@modes.r = true

	send: (data) =>
		lineParsed = parse.parseMessage data
		command = lineParsed.command\upper!
		target = lineParsed.args[1]\lower!
		if command == "PRIVMSG" and target == @username\lower!
			fullhost = lineParsed.source
			fullhostParsed = parse.parseFullhost source
			user = users.userFromNick fullhost.user

			query = lineParsed.args[2]
			queryParsed = parse.parseServiceCommand query
			
			@handler queryParsed, user

module.createService = (name, handler) ->
	service = Service name, handler
	table.insert users.connectedUsers, service
	return service

return module