sqlite3 = require "sqlite3"
dbutils = {}

dbutils.exec = (db, q) ->
	res = db\exec q
	unless res == sqlite3.OK
		error "Could not execute SQL query \"#{q}\": #{res}"

dbutils.exec_safe = (db, q, nametable, limit) ->
	statement, errcode = db\prepare q

	unless statement
		error "Could not execute SQL query \"#{q}\" (error #{errcode}): #{db\errmsg!}"

	if nametable
		statement\bind_names nametable
	
	res = {}
	i = 0
	for dbRow in statement\nrows! do
		if i == limit
			break
		row = {}
		for k,v in pairs dbRow do
			row[k] = v
		table.insert res, row
		i+=1

	statement\finalize!
	if #res == 0
		return nil
	if limit == 1
		return res[1]
	else
		return res

return dbutils