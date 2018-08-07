modutils = {}
hooks = {}

modutils.hookAction = (name, handler) ->
	name = name\upper!
	exists = hooks[name]
	unless exists
		hooks[name] = {}
	
	table.insert hooks[name], handler

modutils.pushAction = (name, data) ->
	name = name\upper!
	if hooks[name]
		for _, handler in pairs hooks[name] do
			handler data

return modutils