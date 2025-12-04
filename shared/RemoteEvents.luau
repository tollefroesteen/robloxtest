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

-- Game end events
RemoteEvents.GameFreezeEvent = getOrCreate("GameFreezeEvent")
RemoteEvents.GameResultsEvent = getOrCreate("GameResultsEvent")
RemoteEvents.CoinsAwardedEvent = getOrCreate("CoinsAwardedEvent")
RemoteEvents.NewAnimalDiscoveredEvent = getOrCreate("NewAnimalDiscoveredEvent")
RemoteEvents.GameEndSequenceEvent = getOrCreate("GameEndSequenceEvent")
RemoteEvents.RematchRequestEvent = getOrCreate("RematchRequestEvent")

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

return RemoteEvents
