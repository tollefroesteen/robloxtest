--!strict
-- ScoreService.luau
-- Centralized score aggregation and broadcasting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local ScoreService = {}

-- Store for all trap scores: { [trapType: string]: number }
local ScoresByTrapType: {[string]: number} = {}

-- Broadcast a score update to all clients
function ScoreService.ApplyScore(trapType: string, animalType: string, trapName: string): nil
    local delta: number = (trapType == animalType) and 1 or -1
    ScoresByTrapType[trapType] = (ScoresByTrapType[trapType] or 0) + delta

    RemoteEvents.ScoreEvent:FireAllClients({
        delta = delta,
        trapType = trapType,
        animalType = animalType,
        totalForTrapType = ScoresByTrapType[trapType],
        trapName = trapName,
    })
end

-- Reset all scores and broadcast zero-state to clients
function ScoreService.ResetAll(): nil
    -- Clear internal state
    table.clear(ScoresByTrapType)
    
    -- Broadcast reset signal (clients will clear their totals)
    RemoteEvents.ResetGameEvent:FireAllClients()
end

-- Get current score for a trap type
function ScoreService.GetScore(trapType: string): number
    return ScoresByTrapType[trapType] or 0
end

return ScoreService
