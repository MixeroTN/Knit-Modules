--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script awaits for the Knit framework to load
      (onStart) and returns after the yield.
      Also returns the requested Services/Controllers.

* This module is for Cmdr and other packages use
* (as they should not be connected to Knit)

]]

-- // Services \\ --

local replicatedStorage = game:GetService("ReplicatedStorage")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local preparationQueue = knit.CreateService({
	Name = "PreparationQueue",
})

-- // Private Variables \\ --

local FRAMEWORK_READY = false

-- // Private Functions \\ --

local function onStart(): ()
	FRAMEWORK_READY = true
end

-- // Public Functions \\ --

function preparationQueue:Await(): boolean
	while not FRAMEWORK_READY do
		task.wait(0.5)
	end

	return FRAMEWORK_READY
end

function preparationQueue:ReturnService(name: string): table
	preparationQueue:Await()

	return knit.GetService(name)
end

function preparationQueue:ReturnController(name: string): table
	preparationQueue:Await()

	return knit.GetController(name)
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return preparationQueue
