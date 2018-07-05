module = {}
module.activeChannels = {}

class Channel
	new: (name) =>
		@name = name
		@topic = nil
		@users = {}
		@modes = {
			-- channel modes
			"b": {} -- ban
			"e": {} -- exception
			"I": {} -- invite-exception
			"l": false -- client limit
			"i": false -- invite-only
			"k": false -- key
			"m": false -- moderated
			"s": false -- secret
			"t": true -- protected topic
			"n": true -- no external messages
			
			-- channel membership prefixes
			"o": {} -- operator
			"v": {} -- voice
		}
		@clientLimit = -1 -- +l
		@key = "" -- +k

	setTopic: (text) =>
		@topic = text

	sendAll: (text) =>
		for _, channelUser in pairs @users do
			channelUser\send text

	removeUser: (user) =>
		-- remove the channel from the user's list of channels
		user.channels[@name] = nil

		-- remove the user from the channel's list of users
		for k, channelUser in pairs @users do
			if channelUser == user
				@users[k] = nil

		-- delete the channel if it is empty
		if #@users < 1
			@destroy!
	
	destroy: =>
		module.activeChannels[@name] = nil

module.getChannel = (name) ->
	name = name\lower!
	-- create the channel if it does not exist
	isNewChannel = false
	unless module.activeChannels[name]
		module.activeChannels[name] = Channel name
		isNewChannel = true
	
	module.activeChannels[name], isNewChannel

module.channelExists = (name) ->
	for _, channel in pairs(module.activeChannels) do
		if channel.name\lower! == name\lower!
			return true
	return false

return module