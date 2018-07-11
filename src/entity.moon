return class Entity
	modesOfType: (letter) =>
		modes = ""

		for mode, modeType in pairs @modeTypes do
			if modeType == letter
				modes ..= mode

		return modes

	getModes: =>
		modes = "+"

		for modeName, value in pairs @modes do
			if type(value) != "table"
				modes ..= modeName

		return modes