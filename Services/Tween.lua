--!nocheck

--[[
.______     ______     _______.
|   _  \   /      |   /       |
|  |_)  | |  ,----'  |   (----`
|   ___/  |  |        \   \
|  |      |  `----.----)   |
| _|       \______|_______/


-- // This script manages tweens

]]

-- // Services \\ --

local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

-- // Object Variables \\ --

local packages = replicatedStorage:WaitForChild("Packages")

-- // Loaded Modules \\ --

local knit = require(packages:WaitForChild("Knit"))
local promise = require(packages:WaitForChild("Promise"))

-- // Knit Setup \\ --

local tween = knit.CreateService({
	Name = "Tween",
	ActiveTweens = {},
})

-- // Types \\ --

type PromiseStatus = {
	Started: "Started",
	Resolved: "Resolved",
	Rejected: "Rejected",
	Cancelled: "Cancelled",
}

type PromiseStatusTable = {
	[string]: PromiseStatus,
}

-- // Private Functions \\ --

local function cancelAllTweens(): PromiseStatus
	-- // This function cancels every active tween

	return promise
		.new(function(resolve)
			for _, element in ipairs(tween.ActiveTweens) do
				element:Cancel()
			end
			tween.ActiveTweens = {}
			return resolve()
		end)
		:catch(warn)
end

-- // Public Functions \\ --

function tween:GetActiveTweens(): PromiseStatus
	-- // This function collects every active tween

	return promise
		.new(function(resolve, _, onCancel)
			if onCancel() then
				promise.delay():andThenCall(cancelAllTweens)
				return onCancel(tween.ActiveTweens)
			end
			return resolve(tween.ActiveTweens)
		end)
		:catch(warn)
end

function tween:Tween(object: Instance, tweenInfo: TweenInfo, properties: table): PromiseStatus
	-- // Create a promise

	return promise
		.new(function(resolve, reject, onCancel)
			if not object or not tweenInfo or not properties then
				return reject(object, tweenInfo, properties)
			end

			local currentTween = tweenService:Create(object, tweenInfo, properties)
			table.insert(tween.ActiveTweens, currentTween)

			if onCancel(function()
				currentTween:Cancel()
			end) then
				return onCancel(currentTween)
			end

			-- // Play the tween

			currentTween.Completed:Once(resolve)
			currentTween:Play()

			--return resolve(currentTween)
		end)
		:catch(warn)
end

function tween:TweenMultiple(objects: table, tweenInfo: TweenInfo, properties: table): PromiseStatusTable
	local promiseStatusTable = {}

	for _, object in next, objects do
		table.insert(promiseStatusTable, self:Tween(object, tweenInfo, properties))
	end

	return promiseStatusTable
end

-- // Initialize \\ --

return tween
