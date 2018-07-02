config = require "config"
public = require "public"
source = config.source

return {
	RPL_WELCOME: (user) ->
		networkName = config.networkName
		nick = user.nick
		username = user.userText
		host = user.client\getpeername!
		":#{source} 001 #{user.userText} :Welcome to the #{networkName} network, #{nick}!~#{username}@#{host}"
	RPL_YOURHOST: (user) ->
		servername = config.serverName
		version = config.version
		":#{source} 002 #{user.userText} :Your host is #{servername}, running version #{version}"
	RPL_CREATED: (user) ->
		date = os.date config.dateFormat, public.created
		time = os.date config.timeFormat, public.created
		":#{source} 003 #{user.userText} :This server was created #{date} at #{time}"
	RPL_MYINFO: (user) ->
		usermodes = "o"
		channelmodes = "i"
		servername = config.serverName
		version = config.version
		":#{source} 004 #{user.userText} #{servername} #{version} #{usermodes} #{channelmodes}"
	RPL_ISUPPORT: (user) ->
		":#{source} 005 #{user.userText} CASEMAPPING=ascii CHANLIMIT=#: CHANNELLEN=50 CHANTYPES=# ELIST=MU HOSTLEN=64 KICKLEN=255 MAXLIST=b:127 NICKLEN=20 PREFIX=(ov)@+ STATUSMSG=@+ TOPICLEN=255 USERLEN=20 :are supported by this server"
	RPL_TOPIC: (user, channel) ->
		":#{source} 332 #{user.userText} #{channel.name} :#{channel.topic}"
	RPL_NAMREPLY: (user, channel) ->
		-- TODO: multiple users per line
		data = {}
		base = ":#{source} 353 #{user.userText} = #{channel.name} :"
		--available = 510 - base\len!
		
		for _, userInChannel in pairs channel.users do
			prefix = userInChannel.channelPrefixes[channel.name]
			table.insert data, "#{base}#{prefix}#{userInChannel.nick}"
		
		data
	ERR_NOSUCHCHANNEL: (user, channel) ->
		":#{source} 403 #{user.userText} #{channel} :No such channel"
	ERR_INVALIDCAPCMD: (command) ->
		":#{source} 410 * #{command} :Invalid CAP command"
	ERR_NOMOTD: (user) ->
		":#{source} 422 #{user.userText} :MOTD File is missing"
	ERR_NONICKNAMEGIVEN: (user) ->
		":#{source} 431 #{user.userText} :No nickname given"
	ERR_ERRONEOUSNICKNAME: (user, nick) ->
		":#{source} 432 #{user.userText} #{nick} :Erroneous nickname"
	ERR_NICKNAMEINUSE: (user, nick) ->
		":#{source} 433 #{user.userText} #{nick} :Nickname is already in use"
	ERR_NEEDMOREPARAMS: (user, command) ->
		":#{source} 461 #{user.userText} #{command} :Not enough parameters"
	ERR_ALREADYREGISTERED: (user) ->
		":#{source} 462 #{user.userText} :You may not reregister"
}