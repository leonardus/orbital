config = require "config"
numerics = require "numerics"
completeRegistration = require "completeRegistration"

return (line, user) ->
	requestedUsername = line.args[1] -- TODO: check for illegal characters in username?
	zero = line.args[2]
	asterisk = line.args[3]
	realname = line.args[4] -- TODO: limit the length of realname?
	
	-- check if the user is registered
	if user.registered
		user\send numerics.ERR_ALREADYREGISTERED user
		return
	
	-- check if enough arguments, dont care about 2nd and 3rd params
	unless requestedUsername and realname
		user\send numerics.ERR_NEEDMOREPARAMS user, "USER"
		return
		
	-- silently truncate the username if it's too long
	if requestedUsername\len! > config.maxUsernameLen
		requestedUsername = requestedUsername\sub 1,config.maxUsernameLen
		
	-- grant the user the username and mark the user as registered
	user.username = requestedUsername
	if user.nick
		completeRegistration user