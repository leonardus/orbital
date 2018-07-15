package.path = "../?.lua;#{package.path}"
numerics = require "numerics"
users = require "users"
channels = require "channels"

buildAction = (modes) ->
	responseModes = ""
	responseArgs = ""
	for _, mode in pairs modes do
		responseModes ..= mode.char
		if mode.arg
			responseArgs ..= mode.arg
	return responseModes, responseArgs

buildResponse = (modesSet, target) ->
	modeResponse = "MODE #{target} "
	responseArgs = " "
	if #modesSet["+"] > 0
		modeResponse ..= "+"
		concatResponse, concatArgs = buildAction modesSet["+"]
		modeResponse ..= concatResponse
		responseArgs ..= concatArgs
	if #modesSet["-"] > 0
		modeResponse ..= "-"
		concatResponse, concatArgs = buildAction modesSet["-"]
		modeResponse ..= concatResponse
		responseArgs ..= concatArgs

	if responseArgs\len! > 1
		modeResponse ..= responseArgs

	return modeResponse

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

	modesSet = {
		"+": {}
		"-": {}
	}

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
			user\send numerics.ERR_NOSUCHCHANNEL user, target
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
						alreadySet = channel.modes[modeChar][argToUse] == applyAction action
						continue if alreadySet

						channel.modes[modeChar][argToUse] = applyAction action
						table.insert modesSet[action], {char: modeChar, arg: argToUse}
					when "v", "o"
						nick = argToUse
						targetUser = users.userFromNick nick
						unless targetUser
							user\send numerics.ERR_NOSUCHNICK user, nick
							continue

						unless targetUser\isInChannel channel
							user\send numerics.ERR_USERNOTINCHANNEL user, nick, channel
							continue

						alreadySet = channel.modes[modeChar][targetUser] == applyAction action
						continue if alreadySet

						channel.modes[modeChar][targetUser] = applyAction action
						targetUser\updatePrefix channel
						table.insert modesSet[action], {char: modeChar, arg: targetUser.nick}
					when "k"
						alreadySet = channel.modes[modeChar] == applyAction action, argToUse
						continue if alreadySet

						channel.modes[modeChar] = applyAction action, argToUse
						table.insert modesSet[action], {char: modeChar}
					when "l"
						if action == "+"
							alreadySet = channel.modes[modeChar] == tonumber argToUse
							continue if alreadySet

							channel.modes[modeChar] = tonumber argToUse
							table.insert modesSet[action], {char: modeChar, arg: argToUse}
						else
							alreadySet = channel.modes[modeChar] == nil
							continue if alreadySet

							channel.modes[modeChar] = nil
							table.insert modesSet[action], {char: modeChar}
					when "i", "m", "s", "t", "n"
						alreadySet = channel.modes[modeChar] == applyAction action
						continue if alreadySet

						channel.modes[modeChar] = applyAction action
						table.insert modesSet[action], {char: modeChar}
		
		if (#modesSet["+"] > 0) or (#modesSet["-"] > 0)
			modeResponse = buildResponse modesSet, target
			channel\sendAll ":#{user\fullhost!} #{modeResponse}"
	
	else -- target is a nick
		unless users.userFromNick target
			user\send numerics.ERR_NOSUCHNICK
			return
		
		-- users cannot set modes on other users
		unless target\lower! == user.nick\lower!
			user\send numerics.ERR_USERSDONTMATCH user
			return

		unless modestring
			user\send numerics.RPL_UMODEIS user
			return

		for i = 1, modestring\len! do -- go through each mode character given
			modeChar = modestring\sub i,i

			if modeChar == "+" or modeChar == "-"
				action = modeChar
				continue

			-- make sure mode exists before proceeding
			unless user.validModes[modeChar]
				user\send numerics.ERR_UNKNOWNMODE user, modeChar
				continue

			switch modeChar
				when "i"
					user.modes[modeChar] = applyAction action
					table.insert modesSet[action], {char: modeChar}
		
		if (#modesSet["+"] > 0) or (#modesSet["-"] > 0)
			modeResponse = buildResponse modesSet, target
			user\send ":#{user\fullhost!} #{modeResponse}"
