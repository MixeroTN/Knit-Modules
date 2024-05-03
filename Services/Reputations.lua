--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages reputations on server

]]

-- // Services \\ --

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")
local server = serverScriptService:WaitForChild("Server")
local datas = server:WaitForChild("Data")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))
local reputationData = require(datas:WaitForChild("ReputationData"))
local signalsService = require(packages:WaitForChild("SignalsService"))

-- // Knit Setup \\ --

local reputationService = knit.CreateService({
	Name = "Reputations",
	Client = {
		ReputationChanged = knit.CreateSignal(),
		KillChanged = knit.CreateSignal(),
		HeroesKillChanged = knit.CreateSignal(),
		VillainsKillChanged = knit.CreateSignal(),

		UpdateRequest = knit.CreateSignal(),
	},
})

reputationService.ReputationChanged = signalsService.new()

local profileManager
local rank

-- // Private Functions \\ --

local function getClosestReputationTier(reputationType: string, reputationNumber: number): number
	local closestTier = 0

	for indexNumber, _ in next, reputationData[reputationType] do
		if reputationType == "positive" then
			if
				tonumber(reputationNumber) >= tonumber(indexNumber)
				and tonumber(indexNumber) > tonumber(closestTier)
			then
				closestTier = indexNumber
			end
		else
			if
				tonumber(reputationNumber) <= tonumber(indexNumber)
				and tonumber(indexNumber) < tonumber(closestTier)
			then
				closestTier = indexNumber
			end
		end
	end

	if closestTier == 0 then
		closestTier = nil
	end

	return closestTier
end

local function getReputationData(reputationNumber: number, dataTable: table?): (number, table)
	dataTable = dataTable or reputationData

	if not (dataTable.default and dataTable.positive and dataTable.negative) then
		return
	end

	if reputationNumber == 0 then
		return 0, dataTable.default
	elseif reputationNumber > 0 then
		local reputationTier = getClosestReputationTier("positive", reputationNumber)

		return reputationTier, dataTable.positive[reputationTier]
	else
		local reputationTier = getClosestReputationTier("negative", reputationNumber)

		return reputationTier, dataTable.negative[reputationTier]
	end
end

local function updateReputationOnKill(player: Player, victim: Player): number
	local playerProfile = profileManager.Profiles[player].Data
	local victimProfile = profileManager.Profiles[victim].Data
	local victimReputationNumber = victimProfile.Reputation.Reputation

	if victimReputationNumber >= 0 then
		playerProfile.Reputation.Reputation -= 1

		playerProfile.Reputation.HeroesKilled += 1
	else
		playerProfile.Reputation.Reputation += 1

		playerProfile.Reputation.VillainsKilled += 1
	end

	victimProfile.Reputation.Reputation = 0

	reputationService.ReputationChanged:Fire(player, playerProfile.Reputation.Reputation)
	reputationService.ReputationChanged:Fire(victim, 0)

	return playerProfile.Reputation.Reputation
end

local function updateReputationOnForce(player: Player, value: number): number
	local playerProfile = profileManager.Profiles[player].Data

	playerProfile.Reputation.Reputation = value

	reputationService.ReputationChanged:Fire(player, playerProfile.Reputation.Reputation)

	return playerProfile.Reputation.Reputation
end

local function characterAdded(character: Model): ()
	local humanoid = character:WaitForChild("Humanoid")
	local deathConnection
	local player = players:GetPlayerFromCharacter(character)

	deathConnection = humanoid.Died:Connect(function(): ()
		local profile = profileManager.Profiles[player].Data

		profile.Reputation.Reputation = 0

		rank.Client.AliveTimeChanged:Fire(player, 0)
		reputationService.ReputationChanged:Fire(player, 0)

		deathConnection:Disconnect()
	end)
end

local function onStart(): ()
	players.PlayerAdded:Connect(function(player: Player): ()
		player.CharacterAdded:Connect(characterAdded)
	end)

	for _, player in next, players:GetPlayers() do
		player.CharacterAdded:Connect(characterAdded)
	end

	task.wait(0.5)

	profileManager = knit.GetService("ProfileManager")
	rank = knit.GetService("Rank")
end

-- // Public Functions \\ --

function reputationService:GetReputationData(reputationNumber: number, dataTable: table?): (number, table)
	return getReputationData(reputationNumber, dataTable)
end

function reputationService:UpdateReputationOnKill(player: Player, victim: Player): number
	return updateReputationOnKill(player, victim)
end

function reputationService:UpdateReputationWithForce(player: Player, value: number): number
	return updateReputationOnForce(player, value)
end

function reputationService.Client:GetPlayerReputation(_, targetPlayer: Player): number
	local profile = profileManager.Profiles[targetPlayer].Data

	return profile.Reputation.Reputation
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return reputationService
