module = {}
module.connectedUsers = {}
module.clients = {}

class User
	new: (client) =>
		@registered = false
		@nick = nil
		@username = nil
		@hostname = ""
		@clientText = "*" -- "<client>" text given to the numeric
		@client = client
		@channels = {}
		@channelPrefixes = {}
	
	send: (data) =>
		if type(data) == "table"
			for _, segment in ipairs data do
				@client\send "#{segment}\r\n"
				print "-> #{segment}"
		else
			@client\send "#{data}\r\n"
			print "-> #{data}"

	prefix: => ":#{@nick}!~#{@username}@#{@hostname}"

	isInChannel: (name) =>
		for _, channel in pairs @channels do
			if channel.name\lower! == name\lower!
				return true
		return false

module.createUser = (client) ->
	remoteAddress, remotePort = client\getpeername!
	module.connectedUsers["#{remoteAddress}/#{remotePort}"] = User client
	
module.getUser = (client) ->
	remoteAddress, remotePort = client\getpeername!
	return module.connectedUsers["#{remoteAddress}/#{remotePort}"]
	
module.userFromNick = (nick) ->
	for _, user in pairs module.connectedUsers do
		if user.nick\lower! == nick\lower!
			return user
	return nil
	
module.removeUser = (client) ->
	remoteAddress, remotePort = client\getpeername!
	module.connectedUsers["#{remoteAddress}/#{remotePort}"].client\close!
	module.connectedUsers["#{remoteAddress}/#{remotePort}"] = nil
	
return module