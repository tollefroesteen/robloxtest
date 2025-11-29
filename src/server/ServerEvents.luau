-- src/server/ServerEvents.luau
local ServerEvents = {}

local FlockSpawnedEvent = Instance.new("BindableEvent")
FlockSpawnedEvent.Name = "FlockSpawnedEvent"
FlockSpawnedEvent.Parent = nil -- Server-only, so not parented to ReplicatedStorage
ServerEvents.FlockSpawnedEvent = FlockSpawnedEvent

local StartGameEvent = Instance.new("BindableEvent")
StartGameEvent.Name = "StartGameEvent"
StartGameEvent.Parent = nil -- Server-only
ServerEvents.StartGameEvent = StartGameEvent

local TimerEndedEvent = Instance.new("BindableEvent")
TimerEndedEvent.Name = "TimerEndedEvent"
TimerEndedEvent.Parent = nil -- Server-only
ServerEvents.TimerEndedEvent = TimerEndedEvent

return ServerEvents