--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages Cmdr access and commands

]]

-- // Services \\ --

local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")
local server = serverScriptService:WaitForChild("Server")
local cmdrAssets = server.Assets.Cmdr

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))
local cmdr = require(packages:WaitForChild("Cmdr"))

-- // Knit Setup \\ --

local cmdrManager = knit.CreateService({
	Name = "CmdrManager",
	Client = {
		MySignal = knit.CreateSignal(),
	},
})

-- // Private Functions \\ --

local function onStart(): ()
	cmdr:RegisterDefaultCommands()
	cmdr:RegisterCommandsIn(cmdrAssets.Commands)
	cmdr:RegisterHooksIn(cmdrAssets.Hooks)
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return cmdrManager
