local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local resetGameEvent = ReplicatedStorage:WaitForChild("ResetGameEvent")
local ButtonEffects = require(script.Parent:WaitForChild("ButtonEffects"))

local player = Players.LocalPlayer

local ResetButtonController = {}

function ResetButtonController.Init()
    local playerGui = player:WaitForChild("PlayerGui")
    local actionsGui = playerGui:WaitForChild("ActionsGui", 5)
    if not actionsGui then
        warn("[ResetButtonController] ActionsGui not found in PlayerGui")
        return
    end

    local frame = actionsGui:WaitForChild("Frame", 5)
    if not frame then
        warn("[ResetButtonController] Frame not found under ActionsGui")
        return
    end

    local resetButton = frame:WaitForChild("ResetButton", 5)
    if not resetButton then
        warn("[ResetButtonController] ResetButton not found under Frame")
        return
    end

    -- Only show button if the player's name matches
    if player.Name ~= "flemmingopingo" then
        resetButton.Visible = false
        return
    else
        resetButton.Visible = true
    end

    -- Add press effect
    ButtonEffects.AddPressEffect(resetButton)

    resetButton.MouseButton1Click:Connect(function()
        resetGameEvent:FireServer()
    end)
end

return ResetButtonController
