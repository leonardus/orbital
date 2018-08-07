sqlite3 = require "sqlite3"
dbutils = {}

dbutils.exec = (db, q) ->
	res = db\exec q
	unless res == sqlite3.OK
		error "Could not execute SQL query \"#{q}\": #{res}"

dbutils.exec_safe = (db, q, nametable) ->
	statement, errcode = db\prepare q

	unless statement
		error "Could not execute SQL query \"#{q}\" (error #{errcode}): #{db\errmsg!}"

	if nametable
		statement\bind_names nametable
	
	res = statement\step!
	if (res != sqlite3.DONE) and (res != sqlite3.ROW)
		error "Could not execute SQL query \"#{q}\" (step): #{res}"

	if res == sqlite3.ROW
		cols = statement\columns!
		statement\finalize!
		return cols

	statement\finalize!

return dbutils