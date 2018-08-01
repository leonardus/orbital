numerics = require "numerics"

motd = {}
motd.MOTD = nil

motd.loadMotd = ->
	motdFile = io.open "MOTD.txt"
	unless motdFile
		return

	motd.MOTD = {}
	for line in motdFile\lines! do
		table.insert motd.MOTD, line

	io.close motdFile

motd.sendMOTD = (user) ->
	unless motd.MOTD
		user\send numerics.ERR_NOMOTD user
		return

	user\send numerics.RPL_MOTDSTART user
	for _, line in ipairs motd.MOTD do
		user\send numerics.RPL_MOTD user, line
	user\send numerics.RPL_ENDOFMOTD user

return motd