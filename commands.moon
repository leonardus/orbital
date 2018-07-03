users = require "users"
channels = require "channels"
numerics = require "numerics"
config = require "config"

completeRegistration = (user) ->
	-- set the user's hostname
	ip = user.client\getpeername!
	hostname = socket.dns.tohostname(ip)
	user.hostname = hostname or ip -- rDNS, ip as fallback

	user.registered = true

	user\send numerics.RPL_WELCOME user
	user\send numerics.RPL_YOURHOST user
	user\send numerics.RPL_CREATED user
	user\send numerics.RPL_MYINFO user
	user\send numerics.RPL_ISUPPORT user
	user\send numerics.ERR_NOMOTD user

commands =
	"NICK": (line, user) ->
		requestedNick = line.args[1]
		
		-- check if a nickname is given
		unless requestedNick
			user\send numerics.ERR_NONICKNAMEGIVEN user
			return
		
		-- check if the nickname is in use
		nickInUse = false
		for _, otherUser in pairs(users.connectedUsers) do
			if otherUser ~= user and otherUser.nick\lower! == requestedNick\lower!
				nickInUse = true
				break
		if nickInUse then
			user\send numerics.ERR_NICKNAMEINUSE user, requestedNick
			return
			
		-- check if nickname is valid
		if (requestedNick\match config.nickPattern) != requestedNick
			user\send numerics.ERR_ERRONEOUSNICKNAME user, requestedNick
			return
			
		user.nick = requestedNick
		user.clientText = requestedNick
		if user.username and not user.registered
			completeRegistration user
		
	"USER": (line, user) ->
		requestedUsername = line.args[1] -- TODO: check for illegal characters in username?
		zero = line.args[2]
		asterisk = line.args[3]
		realname = line.args[4] -- TODO: limit the length of realname?
		
		-- check if the user is registered
		if user.registered
			user\send numerics.ERR_ALREADYREGISTERED user
			return
		
		-- check if enough arguments, dont care about 2nd and 3rd params
		unless requestedUsername and realname
			user\send numerics.ERR_NEEDMOREPARAMS user, "USER"
			return
			
		-- silently truncate the username if it's too long
		if requestedUsername\len! > config.maxUsernameLen
			requestedUsername = requestedUsername\sub 1,config.maxUsernameLen
			
		-- grant the user the username and mark the user as registered
		user.username = requestedUsername
		if user.nick
			completeRegistration user

	"CAP": (line, user) -> -- needs to be implemented
		unless #line.args >= 1
			user\send numerics.ERR_NEEDMOREPARAMS user, "CAP"
			return
		
		subcommand = line.args[1]
		
		
	"JOIN": (line, user) ->
		unless #line.args >= 1
			user\send numerics.ERR_NEEDMOREPARAMS user, "CAP"
			return
		
		channelList = line.args

		for _, requestedChannel in ipairs channelList do
			-- if the user is already in the channel, do nothing
			for _, channel in pairs user.channels do
				if channel.name == requestedChannel
					return
			
			-- ensure the channel name is valid
			chantype = requestedChannel\sub 1,1
			if chantype != "#"
				user\send numerics.NOSUCHCHANNEL user, requestedChannel
				return
			
			channel = channels.getChannel requestedChannel
			
			table.insert user.channels, channel
			table.insert channel.users, user
			
			user.channelPrefixes[requestedChannel] = ""
			
			-- send the JOIN message to all the users in the channel
			for _, channelUser in pairs channel.users do
				channelUser\send ":#{user\prefix!} JOIN #{requestedChannel}"
				
			-- send the channel topic
			if channel.topic
				user\send numerics.RPL_TOPIC user, channel
				
			-- send NAMES reply
			user\send numerics.RPL_NAMREPLY user, channel
	
	"PRIVMSG": (line, user) ->
		target = line.args[1]
		message = line.args[2]

		unless target
			user\send ERR_NORECIPIENT user
			return

		unless message
			user\send numerics.NOTEXTTOSEND user
			return

		-- make sure user/channel exists
		unless channels.channelExists(target) or users.userFromNick(target)
			user\send numerics.ERR_NOSUCHNICK user, target
			return
		
		-- make sure the user is in the channel
		if target\sub(1,1) == "#" and not user\isInChannel target
			user\send numerics.ERR_CANNOTSENDTOCHAN user, target
			return

		-- send the message
		textToSend = ":#{user\prefix!} PRIVMSG #{target} :#{message}"
		if target\sub(1,1) == "#"
			channel = channels.getChannel target
			for _, userInChannel in pairs channel.users do
				if userInChannel != user
					userInChannel\send textToSend
		else
			user = users.userFromNick target
			user\send textToSend

return (user, line) ->
	command = line.command or line.numeric
	if commands[command]
		commands[command] line, user