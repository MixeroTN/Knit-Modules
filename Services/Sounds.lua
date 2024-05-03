--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages sounds on server

]]

-- // Services \\ --

local replicatedStorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Private Variables \\ ---

local sounds = knit.CreateService({
	Name = "Sounds",
	PlayingSounds = {},
	Client = {
		PlaySoundOnClient = knit.CreateSignal(),
		PlaySoundOnParent = knit.CreateSignal(),
	},
})

-- // Private Functions \\ --

local function onStart(): ()
	function sounds:Play(destination: Sound, parent: Instance, customLifetime: number?): Sound
		-- // Clones and plays sound, then destroys it

		local clonedSound = destination:Clone()
		clonedSound.Parent = parent or workspace:WaitForChild("Sounds")
		clonedSound:Play()

		table.insert(self.PlayingSounds, clonedSound)

		debris:AddItem(clonedSound, clonedSound.TimeLength + (customLifetime or 0.1))

		return clonedSound
	end
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart):catch(warn)

return sounds
