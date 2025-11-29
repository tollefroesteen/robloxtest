local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShootEvent = ReplicatedStorage:WaitForChild("ShootEvent")
local ButtonEffects = require(script.Parent:WaitForChild("ButtonEffects"))

local player = Players.LocalPlayer

local MenuController = {}

function MenuController.Init()
    local playerGui = player:WaitForChild("PlayerGui")
    local actionsGui = playerGui:WaitForChild("ActionsGui", 5)
    if not actionsGui then
        warn("[MenuController] ActionsGui not found in PlayerGui")
        return
    end

    local frame = actionsGui:WaitForChild("Frame", 5)
    if not frame then
        warn("[MenuController] Frame not found under ActionsGui")
        return
    end

    local shootButton = frame:WaitForChild("ShootButton", 5)
    if not shootButton then
        warn("[MenuController] ShootButton not found under Frame")
        return
    end

    -- Add press effect
    ButtonEffects.AddPressEffect(shootButton)

    shootButton.MouseButton1Click:Connect(function()
        ShootEvent:FireServer()
    end)
end

return MenuController