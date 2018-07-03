socket = require "socket"
parse = require "ircserverparse"
users = require "users"
commands = require "commands"
public = require "public"

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
	data = client\receive "*l"
	
	print "<- #{data}"

	if data == nil
		-- Terminate the connection
		users.removeUser client
		table.remove clients, clients[client]
		return
		
	line = parse.parseMessage data
	if line
		if line.command or line.numeric
			commands users.getUser(client), line

while true
	readable = socket.select clients
	for _, input in ipairs readable do
		if input == server
			serverReadable!
		else
			clientReadable input