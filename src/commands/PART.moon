package.path = "../?.lua;#{package.path}"
numerics = require "numerics"
parse = require "ircserverparse"

return (line, user) ->
	unless #line.args >= 1
		user\send numerics.ERR_NEEDMOREPARAMS user, "PART"
		return
	
	channelList = parse.explodeCommas(line.args[1])

	for _, requestedChannel in ipairs channelList do
		channel = user.channels[requestedChannel\lower!]
		unless channel
			user\send numerics.ERR_NOTONCHANNEL user, requestedChannel
			continue
		
		-- ensure the channel name is valid
		chantype = requestedChannel\sub 1,1
		if chantype != "#"
			user\send numerics.NOSUCHCHANNEL user, requestedChannel
			continue
			
		-- send the PART message to all users in the channel
		channel\sendAll ":#{user\fullhost!} PART #{channel.name}"

		-- remove the user from the channel
		channel\removeUser user