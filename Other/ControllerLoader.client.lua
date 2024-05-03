--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script loads controllers

]]

-- // Serviecs \\ --

local replicatedStorage = game:GetService("ReplicatedStorage")

-- // Object Variables \\ --

local client = replicatedStorage:WaitForChild("Shared"):WaitForChild("Client")
local controllers = client:WaitForChild("Controllers")

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))

-- // Initialize \\ --

knit.AddControllersDeep(controllers)

-- // Start knit \\ --

knit.Start():catch(warn)
