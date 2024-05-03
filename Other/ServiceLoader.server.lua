--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script loads services

]]

-- // Serviecs \\ --

local serverScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- // Object Variables \\ --

local server = serverScriptService:WaitForChild("Server")
local services = server:WaitForChild("Services")

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Initialize \\ --

knit.AddServices(services)

-- // Start knit \\ --

knit.Start({ ServicePromises = true }):catch(warn)
