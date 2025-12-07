--!strict
-- LeaderboardManager.server.luau
-- Server-side leaderboard management for the lobby
-- Manages both global (cross-server) and server-specific leaderboards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local services = Shared:WaitForChild("services")
local util = Shared:WaitForChild("util")

local LeaderboardService = require(services:WaitForChild("LeaderboardService"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(util:WaitForChild("Log"))

-- Get FavoriteAnimalsService for player data access
local Server = ServerScriptService:WaitForChild("Server")
local FavoriteAnimalsService = require(Server:WaitForChild("FavoriteAnimalsService"))

local CONTEXT = "LeaderboardManager"

-- Configuration
local UPDATE_INTERVAL = 30       -- How often to sync XP to global leaderboard (seconds)
local BROADCAST_INTERVAL = 60    -- How often to broadcast global leaderboard to all clients (seconds)
local SERVER_BROADCAST_INTERVAL = 10  -- How often to broadcast server leaderboard (seconds)
local LEADERBOARD_SIZE = 10      -- Number of entries to show

-- Define type for server leaderboard (same structure as global)
type LeaderboardEntry = {
	Rank: number,
	UserId: number,
	DisplayName: string,
	Value: number,
}

type LeaderboardData = {
	Entries: { LeaderboardEntry },
	LastUpdated: number,
	StatType: string,
}

-- Initialize the leaderboard service
LeaderboardService.Init()

-- Sync a player's XP to the global leaderboard
local function syncPlayerXP(player: Player)
	local data = FavoriteAnimalsService.GetPlayerData(player)
	if data and data.Stats then
		local xp = data.Stats.ExperiencePoints or 0
		LeaderboardService.UpdatePlayerXP(player.UserId, xp)
		Log.Debug(CONTEXT, string.format("Queued XP sync for %s: %d XP", player.Name, xp))
	end
end

-- Build server-specific leaderboard from current players
local function buildServerLeaderboard(): LeaderboardData
	local entries: { LeaderboardEntry } = {}
	
	-- Collect XP for all players in server
	for _, player in Players:GetPlayers() do
		local data = FavoriteAnimalsService.GetPlayerData(player)
		if data and data.Stats then
			local xp = data.Stats.ExperiencePoints or 0
			table.insert(entries, {
				Rank = 0,  -- Will be set after sorting
				UserId = player.UserId,
				DisplayName = player.DisplayName,
				Value = xp,
			})
		end
	end
	
	-- Sort by XP (descending)
	table.sort(entries, function(a, b)
		return a.Value > b.Value
	end)
	
	-- Assign ranks
	for i, entry in entries do
		entry.Rank = i
	end
	
	-- Limit to leaderboard size
	if #entries > LEADERBOARD_SIZE then
		local trimmed = {}
		for i = 1, LEADERBOARD_SIZE do
			table.insert(trimmed, entries[i])
		end
		entries = trimmed
	end
	
	return {
		Entries = entries,
		LastUpdated = os.time(),
		StatType = "XP",
	}
end

-- Broadcast global leaderboard to all players
local function broadcastGlobalLeaderboard()
	local leaderboard = LeaderboardService.GetXPLeaderboard(LEADERBOARD_SIZE)
	RemoteEvents.LeaderboardUpdatedEvent:FireAllClients(leaderboard)
	Log.Debug(CONTEXT, string.format("Broadcast global leaderboard with %d entries", #leaderboard.Entries))
end

-- Broadcast server leaderboard to all players
local function broadcastServerLeaderboard()
	local leaderboard = buildServerLeaderboard()
	RemoteEvents.ServerLeaderboardUpdatedEvent:FireAllClients(leaderboard)
	Log.Debug(CONTEXT, string.format("Broadcast server leaderboard with %d entries", #leaderboard.Entries))
end

-- Send both leaderboards to a specific player
local function sendLeaderboardsToPlayer(player: Player)
	local globalLeaderboard = LeaderboardService.GetXPLeaderboard(LEADERBOARD_SIZE)
	RemoteEvents.LeaderboardUpdatedEvent:FireClient(player, globalLeaderboard)
	
	local serverLeaderboard = buildServerLeaderboard()
	RemoteEvents.ServerLeaderboardUpdatedEvent:FireClient(player, serverLeaderboard)
end

-- Handle player requesting leaderboard refresh
local function onLeaderboardRequested(player: Player)
	sendLeaderboardsToPlayer(player)
end

-- Player joined
local function onPlayerAdded(player: Player)
	-- Wait a moment for player data to load
	task.wait(2)
	
	-- Sync their XP to global leaderboard immediately (not queued)
	local data = FavoriteAnimalsService.GetPlayerData(player)
	if data and data.Stats then
		local xp = data.Stats.ExperiencePoints or 0
		if xp > 0 then
			-- Use immediate sync so player appears on leaderboard right away
			LeaderboardService.SyncPlayerXPNow(player.UserId, xp)
			-- Clear cache to ensure fresh data is fetched
			LeaderboardService.ClearCache()
			Log.Debug(CONTEXT, string.format("Immediate XP sync for %s: %d XP", player.Name, xp))
		end
	end
	
	-- Send current leaderboards to new player
	task.wait(0.5)
	sendLeaderboardsToPlayer(player)
	
	-- Broadcast updated server leaderboard to all (new player joined)
	broadcastServerLeaderboard()
end

-- Player leaving - final XP sync
local function onPlayerRemoving(player: Player)
	local data = FavoriteAnimalsService.GetPlayerData(player)
	if data and data.Stats then
		local xp = data.Stats.ExperiencePoints or 0
		-- Immediate sync on leave
		LeaderboardService.SyncPlayerXPNow(player.UserId, xp)
		Log.Info(CONTEXT, string.format("Final XP sync for %s: %d XP", player.Name, xp))
	end
	
	-- Broadcast updated server leaderboard after player leaves
	task.defer(function()
		broadcastServerLeaderboard()
	end)
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle leaderboard requests from clients
if RemoteEvents.RequestLeaderboardEvent then
	RemoteEvents.RequestLeaderboardEvent.OnServerEvent:Connect(onLeaderboardRequested)
end

-- Handle existing players
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- Periodic XP sync loop
task.spawn(function()
	while true do
		task.wait(UPDATE_INTERVAL)
		
		-- Sync all players' XP
		for _, player in Players:GetPlayers() do
			syncPlayerXP(player)
		end
		
		-- Process pending updates
		LeaderboardService.ProcessPendingUpdates()
	end
end)

-- Periodic global leaderboard broadcast loop
task.spawn(function()
	while true do
		task.wait(BROADCAST_INTERVAL)
		broadcastGlobalLeaderboard()
	end
end)

-- Periodic server leaderboard broadcast loop (more frequent)
task.spawn(function()
	while true do
		task.wait(SERVER_BROADCAST_INTERVAL)
		broadcastServerLeaderboard()
	end
end)

Log.Info(CONTEXT, "LeaderboardManager initialized")
