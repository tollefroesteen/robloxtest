-- RemoteEvents.luau
-- Creates and stores RemoteEvents for client-server communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

local endGameEvent = Instance.new("RemoteEvent")
endGameEvent.Name = "EndGameEvent"
endGameEvent.Parent = ReplicatedStorage
RemoteEvents.EndGameEvent = endGameEvent

local healthEvent = Instance.new("RemoteEvent")
healthEvent.Name = "HealthEvent"
healthEvent.Parent = ReplicatedStorage
RemoteEvents.HealthEvent = healthEvent

local resetGameEvent = Instance.new("RemoteEvent")
resetGameEvent.Name = "ResetGameEvent"
resetGameEvent.Parent = ReplicatedStorage
RemoteEvents.ResetGameEvent = resetGameEvent

local scoreEvent = Instance.new("RemoteEvent")
scoreEvent.Name = "ScoreEvent"
scoreEvent.Parent = ReplicatedStorage
RemoteEvents.ScoreEvent = scoreEvent

local ShootEvent = Instance.new("RemoteEvent")
ShootEvent.Name = "ShootEvent"
ShootEvent.Parent = ReplicatedStorage
RemoteEvents.ShootEvent = ShootEvent

local sprintEvent = Instance.new("RemoteEvent")
sprintEvent.Name = "SprintEvent"
sprintEvent.Parent = ReplicatedStorage
RemoteEvents.SprintEvent = sprintEvent

local AnimalSpawnedEvent = Instance.new("RemoteEvent")
AnimalSpawnedEvent.Name = "AnimalSpawnedEvent"
AnimalSpawnedEvent.Parent = ReplicatedStorage
RemoteEvents.AnimalSpawnedEvent = AnimalSpawnedEvent

return RemoteEvents
