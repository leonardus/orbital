{
version: "orbital-pre"

serverName: "localnet"
source: "localhost"
networkName: "localnet"

dateFormat: "%Y-%m-%d"
timeFormat: "%H:%M:%S"

nickPattern: "[A-Za-z0-9_\-`]+" -- uppercase, lowercase, brackets, underscores, hyphens, backticks
maxUsernameLen: 9
maxHostnameLen: 64

pingTimeout: 120 -- 2 minutes
pingPollRate: 5 -- every 5 seconds
}