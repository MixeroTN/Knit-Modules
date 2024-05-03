--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages the queue

]]

-- // Services \\ --

local memoryStoreService = game:GetService("MemoryStoreService")
local players = game:GetService("Players")

-- // Object Variables \\ --

local loadedMap = memoryStoreService:GetSortedMap("LoadedDatas")

local connections = {}

-- // Private Functions \\ --

local function teleportBack(): () end

local function getAsync(player: Player): RBXScriptConnection
	local status, err, connection

	repeat
		if not status then
			print("GetAsync failed. Retrying in 3 seconds. Error: " .. tostring(err))
			task.wait(3)
		end

		status, err = pcall(function(): boolean
			connection = loadedMap:GetAsync(tostring(player))
		end)
	until status

	print("GetAsync succeed.")

	return connection
end

local function playerAdded(player: Player): ()
	local connection = getAsync(player)

	if not connection then
		return
	end

	connections[player] = connection

	task.wait(1)

	repeat
		connection = getAsync(player)
	until not player or not connection

	print("pA EOL: ", "Player:", player, " Connection:", connection)
end

local function playerRemoving(player: Player): ()
	if connections[player] then
		connections[player]:Disconnect()
		connections[player] = nil
	end

	print("pR EOL: ", "Player:", player)
end

local function main(): ()
	players.PlayerAdded:Connect(playerAdded)

	for _, player in next, players:GetPlayers() do
		playerAdded(player)
	end

	players.PlayerRemoving:Connect(playerRemoving)
end

-- // Initial \\ --

main()
