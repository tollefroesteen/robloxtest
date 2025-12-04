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

local GameEndProcessedEvent = Instance.new("BindableEvent")
GameEndProcessedEvent.Name = "GameEndProcessedEvent"
GameEndProcessedEvent.Parent = nil -- Server-only
ServerEvents.GameEndProcessedEvent = GameEndProcessedEvent

local ForceEndGameEvent = Instance.new("BindableEvent")
ForceEndGameEvent.Name = "ForceEndGameEvent"
ForceEndGameEvent.Parent = nil -- Server-only, used to force end the game (e.g., /endgame command)
ServerEvents.ForceEndGameEvent = ForceEndGameEvent

local PlayerScareEvent = Instance.new("BindableEvent")
PlayerScareEvent.Name = "PlayerScareEvent"
PlayerScareEvent.Parent = nil -- Server-only, fired when player uses scare action
ServerEvents.PlayerScareEvent = PlayerScareEvent

local TeamAbandonedEvent = Instance.new("BindableEvent")
TeamAbandonedEvent.Name = "TeamAbandonedEvent"
TeamAbandonedEvent.Parent = nil -- Server-only, fired when all players leave a team during game
ServerEvents.TeamAbandonedEvent = TeamAbandonedEvent

return ServerEvents