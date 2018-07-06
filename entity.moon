return class Entity
	getModes: =>
		modes = "+"

		for modeName, value in pairs @modes do
			if value == true
				modes ..= modeName

		return modes