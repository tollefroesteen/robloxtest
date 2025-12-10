--!strict
-- PlayerUpgradesService.luau
-- Manages permanent player upgrades (purchased with Robux)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerUpgradesService = {}

-- Types
export type PlayerUpgrades = {
	HeatSeekingAmmo: boolean,
	-- Add more upgrades here in the future
}

-- Storage
local playerUpgrades: { [Player]: PlayerUpgrades } = {}

-- Lazy load RemoteEvents to avoid circular dependencies
local RemoteEvents: any = nil
local function getRemoteEvents()
	if not RemoteEvents then
		local Shared = ReplicatedStorage:WaitForChild("Shared")
		RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
	end
	return RemoteEvents
end

-- Default upgrades for new players
local function getDefaultUpgrades(): PlayerUpgrades
	return {
		HeatSeekingAmmo = false,
	}
end

-- Broadcast upgrades to client
local function broadcastUpgrades(player: Player)
	if not RunService:IsServer() then return end
	
	local upgrades = playerUpgrades[player]
	if upgrades then
		local events = getRemoteEvents()
		if events and events.UpgradesUpdatedEvent then
			print("[PlayerUpgradesService] Broadcasting upgrades to " .. player.Name .. ": HeatSeekingAmmo=" .. tostring(upgrades.HeatSeekingAmmo))
			events.UpgradesUpdatedEvent:FireClient(player, upgrades)
		else
			warn("[PlayerUpgradesService] UpgradesUpdatedEvent not found!")
		end
	end
end

-- Initialize player upgrades
local function initializePlayer(player: Player)
	if playerUpgrades[player] then return end
	
	playerUpgrades[player] = getDefaultUpgrades()
	
	-- TODO: Load upgrades from DataStore
	-- For now, upgrades are session-based only
end

-- Clean up when player leaves
local function cleanupPlayer(player: Player)
	-- TODO: Save upgrades to DataStore
	playerUpgrades[player] = nil
end

-- Check if player has a specific upgrade
function PlayerUpgradesService.HasUpgrade(player: Player, upgradeName: string): boolean
	if not playerUpgrades[player] then
		initializePlayer(player)
	end
	
	local upgrades = playerUpgrades[player]
	if not upgrades then return false end
	
	return upgrades[upgradeName] == true
end

-- Grant an upgrade to a player
function PlayerUpgradesService.GrantUpgrade(player: Player, upgradeName: string): boolean
	if not playerUpgrades[player] then
		initializePlayer(player)
	end
	
	local upgrades = playerUpgrades[player]
	if not upgrades then return false end
	
	-- Check if upgrade exists in the type
	if upgrades[upgradeName] == nil then
		warn("PlayerUpgradesService: Unknown upgrade:", upgradeName)
		return false
	end
	
	upgrades[upgradeName] = true
	-- TODO: Save to DataStore
	
	-- Notify client of upgrade change
	broadcastUpgrades(player)
	
	return true
end

-- Get all upgrades for a player
function PlayerUpgradesService.GetPlayerUpgrades(player: Player): PlayerUpgrades?
	if not playerUpgrades[player] then
		initializePlayer(player)
	end
	
	return playerUpgrades[player]
end

-- Server-side initialization
if RunService:IsServer() then
	Players.PlayerAdded:Connect(initializePlayer)
	Players.PlayerRemoving:Connect(cleanupPlayer)
	
	-- Initialize existing players
	for _, player in Players:GetPlayers() do
		initializePlayer(player)
	end
end

return PlayerUpgradesService
