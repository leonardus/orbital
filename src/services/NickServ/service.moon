services = require "services"

handler = (service, query, user) ->

loader = ->
	services.createService "NickServ", handler

return loader