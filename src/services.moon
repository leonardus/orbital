users = require "users"
parse = require "ircserverparse"
User = users.userClass

module = {}

class Service extends User
	new: (name, handler) =>
		super!
		@isService = true
		@handler = handler
		@registered = true
		@nick = name
		@username = name
		@hostname = "services."
		@modes.r = true

	send: (data) =>
		queryParsed = parse.parseServiceCommand data.query
		
		@handler queryParsed, data.user

	dispatchMessage: (user, message) =>
		user\send ":#{@fullhost!} PRIVMSG #{user.nick} :#{message}"

module.createService = (name, handler) ->
	service = Service name, handler
	table.insert users.connectedUsers, service
	print "* Created service \"#{name}\""
	return service

return module