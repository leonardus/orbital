config = require "config"
public = require "public"
source = config.source

return {
	RPL_WELCOME: (user) ->
		networkName = config.networkName
		nick = user.nick
		host = user.client\getpeername!
		": 001 #{user.clientText} :Welcome to the #{networkName} network, #{nick}!~#{user.username}@#{host}"
	RPL_YOURHOST: (user) ->
		servername = config.serverName
		version = config.version
		": 002 #{user.clientText} :Your host is #{servername}, running version #{version}"
	RPL_CREATED: (user) ->
		date = os.date config.dateFormat, public.created
		time = os.date config.timeFormat, public.created
		": 003 #{user.clientText} :This server was created #{date} at #{time}"
	RPL_MYINFO: (user) ->
		usermodes = "ior"
		channelmodes = "beIlikmstn"
		servername = config.serverName
		version = config.version
		": 004 #{user.clientText} #{servername} #{version} #{usermodes} #{channelmodes}"
	RPL_ISUPPORT: (user) ->
		HOSTLEN = config.maxHostnameLen
		": 005 #{user.clientText} CASEMAPPING=ascii CHANLIMIT=#: CHANNELLEN=50 CHANTYPES=# ELIST=MU HOSTLEN=#{HOSTLEN} KICKLEN=255 MAXLIST=b:127 NICKLEN=20 PREFIX=(ov)@+ STATUSMSG=@+ TOPICLEN=255 USERLEN=20 :are supported by this server"
	RPL_UMODEIS: (user) ->
		": 221 #{user.clientText} #{user\getModes!}"	
	RPL_CHANNELMODEIS: (user, channel) ->
		": 324 #{user.clientText} #{channel.name} #{channel\getModes!}"
	RPL_NOTOPIC: (user, channel) ->
		": 331 #{user.clientText} #{channel.name} :No topic is set"
	RPL_TOPIC: (user, channel) ->
		": 332 #{user.clientText} #{channel.name} :#{channel.topic}"
	RPL_TOPICWHOTIME: (user, channel) ->
		topFullhost = channel.topicFullhost
		topTime = tostring channel.topicTime
		": 333 #{user.clientText} #{channel.name} #{topFullhost} #{topTime}"
	RPL_NAMREPLY: (user, channel) ->
		-- TODO: multiple users per line
		data = {}
		base = ": 353 #{user.clientText} = #{channel.name} :"
		--available = 510 - base\len!
		
		for _, userInChannel in pairs channel.users do
			prefix = userInChannel.channelPrefixes[channel]
			table.insert data, "#{base}#{prefix}#{userInChannel.nick}"
		
		data
	ERR_NOSUCHNICK: (user, nick) ->
		": 401 #{user.clientText} #{nick} :No such nick/channel"
	ERR_NOSUCHCHANNEL: (user, channel) ->
		": 403 #{user.clientText} #{channel} :No such channel"
	ERR_CANNOTSENDTOCHAN: (user, channel) ->
		": 404 #{user.clientText} #{channel.name} :Cannot send to channel"
	ERR_INVALIDCAPCMD: (command) ->
		": 410 * #{command} :Invalid CAP command"
	ERR_NOMOTD: (user) ->
		": 422 #{user.clientText} :MOTD File is missing"
	ERR_NONICKNAMEGIVEN: (user) ->
		": 431 #{user.clientText} :No nickname given"
	ERR_ERRONEOUSNICKNAME: (user, nick) ->
		": 432 #{user.clientText} #{nick} :Erroneous nickname"
	ERR_NICKNAMEINUSE: (user, nick) ->
		": 433 #{user.clientText} #{nick} :Nickname is already in use"
	ERR_USERNOTINCHANNEL: (user, nick, channel) ->
		": 441 #{user.clientText} #{nick} #{channel.name} :They aren't on that channel"
	ERR_NOTONCHANNEL: (user, channel) ->
		": 442 #{user.clientText} #{channel.name} :You're not on that channel"
	ERR_NOTREGISTERED: (user) ->
		": 451 #{user.clientText} :You have not registered"
	ERR_NEEDMOREPARAMS: (user, command) ->
		": 461 #{user.clientText} #{command} :Not enough parameters"
	ERR_ALREADYREGISTERED: (user) ->
		": 462 #{user.clientText} :You may not reregister"
	ERR_CHANNELISFULL: (user, channel) ->
		": 471 #{user.clientText} #{channel.name} :Cannot join channel (+l)"
	ERR_INVITEONLYCHAN: (user, channel) ->
		": 473 #{user.clientText} #{channel.name} :Cannot join channel (+i)"
	ERR_BANNEDFROMCHAN: (user, channel) ->
		": 474 #{user.clientText} #{channel.name} :Cannot join channel (+b)"
	ERR_BADCHANNELKEY: (user, channel) ->
		": 475 #{user.clientText} #{channel.name} :Cannot join channel (+k)"
	ERR_CHANOPRIVISNEEDED: (user, channel) ->
		": 482 #{user.clientText} #{channel.name} :You're not channel operator"
	ERR_USERSDONTMATCH: (user) ->
		": 502 #{user.clientText} :Cannot change mode for other users"
}