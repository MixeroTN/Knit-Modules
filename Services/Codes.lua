--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages codes

]]

-- // Services \\ --

local replicatedStorage = game:GetService("ReplicatedStorage")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local dataManager, profileManager, hudEffects

local codes = knit.CreateService({
	Name = "Codes",
	Client = {
		MySignal = knit.CreateSignal(),
	},
})

-- // Private Variables \\ --

local redeemedCodesProfileArrayName = "RedeemedCodes"

local datas = {}
local actionFunctions = {}

-- // Action Functions (Private) \\ --

actionFunctions.tokens = function(player: Player, _, code: string): boolean
	return pcall(function(): ()
		profileManager.Profiles[player].Data.Stats.Tokens += datas.Codes[code].tokens

		profileManager.Client.Stats:Fire(player, "Tokens", profileManager.Profiles[player].Data.Stats.Tokens)
	end)
end

actionFunctions.powers = function(player: Player, array: table): boolean
	local status, err

	for key, value in next, array do
		status, err = pcall(function(): ()
			profileManager.Profiles[player].Data.RewardedPowers[key] = value
		end)

		if not status then
			warn(err)

			break
		end
	end

	return status
end

actionFunctions.group = function(player: Player, array: table): boolean
	local id = array.id or datas.BasicData.groups.main.id :: number
	local rank = array.rank :: number?
	local playerGroupRank = player:GetRankInGroup(id) :: number

	return (rank and playerGroupRank >= rank) or playerGroupRank > 0
end

actionFunctions.groupRank = function(player: Player, rank: number): boolean
	local id = datas.BasicData.groups.main.id :: number
	local playerGroupRank = player:GetRankInGroup(id) :: number

	return rank and playerGroupRank >= rank
end

actionFunctions.requirements = function(player: Player, requirements: table): boolean
	local status = true

	for key, value in next, requirements do
		local keyFunction = actionFunctions[key]

		status = keyFunction and keyFunction(player, value)

		if not status then
			return false
		end
	end

	return true
end

-- // Private Functions \\ --

local function checkActions(player: Player, actions: table, code: string): boolean
	for key, value in next, actions do
		local keyFunction = actionFunctions[key]

		if keyFunction then
			local status = keyFunction(player, value, code)

			if not status then
				return false
			end
		end
	end

	return true
end

local function saveRedeemedCode(player: Player, code: string): table | string?
	return profileManager:InsertStat(player, redeemedCodesProfileArrayName, code)
end

local function checkCode(code: string): any?
	return datas.Codes[code]
end

local function control(player: Player, code: string): any?
	local checkedCode = checkCode(code)

	if player and code and checkedCode then
		return checkedCode
	end
end

local function onStart(): ()
	task.wait(0.5)

	dataManager = knit.GetService("DataManager")
	profileManager = knit.GetService("ProfileManager")

	datas = {
		BasicData = dataManager.Client:GetData(nil, "BasicData"),
		Codes = dataManager.Client:GetData(nil, "Codes"),
	}
end

-- // Public Functions \\ --

function codes.Client:RedeemCode(player: Player, code: string): table?
	local ctrl = control(player, code)

	if not ctrl or not checkActions(player, ctrl, code) then
		return
	end

	local result = saveRedeemedCode(player, code)

	if type(result) == "string" then
		warn(result)
	elseif result then
		return result
	end
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return codes
