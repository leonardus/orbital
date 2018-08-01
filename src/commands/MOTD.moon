motd = require "motdModule"

return (line, user) ->
	motd.sendMOTD user