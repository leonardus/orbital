users = require "users"
channels = require "channels"
numerics = require "numerics"
config = require "config"
parse = require "ircserverparse"

registrationCommands = {"NICK": true, "USER": true, "CAP": true, "QUIT": true}

commands =
	"NICK": require "commands.NICK"
	"USER": require "commands.USER"
	"CAP": require "commands.CAP"
	"MODE": require "commands.MODE"
	"JOIN": require "commands.JOIN"
	"PART": require "commands.PART"
	"PRIVMSG": require "commands.PRIVMSG"
	"TOPIC": require "commands.TOPIC"
	"QUIT": require "commands.QUIT"
	"NAMES": require "commands.NAMES"
	"KICK": require "commands.KICK"
	"PING": require "commands.PING"

return (user, line) ->
	command = line.command or line.numeric
	command = command\upper!

	unless user.registered or registrationCommands[command]
		user\send numerics.ERR_NOTREGISTERED user
		return

	if commands[command]
		commands[command] line, user