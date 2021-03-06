parseModule = {}

re = require "re"
config = require "config"

parseModule.matchesWithWildcard = (wildcard, actual) -> 
	-- see https://modern.ircdocs.horse/#wildcard-expressions
	i = 0
	wildcardIndex = 1
	ast = false

	for i = 1, actual\len!
		actualChar = actual\sub i,i
		wildcardChar = wildcard\sub wildcardIndex, wildcardIndex

		isEscaped = false
		if wildcardIndex > 1 and wildcard\sub(wildcardIndex-1, wildcardIndex-1) == "\\"
			isEscaped = true

		if (wildcardChar == "?" and not isEscaped) or actualChar == wildcardChar or wildcardChar == "\\"
			if ast
				ast = false
			
			wildcardIndex += 1
			
			continue
		elseif (wildcardChar == "*" and not isEscaped) and wildcardIndex > 1
			if wildcardIndex == wildcard\len!
				return true
			
			ast = true
			wildcardIndex += 1

		isEndOfString = i == actual\len!
		if actualChar != wildcardChar and ((not ast) or isEndOfString)
			return false

	return true

messagePattern = re.compile [[
	line <- {| (source sp)? (command / numeric) {:args: {| (sp arg)* |} :} |}
	
	source <- ':' {:source: ]] .. config.nickPattern .. [[ :}
	
	command <- {:command: [A-Za-z]+ :}
	numeric <- {:numeric: %d^+3^-4 :} -- at most four digits, at least three
	
	arg <- ':' {.*} / {%S+}
	sp <- %s
]]

serviceCommandPattern = re.compile [[
	line <- {| command {:args: {| (sp arg)* |} :} |}
	command <- {:command: [A-Za-z]+ :}
	arg <- ':' {.*} / {%S+}
	sp <- %s
]]

fullhostPattern = re.compile [[
	fullhost <- {|
	{:nick: {[^ !]+} :} '!'
	{:user: '~'? {[^ @]+} :} '@'
	{:host: {[^ ]+} :} |}
]]

parseModule.parseMessage = (line) ->
	parsed = re.match line, messagePattern
	return parsed

parseModule.parseServiceCommand = (line) ->
	parsed = re.match line, serviceCommandPattern
	return parsed

parseModule.parseFullhost = (line) ->
	parsed = re.match line, fullhostPattern
	return parsed

parseModule.explodeCommas = (line) ->
	list = {}
	
	current = ""
	for i = 1, line\len! do
		isEOL = (line\len! == i)
		char = line\sub i,i

		if char != ","
			current ..= char

		addToList = (char == ",") or isEOL
		if addToList and current\len! > 0
			table.insert list, current
			current = ""

	return list

return parseModule