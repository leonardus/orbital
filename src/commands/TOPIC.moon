package.path = "../?.lua;#{package.path}"
numerics = require "numerics"
users = require "users"
channels = require "channels"

return (line, user) ->
	unless #line.args >= 1
		user\send numerics.ERR_NEEDMOREPARAMS user, "TOPIC"
		return

	target = line.args[1]
	newTopic = line.args[2]

	unless channels.channelExists target
		user\send numerics.ERR_NOSUCHCHANNEL user, target
		return

	channel = channels.getChannel target

	-- user must be in channel to view/set topic
	unless user\isInChannel channel
		user\send numerics.ERR_NOTONCHANNEL user, channel
		return

	if newTopic
		-- user must be op or channel must be -t
		if channel.modes.t and not channel.modes.o[user]
			user\send numerics.CHANOPRIVISNEEDED user, channel
			return

		-- set the topic
		utcTimestamp = os.time(os.date("!*t"))
		channel.topic = newTopic
		channel.topicFullhost = user\fullhost!
		channel.topicTime = utcTimestamp

		-- send the topic
		for _, channelUser in pairs channel.users do
			channelUser\send ":#{user\fullhost!} TOPIC #{channel.name} #{channel.topic}"

	else -- user is requesting the topic
		channel\sendTopic user