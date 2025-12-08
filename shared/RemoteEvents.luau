-- RemoteEvents.luau
-- Creates and stores RemoteEvents for client-server communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

local function getOrCreate(name: string)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = ReplicatedStorage
	return ev
end

RemoteEvents.EndGameEvent = getOrCreate("EndGameEvent")
RemoteEvents.HealthEvent = getOrCreate("HealthEvent")
RemoteEvents.ResetGameEvent = getOrCreate("ResetGameEvent")
RemoteEvents.ShootEvent = getOrCreate("ShootEvent")
RemoteEvents.SprintEvent = getOrCreate("SprintEvent")
RemoteEvents.StartGameEvent = getOrCreate("StartGameEvent")
RemoteEvents.AnimalSpawnedEvent = getOrCreate("AnimalSpawnedEvent")
RemoteEvents.TimerUpdateEvent = getOrCreate("TimerUpdateEvent")
RemoteEvents.TeamAssignedEvent = getOrCreate("TeamAssignedEvent")
RemoteEvents.TeamScoreUpdateEvent = getOrCreate("TeamScoreUpdateEvent")
RemoteEvents.PlayerScoredEvent = getOrCreate("PlayerScoredEvent")

-- Player action events
RemoteEvents.FeedEvent = getOrCreate("FeedEvent")
RemoteEvents.ScareEvent = getOrCreate("ScareEvent")

-- Player data events
RemoteEvents.AchievementUnlockedEvent = getOrCreate("AchievementUnlockedEvent")
RemoteEvents.InventoryUpdatedEvent = getOrCreate("InventoryUpdatedEvent")
RemoteEvents.StatsUpdatedEvent = getOrCreate("StatsUpdatedEvent")
RemoteEvents.LevelUpEvent = getOrCreate("LevelUpEvent")
RemoteEvents.RequestPlayerDataEvent = getOrCreate("RequestPlayerDataEvent")         -- Client -> Server: request inventory/stats refresh

-- Game end events
RemoteEvents.GameFreezeEvent = getOrCreate("GameFreezeEvent")
RemoteEvents.GameResultsEvent = getOrCreate("GameResultsEvent")
RemoteEvents.CoinsAwardedEvent = getOrCreate("CoinsAwardedEvent")
RemoteEvents.NewAnimalDiscoveredEvent = getOrCreate("NewAnimalDiscoveredEvent")
RemoteEvents.GameEndSequenceEvent = getOrCreate("GameEndSequenceEvent")
RemoteEvents.RematchRequestEvent = getOrCreate("RematchRequestEvent")
RemoteEvents.TeamForfeitEvent = getOrCreate("TeamForfeitEvent")

-- Shop events
RemoteEvents.ShopPurchaseRequestEvent = getOrCreate("ShopPurchaseRequestEvent")
RemoteEvents.ShopPurchaseResultEvent = getOrCreate("ShopPurchaseResultEvent")
RemoteEvents.ShopBuyCoinsRequestEvent = getOrCreate("ShopBuyCoinsRequestEvent")

-- Respawn events
RemoteEvents.RespawnCountdownEvent = getOrCreate("RespawnCountdownEvent")

-- Shield events
RemoteEvents.ShieldActivateEvent = getOrCreate("ShieldActivateEvent")
RemoteEvents.ShieldStatusEvent = getOrCreate("ShieldStatusEvent")

-- Lobby events
RemoteEvents.PlayRequestEvent = getOrCreate("PlayRequestEvent")
RemoteEvents.TeleportToArenaEvent = getOrCreate("TeleportToArenaEvent")
RemoteEvents.PortalTeleportRequestEvent = getOrCreate("PortalTeleportRequestEvent")

-- Favorite animals events
RemoteEvents.SetFavoriteAnimalEvent = getOrCreate("SetFavoriteAnimalEvent")         -- Client -> Server: request to set/unset favorite
RemoteEvents.FavoriteAnimalsUpdatedEvent = getOrCreate("FavoriteAnimalsUpdatedEvent") -- Server -> Client: sync current favorites

-- Leaderboard events
RemoteEvents.LeaderboardUpdatedEvent = getOrCreate("LeaderboardUpdatedEvent")       -- Server -> Client: global leaderboard data update
RemoteEvents.ServerLeaderboardUpdatedEvent = getOrCreate("ServerLeaderboardUpdatedEvent") -- Server -> Client: server-specific leaderboard
RemoteEvents.RequestLeaderboardEvent = getOrCreate("RequestLeaderboardEvent")       -- Client -> Server: request leaderboard refresh

-- Matchmaking events (1v1 and 2v2)
RemoteEvents.MatchmakingZoneEnteredEvent = getOrCreate("MatchmakingZoneEnteredEvent")       -- Server -> Client: player entered zone
RemoteEvents.MatchmakingZoneExitedEvent = getOrCreate("MatchmakingZoneExitedEvent")         -- Server -> Client: player exited zone
RemoteEvents.MatchmakingZoneFullEvent = getOrCreate("MatchmakingZoneFullEvent")             -- Server -> Client: zone is full (2v2)
RemoteEvents.MatchmakingQueueJoinedEvent = getOrCreate("MatchmakingQueueJoinedEvent")       -- Server -> Client: player added to queue
RemoteEvents.MatchmakingTeamFormedEvent = getOrCreate("MatchmakingTeamFormedEvent")         -- Server -> Client: 2v2 team formed
RemoteEvents.MatchmakingMatchFoundEvent = getOrCreate("MatchmakingMatchFoundEvent")         -- Server -> Client: match found, teleporting
RemoteEvents.MatchmakingCountdownCompleteEvent = getOrCreate("MatchmakingCountdownCompleteEvent") -- Client -> Server: countdown finished
RemoteEvents.MatchmakingCancelQueueEvent = getOrCreate("MatchmakingCancelQueueEvent")       -- Client -> Server: cancel queue request
RemoteEvents.MatchmakingQueueCancelledEvent = getOrCreate("MatchmakingQueueCancelledEvent") -- Server -> Client: queue cancelled confirmation

-- Lucky Block events
RemoteEvents.LuckyBlockSpawnedEvent = getOrCreate("LuckyBlockSpawnedEvent")                 -- Server -> Client: lucky block spawned
RemoteEvents.LuckyBlockDespawnedEvent = getOrCreate("LuckyBlockDespawnedEvent")             -- Server -> Client: lucky block removed
RemoteEvents.LuckyBlockPurchaseRequestEvent = getOrCreate("LuckyBlockPurchaseRequestEvent") -- Client -> Server: request to buy lucky block
RemoteEvents.LuckyBlockRevealRequestEvent = getOrCreate("LuckyBlockRevealRequestEvent")     -- Client -> Server: request to reveal block
RemoteEvents.LuckyBlockRevealStartEvent = getOrCreate("LuckyBlockRevealStartEvent")         -- Server -> Client: reveal animation start
RemoteEvents.LuckyBlockRevealCompleteEvent = getOrCreate("LuckyBlockRevealCompleteEvent")   -- Server -> Client: reveal complete with reward
RemoteEvents.LuckyBlockPickupEvent = getOrCreate("LuckyBlockPickupEvent")                   -- Server -> Client: arena block picked up

return RemoteEvents
