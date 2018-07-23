package.path = "../?.lua;#{package.path}"
users = require "users"

return (line, user) ->
	print "Removing user: #{user.clientText}"
	for k, _ in pairs users.connectedUsers do
		print "Connected user: [#{k}]"
	quitMessage = line.args[1]
	print user.client\getpeername!
	users.removeUser user.client, quitMessage