--!strict
-- GameStateController.luau
-- Client-side controller for managing game state (freeze, results, etc.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "GameStateController"

local GameStateController = {}

-- State
local isGameFrozen = false
local gameResults: any = nil
local initialized = false

-- Callbacks that other controllers can subscribe to
local onFreezeCallbacks: { (frozen: boolean) -> () } = {}
local onResultsCallbacks: { (results: any) -> () } = {}
local onCoinsAwardedCallbacks: { (coins: number, multiplier: number, isWinner: boolean) -> () } = {}
local onNewAnimalCallbacks: { (animalIDs: { string }) -> () } = {}

-- Check if game is frozen (other controllers can use this to disable actions)
function GameStateController.IsGameFrozen(): boolean
	return isGameFrozen
end

-- Get game results (nil if game hasn't ended)
function GameStateController.GetGameResults(): any
	return gameResults
end

-- Subscribe to freeze state changes
function GameStateController.OnFreezeChanged(callback: (frozen: boolean) -> ()): nil
	table.insert(onFreezeCallbacks, callback)
end

-- Subscribe to game results
function GameStateController.OnGameResults(callback: (results: any) -> ()): nil
	table.insert(onResultsCallbacks, callback)
end

-- Subscribe to coins awarded
function GameStateController.OnCoinsAwarded(callback: (coins: number, multiplier: number, isWinner: boolean) -> ()): nil
	table.insert(onCoinsAwardedCallbacks, callback)
end

-- Subscribe to new animal discoveries
function GameStateController.OnNewAnimalDiscovered(callback: (animalIDs: { string }) -> ()): nil
	table.insert(onNewAnimalCallbacks, callback)
end

-- Initialize the controller (only runs once)
function GameStateController.Init(): nil
	if initialized then return end
	initialized = true
	
	Log.Info(CONTEXT, "Initializing GameStateController")
	
	-- Listen for freeze event
	RemoteEvents.GameFreezeEvent.OnClientEvent:Connect(function(frozen: boolean)
		isGameFrozen = frozen
		Log.Info(CONTEXT, string.format("Game frozen: %s", tostring(frozen)))
		
		-- Notify all subscribers
		for _, callback in onFreezeCallbacks do
			task.spawn(callback, frozen)
		end
		
		-- If unfrozen, clear results
		if not frozen then
			gameResults = nil
		end
	end)
	
	-- Listen for game results
	RemoteEvents.GameResultsEvent.OnClientEvent:Connect(function(results: any)
		gameResults = results
		Log.Info(CONTEXT, string.format("Game results received - Winner: %s", results.winningTeam))
		
		-- Notify all subscribers
		for _, callback in onResultsCallbacks do
			task.spawn(callback, results)
		end
	end)
	
	-- Listen for coins awarded
	RemoteEvents.CoinsAwardedEvent.OnClientEvent:Connect(function(coins: number, multiplier: number, isWinner: boolean)
		Log.Info(CONTEXT, string.format("Coins awarded: %d (multiplier: %.2f, winner: %s)", 
			coins, multiplier, tostring(isWinner)))
		
		-- Notify all subscribers
		for _, callback in onCoinsAwardedCallbacks do
			task.spawn(callback, coins, multiplier, isWinner)
		end
	end)
	
	-- Listen for new animal discoveries
	RemoteEvents.NewAnimalDiscoveredEvent.OnClientEvent:Connect(function(animalIDs: { string })
		Log.Info(CONTEXT, string.format("New animals discovered: %d", #animalIDs))
		
		-- Notify all subscribers
		for _, callback in onNewAnimalCallbacks do
			task.spawn(callback, animalIDs)
		end
	end)
	
	Log.Info(CONTEXT, "GameStateController initialized")
end

return GameStateController
