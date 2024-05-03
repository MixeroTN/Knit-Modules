--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages data & profiles

]]

-- // Services \\ --

local marketplaceService = game:GetService("MarketplaceService")
local memoryStoreService = game:GetService("MemoryStoreService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local players = game:GetService("Players")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")
local server = serverScriptService:WaitForChild("Server")
local data = server:WaitForChild("Data")

-- // Loaded Modules \\ --

local profileService = require(packages:WaitForChild("ProfileService"))
local signalsService = require(packages:WaitForChild("SignalsService"))
local developerProducts = require(data:WaitForChild("DeveloperProducts"))
local gamepassData = require(data:WaitForChild("Gamepasses"))
local knit = require(packages:WaitForChild("Knit"))
local profileData = require(data:WaitForChild("ProfileData"))

-- // Private Variables \\ --

local profileKey = "PCS27"
local loadedDatasMapName = "LoadedDatas"

local settings = {
	profileTemplate = profileData.profileTemplate,

	products = developerProducts,

	purchaseIdLog = 50,
}

local profileStore = profileService.GetProfileStore(profileKey, settings.profileTemplate)

local statsToSkip = {
	--"Settings",
	"BanData",
	--"BanHistory",
}

local nameToAdress = {
	x = "Multipliers",
	y = "RewardedPowers",
	r = "Rank",
	s = "Stats",
	g = "Reputation",
}

local loadedDatasMap = memoryStoreService:GetSortedMap(loadedDatasMapName)

local prefixStatsToSkip

-- // Knit Setup \\ --

local hudEffects
local questsService
local rankService
local reputationsService
local settingsService

local profileManager = knit.CreateService({
	Name = "ProfileManager",
	Client = {
		AssignedPowers = knit.CreateSignal(),
		RedeemedCodes = knit.CreateSignal(),
		Quests = knit.CreateSignal(),
		Settings = knit.CreateSignal(),
		RewardedPowers = knit.CreateSignal(),
		Gamepasses = knit.CreateSignal(),
		Multipliers = knit.CreateSignal(),
		BanData = knit.CreateSignal(),
		BanHistory = knit.CreateSignal(),
		Rank = knit.CreateSignal(),
		Reputation = knit.CreateSignal(),
		Stats = knit.CreateSignal(),
		ClaimedChests = knit.CreateSignal(),
		Misc = knit.CreateSignal(),
	},
})

profileManager.Changed = signalsService.new()
profileManager.Profiles = {}

table.freeze(settings.profileTemplate)

-- // Private Functions \\ --

local function addLeaderstats(player: Player): ()
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local reputationValue = Instance.new("StringValue")
	reputationValue.Parent = leaderstats
	reputationValue.Name = "Reputation"
	reputationValue.Value = "N/A"

	local classValue = Instance.new("StringValue")
	classValue.Parent = leaderstats
	classValue.Name = "Class"
	classValue.Value = "N/A"

	task.spawn(function(): ()
		repeat
			task.wait(0.1)
		until profileManager.Profiles[player]

		local profile = profileManager:GetProfileData(player)
		local reputation = profile.Reputation.Reputation
		local _, reputationName = reputationsService:GetReputationData(reputation)

		reputationValue.Value = reputationName.text

		reputationsService.ReputationChanged:Connect(function(changedPlayer: Player, newReputation: number): ()
			if changedPlayer == player then
				local _, changedReputationName = reputationsService:GetReputationData(newReputation)

				reputationValue.Value = changedReputationName.text
			end
		end)

		local rank = profile.Rank.Rank

		if not profile.Settings.ConcealPower.HideRank then
			classValue.Value = rank
		end

		settingsService.SettingChanged:Connect(
			function(changedPlayer: Player, settingName: string, settingValue: table | any?): ()
				if changedPlayer == player and settingName == "ConcealPower" then
					local hideRank = settingValue["HideRank"]

					if hideRank then
						classValue.Value = "N/A"
					else
						classValue.Value = rank
					end
				end
			end
		)

		rankService.RankChanged:Connect(function(changedPlayer: Player, newRank: string): ()
			if changedPlayer == player and not profile.Settings.ConcealPower.HideRank then
				classValue.Value = newRank
			end
		end)

		reputationsService.ReputationChanged:Connect(function(changedPlayer: Player, newReputation: string): ()
			if changedPlayer == player then
				reputationValue.Value = newReputation
			end
		end)
	end)
end

local function playerAdded(player: Player): ()
	-- // This fires whenever a player joins

	local profile = profileStore:LoadProfileAsync(tostring(player.UserId))

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile() -- // Fill missing variables

		-- // Remove profile when player left

		profile:ListenToRelease(function(): ()
			profileManager.Profiles[player] = nil

			player:Kick("Player is on another server!")
		end)

		-- // Check if player exists

		if player:IsDescendantOf(players) then
			profileManager.Profiles[player] = profile
		else
			profile:Release()
		end
	else
		-- // Couldn't load data

		player:Kick("Couldn't load data, please rejoin.")
	end

	addLeaderstats(player)
end

local function playerLeft(player: Player): ()
	local profile = profileManager.Profiles[player]

	if profile ~= nil then
		profile:Release()
	end
end

function purchaseIdCheckAsync(
	profile: table,
	purchaseId: number,
	grantProductCallback: () -> ()
): Enum.ProductPurchaseDecision
	if not profile then
		-- // Return if profile isn't available

		return Enum.ProductPurchaseDecision.NotProcessedYet
	else
		task.spawn(function(): ()
			local metaData = profile.MetaData
			local purchaseIds = metaData.MetaTags.ProfilePurchaseIds
			local result
			local metaTagsConnection

			if not purchaseIds then
				-- // Create ProfilePurchaseIds if it doesn't exists

				purchaseIds = {}

				metaData.MetaTags.ProfilePurchaseIds = purchaseIds
			end

			-- // Grants product if it's not received

			if not table.find(purchaseIds, purchaseId) then
				while #purchaseIds >= settings.purchaseIdLog do
					table.remove(purchaseIds, 1)
				end

				table.insert(purchaseIds, purchaseId)

				task.spawn(grantProductCallback)
			end

			-- // Check on metatags if purchase is granted

			local function checkLatestMetaTags(): ()
				local savedPurchaseIds = metaData.MetaTagsLatest.ProfilePurchaseIds

				if savedPurchaseIds ~= nil and table.find(savedPurchaseIds, purchaseId) ~= nil then
					result = Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end

			checkLatestMetaTags()

			-- // Fires after metatags are updated and if profile is released

			metaTagsConnection = profile.MetaTagsUpdated:Connect(function(): ()
				checkLatestMetaTags()

				if profile:IsActive() == false and result == nil then
					result = Enum.ProductPurchaseDecision.NotProcessedYet
				end
			end)

			-- // Wait until result isn't mil

			while result == nil do
				task.wait(0.1)
			end

			-- // Disconnect metatag function

			metaTagsConnection:Disconnect()

			return result
		end)
	end
end

local function runProductFunction(player: Player, productTable: table): ()
	local profile = profileManager.Profiles[player]

	-- // Grant player product

	for grantName, grantValue in pairs(productTable) do
		profile.Data.Stats[grantName] += grantValue

		if grantName == "Tokens" then
			hudEffects.Client.RunTokenPerMinuteEffect:Fire(
				player,
				"Tokens",
				"+" .. grantValue,
				"rbxassetid://6798832704"
			)

			profileManager.Client.Stats:Fire(player, "Tokens", profile.Data.Stats.Tokens)
		end
	end
end

local function grantProduct(player: Player, productId: number): ()
	local productTable = settings.products[productId]

	-- // Grants product data

	if productTable ~= nil then
		runProductFunction(player, productTable)
	end
end

local function processReceipt(receipInfo: table): Enum.ProductPurchaseDecision
	local player = players:GetPlayerByUserId(receipInfo.PlayerId)

	if not player then
		-- // Purchase isn't successful

		return Enum.ProductPurchaseDecision.NotProcessedYet
	else
		local profile = profileManager.Profiles[player]

		if profile ~= nil then
			-- // Purchase is successful

			local purchaseCheck = purchaseIdCheckAsync(profile, receipInfo.PurchaseId, function(): ()
				grantProduct(player, receipInfo.ProductId)
			end)

			return purchaseCheck
		else
			-- // Purchase isn't successful

			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
end

local function getGamepass(possibleId: number): ()
	for gamepassName, gamepassId in pairs(gamepassData) do
		if possibleId == gamepassId then
			return gamepassName
		end
	end
end

local function onPromptPurchaseFinished(player: Player, purchasedPassID: number, purchaseSuccess: boolean): ()
	if purchaseSuccess then
		local profile = profileManager.Profiles[player]
		local purchasedGamepass = getGamepass(purchasedPassID)

		profile.Data.Gamepasses[purchasedGamepass] = true
	end
end

local function browseValues(array: table): table
	local values = {}

	for _, value in next, array do
		table.insert(values, value)
	end

	return values
end

local function prefixStatsToSkipArray(): table
	if not prefixStatsToSkip then
		prefixStatsToSkip = browseValues(nameToAdress)
	end

	return prefixStatsToSkip
end

local function processToProfile(player: Player?, arrayName: string, key: string, valueToReplace: any?): any?
	if player and valueToReplace then
		profileManager.Profiles[player].Data[arrayName][key] = valueToReplace

		if not tonumber(player) then
			profileManager.Client[arrayName]._re:FireClient(player, key, valueToReplace)
			profileManager.Changed:Fire(player, arrayName, key, valueToReplace)
		end
	end

	return profileManager.Profiles[player].Data[arrayName][key]
end

local function searchTable(
	array: table,
	wanted: string?,
	valueToReplace: any?
): (string, any?) -> (string, string, any?)
	for key, value in next, array do
		if statsToSkip[key] or prefixStatsToSkipArray()[key] then
			continue
		end

		if type(value) == "table" then
			local found, found2, found3 = searchTable(value, wanted)

			if found then
				return key, found, found2, found3
			end
		else
			if key == wanted then
				if valueToReplace then
					key = valueToReplace
				end

				return key, value
			end
		end
	end
end

local function searchControl(player: Player, array: table, wanted: string, prefix: string?, valueToReplace: any?): any?
	local searchIn = array[nameToAdress[prefix]]

	if searchIn then
		return processToProfile(
			player,
			nameToAdress[prefix],
			wanted,
			if array ~= settings.profileTemplate then valueToReplace else nil
		)
	end

	local arrayName, key, value = searchTable(array, wanted, valueToReplace)

	if array == settings.profileTemplate then
		return value
	else
		return processToProfile(player, arrayName, key, valueToReplace)
	end
end

local function getDefaultStat(player: Player, stat: string, prefix: string?): any?
	return searchControl(player, settings.profileTemplate, stat, prefix)
end

local function getPrefixAndStatName(stat: string, skipPrefix: boolean?): (string | boolean, string)
	local prefix = string.lower(string.sub(stat, 1, 1))
	local statName = string.upper(string.sub(stat, 2, 2)) .. string.sub(stat, 3)
	local statString = string.upper(string.sub(stat, 1, 1)) .. string.sub(stat, 2)

	if nameToAdress[prefix] and not skipPrefix then
		return prefix, statName
	else
		return nil, statString
	end
end

local function typeCheck<T>(player: Player, stat: T, prefix: string?, valueToAdd: any?): boolean
	local defaultStat = getDefaultStat(player, stat, prefix) :: T
	local statValue = valueToAdd or defaultStat
	local type1, type2 = type(statValue), type(defaultStat)
	local check = type1 == type2

	assert(
		check or type2 == type(nil),
		("Different value types! statValue: %s (%s) Default stat: %s (%s)"):format(
			tostring(statValue),
			type1,
			tostring(defaultStat),
			type2
		)
	)

	return check or type2 == type(nil)
end

local function valuesControl(
	player: Player,
	stat: string,
	valueToAdd: any?,
	skipPrefix: boolean?,
	skipCheck: boolean?
): boolean
	local prefix, statName = getPrefixAndStatName(stat, skipPrefix)
	local check = skipCheck or typeCheck(player, statName, prefix, valueToAdd)

	warn(player, stat, check, "|", player, statName, prefix, valueToAdd)

	return player and stat and check
end

local function profileCheck(player: Player): boolean
	local timeoutSeconds, progress = 60, 0

	if not player then
		return
	end

	while not profileManager or not profileManager.Profiles or not profileManager.Profiles[player] do
		if progress >= timeoutSeconds then
			return false
		else
			progress += 1
		end

		task.wait(0.5)
	end

	return true
end

local function releaseOnPlayerId(userId: number | Player?, profileToRelease: table): ()
	if tonumber(userId) then
		profileToRelease:Release()
		loadedDatasMap:RemoveAsync(tostring(userId))
	end
end

-- // Public Functions \\ --

function profileManager:KnitStart(): ()
	players.PlayerAdded:Connect(playerAdded)
	players.PlayerRemoving:Connect(playerLeft)

	task.wait(0.5)

	hudEffects = knit.GetService("HUDEffects")
	settingsService = knit.GetService("Settings")
	questsService = knit.GetService("Quests")
	rankService = knit.GetService("Rank")
	reputationsService = knit.GetService("Reputations")
end

function profileManager.Client:GetProfileData(player: Player, neededTable: string?): table?
	if not profileCheck(player) then
		return
	end

	local profile = profileManager.Profiles[player].Data

	if neededTable then
		profile = profile[neededTable]
	end

	return profile
end

function profileManager:GetProfileData(player: Player, neededTable: string?): table?
	if not profileCheck(player) then
		return
	end

	local profile = profileManager.Profiles[player].Data

	if neededTable then
		profile = profile[neededTable]
	end

	return profile
end

function profileManager:InsertStat(player: Player, stat: string, valueToAdd: any): table | string?
	if not valuesControl(player, stat, valueToAdd, true, true) then
		warn("valuesControl reqs not met")
		return
	end

	local result = xpcall(function(): (boolean, any?)
		table.insert(self.Profiles[player].Data[stat], valueToAdd)
		--profileManager.Client[stat]._re:FireClient(player, stat, valueToAdd)
		--profileManager.Changed:Fire(player, stat, stat, valueToAdd)

		return self.Profiles[player].Data[stat]
	end, function<err>(err: err): err
		warn(err)

		return err
	end)

	return result
end

function profileManager:InsertDictionary(
	player: Player,
	stat: string,
	keyToAdd: string,
	valueToAdd: any
): table | string?
	if not valuesControl(player, stat, valueToAdd, true, true) then
		return
	end

	local result = xpcall(function(): (boolean, any?)
		self.Profiles[player].Data[stat][keyToAdd] = valueToAdd
		--profileManager.Client[stat]._re:FireClient(player, stat, valueToAdd)
		--profileManager.Changed:Fire(player, stat, stat, valueToAdd)

		return self.Profiles[player].Data[stat]
	end, function<err>(err: err): err
		warn(err)

		return err
	end)

	return result
end

function profileManager:ClearFromDictionary(player: Player, stat: string, key: string): ()
	if not valuesControl(player, stat, nil, true, true) then
		return
	end

	self.Profiles[player].Data[stat][key] = nil
end

function profileManager:RaiseStat(player: Player, stat: string, valueToAdd: any): any?
	if not valuesControl(player, stat, valueToAdd) then
		return
	end

	local prefix, statName = getPrefixAndStatName(stat)

	valueToAdd += searchControl(player, self.Profiles[player].Data, statName, prefix)

	return searchControl(player, self.Profiles[player].Data, statName, prefix, valueToAdd)
end

function profileManager:SetStat(player: Player | number, stat: string, valueToSet: any): (any?, any?)
	if not valuesControl(player, stat, valueToSet) then
		return
	end

	local selectedProfile

	if tonumber(player) then
		profileManager.Profiles[player] = profileManager:LoadData(player)

		selectedProfile = profileManager.Profiles[player]
	else
		selectedProfile = self.Profiles[player]
	end

	local prefix, statName = getPrefixAndStatName(stat)
	local oldValue = searchControl(player, selectedProfile.Data, statName, prefix)

	if oldValue == nil then
		warn("Old value is nil so the stat does not exist!")

		return
	end

	local newValue = searchControl(player, selectedProfile.Data, statName, prefix, valueToSet)
	local returnTo = newValue, oldValue

	if tonumber(player) then
		releaseOnPlayerId(player, selectedProfile)
	end

	if not tonumber(player) then
		if string.lower(stat) == "yfly" and newValue == true and oldValue == false then
			questsService.Client.PowerRewarded._re:FireClient(player, "Fly")
		end

		if string.lower(stat) == "rrank" then
			rankService:UpdateRank(player, newValue)
		end

		if string.lower(stat) == "greputation" then
			reputationsService:UpdateReputationWithForce(player, newValue)
		end
	end

	return returnTo
end

function profileManager:ReplaceTable(player: Player | number, tableName: string, givenTable: table): table
	for key, value in next, givenTable do
		if not valuesControl(player, key, value, true, true) then
			return
		end
	end

	local selectedProfile

	if tonumber(player) then
		profileManager.Profiles[player] = profileManager:LoadData(player)

		selectedProfile = profileManager.Profiles[player]
	else
		selectedProfile = self.Profiles[player]
	end

	local selectedData = selectedProfile.Data[tableName]
	local oldValue = table.clone(selectedData)

	profileManager.Profiles[player].Data[tableName] = givenTable

	releaseOnPlayerId(player, selectedProfile)

	warn(profileManager.Profiles[player].Data)

	return selectedData, oldValue
end

function profileManager:LoadData(userId: number): table?
	local profile = profileStore:LoadProfileAsync(tostring(userId))

	if profile then
		task.defer(function(): ()
			local status, err

			repeat
				if not status then
					warn(err)
					task.wait(3)
				end

				status, err = pcall(function(): boolean
					loadedDatasMap:SetAsync(tostring(userId), true, 1)
				end)
			until status
		end)

		return profile
	end
end

function profileManager:WipeStat(player: Player, stat: string): any?
	if not valuesControl(player, stat) then
		return
	end

	local prefix, statName = getPrefixAndStatName(stat)
	local valueToSet = getDefaultStat(player, statName, prefix)

	return searchControl(player, self.Profiles[player].Data, statName, prefix, valueToSet)
end

function profileManager:WipeAllStats(player: Player): string?
	if not player then
		return
	end

	local defaultProfileCopy = table.clone(settings.profileTemplate)

	for _, value in ipairs(statsToSkip) do
		defaultProfileCopy[value] = self.Profiles[player].Data[value]
	end

	self.Profiles[player].Data = table.clone(defaultProfileCopy)

	return table.concat(statsToSkip, ", ")
end

-- // Initialize \\ --

marketplaceService.ProcessReceipt = processReceipt
marketplaceService.PromptGamePassPurchaseFinished:Connect(onPromptPurchaseFinished)

return profileManager
