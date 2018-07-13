package.path = "../?.lua;#{package.path}"
numerics = require "numerics"
channels = require "channels"
parse = require "ircserverparse"

return (line, user) ->
	unless #line.args >= 1
		user\send numerics.ERR_NEEDMOREPARAMS user, "JOIN"
		return
	
	channelList = parse.explodeCommas(line.args[1])

	for _, requestedChannel in ipairs channelList do
		-- if the user is already in the channel, do nothing
		if user.channels[requestedChannel\lower!]
			continue
		
		-- ensure the channel name is valid
		chantype = requestedChannel\sub 1,1
		if chantype != "#"
			user\send numerics.NOSUCHCHANNEL user, requestedChannel
			continue
		
		channel, isNewChannel = channels.getChannel requestedChannel

		-- deny the user entry if they are banned
		if user\bannedInChannel channel
			user\send numerics.ERR_BANNEDFROMCHAN user, channel
			continue

		-- if the channel is +i, make sure the user is invited
		isExcepted = user\isInList channel.modes.I
		if channel.modes.i and not isExcepted
			user\send numerics.ERR_INVITEONLYCHAN user, channel
			continue

		-- check if channel limit has been reached
		if channel.modes.l and #channel.users >= channel.modes.l
			user\send numerics.ERR_CHANNELISFULL user, channel
			continue
		
		user.channels[channel.name] = channel
		table.insert channel.users, user
		
		-- set the user's channel prefix
		local prefix
		if isNewChannel -- first user in channel
			channel.modes.o[user] = true
			prefix = "@"
		else
			prefix = ""
		user.channelPrefixes[channel] = prefix
		
		-- send the JOIN message to all the users in the channel
		for _, channelUser in pairs channel.users do
			channelUser\send ":#{user\fullhost!} JOIN #{requestedChannel}"
			
		-- send the channel topic
		if channel.topic
			user\send numerics.RPL_TOPIC user, channel
			
		-- send NAMES reply
		user\send numerics.RPL_NAMREPLY user, channel