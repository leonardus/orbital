return class Entity
	getModes: =>
		modes = ""
		positive = {}
		negative = {}

		for modeName, value in pairs @modes do
			if value == true
				table.insert positive, modeName
			elseif value == false
				table.insert negative, modeName

		positive = table.concat positive
		negative = table.concat negative
		if #positive > 0
			modes ..= "+#{positive}"
		if #negative > 0
			modes ..= "-#{negative}"

		return modes