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
	-- create the channel if it does not exist
	unless module.activeChannels[name]
		module.activeChannels[name] = Channel name
	
	module.activeChannels[name]

module.channelExists = (name) ->
	exists = false

	for _, channel in pairs(module.activeChannels) do
		if channel.name\lower! == name\lower!
			exists = true
			break

	exists

return module