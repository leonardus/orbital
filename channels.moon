module = {}
module.activeChannels = {}

class Channel
	new: (name) =>
		@name = name
		@topic = nil
		@users = {}
		
	setTopic: (text) =>
		@topic = text

module.getChannel = (name) ->
	name = name\lower!
	-- create the channel if it does not exist
	unless module.activeChannels[name]
		module.activeChannels[name] = Channel name
	
	module.activeChannels[name]

module.channelExists = (name) ->
	for _, channel in pairs(module.activeChannels) do
		if channel.name\lower! == name\lower!
			return true
	return false

return module