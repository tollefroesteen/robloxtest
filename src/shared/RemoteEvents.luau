-- RemoteEvents.luau
-- Creates and stores RemoteEvents for client-server communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

-- Create a RemoteEvent for greeting messages
local greetingEvent = Instance.new("RemoteEvent")
greetingEvent.Name = "GreetingEvent"
greetingEvent.Parent = ReplicatedStorage

RemoteEvents.GreetingEvent = greetingEvent

return RemoteEvents
