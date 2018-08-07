sqlite3 = require "sqlite3"
dbutils = {}

dbutils.exec = (db, q) ->
	res = db\exec q
	unless res == sqlite3.OK
		error "Could not execute SQL query \"#{q}\": #{res}"

return dbutils