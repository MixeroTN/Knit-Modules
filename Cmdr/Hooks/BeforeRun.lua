--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


Cmdr: BeforeRun hook
https://eryn.io/Cmdr/guide/Hooks.html

This module is called multiple times on start and each command execution
Connecting it to Knit and waiting for data is pain, also this module
is called from server and client so the data is pasted here and needs
to be mantained.

At least one BeforeRun hook is required to make commands work in the live game!

]]

-- // Services \\

local players = game:GetService("Players")

-- // Private Variables \\ --

local TIMEOUT = 30

local GROUP_ID = 10639016 --basicData.groups.main.id
local ADMIN_RANK = 252 --basicData.groups.main.adminRank

local cache = {}
cache.__index = cache

local cacheStatus = false

-- // Private Types \\ --

type self = {
	rank: number,
	timestamp: number,
}

-- // Public Types \\ --

export type cache = typeof(setmetatable({} :: self, cache))

-- // Private Metatables \\ --

local cacheMeta = {
	__index = function(currentTable: table, key: string): any
		if cacheStatus or not currentTable["name"] then
			return
		end

		cacheStatus = true

		local playerCache = cache[currentTable.name]

		if
			playerCache
			and rawget(playerCache, "timestamp")
			and os.time() - rawget(playerCache, "timestamp") < TIMEOUT
		then
			cacheStatus = false

			return rawget(playerCache, key)
		elseif rawget(playerCache, "timestamp") and rawget(playerCache, key) then
			rawset(cache[currentTable.name], "timestamp", os.time())
			rawset(cache[currentTable.name], key, players[currentTable.name]:GetRankInGroup(GROUP_ID))

			cacheStatus = false

			return
		end

		cacheStatus = false
	end,

	__newindex = function(currentTable: table, key: string, value: cache): ()
		cache[currentTable.name] = {
			name = currentTable.name,
			[key] = value,
			timestamp = os.time(),
		} :: self

		return value
	end,
}

-- // Private Functions \\ --

local function newRankCheck(player: Player): number
	local playerRank = player:GetRankInGroup(GROUP_ID)

	if not cache[player.Name] then
		cache[player.Name] = {
			name = player.Name,
		}

		setmetatable(cache[player.Name], cacheMeta)

		cacheMeta.__index(rawget(cache, player.Name), "rank")
	end

	cache[player.Name].rank = playerRank

	return playerRank
end

local function getRankInGroup(player: Player): number
	local result

	if cache[player.Name] then
		result = cacheMeta.__index(rawget(cache, player.Name), "rank")
	else
		result = newRankCheck(player)
	end

	return result or cacheMeta.__index(rawget(cache, player.Name), "rank")
end

local function adminPermissionCheck(player: Player): boolean
	return (getRankInGroup(player) >= ADMIN_RANK)
end

-- // Public function to return // --

return function(registry: table): (table) -> string?
	registry:RegisterHook("BeforeRun", function(context: table): string?
		if
			not (
				(context.Group == "Admin" or context.Group == "DefaultAdmin")
				and adminPermissionCheck(context.Executor)
			)
		then
			return "You don't have permission to run this command"
		end
	end)
end
