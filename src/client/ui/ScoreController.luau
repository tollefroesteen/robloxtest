local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScoreEvent = ReplicatedStorage:WaitForChild("ScoreEvent")
local ResetGameEvent = ReplicatedStorage:WaitForChild("ResetGameEvent")

local player = Players.LocalPlayer

local ScoreController = {}

local textLabel = nil
local totals = {} -- trapType -> number

local function updateScoreUI()
    if not textLabel then return end
    
    local lines = {"Score:"}

    for trapType, score in pairs(totals) do
        table.insert(lines, string.format("%s: %d", trapType, score))
    end

    textLabel.Text = table.concat(lines, "\n")
end

-- Connect listener immediately (before Init is called)
ScoreEvent.OnClientEvent:Connect(function(payload)
    -- payload = { delta, trapType, animalType, totalForTrapType, trapName }
    totals[payload.trapType] = payload.totalForTrapType

    updateScoreUI()
end)

-- Listen for game reset to clear scores
ResetGameEvent.OnClientEvent:Connect(function()
    totals = {}
    updateScoreUI()
end)

function ScoreController.Init()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- You may need to adjust this path based on your ScreenGui structure
    -- Common patterns: ScoreGui, HUD, MainGui, etc.
    local scoreGui = playerGui:WaitForChild("ScoreGui", 5)
    if not scoreGui then
        warn("[ScoreController] ScoreGui not found in PlayerGui")
        return
    end

    local frame = scoreGui:WaitForChild("Frame", 5)
    if not frame then
        warn("[ScoreController] Frame not found in PlayerGui")
        return
    end

    textLabel = frame:WaitForChild("TextLabel", 5)
    if not textLabel then
        warn("[ScoreController] TextLabel not found under Frame")
        return
    end

    -- Initial UI update
    updateScoreUI()
end

return ScoreController
