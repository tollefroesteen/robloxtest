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

return RemoteEvents
