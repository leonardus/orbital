package.path = "../?.lua;#{package.path}"
config = require "config"
numerics = require "numerics"
users = require "users"
completeRegistration = require "completeRegistration"

return (line, user) ->
	requestedNick = line.args[1]
	
	-- check if a nickname is given
	unless requestedNick
		user\send numerics.ERR_NONICKNAMEGIVEN user
		return
	
	-- check if the nickname is in use
	nickInUse = false
	for _, otherUser in pairs(users.connectedUsers) do
		if otherUser ~= user and otherUser.nick\lower! == requestedNick\lower!
			nickInUse = true
			break
	if nickInUse then
		user\send numerics.ERR_NICKNAMEINUSE user, requestedNick
		return
		
	-- check if nickname is valid
	if (requestedNick\match config.nickPattern) != requestedNick
		user\send numerics.ERR_ERRONEOUSNICKNAME user, requestedNick
		return
		
	user.nick = requestedNick
	user.clientText = requestedNick
	if user.username and not user.registered
		completeRegistration user