--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages connection between server & client for chat, giving neccesary data

]]

-- // Services \\ --

local replicatedStorage = game:GetService("ReplicatedStorage")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local chatService = knit.CreateService({
	Name = "Chat",
	Client = {},
})

local profileManager

-- // Private Functions \\ --

local function onStart(): ()
	task.wait(0.5)

	profileManager = knit.GetService("ProfileManager")
end

-- // Public Functions \\ --

function chatService.Client:GetChatData(player: Player, targetPlayer: Player): table
	local profile = profileManager.Profiles[targetPlayer].Data

	local reputation = profile.Reputation.Reputation
	local hasVIP = profile.Gamepasses.VIP
	local hideTags = profile.Settings.ConcealPower.ChatTags

	return { reputation, hasVIP, hideTags }
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart):catch(warn)

return chatService
