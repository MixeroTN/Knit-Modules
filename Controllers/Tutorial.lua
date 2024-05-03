--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages a tutorial

]]

-- // Services \\ --

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local dataManager, tutorialService, dialogue, tween, visualEffects

local tutorial = knit.CreateController({
	Name = "Tutorial",
})

-- // Object Variables \\ --

local camera = workspace.CurrentCamera
local camerasFolder = workspace:WaitForChild("CameraPositions")

local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- // Private Variables \\ --

local cameraCFrame = camera.CFrame
local defaultCameraFOV = camera.FieldOfView

local isLaunched = false
local isReady = false

local datas = {}

-- // Private Functions \\ --

local function cameraMovement(): CFrame
	-- // This function lets the camera have a small rotation thing depending on mouse

	local x, y = mouse.X / mouse.ViewSizeX, mouse.Y / mouse.ViewSizeY

	camera.CFrame = cameraCFrame * CFrame.new(x * 2, -y * 2, 0)

	return camera.CFrame
end

local function dragAnimation(state: boolean): boolean
	-- // This function plays the cursor drag animation same as on loading

	if state then
		-- // Check if animation is already binded, we got no way to check this naturally

		if table.find(_G.Binds, "Drag") then
			return false
		end

		-- // Update the cameraCFrame variable to make animation work property

		cameraCFrame = camera.CFrame

		-- // Bind an animation to render step and let all know by inserting the name into global table

		runService:BindToRenderStep("Drag", Enum.RenderPriority.Last.Value, cameraMovement)
		table.insert(_G.Binds, "Drag")

		return true
	else
		-- // Unbind an animation from render step and let all know by removing the name from global table

		runService:UnbindFromRenderStep("Drag")
		table.remove(_G.Binds, table.find(_G.Binds, "Drag"))

		task.wait()

		-- // Update the cameraCFrame variable to make animation work property

		camera.CFrame = cameraCFrame

		return true
	end
end

local function getDefaultStat(dataName: string, statName: string): any?
	-- // This function return the default stat

	local toReturn = datas[dataName].default[statName]

	-- // We can't pass TweenInfo data itself

	if string.lower(statName) == "tweeninfo" then
		return TweenInfo.new(table.unpack(toReturn))
	end

	return toReturn
end

local function playTween(instance: Instance, tweenInfo: TweenInfo?, properties: table): any
	-- // This function plays the tween with the provided tweenInfo or the default one if not provided

	return tween:Tween(instance, tweenInfo or getDefaultStat("Camera", "tweenInfo"), properties)
end

local function playCameraToPlayer(): ()
	-- // This function sets the camera to player head, runs after finishing the tutorial

	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local head = character:WaitForChild("Head")
	local humanoid = character:WaitForChild("Humanoid")

	-- // Ensure drag is disabled

	dragAnimation(false)

	-- // Set default TweenInfo and FOV

	camera.CFrame = head.CFrame
	camera.FieldOfView = defaultCameraFOV
	cameraCFrame = camera.CFrame

	-- // Give back camera control to player

	camera.CameraSubject = humanoid
	camera.CameraType = Enum.CameraType.Custom
end

local function playCamera(index: number): ()
	-- // This function prepares the camera animations

	local cameraPart = camerasFolder[tostring(index)]
	local nextCameraPart = camerasFolder:FindFirstChild(tostring(index + 1))

	local cameraStats = datas.Camera.steps
	local cameraStep = cameraStats[index]
	local tweenInfo = cameraStep.tweenInfo or getDefaultStat("Camera", "tweenInfo")

	-- // This table will be sent to tween

	local propertiesToTween = {}

	-- // Sets the custom subject provided in current step or to the current cameraPart if not provided

	camera.CameraSubject = cameraStep.subject or cameraPart

	-- // Sets the cameraCFrame startPosition immediately to the camera part provided in current step
	-- // if 'true' or to the custom instance when the value is an object

	if cameraStep.startPosition == true then
		camera.CFrame = cameraPart.CFrame
	elseif typeof(cameraStep.startPosition) == "Instance" then
		camera.CFrame = cameraStep.startPosition
	else
		propertiesToTween.CFrame = cameraStep.endPosition or cameraPart.CFrame
	end

	-- // Changes the FOV to the one provided, skips when not provided (so it can last for multiple steps)

	if cameraStep.fieldOfView then
		propertiesToTween.FieldOfView = cameraStep.fieldOfView
	end

	task.spawn(function(): ()
		-- // Play and wait for promise to return value

		playTween(camera, tweenInfo, propertiesToTween) --:expect()

		-- // Wait for a time of tween

		task.wait(datas.Camera.default.tweenInfo[1])

		-- // Keep the camera where animation ends

		camera.CFrame = propertiesToTween.CFrame or camera.CFrame
		cameraCFrame = camera.CFrame

		-- // Enable drag animation

		if nextCameraPart then
			dragAnimation(true)
		elseif not isLaunched then
			playCameraToPlayer()
		end
	end)
end

local function playDialogue(index: number): ()
	dialogue:PlayDialogueText(datas.Dialogues.instructor[index], {
		AnimateStyle = "Fade",
		Font = Enum.Font.GothamBold,
		ContainerVerticalAlignment = "Top",
		TextScale = 0.4,
		AnimateStyleTime = 0.1,
		AnimateStepTime = 0.05,
	}, nil, true)
end

local function proccessAll(): boolean
	dialogue:OpenDialogueUI("Instructor", nil, false)

	task.wait(0.5)

	for index = 1, #datas.Camera.steps do
		if not isLaunched then
			break
		end

		playCamera(index)
		playDialogue(index)
	end

	return true
end

local function finish(force: boolean?): boolean
	-- // Finish the tutorial

	-- // Don't finish when still active, finish anyway if force value is positive

	if not isLaunched and not force then
		return false
	else
		dragAnimation(false)
		dialogue:CloseDialogueUI()
		visualEffects:RunVisuals("QuestBeam", { "Enable", workspace.NPCs:FindFirstChild("SuperBoy") })
		playCameraToPlayer()

		isLaunched = false

		return true
	end
end

local function begin(): boolean
	-- // Start the tutorial

	-- // Don't start if not finished

	if isLaunched then
		return false
	else
		isLaunched = true

		-- // Take the camera control from player

		camera.CameraType = Enum.CameraType.Scriptable

		-- // Process all steps

		proccessAll()

		return finish()
	end
end

local function onStart(): ()
	-- // This function runs when knit is started

	task.wait(0.5)

	-- // Get neccesary controllers and services

	dataManager = knit.GetService("DataManager")
	tutorialService = knit.GetService("Tutorial")
	dialogue = knit.GetController("Dialogue")
	tween = knit.GetController("Tween")
	visualEffects = knit.GetController("VisualEffects")

	-- // Get neccesary data

	datas = {
		Camera = dataManager:GetData("Camera"):expect(),
		Dialogues = dataManager:GetData("Dialogues"):expect(),
	}

	-- // Connect to tutorial service events

	tutorialService.Launch:Connect(function(): ()
		repeat
			task.wait(0.5)
		until isReady

		tutorial:Begin()
	end)

	tutorialService.Skip:Connect(function(force: boolean?): ()
		tutorial:Skip(force)
	end)
end

-- // Public functions \\ --

function tutorial:Begin(): boolean
	return begin()
end

function tutorial:Skip(force: boolean?): boolean
	return finish(force)
end

function tutorial:Ready(): ()
	isReady = true
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return tutorial
