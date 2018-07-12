config = require "config"
public = require "public"
source = config.source

return {
	RPL_WELCOME: (user) ->
		networkName = config.networkName
		nick = user.nick
		host = user.client\getpeername!
		":#{source} 001 #{user.clientText} :Welcome to the #{networkName} network, #{nick}!~#{user.username}@#{host}"
	RPL_YOURHOST: (user) ->
		servername = config.serverName
		version = config.version
		":#{source} 002 #{user.clientText} :Your host is #{servername}, running version #{version}"
	RPL_CREATED: (user) ->
		date = os.date config.dateFormat, public.created
		time = os.date config.timeFormat, public.created
		":#{source} 003 #{user.clientText} :This server was created #{date} at #{time}"
	RPL_MYINFO: (user) ->
		usermodes = "o"
		channelmodes = "i"
		servername = config.serverName
		version = config.version
		":#{source} 004 #{user.clientText} #{servername} #{version} #{usermodes} #{channelmodes}"
	RPL_ISUPPORT: (user) ->
		":#{source} 005 #{user.clientText} CASEMAPPING=ascii CHANLIMIT=#: CHANNELLEN=50 CHANTYPES=# ELIST=MU HOSTLEN=64 KICKLEN=255 MAXLIST=b:127 NICKLEN=20 PREFIX=(ov)@+ STATUSMSG=@+ TOPICLEN=255 USERLEN=20 :are supported by this server"
	RPL_CHANNELMODEIS: (user, channel) ->
		":#{source} 324 #{user.clientText} #{channel.name} #{channel\getModes!}"
	RPL_TOPIC: (user, channel) ->
		":#{source} 332 #{user.clientText} #{channel.name} :#{channel.topic}"
	RPL_NAMREPLY: (user, channel) ->
		-- TODO: multiple users per line
		data = {}
		base = ":#{source} 353 #{user.clientText} = #{channel.name} :"
		--available = 510 - base\len!
		
		for _, userInChannel in pairs channel.users do
			prefix = userInChannel.channelPrefixes[channel.name]
			table.insert data, "#{base}#{prefix}#{userInChannel.nick}"
		
		data
	ERR_NOSUCHNICK: (user, nick) ->
		":#{source} 401 #{user.clientText} #{nick} :No such nick/channel"
	ERR_NOSUCHCHANNEL: (user, channel) ->
		":#{source} 403 #{user.clientText} #{channel} :No such channel"
	ERR_INVALIDCAPCMD: (command) ->
		":#{source} 410 * #{command} :Invalid CAP command"
	ERR_NOMOTD: (user) ->
		":#{source} 422 #{user.clientText} :MOTD File is missing"
	ERR_NONICKNAMEGIVEN: (user) ->
		":#{source} 431 #{user.clientText} :No nickname given"
	ERR_ERRONEOUSNICKNAME: (user, nick) ->
		":#{source} 432 #{user.clientText} #{nick} :Erroneous nickname"
	ERR_NICKNAMEINUSE: (user, nick) ->
		":#{source} 433 #{user.clientText} #{nick} :Nickname is already in use"
	ERR_NEEDMOREPARAMS: (user, command) ->
		":#{source} 461 #{user.clientText} #{command} :Not enough parameters"
	ERR_ALREADYREGISTERED: (user) ->
		":#{source} 462 #{user.clientText} :You may not reregister"
	ERR_INVITEONLYCHAN: (user, channel) ->
		":#{source} 473 #{user.clientText} #{channel.name} :Cannot join channel (+i)"
	ERR_BANNEDFROMCHAN: (user, channel) ->
		":#{source} 474 #{user.clientText} #{channel.name} :Cannot join channel (+b)"
	ERR_USERSDONTMATCH: (user) ->
		":#{source} 502 #{user.clientText} :Cannot change mode for other users"
}