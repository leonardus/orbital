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

return motd