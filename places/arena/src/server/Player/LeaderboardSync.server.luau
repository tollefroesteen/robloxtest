--!strict
-- LeaderboardSync.server.luau
-- Arena server script to periodically sync XP to leaderboard OrderedDataStore

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local services = Shared:WaitForChild("services")
local util = Shared:WaitForChild("util")

local LeaderboardService = require(services:WaitForChild("LeaderboardService"))
local Log = require(util:WaitForChild("Log"))

local CONTEXT = "LeaderboardSync"

-- Configuration
local SYNC_INTERVAL = 30  -- How often to process pending XP updates (seconds)

-- Initialize the leaderboard service
LeaderboardService.Init()

-- Periodic sync loop
task.spawn(function()
	while true do
		task.wait(SYNC_INTERVAL)
		
		-- Process any pending XP updates
		LeaderboardService.ProcessPendingUpdates()
		
		Log.Debug(CONTEXT, "Processed pending leaderboard updates")
	end
end)

-- Sync player XP when they leave (ensure final XP is recorded)
Players.PlayerRemoving:Connect(function(player)
	-- Note: The AchievementsService already handles this via UpdatePlayerXP
	-- This is just a safety net to process immediately on leave
	LeaderboardService.ProcessPendingUpdates()
end)

Log.Info(CONTEXT, "LeaderboardSync initialized")
