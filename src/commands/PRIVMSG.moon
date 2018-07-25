numerics = require "numerics"
channels = require "channels"
users = require "users"

return (line, user) ->
	target = line.args[1]
	message = line.args[2]

	unless target
		user\send ERR_NORECIPIENT user
		return

	unless message
		user\send numerics.NOTEXTTOSEND user
		return

	-- make sure user/channel exists
	unless channels.channelExists(target) or users.userFromNick(target)
		user\send numerics.ERR_NOSUCHNICK user, target
		return

	-- send the message
	textToSend = ":#{user\fullhost!} PRIVMSG #{target} :#{message}"
	if target\sub(1,1) == "#"
		channel = channels.getChannel target
	
		-- make sure the user is in the channel
		unless user\isInChannel(channel) or channel.modes.n
			user\send numerics.ERR_CANNOTSENDTOCHAN user, channel
			return

		-- do not send the message if the user is banned
		if user\bannedInChannel channel
			return

		-- deny message if channel is +m and user is not +v/o
		ops = channel.modes.o
		voiced = channel.modes.v
		userHasPermission = ops[user] or voiced[user]
		if channel.modes.m and not userHasPermission
			user\send numerics.ERR_CANNOTSENDTOCHAN user, channel
			return

		for _, userInChannel in pairs channel.users do
			if userInChannel != user
				userInChannel\send textToSend
	else
		targetUser = users.userFromNick target
		targetUser\send textToSend