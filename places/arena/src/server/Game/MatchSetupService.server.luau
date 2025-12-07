--!strict
-- MatchSetupService.server.luau
-- Handles incoming match teleport data and sets up the arena match
-- Reads teleportData to determine match mode and team assignments

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local PlacesConfig = require(Shared:WaitForChild("PlacesConfig"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local CONTEXT = "MatchSetupService"

-- Match state
local matchMode: string? = nil -- "1v1" or "2v2"
local teamA: { number } = {}
local teamB: { number } = {}
local matchId: string? = nil
local isMatchSetup: boolean = false

-- Team spawn positions (adjust based on your arena layout)
local TEAM_A_SPAWN = Vector3.new(-50, 5, 0)
local TEAM_B_SPAWN = Vector3.new(50, 5, 0)

--[[
	Get the teleport data for a player
]]
local function getTeleportData(player: Player): { [string]: any }?
	local success, data = pcall(function()
		return player:GetJoinData().TeleportData
	end)
	
	if success and data then
		return data :: { [string]: any }
	end
	
	return nil
end

--[[
	Determine which team a player belongs to
]]
local function getPlayerTeam(playerId: number): string?
	if table.find(teamA, playerId) then
		return "A"
	elseif table.find(teamB, playerId) then
		return "B"
	end
	return nil
end

--[[
	Spawn player at their team's position
]]
local function spawnPlayerAtTeamPosition(player: Player)
	local team = getPlayerTeam(player.UserId)
	if not team then
		Log.Warn(CONTEXT, string.format("Player %s has no team assignment", player.Name))
		return
	end
	
	local spawnPos = team == "A" and TEAM_A_SPAWN or TEAM_B_SPAWN
	
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	
	if humanoidRootPart then
		humanoidRootPart.CFrame = CFrame.new(spawnPos)
		Log.Debug(CONTEXT, string.format("Spawned %s at Team %s position", player.Name, team))
	end
	
	-- Notify client of team assignment
	RemoteEvents.TeamAssignedEvent:FireClient(player, team)
end

--[[
	Initialize match from teleport data
]]
local function initializeMatch(teleportData: { [string]: any })
	matchMode = teleportData.mode
	teamA = teleportData.teamA or {}
	teamB = teleportData.teamB or {}
	matchId = teleportData.matchId
	isMatchSetup = true
	
	Log.Info(CONTEXT, string.format(
		"Match initialized - Mode: %s, MatchId: %s",
		matchMode or "unknown",
		matchId or "unknown"
	))
	Log.Info(CONTEXT, string.format("Team A: %s", table.concat(teamA, ", ")))
	Log.Info(CONTEXT, string.format("Team B: %s", table.concat(teamB, ", ")))
end

--[[
	Handle player joining the arena
]]
local function onPlayerAdded(player: Player)
	Log.Info(CONTEXT, string.format("Player %s joined arena", player.Name))
	
	-- Try to get teleport data
	local teleportData = getTeleportData(player)
	
	if teleportData and not isMatchSetup then
		-- First player with teleport data initializes the match
		initializeMatch(teleportData)
	end
	
	-- Verify player is part of this match
	local team = getPlayerTeam(player.UserId)
	if not team then
		Log.Warn(CONTEXT, string.format("Player %s is not part of this match!", player.Name))
		-- Optionally teleport them back to lobby
		task.delay(3, function()
			if player.Parent then
				TeleportService:Teleport(PlacesConfig.LOBBY_PLACE_ID, player)
			end
		end)
		return
	end
	
	-- Spawn at correct position
	player.CharacterAdded:Connect(function()
		spawnPlayerAtTeamPosition(player)
	end)
	
	-- Spawn immediately if character exists
	if player.Character then
		spawnPlayerAtTeamPosition(player)
	end
end

--[[
	Teleport all players back to lobby
]]
local function teleportToLobby()
	Log.Info(CONTEXT, "Teleporting all players back to lobby...")
	
	for _, player in Players:GetPlayers() do
		pcall(function()
			TeleportService:Teleport(PlacesConfig.LOBBY_PLACE_ID, player)
		end)
	end
end

--[[
	Get current match info
]]
local function getMatchInfo(): { mode: string?, teamA: { number }, teamB: { number }, matchId: string? }
	return {
		mode = matchMode,
		teamA = teamA,
		teamB = teamB,
		matchId = matchId,
	}
end

-- Connect player added handler
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in game (in case script runs late)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- Export match info for other scripts
local MatchSetupService = {}
MatchSetupService.GetMatchInfo = getMatchInfo
MatchSetupService.GetPlayerTeam = getPlayerTeam
MatchSetupService.TeleportToLobby = teleportToLobby
MatchSetupService.IsMatchSetup = function(): boolean return isMatchSetup end

-- Store in ReplicatedStorage for access by other server scripts
local matchSetupValue = Instance.new("BindableFunction")
matchSetupValue.Name = "GetMatchInfo"
matchSetupValue.OnInvoke = getMatchInfo
matchSetupValue.Parent = ReplicatedStorage

Log.Info(CONTEXT, "Match setup service initialized")

return MatchSetupService
