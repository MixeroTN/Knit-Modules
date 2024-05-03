--!nocheck

local serverScriptService = game:GetService("ServerScriptService")

local banManager = require(serverScriptService:WaitForChild("Server").Services.BanManager)

return function(context: table, player: Player?, reason: string): string
	return table.pack(banManager:Unban(player, context.Executor.UserId, reason))[2]
end
