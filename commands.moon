users = require "users"
channels = require "channels"
numerics = require "numerics"
config = require "config"
parse = require "ircserverparse"

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
		
	"MODE": (line, user) ->
		unless #line.args >= 1
			user\send numerics.ERR_NEEDMOREPARAMS user, "MODE"
			return

		target = line.args[1]
		modestring = line.args[2]

		-- gather list of mode arguments if supplied
		modeArgsUsed = 0
		local modeArgs
		if #line.args > 2
			modeArgs = {}
			for i = 3, #line.args do
				table.insert modeArgs, line.args[i]

		-- adding or removing mode?
		action = "+"

		if target\sub(1,1) == "#"
			unless channels.channelExists target
				user\send numerics.ERR_NOSUCHCHANNEL
				return

			channel = channels.getChannel target

			if not modestring -- user is list of requesting channel modes
				user\send numerics.RPL_CHANNELMODEIS user, channel
				return

			for i = 1, modestring\len! do -- go through each mode character given
				modeChar = modestring\sub i,i

				if modeChar == "+" or modeChar == "-"
					action = modeChar
					continue

				-- make sure mode exists before proceeding
				unless channel.modeTypes[modeChar]
					user\send numerics.ERR_UNKNOWNMODE user, modeChar
					continue

				modeType = channel.modeTypes[modeChar]
				if modeType == "A" and not modeArgs -- requesting a list
					switch modeChar
						when "b"
							user\send numerics.RPL_BANLIST user, channel
						when "e"
							user\send numerics.RPL_EXCEPTLIST user, channel
						when "I"
							user\send numerics.RPL_INVITELIST user, channel
				else -- setting a mode
					--user must be operator
					unless channel.modes.o[user]
						user\send numerics.ERR_CHANOPRIVISNEEDED
						return

					-- get argument if mode accepts an argument
					local argToUse
					acceptsAdd =  action == "+" and modeType != "D"
					acceptsRemove = action == "-" and modeType == "A" or modeType == "B"
					if acceptsAdd or acceptsRemove
						-- requires args, no args given
						if not modeArgs
							continue
						
						-- get the next argument given
						modeArgsUsed += 1
						argToUse = modeArgs[modeArgsUsed]

					switch modeChar
						when "b", "e", "I", "v", "o"
							if argToUse
								if action == "+"
									channel.modes[modeChar][argToUse] = true
								else
									channel.modes[modeChar][argToUse] = nil
						when "k"
							if argToUse
								if action == "+"
									channel.modes[modeChar] = argToUse
								else
									channel.modes[modeChar] = nil
						when "l"
							if action == "+"
								if argToUse
									channel.modes[modeChar] = tonumber argToUse
							else
								channel.modes[modeChar] = nil
						when "i", "m", "s", "t", "n"
							if action == "+"
								channel.modes[modeChar] = true
							else
								channel.modes[modeChar] = nil

		else -- target is a nick
			unless users.userFromNick target
				user\send numerics.ERR_NOSUCHNICK
				return
			
			-- users cannot set modes on other users
			unless target\lower! == user.nick\lower!
				user\send numerics.ERR_USERSDONTMATCH
				return

			unless modestring
				user\send numerics.UMODEIS user
				return

	"JOIN": (line, user) ->
		unless #line.args >= 1
			user\send numerics.ERR_NEEDMOREPARAMS user, "JOIN"
			return
		
		channelList = parse.explodeCommas(line.args[1])

		for _, requestedChannel in ipairs channelList do
			-- if the user is already in the channel, do nothing
			if user.channels[requestedChannel\lower!]
				continue
			
			-- ensure the channel name is valid
			chantype = requestedChannel\sub 1,1
			if chantype != "#"
				user\send numerics.NOSUCHCHANNEL user, requestedChannel
				continue
			
			channel, isNewChannel = channels.getChannel requestedChannel
			
			user.channels[channel.name] = channel
			table.insert channel.users, user
			
			-- set the user's channel prefix
			local prefix
			if isNewChannel -- first user in channel
				channel.modes.o[user] = true
				prefix = "@"
			else
				prefix = ""
			user.channelPrefixes[requestedChannel] = prefix
			
			-- send the JOIN message to all the users in the channel
			for _, channelUser in pairs channel.users do
				channelUser\send ":#{user\fullhost!} JOIN #{requestedChannel}"
				
			-- send the channel topic
			if channel.topic
				user\send numerics.RPL_TOPIC user, channel
				
			-- send NAMES reply
			user\send numerics.RPL_NAMREPLY user, channel
		
	"PART": (line, user) ->
		unless #line.args >= 1
			user\send numerics.ERR_NEEDMOREPARAMS user, "PART"
			return
		
		channelList = parse.explodeCommas(line.args[1])

		for _, requestedChannel in ipairs channelList do
			channel = user.channels[requestedChannel\lower!]
			unless channel
				user\send numerics.ERR_NOTONCHANNEL user, requestedChannel
				continue
			
			-- ensure the channel name is valid
			chantype = requestedChannel\sub 1,1
			if chantype != "#"
				user\send numerics.NOSUCHCHANNEL user, requestedChannel
				continue
				
			-- send the PART message to all users in the channel
			channel\sendAll ":#{user\fullhost!} PART #{channel.name}"

			-- remove the user from the channel
			channel\removeUser user
	
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
		textToSend = ":#{user\fullhost!} PRIVMSG #{target} :#{message}"
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