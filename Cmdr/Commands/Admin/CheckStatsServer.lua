--!nocheck

local HttpService = game:GetService("HttpService")
local serverScriptService = game:GetService("ServerScriptService")

local profileManager = require(serverScriptService:WaitForChild("Server").Services.ProfileManager)

local function encode(json: table): string
	local encoded = HttpService:JSONEncode(json)
	local indent = "	"
	local formatted = ""
	local level = 0

	for i = 1, #encoded do
		local char = encoded:sub(i, i)

		if char == "{" or char == "[" then
			level += 1
			formatted = formatted .. char .. "\n" .. string.rep(indent, level)
		elseif char == "}" or char == "]" then
			level -= 1
			formatted = formatted .. "\n" .. string.rep(indent, level) .. char
		elseif char == "," then
			formatted = formatted .. char .. "\n" .. string.rep(indent, level)
		else
			formatted = formatted .. char
		end
	end

	return formatted
end

return function(_: table, player: Player | number, stat: string?): string
	local returned

	if tonumber(player) then
		returned = profileManager:LoadData(player).Data
	else
		returned = profileManager:GetProfileData(player)
	end

	if returned then
		if stat then
			if stat == ".." then
				print(encode(returned))
				return encode(returned)
			elseif stat == "." then
				local mod = table.clone(returned)

				mod["Quests"] = nil

				return encode(mod)
			end

			for key, value in next, returned do
				if string.lower(key) == string.lower(stat) then
					return encode(value)
				end
			end

			if tonumber(player) then
				returned:Release()
			end

			return "No such a table in the profile! Type . as the table arg to view all, .. to include quests."
		else
			return encode(returned)
		end
	else
		return "The command failed. It is likely that the stat does not exist."
	end
end
