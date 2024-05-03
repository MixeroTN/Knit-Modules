--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script creates a GUI with key binds info

]]

-- // Services \\ --

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local textService = game:GetService("TextService")
local userInputService = game:GetService("UserInputService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

local localPlayer = players.LocalPlayer

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

local cmdrClient, profileManager, tween

-- // Knit Setup \\ --

local keyBindInfo = knit.CreateController({
	Name = "KeyBindInfo",
})

-- // Private Functions \\ --

local function getElementSizes(): table
	-- // This function returns all usefull positions and sizes

	local playerGUI = localPlayer:WaitForChild("PlayerGui")
	local hud = playerGUI:WaitForChild("HUD")

	local PowerSlotC = hud.LowerHotbar.C
	local sidebar = hud.Sidebar
	local strengthSlot = hud.Hotbar.Strength
	local tokensCount = hud.Sidebar.CurrencyBar.Tokens

	return {
		PowerSlotCAbsPos = PowerSlotC.AbsolutePosition,
		PowerSlotCAbsPosOnAP0 = PowerSlotC.AbsolutePosition - PowerSlotC.AbsoluteSize / 2,
		PowerSlotCAbsSize = PowerSlotC.AbsoluteSize,
		SidebarAbsPosX = sidebar.AbsolutePosition.X,
		StrengthSlotAbsPosYOnAP1 = (strengthSlot.AbsolutePosition + strengthSlot.AbsoluteSize).Y,
		TokensCountTextSize = tokensCount.TextSize,
	}
end

local function getTextSizeInTextLabel(text: string, elements: table): Vector2
	-- // This function returns the real size of text that will be set to TextLabel later

	return textService:GetTextSize(
		text,
		elements.TextLabel.TextSize,
		elements.TextLabel.Font,
		elements.TextLabel.AbsoluteSize
	)
end

local function findInDictionary(dictionary: table, value: any): string
	-- // This function searches for given value in dictionary table and returns the value's key

	for key, val in next, dictionary do
		if val == value then
			return key
		end
	end
end

local function updateSize(elements: table): ()
	-- // This function updates the pixel size of the frame relatively to other gui elements

	local sizes = getElementSizes()

	elements.Frame.Size = UDim2.fromOffset(
		sizes.PowerSlotCAbsPosOnAP0.X - sizes.SidebarAbsPosX - sizes.PowerSlotCAbsSize.X / 2,
		elements.Frame.AbsolutePosition.Y - sizes.StrengthSlotAbsPosYOnAP1
	)
end

local function createGUI(): table
	-- // [One time] Create the GUI and change it's sizes

	local playerGUI = localPlayer:WaitForChild("PlayerGui")

	local sizes = getElementSizes()
	local elementsToReturn = {}

	local screenGUI = playerGUI:WaitForChild("KeyBindInfo")

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.Position = UDim2.new(0, sizes.SidebarAbsPosX, 1, -sizes.SidebarAbsPosX)
	frame.Parent = screenGUI
	elementsToReturn.Frame = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.AnchorPoint = Vector2.new(0, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromScale(0, 1)
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	textLabel.LineHeight = 1.15
	textLabel.RichText = true
	textLabel.Text = ""
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextSize = sizes.TokensCountTextSize
	textLabel.TextStrokeTransparency = 1 
	textLabel.TextTransparency = 1 
	textLabel.TextTruncate = Enum.TextTruncate.AtEnd
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	textLabel.Parent = frame
	elementsToReturn.TextLabel = textLabel

	task.delay(1, function(): ()
		tween:Tween(textLabel, TweenInfo.new(2), {
			TextStrokeTransparency = 0.8,
			TextTransparency = 0,
		})
	end)

	return elementsToReturn
end

local function getStats(): table
	-- // Get actual stats

	-- // If there's no character that means we don't give away it's attributes stats
	-- // This approach eliminates the potential errors

	local character = localPlayer.Character

	-- // Let's wait to make sure CmdrClient Controller processed everything

	repeat
		task.wait(0.2)
	until cmdrClient.ActivationKeys :: table | false ~= nil

	-- // Setting to nil makes the key not appear in the table so it will be ignored,
	-- // however the 'false' value will appear

	return {
		Console = cmdrClient.ActivationKeys :: table | false or nil,
		Fly = if character then character:GetAttribute("Fly") :: boolean? else nil,
		SlowWalk = if character then character:GetAttribute("SlowWalk") :: boolean? else nil,
	}
end

local function updateText(elements: table, consoleFrameVisible: boolean?): ()
	-- // This function updates the TextLabel

	local stats = getStats()

	local colors = {
		linesOff = Color3.fromRGB(255, 255, 255):ToHex(),
		linesOn = Color3.fromRGB(236, 195, 31):ToHex(),
	}

	local linesOff = {
		Console = "Activate the command console",
		Fly = "Start flying",
		SlowWalk = "Switch to normal walk speed",
	}

	local linesOn = {
		Console = "Deactivate the command console",
		Fly = "Stop flying",
		SlowWalk = "Switch to power walk speed",
	}

	local lines = {
		linesOn = linesOn,
		linesOff = linesOff,
	}

	local linesToShow, linesToCalculate, orderedLines = {}, {}, {}

	local function getStatus(stat: boolean): string
		return if stat then "linesOn" else "linesOff"
	end

	if stats.Console then
		-- // This is skipped when the value is 'false' instead of 'table'

		local status = getStatus(consoleFrameVisible)
		local esc = if status == "linesOn" then " / [Click anywhere]" else ""

		linesToCalculate.Console = `{table.concat(stats.Console, " / ")}{esc} - {lines[status].Console}`
		linesToShow.Console = `<font color="#{colors[status]}">%s</font>`
	end

	if stats.Fly ~= nil then
		local status = getStatus(stats.Fly)

		linesToCalculate.Fly = `Space x2 - {lines[status].Fly}`
		linesToShow.Fly = `<font color="#{colors[status]}">%s</font>`
	end

	if stats.SlowWalk ~= nil then
		local status = getStatus(stats.SlowWalk)

		linesToCalculate.SlowWalk = `Ctrl - {lines[status].SlowWalk}`
		linesToShow.SlowWalk = `<font color="#{colors[status]}">%s</font>`
	end

	for _, line in next, linesToCalculate do
		-- // To use table.sort we need an array, not a dictionary table

		table.insert(orderedLines, line)
	end

	table.sort(orderedLines, function(a: string, b: string): boolean
		-- // Sorting from the least wide text to the widest one
		-- // Lines to calculate have no rich text tags (html) to be calculated properly

		return getTextSizeInTextLabel(a, elements).X < getTextSizeInTextLabel(b, elements).X --#a < #b
	end)

	for index, text in ipairs(orderedLines) do
		-- // Now we apply the rich text tags by formatting the tags string with the normal text
		-- // It's a bit tricky but it is what it is when you want to use table.sort() instead of
		-- // making your own more complicated sorting function for two dictionary tables.
		-- // Minimally more resource-consuming but the code is much simpler

		orderedLines[index] = linesToShow[findInDictionary(linesToCalculate, text)]:format(text)
	end

	-- // We set the text from strings separated by new line

	elements.TextLabel.Text = table.concat(orderedLines, "\n")
end

local function characterAdded(character: Model, elements: table, consoleFrameVisible: boolean?): ()
	-- // Character signal binds function

	local humanoid = character:WaitForChild("Humanoid")
	local characterConnections = {}
	local deathConnection

	--[[
	-- // Restore the missing attributes if not present
	-- // Otherwise it will appear after using it
	-- // If there's not a given attribute the get call returns 'nil'
	-- // not not makes the 'nil' value 'false' and thus creates an attribute

	character:SetAttribute("Fly", not not character:GetAttribute("Fly"))
	character:SetAttribute("SlowWalk", not not character:GetAttribute("SlowWalk"))
	]]

	deathConnection = humanoid.Died:Connect(function(): ()
		-- // Disconnect this connection

		deathConnection:Disconnect()

		-- // Disconnect all old character's connections

		for _, connection in next, characterConnections do
			connection:Disconnect()
		end

		-- // Set the character attributes to false if not 'nil', the else statement is required

		character:SetAttribute("Fly", if character:GetAttribute("Fly") ~= nil then false else nil)
		character:SetAttribute("SlowWalk", if character:GetAttribute("SlowWalk") ~= nil then false else nil)

		-- // As we disconnected we need to run this manually
		-- // But now we run this once instead of 2 times

		updateText(elements, consoleFrameVisible)
	end)

	local function onAttribute(): ()
		updateText(elements, consoleFrameVisible)
	end

	table.insert(characterConnections, character:GetAttributeChangedSignal("Fly"):Connect(onAttribute))
	table.insert(characterConnections, character:GetAttributeChangedSignal("SlowWalk"):Connect(onAttribute))

	profileManager:GetProfileData("RewardedPowers"):andThen(function(rewardedPowers: table): ()
		if rewardedPowers["Fly"] then
			character:SetAttribute("Fly", false)
		end
	end)
end

local function bindUpdates(elements: table, stats: table): ()
	-- // [One time] Connect to signals to keep TextLabel up-to-date

	local playerGUI = localPlayer:WaitForChild("PlayerGui")
	local frame

	if stats.Console then
		-- // This is skipped when the value is 'false' instead of 'table'
		-- // The value shouldn't be nil as we waited for this in getStats()

		frame = playerGUI:WaitForChild("Cmdr"):WaitForChild("Frame")

		frame:GetPropertyChangedSignal("Visible"):Connect(function(): ()
			updateText(elements, frame.Visible)
		end)

		if frame.Visible then
			updateText(elements, frame.Visible)
		end
	end

	if localPlayer.Character then
		-- // If the character is present already

		characterAdded(localPlayer.Character, elements, if frame then frame.Visible else nil)
	end

	localPlayer.CharacterAdded:Connect(function(character: Model): ()
		characterAdded(character, elements, if frame then frame.Visible else nil)
	end)
end

local function mobileCheck(): boolean
	-- // No keyboard == "mobile"
	-- // We only need to check this because we provide keyboard keys only for now

	return not userInputService.KeyboardEnabled
end

local function onStart(): ()
	-- // This functions runs at first

	if mobileCheck() then
		-- // Return if there's no keyboard

		--print("KeyBindInfo: Player is on mobile")

		return
	end

	task.wait(2)

	-- // Get necessary Controllers

	cmdrClient = knit.GetController("CmdrClient")
	profileManager = knit.GetService("ProfileManager")
	tween = knit.GetController("Tween")

	-- // Wait if the game is not loaded

	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	-- // Wait if the character is not present

	if not localPlayer.Character then
		localPlayer.CharacterAdded:Wait()
	end

	-- // Create the GUI and get the stats
	-- // Stats table here is used to check if we should expect the Cmdr console gui
	-- // and listen to it's signal

	local guiElements = createGUI()
	local stats = getStats()

	updateSize(guiElements)
	updateText(guiElements)
	bindUpdates(guiElements, stats)
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return keyBindInfo
