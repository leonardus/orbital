users = require "users"
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
		if type(data) == "table"
			for _, segment in ipairs data do
				@handler segment
		else
			@handler data

module.createService = (name, handler) ->
	service = Service name, handler
	table.insert users.connectedUsers, service
	return service

return module