numerics = require "numerics"
socket = require "socket"
config = require "config"
motd = require "motdModule"

return (user) ->
	-- set the user's hostname
	ip = user.client\getpeername!
	hostname = socket.dns.tohostname(ip)
	if hostname and (hostname\len! <= config.maxHostnameLen)
		user.hostname = hostname
	else
		user.hostname = ip

	user.registered = true

	user\send numerics.RPL_WELCOME user
	user\send numerics.RPL_YOURHOST user
	user\send numerics.RPL_CREATED user
	user\send numerics.RPL_MYINFO user
	user\send numerics.RPL_ISUPPORT user
	motd.sendMOTD user