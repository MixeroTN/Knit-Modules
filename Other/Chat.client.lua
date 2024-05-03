--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages chat on client

]]

-- // Services \\ --

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local textChatService = game:GetService("TextChatService")

-- // Object Variables \\ --

local localPlayer: Player = players.LocalPlayer

local packages: Folder = replicatedStorage:WaitForChild("Packages")

local channelsFolder: Folder = textChatService:WaitForChild("TextChannels")
local channel: TextChannel = channelsFolder:WaitForChild("RBXSystem")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local dataManager
local profileManager
local reputationsController
local chatService

-- // Private Variables \\ --

local datas = {}

-- // Private Functions \\ --

local function defaultMessage(): table
	return table.clone(datas.ChatData.default)
end

local function welcomeMessage(): table
	return table.clone(datas.ChatData.systemMessages.welcome)
end

local function rankUpMessage(): table
	return table.clone(datas.ChatData.systemMessages.rankUp)
end

local function serverTag(): table
	return table.clone(datas.ChatData.tags.special.server)
end

local function gameLoadedCheck(): boolean
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	return true
end

local function systemMessageHandler(MsgDict: table, ToFormat: table?): ()
	local array: table = {}

	if gameLoadedCheck() then
		for key, value in next, defaultMessage() do
			array[key] = MsgDict[key] or value
			if ToFormat and type(array[key]) == "string" then
				array[key] = array[key]:format(ToFormat[key])
			end
		end

		array["fontColor"] = array["fontColor"]:ToHex() :: string
		array["text"] = ("[%s]: %s"):format(serverTag().text, array["text"])
		MsgDict = array

		channel:DisplaySystemMessage(
			'<font color="#'
				.. MsgDict["fontColor"]
				.. '"><font size="'
				.. MsgDict["fontSize"]
				.. '"><font face="'
				.. MsgDict["font"]
				.. '">'
				.. MsgDict["text"]
				.. "</font></font></font>"
		)
	end
end

local function playerMessageHandler(message: TextChatMessage): TextChatMessageProperties
	if not message.TextSource then
		return
	end

	local properties = Instance.new("TextChatMessageProperties")
	local player: Player = players:GetPlayerByUserId(message.TextSource.UserId)

	local tag = "[%s] "
	local reputationName: string?, reputationColor: string?
	local groupRoleName: string?, groupRoleColor: string?
	local gamepassName: string?, gamepassColor: string?

	local chatData = chatService:GetChatData(player):expect()

	local reputationNum, playerGamepassData, chatTagsEnabled = chatData[1], chatData[2], chatData[3]
	local chatReputationData: table? = datas.ChatData.tags.prefix.reputation
	local reputationData: table = datas.ReputationData
	local validReputationTable: table?

	reputationNum, validReputationTable = reputationsController:GetReputationData(reputationNum)

	reputationName = (tag):format(validReputationTable.text)
	reputationColor = validReputationTable.fontColor:ToHex() :: string

	local groupRank: number = player:GetRoleInGroup(datas.BasicData.groups.main.id)
	local groupRankData: table = datas.ChatData.tags.prefix.group
	local playerRankData: table? = groupRankData.personal[player.UserId]

	groupRoleName = defaultMessage().text
	groupRoleColor = defaultMessage().fontColor:ToHex() :: string

	if not playerRankData then
		playerRankData = defaultMessage()

		for key, value in next, groupRankData.role do
			if string.find(groupRank, key) then
				playerRankData = value
				groupRoleName = (tag):format(value.text)
				groupRoleColor = playerRankData.fontColor:ToHex() :: string
				break
			end
		end
	end

	local gamepassData: table = datas.ChatData.tags.prefix.gamepass

	if playerGamepassData then
		gamepassData = gamepassData.vip
		gamepassName = (tag):format(gamepassData.text)
	else
		gamepassData = defaultMessage()
		gamepassName = gamepassData.text
	end
	gamepassColor = gamepassData.fontColor:ToHex() :: string

	local playerColor: string = groupRoleColor or reputationColor
	local textString: string = "<font size='%s'><font face='%s'>%s</font></font>"

	properties.Text = (textString):format(defaultMessage().fontSize, defaultMessage().font, message.Text)

	if chatTagsEnabled then
		local prefixTextString: string =
			'<font size="%s"><font face="%s"><font color="#%s">%s</font><font color="#%s">%s</font><font color="#%s">%s</font><font color="#%s">%s:</font></font></font>'

		properties.PrefixText = (prefixTextString):format(
			defaultMessage().fontSize,
			defaultMessage().font,
			reputationColor,
			reputationName,
			groupRoleColor,
			groupRoleName,
			gamepassColor,
			gamepassName,
			playerColor,
			player.Name
		)
	else
		local prefixTextString: string = '<font size="%s"><font face="%s">%s:</font></font>'

		properties.PrefixText = (prefixTextString):format(defaultMessage().fontSize, defaultMessage().font, player.Name)
	end

	return properties
end

local function rankChanged(player: Player, rank: string): ()
	if player ~= localPlayer then
		return
	end

	local rankUpMessageTable = rankUpMessage()

	rankUpMessageTable.text = (rankUpMessageTable.text):format(rank)

	systemMessageHandler(rankUpMessageTable)
end

local function onStart(): ()
	dataManager = knit.GetService("DataManager") :: table
	profileManager = knit.GetService("ProfileManager") :: table
	reputationsController = knit.GetController("Reputations")
	chatService = knit.GetService("Chat")

	datas = {
		BasicData = dataManager:GetData("BasicData"):expect() :: table,
		ChatData = dataManager:GetData("ChatData"):expect() :: table,
		ReputationData = dataManager:GetData("ReputationData"):expect() :: table,
	}

	-- // Waiting for humanoid to make sure chat is loaded
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait() :: Model

	character:WaitForChild("Humanoid")

	systemMessageHandler(welcomeMessage())

	textChatService.OnIncomingMessage = playerMessageHandler

	profileManager.Rank._re.OnClientEvent:Connect(rankChanged)
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)
