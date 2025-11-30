--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local SprintConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config"):WaitForChild("SprintConfig"))
local SprintEvent = RemoteEvents.SprintEvent

local player: Player = Players.LocalPlayer

local StaminaController = {}

local MAX_STAMINA: number = SprintConfig.MAX_STAMINA

-- Optional: smooth bar animations
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local barFill: Frame? = nil

-- Function to update bar fill
local function updateBar(currentStamina: number): nil
    if not barFill then return end
    
    local ratio = math.clamp(currentStamina / MAX_STAMINA, 0, 1)
    local targetSize = UDim2.new(ratio, 0, 1, 0)

    TweenService:Create(barFill, tweenInfo, {Size = targetSize}):Play()

    -- Optional: color shift (green -> red as stamina drops)
    barFill.BackgroundColor3 = Color3.fromHSV(ratio * 0.33, 1, 1)
end

-- Listen for updates from server (connect immediately)
SprintEvent.OnClientEvent:Connect(function(isSprinting, stamina)
    updateBar(stamina)
end)

function StaminaController.Init(): nil
    local playerGui = player:WaitForChild("PlayerGui")
    
    local staminaGui = playerGui:WaitForChild("StaminaGui", 5)
    if not staminaGui then
        warn("[StaminaController] StaminaGui not found in PlayerGui")
        return
    end

    local barBackground = staminaGui:WaitForChild("StaminaBarBackground", 5)
    if not barBackground then
        warn("[StaminaController] StaminaBarBackground not found under StaminaGui")
        return
    end

    barFill = barBackground:WaitForChild("StaminaFill", 5)
    if not barFill then
        warn("[StaminaController] StaminaFill not found under StaminaBarBackground")
        return
    end

    -- Initialize full bar
    updateBar(MAX_STAMINA)
end

return StaminaController
