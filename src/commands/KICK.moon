package.path = "../?.lua;#{package.path}"
users = require "users"
channels = require "channels"
numerics = require "numerics"

return (line, user) ->
	channelName = line.args[1]
	nick = line.args[2]
	reason = line.args[3]

	unless channelName and nick
		user\send numerics.ERR_NEEDMOREPARAMS user, "KICK"
		return
	
	-- channel must exist
	unless channels.channelExists channelName
		user\send numerics.ERR_NOSUCHCHANNEL user, channelName

	channel = channels.getChannel channelName

	-- user must be on channel
	unless user\isInChannel channel
		user\send numerics.ERR_NOTONCHANNEL user, channelName
		return

	-- user must be a channel operator
	unless channel.modes.o[user]
		user\send numerics.ERR_CHANOPRIVISNEEDED user, channel
		return

	targetUser = users.userFromNick nick

	-- target user must exist
	unless targetUser
		user\send numerics.ERR_NOSUCHNICK user, nick
		return

	-- target user must be on the channel
	unless targetUser\isInChannel channel
		user\send numerics.ERR_USERNOTINCHANNEL user, nick, channel
		return
			
	-- send the KICK message to all users in the channel
	kickMessage = ":#{user\fullhost!} KICK #{channel.name} #{targetUser.nick}"
	if reason
		kickMessage ..= " :#{reason}"
	channel\sendAll kickMessage

	-- remove the user from the channel
	channel\removeUser targetUser