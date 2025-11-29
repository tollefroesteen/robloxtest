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
RemoteEvents.ScoreEvent = getOrCreate("ScoreEvent")
RemoteEvents.ShootEvent = getOrCreate("ShootEvent")
RemoteEvents.SprintEvent = getOrCreate("SprintEvent")
RemoteEvents.AnimalSpawnedEvent = getOrCreate("AnimalSpawnedEvent")

return RemoteEvents
