--!strict
-- GameEndServiceInit.server.luau
-- Initializes GameEndService and connects event listeners

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "GameEndServiceInit"

-- Load services
local GameEndService = require(ServerScriptService.Server.Game.GameEndService)
local TeamService = require(ServerScriptService.Server.Game.TeamService)
local TrapController = require(ServerScriptService.Server.Game.TrapController)

-- Lazy load player services (they may not be ready yet)
local AchievementsService: any = nil
local InventoryService: any = nil

local function loadPlayerServices()
	local success1, result1 = pcall(function()
		return require(ServerScriptService.Server.Player.AchievementsService)
	end)
	if success1 then
		AchievementsService = result1
	end
	
	local success2, result2 = pcall(function()
		return require(ServerScriptService.Server.Player.InventoryService)
	end)
	if success2 then
		InventoryService = result2
	end
	
	-- Set services on GameEndService
	GameEndService.SetServices(TeamService, TrapController, AchievementsService, InventoryService)
	
	Log.Info(CONTEXT, string.format("Services loaded - Achievements: %s, Inventory: %s",
		tostring(AchievementsService ~= nil), tostring(InventoryService ~= nil)))
end

-- Wait a moment for other services to initialize, then load
task.spawn(function()
	task.wait(1)
	loadPlayerServices()
end)

-- Listen for timer ended (game over)
ServerEvents.TimerEndedEvent.Event:Connect(function()
	Log.Info(CONTEXT, "Timer ended - processing game end")
	
	-- Ensure services are loaded
	if not AchievementsService or not InventoryService then
		loadPlayerServices()
	end
	
	-- Process game end
	task.spawn(function()
		GameEndService.ProcessGameEnd()
	end)
end)

-- Listen for game start to reset state
ServerEvents.StartGameEvent.Event:Connect(function()
	Log.Info(CONTEXT, "Game started - resetting game end state")
	GameEndService.ResetGameState()
end)

-- Listen for manual game reset
RemoteEvents.ResetGameEvent.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("Game reset by %s", player.Name))
	GameEndService.ResetGameState()
end)

Log.Info(CONTEXT, "GameEndService initialized")
