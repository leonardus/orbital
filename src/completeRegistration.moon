numerics = require "numerics"
socket = require "socket"

return (user) ->
	-- set the user's hostname
	ip = user.client\getpeername!
	hostname = socket.dns.tohostname(ip)
	user.hostname = hostname or ip -- rDNS, ip as fallback

	user.registered = true

	user\send numerics.RPL_WELCOME user
	user\send numerics.RPL_YOURHOST user
	user\send numerics.RPL_CREATED user
	user\send numerics.RPL_MYINFO user
	user\send numerics.RPL_ISUPPORT user
	user\send numerics.ERR_NOMOTD user