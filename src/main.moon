package.path = "./?.lua;#{package.path}"

socket = require "socket"
parse = require "ircserverparse"
users = require "users"
commands = require "commands"
public = require "public"
config = require "config"

public.created = os.time!

clients = {}
server = socket.bind "localhost", 6667
table.insert clients, server

serverReadable = ->
	newClient = server\accept!
	if newClient
		users.createUser newClient
		table.insert clients, newClient
		
clientReadable = (client) ->
	data, error = client\receive "*l"
	return if error
	
	print "<- #{data}"
		
	line = parse.parseMessage data
	if line
		if line.command or line.numeric
			user = users.userFromClient(client)
			user.lastMessageTime = socket.gettime!
			user.pingSent = false
			commands user, line

ping = coroutine.create ->
	lastCheck = socket.gettime!
	while true
		timePassed = socket.gettime! - lastCheck
		if timePassed >= config.pingPollRate
			lastCheck = socket.gettime!
			for _, user in pairs users.connectedUsers do
				if user.isService -- don't ping services
					continue

				timeSinceLastMessage = socket.gettime! - user.lastMessageTime
				if timeSinceLastMessage > config.pingTimeout
					roundedTimeout = math.floor(timeSinceLastMessage + 0.5)
					quitMessage = "Ping timeout: #{roundedTimeout} seconds"
					users.removeUser user.client, quitMessage
					table.remove clients, clients[user.client]
				elseif (timeSinceLastMessage > config.pingTimeout/2) and not user.pingSent
					user\send ":#{config.source} PING"
					user.pingSent = true
		else
			coroutine.yield!

listen = coroutine.create ->
	while true
		readable = socket.select clients, nil, 0
		if #readable > 0
			for _, input in ipairs readable do
				if input == server
					serverReadable!
				else
					clientReadable input
		else
			coroutine.resume ping

success, errorMessage = coroutine.resume listen

unless success
	print "Something happened! #{errorMessage}"
	print debug.traceback(listen)
	print "Please report this error along with the traceback."