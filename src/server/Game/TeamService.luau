--!strict
-- TeamService.luau (ModuleScript)
-- Manages team creation, player assignment, and team scores

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "TeamService"

local TeamService = {}

-- Team configuration
local TEAM_CONFIG = {
	{
		Name = "Red Team",
		Color = BrickColor.new("Bright red"),
	},
	{
		Name = "Blue Team", 
		Color = BrickColor.new("Bright blue"),
	},
}

-- Team references
local redTeam: Team? = nil
local blueTeam: Team? = nil

-- Team scores
local teamScores: { [Team]: number } = {}

-- Creates the teams programmatically
function TeamService.CreateTeams(): nil
	Log.Info(CONTEXT, "Creating teams...")
	
	-- Clear existing teams
	for _, team in Teams:GetTeams() do
		team:Destroy()
	end
	
	-- Create Red Team
	local red = Instance.new("Team")
	red.Name = TEAM_CONFIG[1].Name
	red.TeamColor = TEAM_CONFIG[1].Color
	red.AutoAssignable = false -- We handle assignment ourselves
	red.Parent = Teams
	redTeam = red
	teamScores[red] = 0
	
	-- Create Blue Team
	local blue = Instance.new("Team")
	blue.Name = TEAM_CONFIG[2].Name
	blue.TeamColor = TEAM_CONFIG[2].Color
	blue.AutoAssignable = false
	blue.Parent = Teams
	blueTeam = blue
	teamScores[blue] = 0
	
	Log.Info(CONTEXT, "Teams created: Red Team and Blue Team")
end

-- Gets the team with fewer players (for balanced assignment)
local function getTeamWithFewerPlayers(): Team?
	if not redTeam or not blueTeam then return nil end
	
	local redCount = #redTeam:GetPlayers()
	local blueCount = #blueTeam:GetPlayers()
	
	if redCount < blueCount then
		return redTeam
	elseif blueCount < redCount then
		return blueTeam
	else
		-- Equal count, pick randomly
		return if math.random() > 0.5 then redTeam else blueTeam
	end
end

-- Assigns a player to a team (balanced assignment)
function TeamService.AssignPlayerToTeam(player: Player): nil
	local team = getTeamWithFewerPlayers()
	if not team then
		Log.Warn(CONTEXT, string.format("Cannot assign %s - teams not created", player.Name))
		return
	end
	
	player.Team = team
	Log.Info(CONTEXT, string.format("Assigned %s to %s", player.Name, team.Name))
	
	-- Notify clients of team assignment
	RemoteEvents.TeamAssignedEvent:FireAllClients(player, team.Name, team.TeamColor.Color)
end

-- Assigns all current players to teams (called at game start)
function TeamService.AssignAllPlayersToTeams(): nil
	Log.Info(CONTEXT, "Assigning all players to teams...")
	
	-- Reset team assignments first
	for _, player in Players:GetPlayers() do
		player.Team = nil
	end
	
	-- Shuffle players for random assignment
	local playerList = Players:GetPlayers()
	for i = #playerList, 2, -1 do
		local j = math.random(1, i)
		playerList[i], playerList[j] = playerList[j], playerList[i]
	end
	
	-- Assign each player
	for _, player in playerList do
		TeamService.AssignPlayerToTeam(player)
	end
	
	-- Broadcast updated scores
	TeamService.BroadcastTeamScores()
end

-- Broadcasts team scores to all clients
function TeamService.BroadcastTeamScores(): nil
	if not redTeam or not blueTeam then return end
	
	RemoteEvents.TeamScoreUpdateEvent:FireAllClients({
		[TEAM_CONFIG[1].Name] = teamScores[redTeam] or 0,
		[TEAM_CONFIG[2].Name] = teamScores[blueTeam] or 0,
	})
end

-- Public API for adding score to a team
function TeamService.AddTeamScore(team: Team, points: number): nil
	if not teamScores[team] then
		teamScores[team] = 0
	end
	teamScores[team] += points
	Log.Info(CONTEXT, string.format("%s score: %d (+%d)", team.Name, teamScores[team], points))
	TeamService.BroadcastTeamScores()
end

-- Add score to a player's team
function TeamService.AddPlayerTeamScore(player: Player, points: number): nil
	local team = player.Team
	if not team then
		Log.Warn(CONTEXT, string.format("Cannot add score - %s has no team", player.Name))
		return
	end
	TeamService.AddTeamScore(team, points)
end

-- Reset team scores
function TeamService.ResetTeamScores(): nil
	if redTeam then teamScores[redTeam] = 0 end
	if blueTeam then teamScores[blueTeam] = 0 end
	Log.Info(CONTEXT, "Team scores reset")
	TeamService.BroadcastTeamScores()
end

-- Get a team by name
function TeamService.GetTeamByName(name: string): Team?
	if redTeam and redTeam.Name == name then return redTeam end
	if blueTeam and blueTeam.Name == name then return blueTeam end
	return nil
end

return TeamService
