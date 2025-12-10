--!strict
-- LuckyBlockInit.server.luau
-- Initializes and connects Lucky Block spawning to game lifecycle

local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerEvents = require(script.Parent.ServerEvents)
local LuckyBlockSpawner = require(script.Parent.Game.LuckyBlockSpawner)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "LuckyBlockInit"

-- Get or create the arena folder
local function getArenaFolder(): Folder
	local arena = Workspace:FindFirstChild("Arena")
	if not arena then
		arena = Instance.new("Folder")
		arena.Name = "Arena"
		arena.Parent = Workspace
	end
	return arena :: Folder
end

-- Initialize the Lucky Block system
local function initialize()
	local arenaFolder = getArenaFolder()
	
	-- Start spawning when game starts
	ServerEvents.StartGameEvent.Event:Connect(function()
		Log.Info(CONTEXT, "Game started - activating Lucky Block spawner")
		LuckyBlockSpawner.StartSpawnLoop(arenaFolder)
	end)
	
	-- Stop spawning and clear blocks when game ends
	ServerEvents.TimerEndedEvent.Event:Connect(function()
		Log.Info(CONTEXT, "Game ended - stopping Lucky Block spawner")
		LuckyBlockSpawner.StopSpawnLoop()
		LuckyBlockSpawner.ClearAllBlocks(arenaFolder)
	end)
	
	-- Also stop on force end
	ServerEvents.ForceEndGameEvent.Event:Connect(function()
		Log.Info(CONTEXT, "Game force ended - stopping Lucky Block spawner")
		LuckyBlockSpawner.StopSpawnLoop()
		LuckyBlockSpawner.ClearAllBlocks(arenaFolder)
	end)
	
	Log.Info(CONTEXT, "Lucky Block system initialized")
end

initialize()
