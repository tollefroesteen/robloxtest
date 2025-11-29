-- Server bootstrap to initialize shared RemoteEvents early
-- Ensures clients can `require(ReplicatedStorage.Shared.RemoteEvents)` safely

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require the module to create/return RemoteEvents under ReplicatedStorage.Shared
local ok, RemoteEvents = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
end)

if not ok then
    warn("[Bootstrap] Failed to load Shared.RemoteEvents: ", RemoteEvents)
else
    -- Optionally touch key events to ensure they exist (no-op but validates references)
    local _ = RemoteEvents.SprintEvent
    local _2 = RemoteEvents.ScoreEvent
    local _3 = RemoteEvents.ResetGameEvent
    local _4 = RemoteEvents.HealthEvent
    local _5 = RemoteEvents.ShootEvent
    local _6 = RemoteEvents.EndGameEvent
    print("[Bootstrap] Shared.RemoteEvents initialized")
end