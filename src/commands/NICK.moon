config = require "config"
numerics = require "numerics"
users = require "users"
completeRegistration = require "completeRegistration"

return (line, user) ->
	requestedNick = line.args[1]
	if requestedNick == user.nick
		return
	
	-- check if a nickname is given
	unless requestedNick
		user\send numerics.ERR_NONICKNAMEGIVEN user
		return
	
	-- check if the nickname is in use
	nickInUse = false
	for _, otherUser in pairs(users.connectedUsers) do
		if otherUser ~= user and otherUser.nick
			if otherUser.nick\lower! == requestedNick\lower!
				nickInUse = true
				break
	if nickInUse then
		user\send numerics.ERR_NICKNAMEINUSE user, requestedNick
		return
		
	-- check if nickname is valid
	invalidChars = (requestedNick\match config.nickPattern) != requestedNick
	tooLong = requestedNick\len! > config.maxNicknameLen
	if invalidChars or tooLong
		user\send numerics.ERR_ERRONEOUSNICKNAME user, requestedNick
		return

	-- send the NICK message
	nickMessage = ":#{user\fullhost!} NICK #{requestedNick}"
	usersNotified = {}
	user\send nickMessage
	usersNotified[user] = true
	for _, channel in pairs user.channels do
		for _, channelUser in pairs channel.users do
			unless usersNotified[channelUser]
				channelUser\send nickMessage
				usersNotified[channelUser] = true
		
	-- set the nickname
	user.nick = requestedNick
	user.clientText = requestedNick

	-- complete registration
	if user.username and not user.registered
		completeRegistration user