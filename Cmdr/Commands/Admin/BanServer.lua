--!nocheck

local serverScriptService = game:GetService("ServerScriptService")

local banManager = require(serverScriptService:WaitForChild("Server").Services.BanManager)

return function(context: table, player: Player?, timeOfBan: string, reason: string): string
	return table.pack(banManager:Ban(player, context.Executor.UserId, timeOfBan, reason))[2]
end
