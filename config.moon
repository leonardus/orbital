{
version: "orbital-pre"

serverName: "localnet"
networkName: "localnet"
port: 6667

dateFormat: "%Y-%m-%d"
timeFormat: "%H:%M:%S"

nickPattern: "[A-Za-z0-9_%-`]+" -- uppercase, lowercase, brackets, underscores, backticks, hyphens
maxUsernameLen: 9
maxNicknameLen: 20
maxHostnameLen: 64

pingTimeout: 120 -- 2 minutes
pingPollRate: 5 -- every 5 seconds

enabledModules:
	"NickServ": true
}