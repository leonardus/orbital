package.path = "../?.lua;#{package.path}"
users = require "users"

return (line, user) ->
	quitMessage = line.args[1]
	users.removeUser user.client, quitMessage