Entity = require "entity"
socket = require "socket"
parse = require "ircserverparse"

module = {}
module.connectedUsers = {}
module.clients = {}

class User extends Entity
	new: (client) =>
		@registered = false
		@nick = nil
		@username = nil
		@hostname = ""
		@clientText = "*" -- "<client>" text given to the numeric
		@client = client
		@channels = {}
		@channelPrefixes = {}
		@validModes = {"i": true, "o": true, "r": true}
		@modes = {
			"i": true
			"o": nil
			"r": nil
		}
		@lastMessageTime = socket.gettime!
		@pingSent = false
	
	send: (data) =>
		if type(data) == "table"
			for _, segment in ipairs data do
				@client\send "#{segment}\r\n"
				print "-> #{segment}"
		else
			@client\send "#{data}\r\n"
			print "-> #{data}"

	fullhost: => "#{@nick}!~#{@username}@#{@hostname}"

	isInChannel: (channel) =>
		for _, userChannel in pairs @channels do
			if userChannel.name\lower! == channel.name\lower!
				return true
		return false

	isInList: (list) =>
		for hostmask, _ in pairs list do
			if parse.matchesWithWildcard hostmask, @fullhost!
				return true
		return false

	bannedInChannel: (channel) =>
		isBanned = @isInList channel.modes.b
		hasExcepti2on = @isInList channel.modes.e
		return isBanned and not hasException

	updatePrefix: (channel) =>
		hasOp = channel.modes.o[self]
		hasVoice = channel.modes.v[self]

		if hasOp
			@channelPrefixes[channel] = "@"
		elseif hasVoice
			@channelPrefixes[channel] = "+"
		else
			@channelPrefixes[channel] = ""

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