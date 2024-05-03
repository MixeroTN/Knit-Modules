--!nocheck

local character = script.Parent.Parent
local humanoid = character:WaitForChild("Humanoid")

local stateType = Enum.HumanoidStateType

humanoid:SetStateEnabled(stateType.FallingDown, false)
humanoid:SetStateEnabled(stateType.Ragdoll, false)
