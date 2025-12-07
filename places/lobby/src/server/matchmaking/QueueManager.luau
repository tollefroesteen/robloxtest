--!strict
-- QueueManager.luau
-- Manages cross-server matchmaking queues using MemoryStoreService
-- Handles Solo1Queue, Solo2Queue, and Team2Queue

local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local MatchmakingConfig = require(Shared:WaitForChild("config"):WaitForChild("MatchmakingConfig"))

local CONTEXT = "QueueManager"

local QueueManager = {}

-- MemoryStore sorted maps for each queue type
local solo1Queue: MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(MatchmakingConfig.QUEUE_NAMES.SOLO_1V1)
local solo2Queue: MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(MatchmakingConfig.QUEUE_NAMES.SOLO_2V2)
local team2Queue: MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(MatchmakingConfig.QUEUE_NAMES.TEAM_2V2)

-- Server identifier for this server
local serverId = HttpService:GenerateGUID(false)

-- Generate unique keys for queue entries
local function generateEntryKey(playerId: number): string
	return string.format("%d_%s_%d", playerId, serverId, os.time())
end

local function generateTeamKey(player1Id: number, player2Id: number): string
	-- Sort IDs to ensure consistent key regardless of order
	local id1, id2 = math.min(player1Id, player2Id), math.max(player1Id, player2Id)
	return string.format("team_%d_%d_%s", id1, id2, serverId)
end

--[[
	Add a solo player to the 1v1 queue
]]
function QueueManager.AddToSolo1Queue(playerId: number): boolean
	local key = generateEntryKey(playerId)
	local entry: MatchmakingConfig.Solo1Entry = {
		type = "solo1",
		playerId = playerId,
		queuedAt = os.time(),
		serverId = serverId,
	}
	
	local success, err = pcall(function()
		solo1Queue:SetAsync(key, entry, MatchmakingConfig.QUEUE_ENTRY_TTL)
	end)
	
	if success then
		Log.Info(CONTEXT, string.format("Added player %d to Solo1Queue", playerId))
	else
		Log.Warn(CONTEXT, string.format("Failed to add player %d to Solo1Queue: %s", playerId, tostring(err)))
	end
	
	return success
end

--[[
	Add a solo player to the 2v2 queue (looking for a team)
]]
function QueueManager.AddToSolo2Queue(playerId: number): boolean
	local key = generateEntryKey(playerId)
	local entry: MatchmakingConfig.Solo2Entry = {
		type = "solo2",
		playerId = playerId,
		queuedAt = os.time(),
		serverId = serverId,
	}
	
	local success, err = pcall(function()
		solo2Queue:SetAsync(key, entry, MatchmakingConfig.QUEUE_ENTRY_TTL)
	end)
	
	if success then
		Log.Info(CONTEXT, string.format("Added player %d to Solo2Queue", playerId))
	else
		Log.Warn(CONTEXT, string.format("Failed to add player %d to Solo2Queue: %s", playerId, tostring(err)))
	end
	
	return success
end

--[[
	Add a pre-formed team of 2 to the 2v2 queue
]]
function QueueManager.AddToTeam2Queue(player1Id: number, player2Id: number): boolean
	local key = generateTeamKey(player1Id, player2Id)
	local entry: MatchmakingConfig.Team2Entry = {
		type = "team2",
		players = { player1Id, player2Id },
		queuedAt = os.time(),
		serverId = serverId,
	}
	
	local success, err = pcall(function()
		team2Queue:SetAsync(key, entry, MatchmakingConfig.QUEUE_ENTRY_TTL)
	end)
	
	if success then
		Log.Info(CONTEXT, string.format("Added team (%d, %d) to Team2Queue", player1Id, player2Id))
	else
		Log.Warn(CONTEXT, string.format("Failed to add team to Team2Queue: %s", tostring(err)))
	end
	
	return success
end

--[[
	Remove a player from all queues
]]
function QueueManager.RemovePlayerFromQueues(playerId: number): boolean
	local removed = false
	
	-- Try to remove from Solo1Queue
	local success1 = pcall(function()
		local items = solo1Queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		for _, item in items do
			local entry = item.value :: MatchmakingConfig.Solo1Entry
			if entry.playerId == playerId then
				solo1Queue:RemoveAsync(item.key)
				removed = true
				Log.Debug(CONTEXT, string.format("Removed player %d from Solo1Queue", playerId))
			end
		end
	end)
	
	-- Try to remove from Solo2Queue
	local success2 = pcall(function()
		local items = solo2Queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		for _, item in items do
			local entry = item.value :: MatchmakingConfig.Solo2Entry
			if entry.playerId == playerId then
				solo2Queue:RemoveAsync(item.key)
				removed = true
				Log.Debug(CONTEXT, string.format("Removed player %d from Solo2Queue", playerId))
			end
		end
	end)
	
	-- Try to remove from Team2Queue (if player is in a team)
	local success3 = pcall(function()
		local items = team2Queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		for _, item in items do
			local entry = item.value :: MatchmakingConfig.Team2Entry
			if table.find(entry.players, playerId) then
				team2Queue:RemoveAsync(item.key)
				removed = true
				Log.Debug(CONTEXT, string.format("Removed team containing player %d from Team2Queue", playerId))
			end
		end
	end)
	
	if removed then
		Log.Info(CONTEXT, string.format("Player %d removed from queues", playerId))
	end
	
	return removed
end

--[[
	Get entries from Solo1Queue for matchmaking
]]
function QueueManager.GetSolo1Entries(limit: number?): { MatchmakingConfig.Solo1Entry }
	local entries: { MatchmakingConfig.Solo1Entry } = {}
	
	local success, err = pcall(function()
		local items = solo1Queue:GetRangeAsync(Enum.SortDirection.Ascending, limit or 50)
		for _, item in items do
			table.insert(entries, item.value :: MatchmakingConfig.Solo1Entry)
		end
	end)
	
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to get Solo1Queue entries: %s", tostring(err)))
	end
	
	return entries
end

--[[
	Get entries from Solo2Queue for matchmaking
]]
function QueueManager.GetSolo2Entries(limit: number?): { MatchmakingConfig.Solo2Entry }
	local entries: { MatchmakingConfig.Solo2Entry } = {}
	
	local success, err = pcall(function()
		local items = solo2Queue:GetRangeAsync(Enum.SortDirection.Ascending, limit or 50)
		for _, item in items do
			table.insert(entries, item.value :: MatchmakingConfig.Solo2Entry)
		end
	end)
	
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to get Solo2Queue entries: %s", tostring(err)))
	end
	
	return entries
end

--[[
	Get entries from Team2Queue for matchmaking
]]
function QueueManager.GetTeam2Entries(limit: number?): { MatchmakingConfig.Team2Entry }
	local entries: { MatchmakingConfig.Team2Entry } = {}
	
	local success, err = pcall(function()
		local items = team2Queue:GetRangeAsync(Enum.SortDirection.Ascending, limit or 50)
		for _, item in items do
			table.insert(entries, item.value :: MatchmakingConfig.Team2Entry)
		end
	end)
	
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to get Team2Queue entries: %s", tostring(err)))
	end
	
	return entries
end

--[[
	Atomically remove entries from Solo1Queue by player IDs
	Returns true if all were successfully removed
]]
function QueueManager.RemoveSolo1Entries(playerIds: { number }): boolean
	local allRemoved = true
	
	pcall(function()
		local items = solo1Queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		for _, item in items do
			local entry = item.value :: MatchmakingConfig.Solo1Entry
			if table.find(playerIds, entry.playerId) then
				local success = pcall(function()
					solo1Queue:RemoveAsync(item.key)
				end)
				if not success then
					allRemoved = false
				end
			end
		end
	end)
	
	return allRemoved
end

--[[
	Atomically remove entries from Solo2Queue by player IDs
]]
function QueueManager.RemoveSolo2Entries(playerIds: { number }): boolean
	local allRemoved = true
	
	pcall(function()
		local items = solo2Queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		for _, item in items do
			local entry = item.value :: MatchmakingConfig.Solo2Entry
			if table.find(playerIds, entry.playerId) then
				local success = pcall(function()
					solo2Queue:RemoveAsync(item.key)
				end)
				if not success then
					allRemoved = false
				end
			end
		end
	end)
	
	return allRemoved
end

--[[
	Remove a team entry from Team2Queue
]]
function QueueManager.RemoveTeam2Entry(playerIds: { number }): boolean
	local removed = false
	
	pcall(function()
		local items = team2Queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		for _, item in items do
			local entry = item.value :: MatchmakingConfig.Team2Entry
			-- Check if all players in the entry match
			local allMatch = true
			for _, pid in playerIds do
				if not table.find(entry.players, pid) then
					allMatch = false
					break
				end
			end
			if allMatch and #entry.players == #playerIds then
				pcall(function()
					team2Queue:RemoveAsync(item.key)
				end)
				removed = true
			end
		end
	end)
	
	return removed
end

--[[
	Get the current server ID
]]
function QueueManager.GetServerId(): string
	return serverId
end

--[[
	Clean up stale entries from all queues
]]
function QueueManager.CleanupStaleEntries()
	local currentTime = os.time()
	local threshold = currentTime - MatchmakingConfig.STALE_ENTRY_THRESHOLD
	local cleanedCount = 0
	
	-- Clean Solo1Queue
	pcall(function()
		local items = solo1Queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		for _, item in items do
			local entry = item.value :: MatchmakingConfig.Solo1Entry
			if entry.queuedAt < threshold then
				solo1Queue:RemoveAsync(item.key)
				cleanedCount += 1
			end
		end
	end)
	
	-- Clean Solo2Queue
	pcall(function()
		local items = solo2Queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		for _, item in items do
			local entry = item.value :: MatchmakingConfig.Solo2Entry
			if entry.queuedAt < threshold then
				solo2Queue:RemoveAsync(item.key)
				cleanedCount += 1
			end
		end
	end)
	
	-- Clean Team2Queue
	pcall(function()
		local items = team2Queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		for _, item in items do
			local entry = item.value :: MatchmakingConfig.Team2Entry
			if entry.queuedAt < threshold then
				team2Queue:RemoveAsync(item.key)
				cleanedCount += 1
			end
		end
	end)
	
	if cleanedCount > 0 then
		Log.Debug(CONTEXT, string.format("Cleaned up %d stale queue entries", cleanedCount))
	end
end

return QueueManager
