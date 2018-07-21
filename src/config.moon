return {
	version: "orbital-pre"
	
	serverName: "localnet"
	source: "localhost"
	networkName: "localnet"
	
	dateFormat: "%Y-%m-%d"
	timeFormat: "%H:%M:%S"
	
	nickPattern: "[A-Za-z0-9_\-`]+" -- uppercase, lowercase, brackets, underscores, hyphens, backticks
	maxUsernameLen: 20

	pingTimeout: 120 -- 2 minutes
}