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

	if error
		print "Terminated #{client\getpeername!}: #{error}"
		-- Terminate the connection
		users.removeUser client
		table.remove clients, clients[client]
		return
	
	print "<- #{data}"
		
	line = parse.parseMessage data
	if line
		if line.command or line.numeric
			user = users.getUser(client)
			user.lastMessageTime = socket.gettime!
			user.pingSent = false
			commands user, line

ping = coroutine.create ->
	lastCheck = socket.gettime!
    while true
        timePassed = socket.gettime! - last
        if timePassed >= 1
			last = socket.gettime!
			for _, user in pairs users.connectedUsers do
				timeSinceLastMessage = socket.gettime! - user.lastMessageTime
				if timeSinceLastMessage > config.pingTimeout
					users.removeUser user.client
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

coroutine.resume listen