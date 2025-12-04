--!strict
-- GameEndService.luau
-- Handles game end logic: freezing, winner determination, achievements, and coin rewards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local GameEndConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config"):WaitForChild("GameEndConfig"))
local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "GameEndService"

local GameEndService = {}

-- Services (set via dependency injection)
local TeamService: any = nil
local TrapController: any = nil
local AchievementsService: any = nil
local InventoryService: any = nil

-- Game state
local isProcessingGameEnd = false
local isGameActive = false  -- Track if game is in progress

-- Track achievements unlocked during the game for each player
local gameAchievements: { [Player]: { string } } = {}

-- Achievement callback to capture unlocks during the game
local function onAchievementUnlocked(player: Player, achievementID: string, _achievementDef: any): nil
	if isGameActive and gameAchievements[player] then
		table.insert(gameAchievements[player], achievementID)
		Log.Info(CONTEXT, string.format("Tracked achievement for %s: %s", player.Name, achievementID))
	end
end

-- Start tracking achievements for a new game
function GameEndService.StartGameTracking(): nil
	Log.Info(CONTEXT, "Starting game achievement tracking")
	isGameActive = true
	gameAchievements = {}
	for _, player in Players:GetPlayers() do
		gameAchievements[player] = {}
	end
	
	-- Notify TeamService that game is active (for abandonment detection)
	if TeamService then
		TeamService.SetGameActive(true)
	end
end

-- Add a player to tracking (for players who join mid-game)
function GameEndService.AddPlayerToTracking(player: Player): nil
	if isGameActive and not gameAchievements[player] then
		gameAchievements[player] = {}
	end
end

-- Set service dependencies (called by init script)
function GameEndService.SetServices(teamSvc: any, trapCtrl: any, achievementsSvc: any, inventorySvc: any): nil
	TeamService = teamSvc
	TrapController = trapCtrl
	AchievementsService = achievementsSvc
	InventoryService = inventorySvc
	
	-- Register callback to capture achievements unlocked during the game
	if AchievementsService and AchievementsService.OnAchievementCompleted then
		AchievementsService.OnAchievementCompleted(onAchievementUnlocked)
	end
end

-- Freeze all players (anchor them, disable controls)
local function freezePlayers(): nil
	Log.Info(CONTEXT, "Freezing all players")
	
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			
			if humanoid then
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
				humanoid.JumpHeight = 0
			end
			
			if rootPart and rootPart:IsA("BasePart") then
				rootPart.Anchored = true
			end
		end
	end
	
	-- Notify clients to disable actions
	RemoteEvents.GameFreezeEvent:FireAllClients(true)
end

-- Unfreeze all players
local function unfreezePlayers(): nil
	Log.Info(CONTEXT, "Unfreezing all players")
	
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			
			if humanoid then
				humanoid.WalkSpeed = 16  -- Default walk speed
				humanoid.JumpPower = 50  -- Default jump power
				humanoid.JumpHeight = 7.2  -- Default jump height
			end
			
			if rootPart and rootPart:IsA("BasePart") then
				rootPart.Anchored = false
			end
		end
	end
	
	-- Notify clients to enable actions
	RemoteEvents.GameFreezeEvent:FireAllClients(false)
end

-- Freeze all animals
local function freezeAnimals(): nil
	Log.Info(CONTEXT, "Freezing all animals")
	
	local Flock = workspace:FindFirstChild("Flock")
	if not Flock then return end
	
	for _, animal in Flock:GetChildren() do
		if animal:IsA("BasePart") then
			animal.Anchored = true
			animal.AssemblyLinearVelocity = Vector3.zero
			animal.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

-- Calculate coin bonus multiplier based on achievements and special animals
function GameEndService.CalculateBonusMultiplier(player: Player): number
	local bonusMultiplier = 1.0
	
	if not AchievementsService then
		return bonusMultiplier
	end
	
	local stats = AchievementsService.GetStats(player)
	if not stats then
		return bonusMultiplier
	end
	
	-- Add achievement-based bonuses (read from AchievementRegistry)
	for achievementID, achievementDef in AchievementRegistry.Achievements do
		if achievementDef.CoinBonus and achievementDef.CoinBonus > 0 then
			if AchievementsService.IsAchievementCompleted(player, achievementID) then
				bonusMultiplier += achievementDef.CoinBonus
				Log.Info(CONTEXT, string.format("%s has achievement bonus %s: +%.0f%%", 
					player.Name, achievementID, achievementDef.CoinBonus * 100))
			end
		end
	end
	
	-- Add special animal bonuses (based on capture index)
	for animalID, bonus in GameEndConfig.Bonuses.SPECIAL_ANIMAL_BONUSES do
		if stats.CapturedAnimalIndex[animalID] then
			bonusMultiplier += bonus
			Log.Info(CONTEXT, string.format("%s has special animal bonus %s: +%.0f%%", 
				player.Name, animalID, bonus * 100))
		end
	end
	
	return bonusMultiplier
end

-- Award coins to a player
local function awardCoins(player: Player, baseAmount: number, isWinner: boolean): number
	if not InventoryService then
		Log.Warn(CONTEXT, "InventoryService not available")
		return 0
	end
	
	-- Calculate final amount with bonuses
	local bonusMultiplier = GameEndService.CalculateBonusMultiplier(player)
	local finalAmount = math.round(baseAmount * bonusMultiplier)
	
	-- Add coins to inventory
	local success, message = InventoryService.AddItem(player, "COIN", finalAmount)
	if success then
		Log.Info(CONTEXT, string.format("Awarded %d coins to %s (base: %d, multiplier: %.2f)", 
			finalAmount, player.Name, baseAmount, bonusMultiplier))
		
		-- Notify client
		RemoteEvents.CoinsAwardedEvent:FireClient(player, finalAmount, bonusMultiplier, isWinner)
	else
		Log.Warn(CONTEXT, string.format("Failed to award coins to %s: %s", player.Name, message))
	end
	
	return finalAmount
end

-- Update player achievements based on newly captured animals
local function updatePlayerAchievements(player: Player, capturedAnimalIDs: { string }): { string }
	if not AchievementsService then
		return {}
	end
	
	local stats = AchievementsService.GetStats(player)
	if not stats then
		return {}
	end
	
	local newDiscoveries: { string } = {}
	
	-- Check each captured animal
	for _, animalID in capturedAnimalIDs do
		-- Check if this is a new discovery for this player
		if not stats.CapturedAnimalIndex[animalID] then
			table.insert(newDiscoveries, animalID)
			-- Note: RecordAnimalCapture was already called during capture,
			-- but we track new discoveries here for end-game notification
		end
	end
	
	return newDiscoveries
end

-- Process game end
function GameEndService.ProcessGameEnd(): nil
	if isProcessingGameEnd then
		Log.Warn(CONTEXT, "Already processing game end")
		return
	end
	
	isProcessingGameEnd = true
	isGameActive = false  -- Stop tracking new achievements
	Log.Info(CONTEXT, "Processing game end...")
	
	-- Notify TeamService that game is no longer active
	if TeamService then
		TeamService.SetGameActive(false)
	end
	
	-- Step 1: Freeze everything
	if TrapController then
		TrapController.SetGameActive(false)
	end
	freezePlayers()
	freezeAnimals()
	
	-- Wait for freeze duration
	task.wait(GameEndConfig.FREEZE_DURATION)
	
	-- Step 2: Determine winner
	if not TeamService then
		Log.Warn(CONTEXT, "TeamService not available")
		isProcessingGameEnd = false
		return
	end
	
	-- Check if this is a forfeit situation (one team abandoned)
	local abandonedTeam = TeamService.GetAbandonedTeam()
	local isForfeit = abandonedTeam ~= nil
	
	local redTeam, blueTeam = TeamService.GetTeams()
	
	if not redTeam or not blueTeam then
		Log.Warn(CONTEXT, "Could not determine winner - teams not found")
		isProcessingGameEnd = false
		return
	end
	
	-- Determine winner: In forfeit, the non-abandoned team wins regardless of score
	local winningTeam, winningScore, isTie
	if isForfeit then
		-- Winner is the team that did NOT abandon
		winningTeam = if abandonedTeam == redTeam then blueTeam else redTeam
		winningScore = TeamService.GetTeamScore(winningTeam)
		isTie = false
	else
		winningTeam, winningScore, isTie = TeamService.DetermineWinner()
	end
	
	if not winningTeam then
		Log.Warn(CONTEXT, "Could not determine winner")
		isProcessingGameEnd = false
		return
	end
	
	local losingTeam = if winningTeam == redTeam then blueTeam else redTeam
	local losingScore = TeamService.GetTeamScore(losingTeam)
	
	if isForfeit then
		Log.Info(CONTEXT, string.format("FORFEIT - Winner: %s (Score: %d), Loser (abandoned): %s (Score: %d)",
			winningTeam.Name, winningScore, losingTeam.Name, losingScore))
	else
		Log.Info(CONTEXT, string.format("Winner: %s (Score: %d), Loser: %s (Score: %d), Tie: %s",
			winningTeam.Name, winningScore, losingTeam.Name, losingScore, tostring(isTie)))
	end
	
	-- Step 3: Get captured animals for each team
	local winningTeamAnimals = {}
	local losingTeamAnimals = {}
	
	if TrapController then
		winningTeamAnimals = TrapController.GetCapturedAnimalsByTeam(winningTeam.Name)
		losingTeamAnimals = TrapController.GetCapturedAnimalsByTeam(losingTeam.Name)
	end
	
	-- Step 4: Process winning team players
	local winnerResults: { { player: Player, coins: number, baseCoins: number, newAnimals: { string } } } = {}
	
	for _, player in winningTeam:GetPlayers() do
		-- Update stats
		if AchievementsService then
			AchievementsService.IncrementStat(player, "TotalWins", 1)
			AchievementsService.IncrementStat(player, "TotalGamesPlayed", 1)
		end
		
		-- Calculate coin reward (100% of team score)
		local baseCoins = math.floor(winningScore * GameEndConfig.WINNER_COIN_MULTIPLIER)
		local awardedCoins = awardCoins(player, baseCoins, true)
		
		-- Track new animal discoveries (for display)
		local newAnimals = updatePlayerAchievements(player, winningTeamAnimals)
		
		-- Notify player of new discoveries
		if #newAnimals > 0 then
			RemoteEvents.NewAnimalDiscoveredEvent:FireClient(player, newAnimals)
		end
		
		table.insert(winnerResults, {
			player = player,
			coins = awardedCoins,
			baseCoins = baseCoins,
			newAnimals = newAnimals,
		})
	end
	
	-- Step 5: Process losing team players
	-- Note: In forfeit situations, losing team players have already left, so this loop may be empty
	-- If they somehow reconnected or there are remaining players, they get NO rewards for forfeit
	local loserResults: { { player: Player, coins: number, baseCoins: number, newAnimals: { string } } } = {}
	
	for _, player in losingTeam:GetPlayers() do
		-- Update stats
		if AchievementsService then
			AchievementsService.IncrementStat(player, "TotalLosses", 1)
			AchievementsService.IncrementStat(player, "TotalGamesPlayed", 1)
		end
		
		local awardedCoins = 0
		local baseCoins = 0
		
		-- Only award coins if NOT a forfeit
		if not isForfeit then
			-- Calculate coin reward (25% of team score, minimum guaranteed)
			baseCoins = math.floor(losingScore * GameEndConfig.LOSER_COIN_MULTIPLIER)
			baseCoins = math.max(baseCoins, GameEndConfig.MINIMUM_LOSER_COINS)
			awardedCoins = awardCoins(player, baseCoins, false)
		else
			Log.Info(CONTEXT, string.format("No coins for %s - team forfeited", player.Name))
		end
		
		-- Track new animal discoveries (for display) - still award discoveries even in forfeit
		local newAnimals = updatePlayerAchievements(player, losingTeamAnimals)
		
		-- Notify player of new discoveries
		if #newAnimals > 0 then
			RemoteEvents.NewAnimalDiscoveredEvent:FireClient(player, newAnimals)
		end
		
		table.insert(loserResults, {
			player = player,
			coins = awardedCoins,
			baseCoins = baseCoins,
			newAnimals = newAnimals,
		})
	end
	
	-- Step 6: Broadcast game results to all clients
	local resultsData = {
		winningTeam = winningTeam.Name,
		winningScore = winningScore,
		losingTeam = losingTeam.Name,
		losingScore = losingScore,
		isTie = isTie,
		isForfeit = isForfeit,
	}
	
	RemoteEvents.GameResultsEvent:FireAllClients(resultsData)
	
	-- Step 7: Send personalized game end sequence to each player
	for _, result in winnerResults do
		local playerAchievements = gameAchievements[result.player] or {}
		Log.Info(CONTEXT, string.format("Sending %d achievements to winner %s", #playerAchievements, result.player.Name))
		local sequenceData = {
			results = resultsData,
			coins = result.coins,
			baseCoins = result.baseCoins,
			multiplier = GameEndService.CalculateBonusMultiplier(result.player),
			achievements = playerAchievements,
			newAnimals = result.newAnimals,
			isWinner = true,
			isForfeit = isForfeit,
		}
		RemoteEvents.GameEndSequenceEvent:FireClient(result.player, sequenceData)
	end
	
	for _, result in loserResults do
		local playerAchievements = gameAchievements[result.player] or {}
		Log.Info(CONTEXT, string.format("Sending %d achievements to loser %s", #playerAchievements, result.player.Name))
		local sequenceData = {
			results = resultsData,
			coins = result.coins,
			baseCoins = result.baseCoins,
			multiplier = GameEndService.CalculateBonusMultiplier(result.player),
			achievements = playerAchievements,
			newAnimals = result.newAnimals,
			isWinner = false,
			isForfeit = isForfeit,
		}
		RemoteEvents.GameEndSequenceEvent:FireClient(result.player, sequenceData)
	end
	
	Log.Info(CONTEXT, "Game end processing complete")
	
	-- Wait for results display duration before allowing reset
	task.wait(GameEndConfig.RESULTS_DISPLAY_DURATION)
	
	isProcessingGameEnd = false
	
	-- Clear achievement tracking for next game
	gameAchievements = {}
end

-- Reset game state (called when a new game starts)
function GameEndService.ResetGameState(): nil
	Log.Info(CONTEXT, "Resetting game state")
	
	isProcessingGameEnd = false
	
	-- Unfreeze players
	unfreezePlayers()
	
	-- Re-enable trap captures
	if TrapController then
		TrapController.SetGameActive(true)
		TrapController.ResetCapturedAnimals()
	end
end

-- Check if game end is being processed
function GameEndService.IsProcessingGameEnd(): boolean
	return isProcessingGameEnd
end

return GameEndService
