--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "HealthController"
local player: Player = Players.LocalPlayer

local HealthController = {}

local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local barFill: Frame? = nil

local function updateHealthBar(currentHealth: number, maxHealth: number): nil
    if not barFill then return end
    
    local ratio = math.clamp(currentHealth / maxHealth, 0, 1)
    local targetSize = UDim2.new(ratio, 0, 1, 0)

    -- tween the bar
    TweenService:Create(barFill, tweenInfo, {Size = targetSize}):Play()

    -- green -> yellow -> red
    barFill.BackgroundColor3 = Color3.fromHSV(ratio * 0.33, 1, 1)
end

-- Listen for server updates (connect immediately)
RemoteEvents.HealthEvent.OnClientEvent:Connect(function(currentHealth, maxHealth)
    updateHealthBar(currentHealth, maxHealth)
end)

function HealthController.Init(): nil
    local playerGui = player:WaitForChild("PlayerGui")
    
    local healthGui = playerGui:WaitForChild("HealthGui", 5)
    if not healthGui then
        Log.Warn(CONTEXT, "HealthGui not found in PlayerGui")
        return
    end

    local barBackground = healthGui:WaitForChild("HealthBarBackground", 5)
    if not barBackground then
        Log.Warn(CONTEXT, "HealthBarBackground not found under HealthGui")
        return
    end

    barFill = barBackground:WaitForChild("HealthFill", 5)
    if not barFill then
        Log.Warn(CONTEXT, "HealthFill not found under HealthBarBackground")
        return
    end

    -- Initialize full bar
    updateHealthBar(100, 100)
end

return HealthController
