--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages Cmdr on client

]]

-- // Services \\ --

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local testService = game:GetService("TestService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

local localPlayer = players.LocalPlayer

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))
local cmdr = require(replicatedStorage:WaitForChild("CmdrClient"))

-- // Knit Setup \\ --

local cmdrClient = knit.CreateController({
	Name = "CmdrClient",
	--> ActivationKeys :: table | false
})

-- // Private Variables \\ --

local ACTIVATION_KEYS = {
	Enum.KeyCode.F2,
}

-- // Private Functions \\ --

local activationKeysAsStrings = function(): table
	local tableToReturn = {}

	for _, keyCode in next, ACTIVATION_KEYS do
		table.insert(tableToReturn, keyCode.Name)
	end

	return tableToReturn
end

local function onStart(): ()
	task.wait(0.5)

	local dataManager = knit.GetService("DataManager")

	local basicData = dataManager:GetData("BasicData"):expect()

	local mainGroupId = basicData.groups.main.id
	local mainGroupAdminRank = basicData.groups.main.adminRank

	if localPlayer:GetRankInGroup(mainGroupId) >= mainGroupAdminRank then
		cmdrClient.ActivationKeys = activationKeysAsStrings()

		testService:Message("Cmdr console granted!")
	else
		cmdrClient.ActivationKeys = {}
	end

	cmdr:SetActivationKeys(ACTIVATION_KEYS)
	cmdr:SetEnabled(#cmdrClient.ActivationKeys > 0)
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return cmdrClient
