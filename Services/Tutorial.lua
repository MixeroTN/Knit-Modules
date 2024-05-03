--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages a tutorial on server

]]

-- // Services \\ --

local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local tutorial = knit.CreateService({
	Name = "Tutorial",
	Client = {
		Launch = knit.CreateSignal(),
		Skip = knit.CreateSignal(),
	},
})

-- // Private Variables \\ --

local LAUNCH_IN_STUDIO = false

local launchStatus = true

-- // Private Functions \\ --

local function onStart(): ()
	if runService:IsStudio() and not LAUNCH_IN_STUDIO then
		launchStatus = false
	end
end

-- // Public Functions \\ --

function tutorial:Call(player: Player, eventName: string, ...: any?): boolean
	if launchStatus then
		tutorial.Client[eventName]:Fire(player, ...)

		return true
	else
		return false
	end
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return tutorial
