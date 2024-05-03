--!nocheck

return function(_: table, player: Player, destination: string): string
	local returned = workspace.NPCs:FindFirstChild(destination)

	for _, npc in pairs(game.Workspace.NPCs:GetChildren()) do
		if string.lower(npc.Name) == string.lower(destination) then
			returned = npc
		end
	end

	if returned then
		local character = player.Character
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		local humanoid = character:WaitForChild("Humanoid")

		if humanoid.Health <= 0 then
			return "The command failed because the player is not alive at the moment."
		end

		if returned:IsA("Model") then
			humanoidRootPart.CFrame = returned.HumanoidRootPart.CFrame
		else
			humanoidRootPart.CFrame = returned.CFrame
		end

		return ('Teleported "%s" player to %s'):format(player.Name, destination)
	else
		return "The command failed. It is likely that the destination does not exist."
	end
end
