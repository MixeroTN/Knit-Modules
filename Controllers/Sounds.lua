--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages sounds on client

]]

-- // Services \\ --

local replicatedStorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local soundService = game:GetService("SoundService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Private Variables \\ ---

local sounds = knit.CreateController({
	Name = "Sounds",
	PlayingSounds = {},
})
local soundServiceKnit

-- // Private Functions \\ --

local function onStart(): ()
	soundServiceKnit = knit.GetService("Sounds")

	soundServiceKnit.PlaySoundOnClient._re.OnClientEvent:Connect(function(destination: Sound): ()
		-- // Plays the sound, but from a request from server

		sounds:Play(destination)
	end)

	task.wait(0.5)

	function sounds:Play(destination: Sound): ()
		-- // Plays the sound

		soundService:PlayLocalSound(destination)
	end

	--[[
    function soundServiceKnit.PlaySoundOnClient:Connect(destination : Sound): ()
        -- // Plays the sound, but from a request from server

        sounds:Play(destination)
    end
    ]]

	function soundServiceKnit.PlaySoundOnParent:Connect(destination: Sound, parent: Instance?): ()
		if parent then
			sounds:PlayWithClone(destination, parent)
		end
	end

	function sounds:PlayWithClone(destination: Sound, parent: Instance?): Sound
		-- // Plays the sound but instead clones it, this allows the sound properties be modified during its play

		local sound = destination:Clone()
		sound.Parent = parent or workspace.Temporary
		sound:Play()

		if not sound.Looped then
			debris:AddItem(sound, sound.TimeLength + 1)
		end

		return sound
	end
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return sounds
