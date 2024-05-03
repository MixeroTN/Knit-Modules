--!nocheck

local teleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")

local server = ServerScriptService:WaitForChild("Server")

local preparationQueue = require(server:WaitForChild("PreparationQueue"))

local indicators = preparationQueue:ReturnService("Indicators")

return function(context: table, player: Player): string
	local status, err = pcall(function(): ()
		-- // Yield until Knit Framework is ready
		preparationQueue:Await()

		-- // Indicates the Popup
		indicators:IndicatePopupFromTemplateToPlayer(
			player,
			"rejoin",
			`You will rejoin this server shortly.{if player ~= context.Executor
				then (" Initiated by %s"):format(context.Executor.Name)
				else ""}`
		)

		-- // Teleport
		task.wait(1)
		teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player, nil, "rejoin")
	end)

	if status then
		if player == context.Executor then
			return ">>> Rejoining..."
		else
			return "Rejoining a player: " .. player.Name
		end
	else
		indicators:IndicatePopupFromTemplateToPlayer(player, "rejoin", `The teleport failed.`)

		return "The command failed. Error message: " .. tostring(err)
	end
end
