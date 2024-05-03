--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages player bans globally

]]

-- // Services \\ --

local httpService = game:GetService("HttpService")
local messagingService = game:GetService("MessagingService")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local testService = game:GetService("TestService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Knit Setup \\ --

local banManager = knit.CreateService({
	Name = "BanManager",
})

local profileManager

-- // Private Functions \\ --

local function getPermBanPrefix(timeString: string): boolean
	return timeString == "." or timeString == "0"
end

local function getNoReasonPrefix(reason: string): boolean
	return reason == "."
end

local function calculateTime(timeString: string): number?
	if getPermBanPrefix(timeString) then
		return math.huge
	end

	local dateMap = {
		y = "year",
		mo = "month",
		d = "day",
		h = "hour",
		m = "min",
		s = "sec",
	}

	local date = os.date("!*t")

	local pattern = "(%d+)(%a+)"

	for number, word in timeString:gmatch(pattern) do
		if not dateMap[word] then
			return
		end

		date[dateMap[word]] += tonumber(number)
	end

	return os.time(date)
end

local function timeSubtraction(time: number): table
	local expirationDate = os.date("!*t", time)
	local currentDate = os.date("!*t")

	for key in next, expirationDate do
		if type(expirationDate[key]) == "number" then
			expirationDate[key] -= currentDate[key]
		end
	end

	return expirationDate
end

local function remainingTimeToString(time: number): string
	local date = timeSubtraction(time)

	local dateMapFew = {
		year = "years",
		month = "months",
		day = "days",
		hour = "hours",
		min = "mins",
		sec = "secs",
	}

	local dateToDisplay = {}

	for key, value in next, dateMapFew do
		if date[key] then
			if date[key] > 1 then
				table.insert(dateToDisplay, `{tostring(date[key])} {value}`)
			elseif date[key] == 1 then
				table.insert(dateToDisplay, `{tostring(date[key])} {key}`)
			end
		end
	end

	return table.concat(dateToDisplay, " ")
end

local function getPlayerIdFromString(playerName: string): (boolean, number | string)
	return pcall(function(): number
		return players:GetUserIdFromNameAsync(playerName)
	end)
end

local function getPlayerId(player: Player | string | number): number | string?
	if typeof(player) == "Instance" then
		return player.UserId
	elseif typeof(player) == "string" then
		return table.pack(getPlayerIdFromString(player))[2]
	elseif typeof(player) == "number" then
		return player
	end
end

local function setNewBanData(time: number?, reason: string, executor: number?): table
	return {
		Banned = if time then true else false,
		BanReason = if getNoReasonPrefix(reason) then "" else reason,
		BannedFor = time or 0,
		BannedBy = executor or 0,
	}
end

local function decodeMessage(message: string): (string, string, string, string)
	local splitValues = {}

	for value in message:gmatch("[^|]+") do
		table.insert(splitValues, value)
	end

	return table.unpack(splitValues)
end

local function kick(player: Player, reason: string, executor: number?, altTitle: string?, timeLeft: string?): ()
	player:Kick(
		("%s%s%s%s"):format(
			altTitle or "You have been kicked",
			if executor then ` by {players:GetNameFromUserIdAsync(executor)}.` else "!",
			if reason then ` Reason: {reason}.` else "",
			if timeLeft then ` Time left: {timeLeft}.` else ""
		)
	)
end

local function banKick(player: Player, reason: string, executor: number, timeLeft: string?): ()
	kick(player, reason, executor, "You have been banned", timeLeft)
end

local function getPlayerInServer(playerId: number): Player?
	return players:FindFirstChild(players:GetNameFromUserIdAsync(playerId))
end

local function validateMessage(message): boolean?
	local id, reason, executor, time = decodeMessage(message)
	local player = getPlayerInServer(tonumber(id))

	return player, reason, executor, time
end

local function getError(playerId: number | string?, time: number?, checkForTime: boolean?): string?
	if not playerId then
		return "Unknown type of player."
	elseif type(playerId) == "string" then
		return playerId
	elseif checkForTime and not time then
		return "Incorrect time format."
	end
end

local function onStart(): ()
	task.wait(0.5)

	profileManager = knit.GetService("ProfileManager")

	-- // MESSAGE FORMAT: "<player-id>|<reason>|<executor-id>|<expiration-time>"
	-- // This only kicks the player with the provided message
	-- // The Ban public function loads the profile and saves the ban

	messagingService:SubscribeAsync("Ban", function(message: table): ()
		local player, reason, executor, time = validateMessage(message["Data"])
		local timeLeft = remainingTimeToString(calculateTime(time))

		if player then
			banKick(player, reason, executor, timeLeft)
		end
	end)

	messagingService:SubscribeAsync("Kick", function(message: table): ()
		local player, reason, executor = validateMessage(message["Data"])

		if player then
			kick(player, reason, executor)
		end
	end)

	messagingService:SubscribeAsync("Test", function(message: table): ()
		testService:Message("[MSG ECHO TEST]: " .. message["Data"])
	end)

	-- // Listen to joining player and kick the banned ones

	local function playerAdded(player: Player): ()
		local playerBanData = profileManager:GetProfileData(player, "BanData")
		local timeLeft = remainingTimeToString(playerBanData["BannedFor"])

		if playerBanData["BannedFor"] > os.time() then
			banKick(player, playerBanData["BanReason"], playerBanData["BannedBy"], timeLeft)
		elseif playerBanData["BannedFor"] > 0 then
			banManager:Unban(player, nil, `[Expired] {playerBanData["BanReason"]}`)
		end
	end

	players.PlayerAdded:Connect(playerAdded)

	for _, player in next, players:GetPlayers() do
		playerAdded(player)
	end
end

-- // Public Functions \\ --

function banManager:GetHistory(player: Player | string | number, timeZone: number): table
	local tableToReturn = {}
	local playerBanHistory, playerId

	if typeof(player) ~= "Instance" then
		playerId = getPlayerId(player)
		playerBanHistory = profileManager:LoadData(playerId).Data["BanHistory"]
	else
		playerBanHistory = profileManager:GetProfileData(player, "BanHistory")
	end

	for key, value in next, playerBanHistory do
		local timeZoneOffsetHours = tonumber(string.sub(timeZone, 1, 3))
		local timeZoneOffsetMinutes = tonumber(string.sub(timeZone, 1, 1) .. string.sub(timeZone, 4, 5))
		local savedDate = os.date("!*t", key)
		local newDate = table.clone(savedDate)

		newDate.hour += timeZoneOffsetHours
		newDate.min += timeZoneOffsetMinutes

		local newTime = os.time(newDate)
		local timeZoneOffset = os.time(os.date("*t")) - os.time(os.date("!*t"))
		local timeValue = newTime - timeZoneOffset
		local valueToReturn = `[{os.date("%x %X", timeValue)}]: {value}`

		tableToReturn[key] = valueToReturn
	end

	return tableToReturn, playerBanHistory
end

function banManager:GetHistoryInString(player: Player | string | number, timeZone: number): string
	local fullTable, playerBanHistory = self:GetHistory(player, timeZone)
	local sortingTable, addInfo = {}, {}
	local concat = "Calculated Timezone: " .. timeZone .. "\n"

	concat = concat .. string.rep("-", #concat)

	for key in next, playerBanHistory do
		table.insert(sortingTable, key)
	end

	table.sort(sortingTable, function(a: number, b: number): ()
		return a > b
	end)

	for _, value in ipairs(sortingTable) do
		concat = concat .. "\n" .. fullTable[value]
	end

	if #sortingTable == 0 then
		table.insert(addInfo, "\nNo activity for this user.")
	end

	return concat .. table.concat(addInfo, "\n")
end

function banManager:Ban(
	player: Player | string | number,
	executor: number,
	timeString: string,
	reason: string
): (boolean, string)
	-- // Typechecking explained: player: player object or account name or id,
	-- // timestring: "4d7h" / "1y2mo3d4h5m6s" (for example), reason: "exploiting" (for example),
	-- // Returning: boolean (Did it succeed?): true/false, string: message to return (mainly for Cmdr)

	local playerId = getPlayerId(player)
	local time = calculateTime(timeString)
	local error = getError(playerId, time, true)
	local remainingTime = remainingTimeToString(time)

	if error then
		return false, error
	end

	messagingService:PublishAsync(
		"Ban",
		`{playerId}|{if getNoReasonPrefix(reason) then "" else reason}|{executor}|{timeString}`
	)

	local newBanData = setNewBanData(time, reason, executor)
	local playerName = players:GetNameFromUserIdAsync(playerId)
	local executorName = players:GetNameFromUserIdAsync(executor)
	local returned, oldValue = profileManager:ReplaceTable(player, "BanData", newBanData)

	--[[if remainingTime <= 5 then
		remainingTime = "[Unbanned]"
	end]]

	profileManager:InsertDictionary(
		player,
		"BanHistory",
		tostring(os.time()),
		`BAN || For: {remainingTime} || By: {executorName} || Reason: {reason}`
	)

	if returned then
		if oldValue["Banned"] then
			return true,
				`{playerName} was banned before. The ban data has been overwritted with the provided one.`
					.. if oldValue["BannedFor"] == math.huge
						then " Was banned permanently."
						else "" .. `The reason was: {if oldValue["BanReason"]
							then oldValue["BanReason"]
							else "[No reason]"}.`
		else
			return true, `{playerName} has been banned!`
		end
	else
		return false, "The command failed. Check the console."
	end
end

function banManager:Unban(player: Player | string | number, executor: number?, reason: string): (boolean, string)
	-- // Typechecking explained: player: player object or account name or id,
	-- // reason: "it was a mistake" (for example),
	-- // Returning: boolean (Did it succeed?): true/false, string: message to return (mainly for Cmdr)

	local playerId = getPlayerId(player)
	local error = getError(playerId)

	if error then
		return false, error
	end

	local playerName = players:GetNameFromUserIdAsync(playerId)
	local executorName = if executor then players:GetNameFromUserIdAsync(executor) else "[System]"
	local returned, oldValue = profileManager:ReplaceTable(player, "BanData", setNewBanData(nil, reason, executor))

	profileManager:InsertDictionary(
		player,
		"BanHistory",
		tostring(os.time()),
		`UNBAN || By: {executorName} || Reason: {reason}`
	)

	if returned then
		if oldValue["Banned"] then
			return true,
				`{playerName} has been unbanned.` .. if oldValue["BannedFor"] == math.huge
					then " Was banned permanently."
					else "" .. `The ban reason was: {if oldValue["BanReason"]
						then oldValue["BanReason"]
						else "[No reason]"}.`
		else
			return true,
				`{playerName} wasn't banned! However, the reason has been overwritted.`
					.. `The ban reason was: {if oldValue["BanReason"] then oldValue["BanReason"] else "[No reason]"}.`
		end
	else
		return false, "The command failed. Check the console."
	end
end

-- // Initialize \\ --

knit.OnStart():andThen(onStart, warn)

return banManager
