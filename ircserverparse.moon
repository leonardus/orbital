re = require "re"
config = require "config"

pattern = re.compile [[
	line <- {| (source sp)? (command / numeric) {:args: {| (sp arg)* |} :} |}
	
	source <- ':' {:source: ]] .. config.nickPattern .. [[ :}
	
	command <- {:command: [A-Za-z]+ :}
	numeric <- {:numeric: %d^+3^-4 :} -- at most four digits, at least three
	
	arg <- ':' {.+} / {%S+}
	sp <- %s
]]

(line) ->
	parsed = re.match line, pattern
	parsed