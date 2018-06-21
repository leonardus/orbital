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

return module