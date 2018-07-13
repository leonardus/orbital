package.path = "../?.lua;#{package.path}"
numerics = require "numerics"
users = require "users"
channels = require "channels"

applyAction = (action, positive=true) ->
	if action == "+"
		return positive
	else
		return nil

return (line, user) ->
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
					when "b", "e", "I"
						if argToUse
							channel.modes[modeChar][argToUse] = applyAction action
					when "v", "o"
						nick = argToUse
						targetUser = users.userFromNick nick
						unless targetUser
							user\send numerics.ERR_NOSUCHNICK user, nick
							continue

						unless targetUser\isInChannel channel
							user\send numerics.ERR_USERNOTINCHANNEL user, nick, channel
							continue

						channel.modes[modeChar][targetUser] = applyAction action
						targetUser\updatePrefix channel
					when "k"
						if argToUse
							channel.modes[modeChar] = applyAction action, argToUse
					when "l"
						if action == "+"
							if argToUse
								channel.modes[modeChar] = tonumber argToUse
						else
							channel.modes[modeChar] = nil
					when "i", "m", "s", "t", "n"
						channel.modes[modeChar] = applyAction action

	else -- target is a nick
		unless users.userFromNick target
			user\send numerics.ERR_NOSUCHNICK
			return
		
		-- users cannot set modes on other users
		unless target\lower! == user.nick\lower!
			user\send numerics.ERR_USERSDONTMATCH user
			return

		unless modestring
			user\send numerics.UMODEIS user
			return