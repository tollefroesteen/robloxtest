--!strict
-- MatchmakingService.luau
-- Server-side matchmaking service that processes queues and creates matches
-- Handles 1v1 and 2v2 match formation

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local PlacesConfig = require(Shared:WaitForChild("PlacesConfig"))
local MatchmakingConfig = require(Shared:WaitForChild("config"):WaitForChild("MatchmakingConfig"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local QueueManager = require(script.Parent:WaitForChild("QueueManager"))

local CONTEXT = "MatchmakingService"

local MatchmakingService = {}

-- Track players currently in matchmaking process (prevent double-queueing)
local playersInQueue: { [number]: boolean } = {}
local playersInZone: { [number]: string } = {} -- playerId -> zoneType ("1v1" or "2v2")
local playerZoneId: { [number]: number } = {} -- playerId -> zoneIndex (for per-zone team formation)
local playerCountdowns: { [number]: number } = {} -- playerId -> countdown remaining

-- Track players in each 2v2 zone for team formation: { [zoneId]: { userId1, userId2, ... } }
local playersIn2v2Zones: { [number]: { [number]: boolean } } = {}

-- Running state
local isRunning = false
local matchmakingThread: thread? = nil
local cleanupThread: thread? = nil

--[[
	Check if a player is currently online on this server
]]
local function isPlayerOnline(playerId: number): boolean
	local player = Players:GetPlayerByUserId(playerId)
	return player ~= nil
end

--[[
	Get Player objects from user IDs (only returns players on this server)
]]
local function getPlayersFromIds(playerIds: { number }): { Player }
	local players: { Player } = {}
	for _, userId in playerIds do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			table.insert(players, player)
		end
	end
	return players
end

--[[
	Generate a unique match ID
]]
local function generateMatchId(): string
	return HttpService:GenerateGUID(false)
end

--[[
	Teleport players to a private arena server
]]
local function teleportToArena(playerIds: { number }, teleportData: MatchmakingConfig.TeleportData)
	local players = getPlayersFromIds(playerIds)
	
	if #players == 0 then
		Log.Warn(CONTEXT, "No players available for teleport")
		return false
	end
	
	-- Check arena place ID is configured
	if PlacesConfig.ARENA_PLACE_ID == 0 then
		Log.Warn(CONTEXT, "Arena place ID not configured!")
		return false
	end
	
	-- Reserve a private server
	local success, result = pcall(function()
		local serverCode = TeleportService:ReserveServer(PlacesConfig.ARENA_PLACE_ID)
		
		Log.Info(CONTEXT, string.format(
			"Teleporting %d players to arena (mode: %s, matchId: %s)",
			#players, teleportData.mode, teleportData.matchId
		))
		
		TeleportService:TeleportToPrivateServer(
			PlacesConfig.ARENA_PLACE_ID,
			serverCode,
			players,
			nil,
			teleportData
		)
		
		return true
	end)
	
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to teleport players: %s", tostring(result)))
		return false
	end
	
	-- Clean up tracking for teleported players
	for _, pid in playerIds do
		local zoneId = playerZoneId[pid]
		playersInQueue[pid] = nil
		playersInZone[pid] = nil
		playerCountdowns[pid] = nil
		playerZoneId[pid] = nil
		if zoneId and playersIn2v2Zones[zoneId] then
			playersIn2v2Zones[zoneId][pid] = nil
		end
	end
	
	return true
end

--[[
	Process 1v1 matchmaking
	Match two solo players from Solo1Queue
]]
local function process1v1Matches()
	local entries = QueueManager.GetSolo1Entries(50)
	
	-- Need at least 2 players
	if #entries < 2 then
		return
	end
	
	-- Filter to only include players still online
	local validEntries: { MatchmakingConfig.Solo1Entry } = {}
	for _, entry in entries do
		if isPlayerOnline(entry.playerId) then
			table.insert(validEntries, entry)
		else
			-- Remove offline player from queue
			QueueManager.RemovePlayerFromQueues(entry.playerId)
		end
	end
	
	-- Match pairs of players
	local i = 1
	while i + 1 <= #validEntries do
		local player1 = validEntries[i]
		local player2 = validEntries[i + 1]
		
		-- Create match
		local matchId = generateMatchId()
		local teleportData: MatchmakingConfig.TeleportData = {
			mode = "1v1",
			teamA = { player1.playerId },
			teamB = { player2.playerId },
			matchId = matchId,
		}
		
		Log.Info(CONTEXT, string.format(
			"1v1 Match found: %d vs %d",
			player1.playerId, player2.playerId
		))
		
		-- Remove from queues first
		QueueManager.RemoveSolo1Entries({ player1.playerId, player2.playerId })
		
		-- Teleport players
		teleportToArena({ player1.playerId, player2.playerId }, teleportData)
		
		i += 2
	end
end

--[[
	Process 2v2 matchmaking
	Priority: team2+team2 > team2+solo2+solo2 > solo2x4
]]
local function process2v2Matches()
	local teamEntries = QueueManager.GetTeam2Entries(50)
	local soloEntries = QueueManager.GetSolo2Entries(50)
	
	-- Filter valid entries (players still online)
	local validTeams: { MatchmakingConfig.Team2Entry } = {}
	for _, entry in teamEntries do
		local allOnline = true
		for _, pid in entry.players do
			if not isPlayerOnline(pid) then
				allOnline = false
				break
			end
		end
		if allOnline then
			table.insert(validTeams, entry)
		else
			-- Remove team with offline player
			QueueManager.RemoveTeam2Entry(entry.players)
		end
	end
	
	local validSolos: { MatchmakingConfig.Solo2Entry } = {}
	for _, entry in soloEntries do
		if isPlayerOnline(entry.playerId) then
			table.insert(validSolos, entry)
		else
			QueueManager.RemovePlayerFromQueues(entry.playerId)
		end
	end
	
	-- Priority 1: team2 + team2
	while #validTeams >= 2 do
		local team1 = table.remove(validTeams, 1) :: MatchmakingConfig.Team2Entry
		local team2 = table.remove(validTeams, 1) :: MatchmakingConfig.Team2Entry
		
		local matchId = generateMatchId()
		local teleportData: MatchmakingConfig.TeleportData = {
			mode = "2v2",
			teamA = team1.players,
			teamB = team2.players,
			matchId = matchId,
		}
		
		Log.Info(CONTEXT, string.format(
			"2v2 Match (team+team): Team A (%d, %d) vs Team B (%d, %d)",
			team1.players[1], team1.players[2],
			team2.players[1], team2.players[2]
		))
		
		-- Remove from queues
		QueueManager.RemoveTeam2Entry(team1.players)
		QueueManager.RemoveTeam2Entry(team2.players)
		
		-- Teleport
		local allPlayerIds = { team1.players[1], team1.players[2], team2.players[1], team2.players[2] }
		teleportToArena(allPlayerIds, teleportData)
	end
	
	-- Priority 2: team2 + solo2 + solo2
	while #validTeams >= 1 and #validSolos >= 2 do
		local team1 = table.remove(validTeams, 1) :: MatchmakingConfig.Team2Entry
		local solo1 = table.remove(validSolos, 1) :: MatchmakingConfig.Solo2Entry
		local solo2 = table.remove(validSolos, 1) :: MatchmakingConfig.Solo2Entry
		
		local matchId = generateMatchId()
		local teleportData: MatchmakingConfig.TeleportData = {
			mode = "2v2",
			teamA = team1.players,
			teamB = { solo1.playerId, solo2.playerId },
			matchId = matchId,
		}
		
		Log.Info(CONTEXT, string.format(
			"2v2 Match (team+solos): Team A (%d, %d) vs Team B (%d, %d)",
			team1.players[1], team1.players[2],
			solo1.playerId, solo2.playerId
		))
		
		-- Remove from queues
		QueueManager.RemoveTeam2Entry(team1.players)
		QueueManager.RemoveSolo2Entries({ solo1.playerId, solo2.playerId })
		
		-- Teleport
		local allPlayerIds = { team1.players[1], team1.players[2], solo1.playerId, solo2.playerId }
		teleportToArena(allPlayerIds, teleportData)
	end
	
	-- Priority 3: solo2 x 4 (create two balanced teams)
	while #validSolos >= 4 do
		local solo1 = table.remove(validSolos, 1) :: MatchmakingConfig.Solo2Entry
		local solo2 = table.remove(validSolos, 1) :: MatchmakingConfig.Solo2Entry
		local solo3 = table.remove(validSolos, 1) :: MatchmakingConfig.Solo2Entry
		local solo4 = table.remove(validSolos, 1) :: MatchmakingConfig.Solo2Entry
		
		local matchId = generateMatchId()
		local teleportData: MatchmakingConfig.TeleportData = {
			mode = "2v2",
			teamA = { solo1.playerId, solo2.playerId },
			teamB = { solo3.playerId, solo4.playerId },
			matchId = matchId,
		}
		
		Log.Info(CONTEXT, string.format(
			"2v2 Match (4 solos): Team A (%d, %d) vs Team B (%d, %d)",
			solo1.playerId, solo2.playerId,
			solo3.playerId, solo4.playerId
		))
		
		-- Remove from queues
		QueueManager.RemoveSolo2Entries({ 
			solo1.playerId, solo2.playerId, 
			solo3.playerId, solo4.playerId 
		})
		
		-- Teleport
		local allPlayerIds = { 
			solo1.playerId, solo2.playerId, 
			solo3.playerId, solo4.playerId 
		}
		teleportToArena(allPlayerIds, teleportData)
	end
end

--[[
	Main matchmaking loop
]]
local function runMatchmaking()
	while isRunning do
		-- Process both queue types
		local success1, err1 = pcall(process1v1Matches)
		if not success1 then
			Log.Warn(CONTEXT, string.format("Error in 1v1 matchmaking: %s", tostring(err1)))
		end
		
		local success2, err2 = pcall(process2v2Matches)
		if not success2 then
			Log.Warn(CONTEXT, string.format("Error in 2v2 matchmaking: %s", tostring(err2)))
		end
		
		task.wait(MatchmakingConfig.MATCHMAKING_TICK_INTERVAL)
	end
end

--[[
	Cleanup loop for stale entries
]]
local function runCleanup()
	while isRunning do
		task.wait(MatchmakingConfig.QUEUE_CLEANUP_INTERVAL)
		
		local success, err = pcall(function()
			QueueManager.CleanupStaleEntries()
		end)
		
		if not success then
			Log.Warn(CONTEXT, string.format("Error in queue cleanup: %s", tostring(err)))
		end
	end
end

--[[
	Called when a player enters a matchmaking zone
]]
function MatchmakingService.OnPlayerEnteredZone(player: Player, zoneType: "1v1" | "2v2", zoneId: number?)
	local userId = player.UserId
	
	-- Already in a zone or queue
	if playersInZone[userId] then
		return
	end
	
	playersInZone[userId] = zoneType
	playerCountdowns[userId] = MatchmakingConfig.COUNTDOWN_SECONDS
	
	if zoneType == "2v2" and zoneId then
		playerZoneId[userId] = zoneId
		-- Initialize zone tracking if needed
		if not playersIn2v2Zones[zoneId] then
			playersIn2v2Zones[zoneId] = {}
		end
		playersIn2v2Zones[zoneId][userId] = true
	end
	
	Log.Debug(CONTEXT, string.format("Player %s entered %s zone (id: %s)", player.Name, zoneType, tostring(zoneId)))
	
	-- Notify client to start countdown UI
	RemoteEvents.MatchmakingZoneEnteredEvent:FireClient(player, zoneType)
	
	-- Check for instant team formation in 2v2
	if zoneType == "2v2" and zoneId then
		task.defer(function()
			MatchmakingService.CheckTeamFormationInZone(zoneId)
		end)
	end
end

--[[
	Called when a player exits a matchmaking zone
]]
function MatchmakingService.OnPlayerExitedZone(player: Player, _zoneId: number?)
	local userId = player.UserId
	
	if not playersInZone[userId] then
		return
	end
	
	local zoneType = playersInZone[userId]
	local zoneId = playerZoneId[userId]
	
	playersInZone[userId] = nil
	playerCountdowns[userId] = nil
	playerZoneId[userId] = nil
	
	-- Remove from zone-specific tracking
	if zoneId and playersIn2v2Zones[zoneId] then
		playersIn2v2Zones[zoneId][userId] = nil
	end
	
	Log.Debug(CONTEXT, string.format("Player %s exited %s zone", player.Name, zoneType))
	
	-- Notify client to cancel countdown
	RemoteEvents.MatchmakingZoneExitedEvent:FireClient(player)
end

--[[
	Called when a player's countdown reaches zero
]]
function MatchmakingService.OnCountdownComplete(player: Player)
	local userId = player.UserId
	local zoneType = playersInZone[userId]
	
	if not zoneType then
		return
	end
	
	-- Prevent double-queueing
	if playersInQueue[userId] then
		return
	end
	
	playersInQueue[userId] = true
	
	Log.Info(CONTEXT, string.format("Player %s countdown complete for %s", player.Name, zoneType))
	
	if zoneType == "1v1" then
		QueueManager.AddToSolo1Queue(userId)
	elseif zoneType == "2v2" then
		-- Check if they should be added as solo or if there's a teammate
		-- At this point, if no team formed, add as solo
		QueueManager.AddToSolo2Queue(userId)
	end
	
	-- Notify client they're in queue
	RemoteEvents.MatchmakingQueueJoinedEvent:FireClient(player, zoneType)
end

--[[
	Check if two players in a specific 2v2 zone can form a team
]]
function MatchmakingService.CheckTeamFormationInZone(zoneId: number)
	local zonePlayersMap = playersIn2v2Zones[zoneId]
	if not zonePlayersMap then return end
	
	local playersInThisZone: { Player } = {}
	
	for userId, isIn in zonePlayersMap do
		if isIn and not playersInQueue[userId] then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				table.insert(playersInThisZone, player)
			end
		end
	end
	
	-- If 2 players are in this specific zone together, form a team immediately
	if #playersInThisZone >= 2 then
		local player1 = playersInThisZone[1]
		local player2 = playersInThisZone[2]
		
		local userId1 = player1.UserId
		local userId2 = player2.UserId
		
		-- Mark as in queue
		playersInQueue[userId1] = true
		playersInQueue[userId2] = true
		playersInZone[userId1] = nil
		playersInZone[userId2] = nil
		playerZoneId[userId1] = nil
		playerZoneId[userId2] = nil
		
		-- Remove from zone tracking
		zonePlayersMap[userId1] = nil
		zonePlayersMap[userId2] = nil
		
		-- Add as a team
		QueueManager.AddToTeam2Queue(userId1, userId2)
		
		Log.Info(CONTEXT, string.format(
			"Team formed in zone %d: %s and %s",
			zoneId, player1.Name, player2.Name
		))
		
		-- Notify both clients
		RemoteEvents.MatchmakingTeamFormedEvent:FireClient(player1, player2.Name)
		RemoteEvents.MatchmakingTeamFormedEvent:FireClient(player2, player1.Name)
		RemoteEvents.MatchmakingQueueJoinedEvent:FireClient(player1, "2v2")
		RemoteEvents.MatchmakingQueueJoinedEvent:FireClient(player2, "2v2")
	end
end

--[[
	Handle player leaving the game
]]
function MatchmakingService.OnPlayerRemoving(player: Player)
	local userId = player.UserId
	local zoneId = playerZoneId[userId]
	
	-- Clean up local tracking
	playersInQueue[userId] = nil
	playersInZone[userId] = nil
	playerCountdowns[userId] = nil
	playerZoneId[userId] = nil
	
	-- Remove from zone-specific tracking
	if zoneId and playersIn2v2Zones[zoneId] then
		playersIn2v2Zones[zoneId][userId] = nil
	end
	
	-- Remove from global queues
	QueueManager.RemovePlayerFromQueues(userId)
	
	Log.Debug(CONTEXT, string.format("Cleaned up matchmaking for departing player %s", player.Name))
end

--[[
	Check if a player is currently in queue
]]
function MatchmakingService.IsPlayerInQueue(player: Player): boolean
	return playersInQueue[player.UserId] == true
end

--[[
	Check if a player is in a matchmaking zone
]]
function MatchmakingService.IsPlayerInZone(player: Player): boolean
	return playersInZone[player.UserId] ~= nil
end

--[[
	Get the zone type a player is in
]]
function MatchmakingService.GetPlayerZone(player: Player): string?
	return playersInZone[player.UserId]
end

--[[
	Handle cancel queue request from client
]]
function MatchmakingService.OnCancelQueue(player: Player)
	local userId = player.UserId
	
	if not playersInQueue[userId] then
		Log.Debug(CONTEXT, string.format("Player %s tried to cancel but not in queue", player.Name))
		return
	end
	
	Log.Info(CONTEXT, string.format("Player %s cancelled queue", player.Name))
	
	-- Remove from all queues
	QueueManager.RemovePlayerFromQueues(userId)
	
	-- Clean up tracking
	local zoneId = playerZoneId[userId]
	playersInQueue[userId] = nil
	playersInZone[userId] = nil
	playerCountdowns[userId] = nil
	playerZoneId[userId] = nil
	if zoneId and playersIn2v2Zones[zoneId] then
		playersIn2v2Zones[zoneId][userId] = nil
	end
	
	-- Notify client
	RemoteEvents.MatchmakingQueueCancelledEvent:FireClient(player)
end

--[[
	Start the matchmaking service
]]
function MatchmakingService.Start()
	if isRunning then
		Log.Warn(CONTEXT, "Matchmaking service is already running")
		return
	end
	
	isRunning = true
	
	-- Connect player removing handler
	Players.PlayerRemoving:Connect(MatchmakingService.OnPlayerRemoving)
	
	-- Connect countdown complete event from clients
	RemoteEvents.MatchmakingCountdownCompleteEvent.OnServerEvent:Connect(function(player)
		MatchmakingService.OnCountdownComplete(player)
	end)
	
	-- Connect cancel queue event from clients
	RemoteEvents.MatchmakingCancelQueueEvent.OnServerEvent:Connect(function(player)
		MatchmakingService.OnCancelQueue(player)
	end)
	
	-- Start matchmaking loop
	matchmakingThread = task.spawn(runMatchmaking)
	
	-- Start cleanup loop
	cleanupThread = task.spawn(runCleanup)
	
	Log.Info(CONTEXT, "Matchmaking service started")
end

--[[
	Stop the matchmaking service
]]
function MatchmakingService.Stop()
	isRunning = false
	
	if matchmakingThread then
		task.cancel(matchmakingThread)
		matchmakingThread = nil
	end
	
	if cleanupThread then
		task.cancel(cleanupThread)
		cleanupThread = nil
	end
	
	Log.Info(CONTEXT, "Matchmaking service stopped")
end

return MatchmakingService
