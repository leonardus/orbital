numerics = require "numerics"

return (line, user) -> -- needs to be implemented
	unless #line.args >= 1
		user\send numerics.ERR_NEEDMOREPARAMS user, "CAP"
		return
	
	subcommand = line.args[1]