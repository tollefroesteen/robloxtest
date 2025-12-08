--!strict
-- DebugCommandsInit.server.luau (Arena)
-- Initializes shared debug commands with arena-specific extensions

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DebugCommands = require(Shared:WaitForChild("util"):WaitForChild("DebugCommands"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local ServerEvents = require(ServerScriptService.Server.ServerEvents)

local CONTEXT = "DebugCommands:Arena"

-- Lazy load arena-specific modules
local AnimalLibraryModule: any = nil
local function getAnimalLibrary()
	if not AnimalLibraryModule then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Animal.AnimalLibraryModule)
		end)
		if success then
			AnimalLibraryModule = service
		end
	end
	return AnimalLibraryModule
end

local AnimalBuilder: any = nil
local function getAnimalBuilder()
	if not AnimalBuilder then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Animal.AnimalBuilder)
		end)
		if success then
			AnimalBuilder = service
		end
	end
	return AnimalBuilder
end

local ShieldService: any = nil
local function getShieldService()
	if not ShieldService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Player.ShieldService)
		end)
		if success then
			ShieldService = service
		end
	end
	return ShieldService
end

local GameEndService: any = nil
local function getGameEndService()
	if not GameEndService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Game.GameEndService)
		end)
		if success then
			GameEndService = service
		end
	end
	return GameEndService
end

local AchievementsService: any = nil
local function getAchievementsService()
	if not AchievementsService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Player.AchievementsService)
		end)
		if success then
			AchievementsService = service
		end
	end
	return AchievementsService
end

local TeamService: any = nil
local function getTeamService()
	if not TeamService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Game.TeamService)
		end)
		if success then
			TeamService = service
		end
	end
	return TeamService
end

local InventoryService: any = nil
local function getInventoryService()
	if not InventoryService then
		local success, service = pcall(function()
			return require(Shared:WaitForChild("services"):WaitForChild("InventoryService"))
		end)
		if success then
			InventoryService = service
		end
	end
	return InventoryService
end

local LuckyBlockSpawner: any = nil
local function getLuckyBlockSpawner()
	if not LuckyBlockSpawner then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Game.LuckyBlockSpawner)
		end)
		if success then
			LuckyBlockSpawner = service
		end
	end
	return LuckyBlockSpawner
end

-- Helper function to spawn an animal in front of player
local function spawnAnimalInFront(animalDef: any, player: Player, offset: number?, readyDelay: number?): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		Log.Warn(CONTEXT, "Player has no HumanoidRootPart")
		return false
	end
	
	local builder = getAnimalBuilder()
	if not builder then
		Log.Warn(CONTEXT, "AnimalBuilder not available")
		return false
	end
	
	-- Ensure Flock folder exists
	local flockFolder = Workspace:FindFirstChild("Flock")
	if not flockFolder then
		flockFolder = Instance.new("Folder")
		flockFolder.Name = "Flock"
		flockFolder.Parent = Workspace
	end
	
	-- Calculate spawn position in front of player
	local spawnOffset = offset or 10
	local spawnPos = root.Position + root.CFrame.LookVector * spawnOffset
	local targetPos = Vector3.new(spawnPos.X, spawnPos.Y + 2, spawnPos.Z)
	
	-- Build the animal
	local templateID = animalDef.Template or "DEFAULT"
	local clone = builder.BuildAnimal(templateID, animalDef.Color, targetPos)
	
	-- Set attributes
	clone:SetAttribute("TemplateID", templateID)
	clone:SetAttribute("PointValue", animalDef.PointValue)
	clone:SetAttribute("CurrentPointValue", animalDef.PointValue)
	clone:SetAttribute("MaxSpeed", animalDef.MaxSpeed)
	clone:SetAttribute("Hungriness", animalDef.Hungriness)
	clone:SetAttribute("FearFactor", animalDef.FearFactor)
	clone:SetAttribute("ObservationRadius", animalDef.ObservationRadius)
	clone:SetAttribute("ID", animalDef.ID)
	clone:SetAttribute("Team", "None")
	clone:SetAttribute("InCage", false)
	clone:SetAttribute("MovementState", "Idle")
	
	clone.Parent = flockFolder
	clone:SetNetworkOwner(nil)
	
	-- Mark as ready for flocking after delay
	local delay = readyDelay or 0.5
	task.delay(delay, function()
		if clone and clone.Parent then
			clone:SetAttribute("ReadyForFlocking", true)
		end
	end)
	
	-- Fire spawn events
	RemoteEvents.AnimalSpawnedEvent:FireAllClients(clone)
	ServerEvents.FlockSpawnedEvent:Fire(clone)
	
	return true
end

-- Grant item to all players
local function grantItemToAll(itemID: string, amount: number, grantedBy: Player)
	local invService = getInventoryService()
	if not invService then
		Log.Warn(CONTEXT, "InventoryService not available")
		return
	end
	
	local count = 0
	for _, player in Players:GetPlayers() do
		local success, msg = invService.AddItem(player, itemID, amount)
		if success then
			count += 1
		end
	end
	
	Log.Info(CONTEXT, string.format("%s granted %dx %s to %d players", grantedBy.Name, amount, itemID, count))
end

-- Arena-specific command handler
local function handleArenaCommand(player: Player, message: string, lowerMessage: string)
	-- /debughelparena - show arena-specific commands
	if lowerMessage == "/debughelparena" then
		Log.Info(CONTEXT, "=== Arena Debug Commands ===")
		Log.Info(CONTEXT, "Player: /shield, /grantshield <amt>")
		Log.Info(CONTEXT, "Game: /endgame, /resetachievements, /resetxp, /resetall")
		Log.Info(CONTEXT, "Achievements: /grantachievement <id>, /listachievements, /myachievements")
		Log.Info(CONTEXT, "Achievements: /setachievementprogress <id> <val>, /grantallbonusachievements, /setlevel <lvl>")
		Log.Info(CONTEXT, "Scores: /setredscore <n>, /setbluescore <n>, /setscore <red> <blue>, /resetscores")
		Log.Info(CONTEXT, "Teams: /switchteam [red|blue], /teamstatus, /setgameactive <true|false>, /simulateforfeit <red|blue>")
		Log.Info(CONTEXT, "Animals: /spawnanimal <id> [delay], /spawnrandom [count] [delay], /spawnall [delay], /listanimals")
		Log.Info(CONTEXT, "Lucky Blocks: /spawnluckyblock [rarity], /clearluckyblocks, /startluckyloop, /stopluckyloop")
		Log.Info(CONTEXT, "Other: /spawnfood [attract], /spawngift")
		return
	end
	
	-- /spawnluckyblock [rarity] - spawn a lucky block in front of the player
	local spawnLuckyMatch = lowerMessage:match("^/spawnluckyblock%s*(%w*)$")
	if lowerMessage == "/spawnluckyblock" or spawnLuckyMatch then
		local spawner = getLuckyBlockSpawner()
		if spawner and spawner.SpawnLuckyBlockForPlayer then
			local rarity = if spawnLuckyMatch and #spawnLuckyMatch > 0 then spawnLuckyMatch else nil
			local blockID = spawner.SpawnLuckyBlockForPlayer(player, rarity)
			if blockID then
				Log.Info(CONTEXT, string.format("%s spawned lucky block: %s", player.Name, blockID))
			else
				Log.Warn(CONTEXT, "Failed to spawn lucky block")
			end
		else
			Log.Warn(CONTEXT, "LuckyBlockSpawner not available")
		end
		return
	end
	
	-- /clearluckyblocks - clear all active lucky blocks
	if lowerMessage == "/clearluckyblocks" then
		local spawner = getLuckyBlockSpawner()
		if spawner then
			local arenaFolder = Workspace:FindFirstChild("Arena") or Workspace:FindFirstChild("Flock") or Workspace
			spawner.ClearAllBlocks(arenaFolder)
			Log.Info(CONTEXT, string.format("%s cleared all lucky blocks", player.Name))
		end
		return
	end
	
	-- /startluckyloop - start automatic lucky block spawning
	if lowerMessage == "/startluckyloop" then
		local spawner = getLuckyBlockSpawner()
		if spawner then
			local arenaFolder = Workspace:FindFirstChild("Arena") or Workspace:FindFirstChild("Flock") or Workspace
			spawner.StartSpawnLoop(arenaFolder)
			Log.Info(CONTEXT, string.format("%s started lucky block spawn loop", player.Name))
		end
		return
	end
	
	-- /stopluckyloop - stop automatic lucky block spawning
	if lowerMessage == "/stopluckyloop" then
		local spawner = getLuckyBlockSpawner()
		if spawner then
			spawner.StopSpawnLoop()
			Log.Info(CONTEXT, string.format("%s stopped lucky block spawn loop", player.Name))
		end
		return
	end
	
	-- /shield - activate shield instantly
	if lowerMessage == "/shield" then
		local shieldSvc = getShieldService()
		if shieldSvc then
			shieldSvc.ActivateShield(player, 10)
			Log.Info(CONTEXT, string.format("%s activated debug shield", player.Name))
		end
		return
	end
	
	-- /grantshield <amount>
	local shieldMatch = lowerMessage:match("^/grantshield%s+(%d+)$")
	if shieldMatch then
		local amount = tonumber(shieldMatch)
		if amount and amount > 0 then
			grantItemToAll("TOOL_SHIELD", amount, player)
		end
		return
	end
	
	-- /endgame - force end the game
	if lowerMessage == "/endgame" then
		Log.Info(CONTEXT, string.format("%s triggered /endgame command", player.Name))
		ServerEvents.ForceEndGameEvent:Fire()
		return
	end
	
	-- /spawnanimal <id> [delay]
	local spawnAnimalMatch = lowerMessage:match("^/spawnanimal%s+([%w_]+)%s*(%d*%.?%d*)$")
	if spawnAnimalMatch then
		local animalID, delayStr = lowerMessage:match("^/spawnanimal%s+([%w_]+)%s*(%d*%.?%d*)$")
		animalID = animalID:upper()
		local readyDelay = tonumber(delayStr) or 0.5
		local library = getAnimalLibrary()
		if library then
			local animalDef = library.GetByID(animalID)
			if animalDef then
				if spawnAnimalInFront(animalDef, player, nil, readyDelay) then
					Log.Info(CONTEXT, string.format("%s spawned animal: %s (%s)", player.Name, animalID, animalDef.Name))
				end
			else
				Log.Warn(CONTEXT, string.format("Animal not found: %s. Use /listanimals to see valid IDs", animalID))
			end
		end
		return
	end
	
	-- /spawnrandom [count] [delay]
	local spawnRandomMatch = lowerMessage:match("^/spawnrandom%s*(%d*)%s*(%d*%.?%d*)$")
	if lowerMessage == "/spawnrandom" or spawnRandomMatch then
		local countStr, delayStr = lowerMessage:match("^/spawnrandom%s*(%d*)%s*(%d*%.?%d*)$")
		local count = tonumber(countStr) or 1
		count = math.clamp(count, 1, 20)
		local readyDelay = tonumber(delayStr) or 0.5
		
		local library = getAnimalLibrary()
		if library then
			local spawned = 0
			for i = 1, count do
				local animalDef = library.GetRandomType()
				local offset = 10 + (i - 1) * 3
				if spawnAnimalInFront(animalDef, player, offset, readyDelay) then
					spawned += 1
				end
				if i < count then
					task.wait(0.1)
				end
			end
			Log.Info(CONTEXT, string.format("%s spawned %d random animals", player.Name, spawned))
		end
		return
	end
	
	-- /listanimals
	if lowerMessage == "/listanimals" then
		local library = getAnimalLibrary()
		if library then
			Log.Info(CONTEXT, "=== Available Animals ===")
			for _, animalDef in library.List do
				Log.Info(CONTEXT, string.format("  %s: %s (Template: %s, Points: %d)", 
					animalDef.ID, animalDef.Name, animalDef.Template or "DEFAULT", animalDef.PointValue))
			end
		end
		return
	end
	
	-- /resetachievements
	if lowerMessage == "/resetachievements" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			for _, p in Players:GetPlayers() do
				achievementsSvc.ResetAchievements(p)
			end
			Log.Info(CONTEXT, string.format("%s reset achievements for all players", player.Name))
		end
		return
	end
	
	-- /resetxp
	if lowerMessage == "/resetxp" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			for _, p in Players:GetPlayers() do
				achievementsSvc.ResetXP(p)
			end
			Log.Info(CONTEXT, string.format("%s reset XP for all players", player.Name))
		end
		return
	end
	
	-- /resetall
	if lowerMessage == "/resetall" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			for _, p in Players:GetPlayers() do
				achievementsSvc.ResetAllStats(p)
			end
			Log.Info(CONTEXT, string.format("%s reset all stats for all players", player.Name))
		end
		return
	end
	
	-- /setredscore <score>
	local redScoreMatch = lowerMessage:match("^/setredscore%s+(%d+)$")
	if redScoreMatch then
		local score = tonumber(redScoreMatch)
		if score then
			local teamSvc = getTeamService()
			if teamSvc then
				local redTeam = teamSvc.GetTeamByName("Red Team")
				if redTeam then
					teamSvc.SetTeamScore(redTeam, score)
					Log.Info(CONTEXT, string.format("%s set Red Team score to %d", player.Name, score))
				end
			end
		end
		return
	end
	
	-- /setbluescore <score>
	local blueScoreMatch = lowerMessage:match("^/setbluescore%s+(%d+)$")
	if blueScoreMatch then
		local score = tonumber(blueScoreMatch)
		if score then
			local teamSvc = getTeamService()
			if teamSvc then
				local blueTeam = teamSvc.GetTeamByName("Blue Team")
				if blueTeam then
					teamSvc.SetTeamScore(blueTeam, score)
					Log.Info(CONTEXT, string.format("%s set Blue Team score to %d", player.Name, score))
				end
			end
		end
		return
	end
	
	-- /resetscores
	if lowerMessage == "/resetscores" then
		local teamSvc = getTeamService()
		if teamSvc then
			teamSvc.ResetTeamScores()
			Log.Info(CONTEXT, string.format("%s reset team scores", player.Name))
		end
		return
	end
	
	-- /teamstatus
	if lowerMessage == "/teamstatus" then
		local teamSvc = getTeamService()
		if teamSvc then
			local redTeam = teamSvc.GetTeamByName("Red Team")
			local blueTeam = teamSvc.GetTeamByName("Blue Team")
			if redTeam and blueTeam then
				local redCount = #redTeam:GetPlayers()
				local blueCount = #blueTeam:GetPlayers()
				local redScore = teamSvc.GetTeamScore(redTeam)
				local blueScore = teamSvc.GetTeamScore(blueTeam)
				local isActive = teamSvc.IsGameActive()
				
				Log.Info(CONTEXT, string.format("Team Status - Game Active: %s", tostring(isActive)))
				Log.Info(CONTEXT, string.format("Red Team: %d players, Score: %d", redCount, redScore))
				Log.Info(CONTEXT, string.format("Blue Team: %d players, Score: %d", blueCount, blueScore))
			end
		end
		return
	end
	
	-- /switchteam [red|blue]
	local switchMatch = lowerMessage:match("^/switchteam%s*(%w*)$")
	if lowerMessage == "/switchteam" or switchMatch then
		local teamSvc = getTeamService()
		if teamSvc then
			local redTeam = teamSvc.GetTeamByName("Red Team")
			local blueTeam = teamSvc.GetTeamByName("Blue Team")
			if redTeam and blueTeam then
				local targetTeam: Team? = nil
				if switchMatch == "red" then
					targetTeam = redTeam
				elseif switchMatch == "blue" then
					targetTeam = blueTeam
				else
					targetTeam = if player.Team == redTeam then blueTeam else redTeam
				end
				if targetTeam then
					player.Team = targetTeam
					Log.Info(CONTEXT, string.format("%s switched to %s", player.Name, targetTeam.Name))
				end
			end
		end
		return
	end
end

-- Register arena services and initialize
DebugCommands.RegisterServices({
	AnimalBuilder = getAnimalBuilder(),
	handleCommand = handleArenaCommand,
})

DebugCommands.Init()

Log.Info(CONTEXT, "Arena debug commands initialized")
