--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))
local ShootEvent = RemoteEvents.ShootEvent
local ButtonEffects = require(script.Parent:WaitForChild("ButtonEffects"))

local CONTEXT = "MenuController"
local player: Player = Players.LocalPlayer

local MenuController = {}

function MenuController.Init(): nil
    local playerGui = player:WaitForChild("PlayerGui")
    local actionsGui = playerGui:WaitForChild("ActionsGui", 5)
    if not actionsGui then
        Log.Warn(CONTEXT, "ActionsGui not found in PlayerGui")
        return
    end

    local frame = actionsGui:WaitForChild("Frame", 5)
    if not frame then
        Log.Warn(CONTEXT, "Frame not found under ActionsGui")
        return
    end

    local shootButton = frame:WaitForChild("ShootButton", 5)
    if not shootButton then
        Log.Warn(CONTEXT, "ShootButton not found under Frame")
        return
    end

    -- Add press effect
    ButtonEffects.AddPressEffect(shootButton)

    shootButton.MouseButton1Click:Connect(function()
        ShootEvent:FireServer()
    end)
end

return MenuController