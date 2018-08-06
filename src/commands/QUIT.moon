users = require "users"

return (line, user) ->
	quitMessage = line.args[1]
	user\remove quitMessage