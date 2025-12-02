--!strict
-- GameTimerService.server.luau
-- Manages the game timer: starts when game starts, fires end game event when timer ends
-- Broadcasts timer updates to all clients

print("[GameTimerService] Script starting...")

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Add pcall to catch require errors
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
	warn("[GameTimerService] Failed to find Shared folder in ReplicatedStorage")
	return
end

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local configFolder = Shared:WaitForChild("config", 5)
if not configFolder then
	warn("[GameTimerService] Failed to find config folder")
	return
end

local GameTimerConfig = require(configFolder:WaitForChild("GameTimerConfig"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "GameTimerService"

local StartGameEvent = ServerEvents.StartGameEvent
local TimerEndedEvent = ServerEvents.TimerEndedEvent
local ForceEndGameEvent = ServerEvents.ForceEndGameEvent
local TimerUpdateRemote = RemoteEvents.TimerUpdateEvent
local EndGameRemote = RemoteEvents.EndGameEvent

local timerRunning = false
local timeRemaining = 0

Log.Info(CONTEXT, "GameTimerService initialized, listening for StartGameEvent")

-- Broadcasts timer update to all clients
local function broadcastTimerUpdate(remaining: number): nil
	TimerUpdateRemote:FireAllClients(remaining)
end

-- Runs the timer countdown
local function runTimer(): nil
	if timerRunning then
		Log.Warn(CONTEXT, "Timer already running, ignoring duplicate start")
		return
	end

	timerRunning = true
	timeRemaining = GameTimerConfig.DURATION
	Log.Info(CONTEXT, string.format("Game timer started: %d seconds", timeRemaining))

	-- Send initial timer value
	broadcastTimerUpdate(timeRemaining)

	-- Timer loop
	while timerRunning and timeRemaining > 0 do
		task.wait(GameTimerConfig.UPDATE_INTERVAL)
		timeRemaining = timeRemaining - GameTimerConfig.UPDATE_INTERVAL

		if timeRemaining < 0 then
			timeRemaining = 0
		end

		broadcastTimerUpdate(timeRemaining)
	end

	if timerRunning then
		timerRunning = false
		Log.Info(CONTEXT, "Game timer ended")

		-- Fire server-side TimerEndedEvent (for other server systems)
		TimerEndedEvent:Fire()

		-- Fire EndGameEvent to notify all clients
		EndGameRemote:FireAllClients()
	end
end

-- Listen for game start event
StartGameEvent.Event:Connect(function()
	Log.Info(CONTEXT, "StartGameEvent received, starting timer")
	task.spawn(runTimer)
end)

-- Optional: Reset timer when game resets
RemoteEvents.ResetGameEvent.OnServerEvent:Connect(function(player: Player)
	if timerRunning then
		Log.Info(CONTEXT, string.format("Timer reset by %s", player.Name))
		timerRunning = false
		timeRemaining = 0
		broadcastTimerUpdate(0)
	end
end)

-- Listen for forced game end (e.g., /endgame command)
ForceEndGameEvent.Event:Connect(function()
	if timerRunning then
		Log.Info(CONTEXT, "Force end game received, stopping timer")
		timerRunning = false
		timeRemaining = 0
		broadcastTimerUpdate(0)
		
		-- Fire TimerEndedEvent to notify other systems
		TimerEndedEvent:Fire()
		
		-- Fire EndGameEvent to notify clients
		EndGameRemote:FireAllClients()
	else
		Log.Info(CONTEXT, "Force end game received, but timer not running")
	end
end)
