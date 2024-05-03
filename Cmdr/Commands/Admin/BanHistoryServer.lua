--!nocheck

local serverScriptService = game:GetService("ServerScriptService")

local banManager = require(serverScriptService:WaitForChild("Server").Services.BanManager)

return function(context: table, player: Player | string | number): string
	return banManager:GetHistoryInString(player, context.Executor:GetAttribute("Timezone"))
end
