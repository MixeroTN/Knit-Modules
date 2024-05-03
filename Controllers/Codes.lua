--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages codes on client

]]

-- // Services \\ --

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- // Object Variables \\ --

local localPlayer = players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local codesGui = playerGui:WaitForChild("Codes")
local mainFrame = codesGui:WaitForChild("MainFrame")
local enterButton = mainFrame:WaitForChild("EnterButton")
local textBox = mainFrame:WaitForChild("TextBox")

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local codes = knit.CreateController({
	Name = "Codes",
})

-- // Knit Services \\ --

local codesService, dataManager, profileManager, slotController

-- // Private Variables \\ --

local responseTextColors = {
	red = Color3.fromRGB(255, 24, 24),
	green = Color3.fromRGB(50, 255, 19),
	white = Color3.fromRGB(255, 255, 255),
}

local redeemedCodesProfileArrayName = "RedeemedCodes"

local timeout = 1.5

local alreadyOpened = false
local canInput = true

local datas = {}

-- // Private Functions \\ --

local function isCodeExisting(code: string): boolean
	return datas.Codes[code] ~= nil
end

local function isCodeRedeemed(code: string): boolean
	return table.find(profileManager:GetProfileData():expect()[redeemedCodesProfileArrayName], code) ~= nil
end

local function onInput(code: string): (boolean?, string?)
	-- // This function runs when a code is being tried to redeem

	if not code or code == "" then
		return
	end

	-- // Code doesn't exist

	if not isCodeExisting(code) then
		return false, "Code does not exist!"
	end

	-- // Code is redeemed

	if isCodeRedeemed(code) then
		return false, "Code is already redeemed!"
	end

	-- // Redeem code

	local status = codesService:RedeemCode(code):expect()

	if not status then
		return false, "You can't redeem this code!"
	end

	return true, "Code successfully redeemed!"
end

local function unlock(): ()
	-- // Unlock codes section

	canInput = true
	textBox.TextEditable = true
	textBox.ClearTextOnFocus = true
	textBox.TextColor3 = responseTextColors.white
	textBox.Text = ""
end

local function lock(andUnlock: boolean?, customTime: number?): ()
	-- // Lock codes section

	canInput = false
	textBox.TextEditable = false
	textBox.ClearTextOnFocus = false

	if andUnlock then
		task.wait(customTime or timeout)
		unlock()
	end
end

local function setTextBoxColor(color: Color3): Color3
	-- // Sets textbox color for codes

	textBox.TextColor3 = color

	return textBox.TextColor3
end

local function chooseTextBoxColor(value: boolean?): Color3
	-- // Choose text box color

	local textBoxColorStatus

	if value == true then
		textBoxColorStatus = setTextBoxColor(responseTextColors.green)
	elseif value == false then
		textBoxColorStatus = setTextBoxColor(responseTextColors.red)
	else -- // nil
		textBoxColorStatus = setTextBoxColor(responseTextColors.white)
	end

	return textBoxColorStatus
end

local function textBoxControl(code: string?): boolean?
	-- // textBoxControl

	code = code or textBox.Text

	local result = table.pack(onInput(code))

	if #result < 2 then
		return
	end

	chooseTextBoxColor(result[1])

	textBox.Text = result[2] or ""

	return result[1]
end

local function buttonPressed(): ()
	-- // This runs whenever the button is pressed

	if not canInput then
		return
	end

	textBoxControl()
	lock(true)
end

local function bindSlot(slot: ImageButton): ()
	slot.MouseEnter:Connect(function(): ()
		slotController:MouseEntered(slot)
	end)

	slot.MouseLeave:Connect(function(): ()
		slotController:MouseLeave(slot)
	end)

	slot.MouseButton1Down:Connect(function(): ()
		slotController:MouseDown(slot)
	end)

	slot.MouseButton1Click:Connect(function(): ()
		buttonPressed()
	end)
end

local function onStart(): ()
	task.wait(0.5)

	-- // Get neccesary utilities

	codesService = knit.GetService("Codes")
	dataManager = knit.GetService("DataManager")
	profileManager = knit.GetService("ProfileManager")
	slotController = knit.GetController("Slot")

	datas = {
		Codes = dataManager:GetData("Codes"):expect(),
	}

	-- // Bind tweens for enter button

	bindSlot(enterButton)
end

-- // Public Functions \\ --

function codes:Opened(): ()
	if not alreadyOpened then
		alreadyOpened = true
	end
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return codes
