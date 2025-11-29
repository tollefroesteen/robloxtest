--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local resetGameEvent = RemoteEvents.ResetGameEvent
local ButtonEffects = require(script.Parent:WaitForChild("ButtonEffects"))

local player: Player = Players.LocalPlayer

-- Simple whitelist for who can see/use Reset button
local ALLOWED_USERS: {[string]: boolean} = {
    flemmingopingo = true,
    -- Add more usernames here as needed
}

local ResetButtonController = {}

function ResetButtonController.Init(): nil
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

    local resetButton: TextButton? = frame:WaitForChild("ResetButton", 5)
    if not resetButton then
        warn("[ResetButtonController] ResetButton not found under Frame")
        return
    end

    -- Only show button if the player's name is allowed
    if not ALLOWED_USERS[player.Name] then
        resetButton.Visible = false
        return
    end
    resetButton.Visible = true

    -- Add press effect
    ButtonEffects.AddPressEffect(resetButton)

    resetButton.MouseButton1Click:Connect(function()
        resetGameEvent:FireServer()
    end)
end

return ResetButtonController
