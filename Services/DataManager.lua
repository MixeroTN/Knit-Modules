--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages data in the service

]]

-- // Services \\ --

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")
local server = serverScriptService:WaitForChild("Server")
local data = server:WaitForChild("Data")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local dataManager = knit.CreateService({
	Name = "DataManager",
	Client = {
		Timezone = knit.CreateSignal(),
	},
	Datas = {},
	Timezones = {},
})

-- * change that if this would be unsafe
local function setup(): table
	dataManager.Client.Timezone:Connect(function(player: Player, timeZone: string): ()
		dataManager.Timezones[player.UserId] = timeZone
		players[player.Name]:SetAttribute("Timezone", timeZone)
	end)

	players.PlayerRemoving:Connect(function(player: Player): ()
		dataManager.Timezones[player.UserId] = nil
	end)

	for _, currentData in ipairs(data:GetDescendants()) do
		if currentData:IsA("ModuleScript") then
			dataManager["Datas"][currentData.Name] = require(currentData)
		end
	end

	return dataManager["Datas"]
end

-- // Public Functions \\ --

function dataManager.Client:GetData(_: Player, dataName: string): table?
	-- // If data doesn't exist, return

	local datas = dataManager["Datas"]

	if not dataName then
		return
	end

	if not datas then
		setup()
	end

	local dataToSend = datas[dataName]

	return dataToSend
end

function dataManager.Client:GetAllData(): table
	return dataManager["Datas"] or setup()
end

function dataManager:GetData(dataName: string): table?
	return self.Client:GetData(nil, dataName)
end

function dataManager:GetAllData(): table
	return self.Client:GetAllData()
end

-- // Initialize \\ --

knit.OnStart():andThen(setup, warn)

return dataManager
