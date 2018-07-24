package.path = "../?.lua;#{package.path}"
users = require "users"
channels = require "channels"
numerics = require "numerics"
parse = require "ircserverparse"

return (line, user) ->
	requestedChannels = line.args[1]

	unless requestedChannels
		user\send numerics.ERR_NEEDMOREPARAMS user, "NAMES"
		return

	channelList = parse.explodeCommas requestedChannels
	for _, channelName in pairs channelList do
		unless channels.channelExists channelName
			user\send numerics.ERR_NOSUCHCHANNEL user, channelName
			continue

		channel = channels.getChannel channelName
		user\send numerics.RPL_NAMREPLY user, channel