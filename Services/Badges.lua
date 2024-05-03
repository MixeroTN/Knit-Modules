--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages badges

]]

-- // Services \\ --

local badgeService = game:GetService("BadgeService")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local dataManager, profileManager, ranks, tutorial

local badges = knit.CreateService({
	Name = "Badges",
	Client = {},
})

-- // Private Variables \\ --

-- // BadgeService call limit is 100 per minute

local bsCurrent = 0
local bsLimit = 100

local datas = {}
local playerBindedFunction = {}

-- // Private Functions \\ --

local function bsLimitControl(): boolean
	while bsCurrent >= bsLimit do
		task.wait(1)
	end

	bsCurrent += 1

	task.defer(function(): ()
		task.wait(60)

		bsCurrent -= 1
	end)

	return true
end

local function awardBadge(player: Player, badgeId: number): boolean?
	if bsLimitControl() then
		local success, badgeInfo = pcall(badgeService.GetBadgeInfoAsync, badgeService, badgeId)

		if success then
			if badgeInfo.IsEnabled and bsLimitControl() then
				local awarded = pcall(badgeService.AwardBadge, badgeService, player.UserId, badgeId)

				if not awarded then
					return false
				else
					return true
				end
			end
		end
	end
end

local function checkBadge(player: Player, badgeId: number): boolean?
	if bsLimitControl() then
		local success, hasBadge = pcall(badgeService.UserHasBadgeAsync, badgeService, player.UserId, badgeId)

		if not success then
			return
		elseif hasBadge then
			return true
		else
			return false
		end
	end
end

local function safeCheck(func: any, ...: any?): any?
	local MAX_RETRIES = 10
	local TIMEOUT = 1

	for _ = 1, MAX_RETRIES do
		local action = func(...)

		if action or action == false then
			return action
		end

		task.wait(TIMEOUT)
	end
end

local function welcomeBadge(player: Player): ()
	local badgeId = datas.Badges.badges.special.Welcome.id
	local badgeStatus = safeCheck(checkBadge, player, badgeId)

	if badgeStatus ~= nil then
		if badgeStatus == false then
			-- // This is a first time player gains the welcome badge

			badgeStatus = safeCheck(awardBadge, player, badgeId)

			-- // Launch tutorial

			tutorial:Call(player, "Launch")
		end
	end
end

local function metADevBadge(_: Player): ()
	local badgeId = datas.Badges.badges.special.MetADev.id

	local function giveBadgeToEveryone(): ()
		for _, player2 in pairs(players:GetPlayers()) do
			safeCheck(awardBadge, player2, badgeId)
			task.wait()
		end
	end

	local function checkWordsForDev(givenPlayer: Player): boolean?
		local playerRank = givenPlayer:GetRoleInGroup(datas.BasicData.groups.main.id)

		for _, word in pairs(datas.Badges.groupRoleWordsToCountAsDev) do
			if string.find(playerRank, word) then
				giveBadgeToEveryone()

				return true
			end
		end
	end

	for _, player2 in pairs(players:GetPlayers()) do
		checkWordsForDev(player2)
	end
end

local function secretBadge(player: Player): ()
	local MAX_MAGNITUDE = 150

	local badgeId = datas.Badges.badges.special.Secret.id
	local badgeStatus = safeCheck(checkBadge, player, badgeId)

	if badgeStatus ~= nil then
		if badgeStatus == false then
			local character = player.Character or player.CharacterAdded:Wait()
			local magnitude = (
				workspace:WaitForChild("Chests"):WaitForChild("CaveChest").Hitbox.Position
				- character:WaitForChild("HumanoidRootPart").Position
			).Magnitude

			if magnitude <= MAX_MAGNITUDE then
				badgeStatus = safeCheck(awardBadge, player, badgeId)
			end
		end
	end
end

local function classBadge(player: Player): ()
	local playerData = profileManager:GetProfileData(player)
	local playerRank = playerData.Rank.Rank
	local playerRankData = datas.RankData.ranks[playerRank] or datas.RankData.default
	local playerRankPower = playerRankData.rankPower

	for rank, data in next, datas.RankData.ranks do
		if data.rankPower <= playerRankPower then
			local badgeId = datas.Badges.badges.rank[rank].id
			local badgeStatus = safeCheck(checkBadge, player, badgeId)

			if badgeStatus == false then
				safeCheck(awardBadge, player, badgeId)
			end
		end
	end
end

local function playerJoined(player: Player): ()
	welcomeBadge(player)
	metADevBadge(player)
	classBadge(player)

	playerBindedFunction[player.Name] = {
		ranks.RankChanged:Connect(function(playerFromEvent: Player, rank: string): ()
			if playerFromEvent == player then
				classBadge(player)
			end
		end),
	}
end

local function playerLeft(player: Player): ()
	for _, func in next, playerBindedFunction[player.Name] do
		func:Disconnect()
	end

	playerBindedFunction[player.Name] = nil
end

local function onStart(): ()
	task.wait(0.5)

	dataManager = knit.GetService("DataManager")
	profileManager = knit.GetService("ProfileManager")
	ranks = knit.GetService("Rank")
	tutorial = knit.GetService("Tutorial")

	datas = {
		Badges = dataManager:GetData("Badges"),
		BasicData = dataManager:GetData("BasicData"),
		RankData = dataManager:GetData("RankData"),
	}

	task.wait(2)

	players.PlayerAdded:Connect(playerJoined)
	players.PlayerRemoving:Connect(playerLeft)

	for _, player in next, players:GetPlayers() do
		playerJoined(player)
	end
end

-- // Public Functions \\ --

function badges:AwardSecretBadge(player: Player): ()
	secretBadge(player)
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return badges
