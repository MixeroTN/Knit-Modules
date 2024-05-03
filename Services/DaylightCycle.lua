--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages daylight cycle

]]

-- // Services \\ --

local lighting = game:GetService("Lighting")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))
local signal = require(packages:WaitForChild("SignalsService"))

-- // Private Variables \\ --

local daylightCycleEnabled = false

-- // Knit Setup \\ --

local daylightCycle = knit.CreateService({
	Name = "DaylightCycle",
})

daylightCycle.CycleSwitched = signal.new()

-- // Private Functions \\ --

local function onStart(): ()
	local tween = knit.GetService("Tween")

	local transitionTime = 65
	local tweenInfo = TweenInfo.new(transitionTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

	local dayTime = { 125, 12 }
	local nightTime = { 125, 100 }

	if daylightCycleEnabled then
		while true do
			for _, value in pairs({ dayTime, nightTime }) do
				tween:Tween(lighting, tweenInfo, { ClockTime = value[2] }):expect()
				task.wait(value[1])
			end
		end
	end
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return daylightCycle
