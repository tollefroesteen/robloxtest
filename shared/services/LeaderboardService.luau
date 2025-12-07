--!strict
--[=[
	@module LeaderboardService
	@description Shared leaderboard service for fetching and managing player rankings across all places.
	             Uses OrderedDataStore for efficient sorted retrieval and cross-place persistence.
	
	@usage
		-- Server-side initialization (call once on server startup)
		LeaderboardService.Init()
		
		-- Update player XP (queued for batch processing)
		LeaderboardService.UpdatePlayerXP(player.UserId, newXPValue)
		
		-- Get top 10 players
		local data = LeaderboardService.GetXPLeaderboard(10)
		for _, entry in data.Entries do
			print(entry.Rank, entry.DisplayName, entry.Value)
		end
	
	@dependencies
		- DataStoreService (OrderedDataStore)
		- RunService (client/server detection)
	
	@author Generated for robloxtest project
	@version 1.0.0
]=]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

--[=[
	@type LeaderboardEntry
	@field Rank number -- 1-based rank position on the leaderboard
	@field UserId number -- Roblox UserId of the player
	@field DisplayName string -- Player's display name (or "PlayerXXX" if unavailable)
	@field Value number -- The stat value (e.g., XP amount)
]=]
export type LeaderboardEntry = {
	Rank: number,
	UserId: number,
	DisplayName: string,
	Value: number,
}

--[=[
	@type LeaderboardData
	@field Entries {LeaderboardEntry} -- Array of leaderboard entries sorted by rank
	@field LastUpdated number -- Unix timestamp when data was last fetched
	@field StatType string -- Type of stat (e.g., "XP")
]=]
export type LeaderboardData = {
	Entries: { LeaderboardEntry },
	LastUpdated: number,
	StatType: string,
}

local CONTEXT = "LeaderboardService"

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

--[=[
	@config CONFIG
	@description Tunable settings for leaderboard behavior.
	             Adjust these values based on your game's needs and DataStore limits.
]=]
local CONFIG = {
	-- OrderedDataStore name (versioned to allow schema changes)
	-- IMPORTANT: Changing this will reset the leaderboard!
	XP_LEADERBOARD_NAME = "Leaderboard_XP_v1",
	
	-- Entry limits for GetXPLeaderboard()
	DEFAULT_ENTRIES = 10,   -- Default number of entries to fetch
	MAX_ENTRIES = 100,      -- Maximum allowed entries per request
	
	-- Cache settings (helps reduce DataStore API calls)
	CACHE_DURATION = 60,    -- Seconds before cache is considered stale
	
	-- Batch sync interval (ProcessPendingUpdates is called at this interval)
	SYNC_INTERVAL = 30,     -- Seconds between XP sync batches
}

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

local LeaderboardService = {}
LeaderboardService.Config = CONFIG  -- Exposed for external configuration if needed

--------------------------------------------------------------------------------
-- Private State
--------------------------------------------------------------------------------

-- OrderedDataStore reference (initialized in Init())
local xpLeaderboard: OrderedDataStore? = nil

-- In-memory cache to reduce DataStore reads
-- Key format: "XP_{count}" -> LeaderboardData
local leaderboardCache: { [string]: LeaderboardData } = {}

-- Queue of pending XP updates (processed in batches to avoid rate limits)
-- Maps UserId -> latest XP value
local pendingXPUpdates: { [number]: number } = {}

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--[=[
	@function Init
	@description Initialize the OrderedDataStore connection.
	             Must be called once on server startup before using other functions.
	             Safe to call in Studio (will warn but not error if DataStore unavailable).
	
	@server-only
	@returns void
]=]
function LeaderboardService.Init()
	if RunService:IsClient() then
		warn("[" .. CONTEXT .. "] LeaderboardService.Init() should only be called on server")
		return
	end
	
	local success, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(CONFIG.XP_LEADERBOARD_NAME)
	end)
	
	if success then
		xpLeaderboard = result
		print("[" .. CONTEXT .. "] OrderedDataStore initialized")
	else
		warn("[" .. CONTEXT .. "] OrderedDataStore unavailable (Studio mode?): " .. tostring(result))
	end
end

--[=[
	@function UpdatePlayerXP
	@description Queue a player's XP value for batch sync to the leaderboard.
	             Updates are batched to avoid DataStore rate limits.
	             Call ProcessPendingUpdates() periodically to flush the queue.
	
	@param userId number -- The player's Roblox UserId
	@param xp number -- The player's current total XP value
	
	@server-only
	@returns void
]=]
function LeaderboardService.UpdatePlayerXP(userId: number, xp: number)
	if RunService:IsClient() then
		return
	end
	
	pendingXPUpdates[userId] = xp
end

--[=[
	@function SyncPlayerXPNow
	@description Immediately write a player's XP to the OrderedDataStore.
	             Bypasses the pending queue for urgent updates (e.g., player leaving).
	             Use sparingly to avoid hitting DataStore rate limits.
	
	@param userId number -- The player's Roblox UserId
	@param xp number -- The player's current total XP value
	
	@server-only
	@returns boolean -- true if sync succeeded, false otherwise
]=]
function LeaderboardService.SyncPlayerXPNow(userId: number, xp: number): boolean
	if RunService:IsClient() or not xpLeaderboard then
		return false
	end
	
	local success, err = pcall(function()
		xpLeaderboard:SetAsync(tostring(userId), xp)
	end)
	
	if not success then
		warn("[" .. CONTEXT .. "] Failed to sync XP for " .. userId .. ": " .. tostring(err))
	end
	
	return success
end

--[=[
	@function ProcessPendingUpdates
	@description Flush all queued XP updates to the OrderedDataStore.
	             Should be called periodically (e.g., every CONFIG.SYNC_INTERVAL seconds).
	             Includes a small delay between writes to avoid rate limiting.
	
	@server-only
	@returns void
]=]
function LeaderboardService.ProcessPendingUpdates()
	if RunService:IsClient() or not xpLeaderboard then
		return
	end
	
	for userId, xp in pendingXPUpdates do
		local success, err = pcall(function()
			xpLeaderboard:SetAsync(tostring(userId), xp)
		end)
		
		if not success then
			warn("[" .. CONTEXT .. "] Failed to update XP for " .. userId .. ": " .. tostring(err))
		end
		
		-- Small delay to avoid rate limiting
		task.wait(0.1)
	end
	
	pendingXPUpdates = {}
end

--[=[
	@function GetXPLeaderboard
	@description Fetch the top players sorted by XP (descending).
	             Returns cached data if fresh (within CACHE_DURATION), otherwise
	             fetches from the OrderedDataStore.
	
	@param count number? -- Number of entries to fetch (default: 10, max: 100)
	
	@returns LeaderboardData -- Contains Entries array, LastUpdated timestamp, and StatType
	
	@example
		local data = LeaderboardService.GetXPLeaderboard(10)
		for _, entry in data.Entries do
			print(string.format("#%d %s: %s XP", entry.Rank, entry.DisplayName, entry.Value))
		end
]=]
function LeaderboardService.GetXPLeaderboard(count: number?): LeaderboardData
	local numEntries = math.clamp(count or CONFIG.DEFAULT_ENTRIES, 1, CONFIG.MAX_ENTRIES)
	local cacheKey = "XP_" .. numEntries
	
	-- Check cache
	local cached = leaderboardCache[cacheKey]
	if cached and (os.time() - cached.LastUpdated) < CONFIG.CACHE_DURATION then
		return cached
	end
	
	-- Fetch from DataStore
	local entries: { LeaderboardEntry } = {}
	
	if xpLeaderboard then
		local success, pages = pcall(function()
			return xpLeaderboard:GetSortedAsync(false, numEntries)  -- false = descending (highest first)
		end)
		
		if success and pages then
			local data = pages:GetCurrentPage()
			for rank, entry in data do
				local userId = tonumber(entry.key) or 0
				local displayName = "Player" .. userId
				
				-- Try to get display name from Players service
				local player = game:GetService("Players"):GetPlayerByUserId(userId)
				if player then
					displayName = player.DisplayName
				else
					-- Try to fetch name (this may fail for players not in game)
					local nameSuccess, name = pcall(function()
						return game:GetService("Players"):GetNameFromUserIdAsync(userId)
					end)
					if nameSuccess and name then
						displayName = name
					end
				end
				
				table.insert(entries, {
					Rank = rank,
					UserId = userId,
					DisplayName = displayName,
					Value = entry.value,
				})
			end
		else
			warn("[" .. CONTEXT .. "] Failed to fetch leaderboard: " .. tostring(pages))
		end
	end
	
	-- Create leaderboard data
	local leaderboardData: LeaderboardData = {
		Entries = entries,
		LastUpdated = os.time(),
		StatType = "XP",
	}
	
	-- Update cache
	leaderboardCache[cacheKey] = leaderboardData
	
	return leaderboardData
end

--[=[
	@function GetPlayerXPRank
	@description Get a specific player's rank on the XP leaderboard.
	             Note: This makes a direct DataStore call (not cached).
	
	@param userId number -- The player's Roblox UserId
	
	@returns number? -- 1-based rank position, or nil if player not found or error
]=]
function LeaderboardService.GetPlayerXPRank(userId: number): number?
	if not xpLeaderboard then
		return nil
	end
	
	local success, rank = pcall(function()
		return xpLeaderboard:GetRankAsync(tostring(userId))
	end)
	
	if success then
		return rank
	end
	
	return nil
end

--[=[
	@function ClearCache
	@description Clear the in-memory leaderboard cache.
	             Next call to GetXPLeaderboard() will fetch fresh data from DataStore.
	             Useful after major XP changes or for debugging.
	
	@returns void
]=]
function LeaderboardService.ClearCache()
	leaderboardCache = {}
end

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

--[=[
	@function FormatXP
	@description Format an XP value for human-readable display.
	             Abbreviates large numbers with K (thousands) or M (millions).
	
	@param xp number -- The raw XP value
	
	@returns string -- Formatted string (e.g., 1500 -> "1.5K", 2500000 -> "2.5M")
	
	@example
		LeaderboardService.FormatXP(500)      -- "500"
		LeaderboardService.FormatXP(1500)     -- "1.5K"
		LeaderboardService.FormatXP(2500000)  -- "2.5M"
]=]
function LeaderboardService.FormatXP(xp: number): string
	if xp >= 1000000 then
		return string.format("%.1fM", xp / 1000000)
	elseif xp >= 1000 then
		return string.format("%.1fK", xp / 1000)
	else
		return tostring(xp)
	end
end

return LeaderboardService
