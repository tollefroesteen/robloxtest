local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuController = require(script.Parent:WaitForChild("MenuController"))
local RunButtonController = require(script.Parent:WaitForChild("RunButtonController"))
local ResetButtonController = require(script.Parent:WaitForChild("ResetButtonController"))
local ScoreController = require(script.Parent:WaitForChild("ScoreController"))
local StaminaController = require(script.Parent:WaitForChild("StaminaController"))
local HealthController = require(script.Parent:WaitForChild("HealthController"))
local AnimalAnimationController = require(script.Parent.Parent:WaitForChild("controllers"):WaitForChild("AnimalController"))

local player = Players.LocalPlayer

print("Hello world, from client!")

local function initializeUI()
    -- Initialize UI
    MenuController.Init()
    RunButtonController.Init()
    ResetButtonController.Init()
    ScoreController.Init()
    StaminaController.Init()
    HealthController.Init()
end

-- Initialize on first load
initializeUI()

-- Initialize animal animations (non-UI)
AnimalAnimationController.Init()

-- Reinitialize when GUI resets (if ActionsGui has ResetOnSpawn=true or gets destroyed)
local playerGui = player:WaitForChild("PlayerGui")
playerGui.ChildAdded:Connect(function(child)
    if child.Name == "ActionsGui" then
        -- Wait a moment for GUI to fully load
        task.wait(0.1)
        initializeUI()
    end
end)

-- Rest of your client setup...