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
local promise = require(packages.Promise)

-- // Knit Setup \\ --

local tween = knit.CreateService{
    Name = "Tween",
    ActiveTweens = {}
}

-- // Private Functions \\ --

local function cancelAllTweens()
    return promise.new(function(resolve)
        for _, element in ipairs(tween.ActiveTweens) do
            element:Cancel()
        end
        tween.ActiveTweens = {}
        return resolve()
    end):catch(warn)
end

-- // Public Functions \\ --

function tween:GetActiveTweens()
    return promise.new(function(resolve, _, onCancel)
        if onCancel() then
            promise.delay():andThenCall(cancelAllTweens)
            return onCancel(tween.ActiveTweens)
        end
        return resolve(tween.ActiveTweens)
    end):catch(warn)
end

function tween:Tween(object: Instance, tweenInfo: TweenInfo, properties: table)
    return promise.new(function(resolve, reject, onCancel)
        if not object or not tweenInfo or not properties then
            return reject(object, tweenInfo, properties)
        end

        local currentTween = tweenService:Create(object, tweenInfo, properties)
        table.insert(tween.ActiveTweens, currentTween)

        if onCancel(function() currentTween:Cancel() end) then
            return onCancel(currentTween)
        end

        currentTween.Completed:Once(resolve)
        currentTween:Play()
    end):catch(warn)
end

-- // Initialize \\ --

return tween