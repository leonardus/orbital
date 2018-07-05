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