--!strict
-- DebugCommands.server.luau
-- Admin/debug commands for testing (chat commands)
-- Usage: Type "/grantcoins 100" in chat to give all players 100 coins

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))
local ServerEvents = require(ServerScriptService.Server.ServerEvents)

-- Lazy load animal modules
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

local CONTEXT = "DebugCommands"

-- List of admin user IDs (add your Roblox user ID here)
-- In Studio, all players are treated as admins for testing
local ADMIN_USER_IDS: { number } = {
    7321086050,
    9332159012,
    6013582887
	-- Add your user ID here, e.g.: 12345678,
}

-- Lazy load services
local InventoryService: any = nil
local function getInventoryService()
	if not InventoryService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Player.InventoryService)
		end)
		if success then
			InventoryService = service
		end
	end
	return InventoryService
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

-- Check if player is admin (or in Studio)
local function isAdmin(player: Player): boolean
	-- Always allow in Studio for testing
	if game:GetService("RunService"):IsStudio() then
		return true
	end
	
	-- Check admin list
	for _, adminId in ADMIN_USER_IDS do
		if player.UserId == adminId then
			return true
		end
	end
	
	return false
end

-- Grant coins to all players
local function grantCoinsToAll(amount: number, grantedBy: Player): nil
	local invService = getInventoryService()
	if not invService then
		Log.Warn(CONTEXT, "InventoryService not available")
		return
	end
	
	local count = 0
	for _, player in Players:GetPlayers() do
		local success, msg = invService.AddItem(player, "COIN", amount)
		if success then
			count += 1
		else
			Log.Warn(CONTEXT, string.format("Failed to grant coins to %s: %s", player.Name, msg))
		end
	end
	
	Log.Info(CONTEXT, string.format("%s granted %d coins to %d players", grantedBy.Name, amount, count))
end

-- Grant specific item to all players
local function grantItemToAll(itemID: string, amount: number, grantedBy: Player): nil
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
		else
			Log.Warn(CONTEXT, string.format("Failed to grant %s to %s: %s", itemID, player.Name, msg))
		end
	end
	
	Log.Info(CONTEXT, string.format("%s granted %dx %s to %d players", grantedBy.Name, amount, itemID, count))
end

-- Parse chat commands
local function onPlayerChatted(player: Player, message: string): nil
	if not isAdmin(player) then return end
	
	local lowerMessage = message:lower()
	
	-- /grantcoins <amount>
	local coinsMatch = lowerMessage:match("^/grantcoins%s+(%d+)$")
	if coinsMatch then
		local amount = tonumber(coinsMatch)
		if amount and amount > 0 then
			grantCoinsToAll(amount, player)
		end
		return
	end
	
	-- /grantitem <itemID> <amount>
	local itemID, itemAmount = lowerMessage:match("^/grantitem%s+(%w+)%s+(%d+)$")
	if itemID and itemAmount then
		local amount = tonumber(itemAmount)
		if amount and amount > 0 then
			grantItemToAll(itemID:upper(), amount, player)
		end
		return
	end
	
	-- /grantammo <amount> (shortcut for AMMO_BASIC)
	local ammoMatch = lowerMessage:match("^/grantammo%s+(%d+)$")
	if ammoMatch then
		local amount = tonumber(ammoMatch)
		if amount and amount > 0 then
			grantItemToAll("AMMO_BASIC", amount, player)
		end
		return
	end
	
	-- /grantbait <amount> (shortcut for FOOD_BAIT)
	local baitMatch = lowerMessage:match("^/grantbait%s+(%d+)$")
	if baitMatch then
		local amount = tonumber(baitMatch)
		if amount and amount > 0 then
			grantItemToAll("FOOD_BAIT", amount, player)
		end
		return
	end
	
	-- /die - kill yourself to test respawn
	if lowerMessage == "/die" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
			Log.Info(CONTEXT, string.format("%s used /die command", player.Name))
		end
		return
	end
	
	-- Helper function to spawn an animal in front of player
	-- readyDelay: time in seconds before marking ReadyForFlocking (default 0.5)
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
		local flockFolder = workspace:FindFirstChild("Flock")
		if not flockFolder then
			flockFolder = Instance.new("Folder")
			flockFolder.Name = "Flock"
			flockFolder.Parent = workspace
		end
		
		-- Calculate spawn position in front of player
		local spawnOffset = offset or 10
		local spawnPos = root.Position + root.CFrame.LookVector * spawnOffset
		local targetPos = Vector3.new(spawnPos.X, spawnPos.Y + 2, spawnPos.Z)
		
		-- Build the animal DIRECTLY at spawn position (no moving needed)
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
		
		-- Set color on body
		local visual = clone:FindFirstChild("Visual")
		if visual then
			local bouncepart = visual:FindFirstChild("Bouncepart")
			if bouncepart then
				bouncepart.Color = animalDef.Color.Color
			end
		end
		
		-- Animal is already at correct position - just parent to workspace
		clone.Parent = flockFolder
		clone:SetNetworkOwner(nil)
		
		-- Mark as ready for flocking AFTER positions have replicated to clients
		-- Use delay to give network time to sync part positions
		local delay = readyDelay or 0.5
		task.delay(delay, function()
			if clone and clone.Parent then
				clone:SetAttribute("ReadyForFlocking", true)
			end
		end)
		
		-- Fire spawn events
		local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
		RemoteEvents.AnimalSpawnedEvent:FireAllClients(clone)
		ServerEvents.FlockSpawnedEvent:Fire(clone)
		
		return true
	end
	
	-- /spawnanimal <id> [delay] - spawn a specific animal by ID in front of player
	-- Optional delay parameter (in seconds) controls ReadyForFlocking timing (default 0.5)
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
					Log.Info(CONTEXT, string.format("%s spawned animal: %s (%s) with delay %.2fs", player.Name, animalID, animalDef.Name, readyDelay))
				end
			else
				Log.Warn(CONTEXT, string.format("Animal not found: %s. Use /listanimals to see valid IDs", animalID))
			end
		else
			Log.Warn(CONTEXT, "AnimalLibraryModule not available")
		end
		return
	end
	
	-- /spawnrandom [count] [delay] - spawn 1 or more random animals in front of player
	-- Optional delay parameter (in seconds) controls ReadyForFlocking timing (default 0.5)
	-- Examples: /spawnrandom, /spawnrandom 5, /spawnrandom 10 2.0
	local spawnRandomMatch = lowerMessage:match("^/spawnrandom%s*(%d*)%s*(%d*%.?%d*)$")
	if lowerMessage == "/spawnrandom" or spawnRandomMatch then
		local countStr, delayStr = lowerMessage:match("^/spawnrandom%s*(%d*)%s*(%d*%.?%d*)$")
		local count = tonumber(countStr) or 1
		count = math.clamp(count, 1, 20) -- Limit to 20 max
		local readyDelay = tonumber(delayStr) or 0.5
		
		local library = getAnimalLibrary()
		if library then
			local spawned = 0
			for i = 1, count do
				local animalDef = library.GetRandomType()
				-- Spread animals out at different distances
				local offset = 10 + (i - 1) * 3
				if spawnAnimalInFront(animalDef, player, offset, readyDelay) then
					spawned += 1
				end
				-- Small delay between spawns to ensure proper initialization
				if i < count then
					task.wait(0.1)
				end
			end
			Log.Info(CONTEXT, string.format("%s spawned %d random animals with delay %.2fs", player.Name, spawned, readyDelay))
		else
			Log.Warn(CONTEXT, "AnimalLibraryModule not available")
		end
		return
	end
	
	-- /listanimals - list all available animal IDs
	if lowerMessage == "/listanimals" then
		local library = getAnimalLibrary()
		if library then
			Log.Info(CONTEXT, "=== Available Animals ===")
			for _, animalDef in library.List do
				Log.Info(CONTEXT, string.format("  %s: %s (Template: %s, Points: %d, SpawnChance: %d%%)", 
					animalDef.ID, animalDef.Name, animalDef.Template or "DEFAULT", animalDef.PointValue, animalDef.SpawnChance or 0))
			end
		else
			Log.Warn(CONTEXT, "AnimalLibraryModule not available")
		end
		return
	end
	
	-- /spawnfood [attractiveness] - spawn food at player location for testing
	local foodMatch = lowerMessage:match("^/spawnfood%s*(%d*)$")
	if lowerMessage == "/spawnfood" or foodMatch then
		local attract = tonumber(foodMatch) or 8
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			-- Ensure Food folder exists
			local foodFolder = workspace:FindFirstChild("Food")
			if not foodFolder then
				foodFolder = Instance.new("Folder")
				foodFolder.Name = "Food"
				foodFolder.Parent = workspace
			end
			
			-- Place food in front of player
			local placePos = root.Position + root.CFrame.LookVector * 5
			local rayResult = workspace:Raycast(placePos + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0))
			if rayResult then
				placePos = rayResult.Position + Vector3.new(0, 0.5, 0)
			end
			
			local food = Instance.new("Part")
			food.Name = "DebugFood"
			food.Shape = Enum.PartType.Ball
			food.Size = Vector3.new(2, 2, 2)
			food.Color = Color3.fromRGB(255, 200, 50)
			food.Material = Enum.Material.Neon
			food.Anchored = true
			food.CanCollide = false
			food.Position = placePos
			food:SetAttribute("FoodAmount", 200)
			food:SetAttribute("Attractiveness", attract)
			food.Parent = foodFolder
			
			Log.Info(CONTEXT, string.format("%s spawned food (Attractiveness: %d)", player.Name, attract))
		end
		return
	end
	
	-- /shield - activate shield instantly (for testing)
	if lowerMessage == "/shield" then
		local shieldSvc = getShieldService()
		if shieldSvc then
			shieldSvc.ActivateShield(player, 10)
			Log.Info(CONTEXT, string.format("%s activated debug shield", player.Name))
		end
		return
	end
	
	-- /grantshield <amount> - grant shield items
	local shieldMatch = lowerMessage:match("^/grantshield%s+(%d+)$")
	if shieldMatch then
		local amount = tonumber(shieldMatch)
		if amount and amount > 0 then
			grantItemToAll("TOOL_SHIELD", amount, player)
		end
		return
	end
	
	-- /spawngift - spawn a gift at player location for testing
	if lowerMessage == "/spawngift" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			-- Ensure Gifts folder exists
			local giftsFolder = workspace:FindFirstChild("Gifts")
			if not giftsFolder then
				giftsFolder = Instance.new("Folder")
				giftsFolder.Name = "Gifts"
				giftsFolder.Parent = workspace
			end
			
			-- Create a random gift
			local giftItems = {"COIN", "AMMO_BASIC", "FOOD_BAIT", "TOOL_SHIELD"}
			local itemID = giftItems[math.random(1, #giftItems)]
			local amount = math.random(5, 20)
			
			local placePos = root.Position + root.CFrame.LookVector * 5 + Vector3.new(0, 2, 0)
			
			-- Create gift model (same structure as GiftSpawner)
			local giftModel = Instance.new("Model")
			giftModel.Name = "Gift_" .. itemID
			
			local giftPart = Instance.new("Part")
			giftPart.Name = "GiftBox"
			giftPart.Shape = Enum.PartType.Block
			giftPart.Size = Vector3.new(2, 2, 2)
			giftPart.Color = Color3.fromRGB(255, 215, 0)
			giftPart.Material = Enum.Material.Neon
			giftPart.Anchored = true
			giftPart.CanCollide = false
			giftPart.Position = placePos
			giftPart.Parent = giftModel
			
			giftModel.PrimaryPart = giftPart
			giftModel:SetAttribute("ItemID", itemID)
			giftModel:SetAttribute("Amount", amount)
			
			-- Attachment for particles
			local attachment = Instance.new("Attachment")
			attachment.Parent = giftPart
			
			-- Particles
			local particles = Instance.new("ParticleEmitter")
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
			particles.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(1, 0),
			})
			particles.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.8, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			})
			particles.LightEmission = 1
			particles.LightInfluence = 0
			particles.Lifetime = NumberRange.new(0.5, 1.5)
			particles.Rate = 30
			particles.Speed = NumberRange.new(3, 6)
			particles.SpreadAngle = Vector2.new(360, 360)
			particles.Acceleration = Vector3.new(0, 2, 0)
			particles.Parent = attachment
			
			-- Point light
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 255, 150)
			light.Brightness = 2
			light.Range = 8
			light.Parent = giftPart
			
			-- Billboard label
			local ItemRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("ItemRegistry"))
			local itemDef = ItemRegistry.GetItem(itemID)
			local itemName = itemDef and itemDef.Name or itemID
			
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "GiftLabel"
			billboard.Size = UDim2.new(0, 150, 0, 50)
			billboard.StudsOffset = Vector3.new(0, 3, 0)
			billboard.AlwaysOnTop = true
			billboard.Adornee = giftPart
			billboard.Parent = giftModel
			
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			frame.BackgroundTransparency = 0.3
			frame.BorderSizePixel = 0
			frame.Parent = billboard
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = frame
			
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.Text = string.format("🎁 %dx %s", amount, itemName)
			label.Parent = frame
			
			giftModel.Parent = giftsFolder
			
			-- Floating animation
			task.spawn(function()
				local startY = placePos.Y
				local floatOffset = 0
				local rotation = 0
				while giftModel and giftModel.Parent and giftPart and giftPart.Parent do
					floatOffset += 0.05
					rotation += 1
					local newY = startY + math.sin(floatOffset) * 0.5
					giftPart.CFrame = CFrame.new(placePos.X, newY, placePos.Z) * CFrame.Angles(0, math.rad(rotation), 0)
					task.wait(0.03)
				end
			end)
			
			-- Touch handler
			giftPart.Touched:Connect(function(hit)
				local touchPlayer = Players:GetPlayerFromCharacter(hit.Parent)
				if not touchPlayer then return end
				if giftModel:GetAttribute("Collected") then return end
				giftModel:SetAttribute("Collected", true)
				
				local invService = getInventoryService()
				if invService then
					invService.AddItem(touchPlayer, itemID, amount)
				end
				giftModel:Destroy()
			end)
			
			Log.Info(CONTEXT, string.format("%s spawned debug gift: %dx %s", player.Name, amount, itemName))
		end
		return
	end
	
	-- /debughelp - show available commands
	if lowerMessage == "/debughelp" then
		Log.Info(CONTEXT, "=== Debug Commands ===")
		Log.Info(CONTEXT, "Items: /grantcoins <amt>, /grantammo <amt>, /grantbait <amt>, /grantshield <amt>, /grantitem <id> <amt>")
		Log.Info(CONTEXT, "Player: /die, /shield, /spawnfood [attract], /spawngift")
		Log.Info(CONTEXT, "Game: /endgame, /resetachievements, /resetxp, /resetall")
		Log.Info(CONTEXT, "Achievements: /grantachievement <id>, /listachievements, /myachievements, /setachievementprogress <id> <val>")
		Log.Info(CONTEXT, "Achievements: /grantallbonusachievements, /setlevel <level>")
		Log.Info(CONTEXT, "Scores: /setredscore <score>, /setbluescore <score>, /setscore <red> <blue>, /resetscores")
		Log.Info(CONTEXT, "Teams: /switchteam [red|blue], /teamstatus, /setgameactive <true|false>, /simulateforfeit <red|blue>")
		Log.Info(CONTEXT, "Animals: /spawnanimal <id> [delay], /spawnrandom [count] [delay], /listanimals")
		return
	end
	
	-- /endgame - force end the game for testing
	if lowerMessage == "/endgame" then
		Log.Info(CONTEXT, string.format("%s triggered /endgame command", player.Name))
		-- Fire ForceEndGameEvent which will stop timer and trigger proper game end flow
		ServerEvents.ForceEndGameEvent:Fire()
		return
	end
	
	-- /resetachievements - reset all achievements for all players
	if lowerMessage == "/resetachievements" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			for _, p in Players:GetPlayers() do
				achievementsSvc.ResetAchievements(p)
			end
			Log.Info(CONTEXT, string.format("%s reset achievements for all players", player.Name))
		else
			Log.Warn(CONTEXT, "AchievementsService not available")
		end
		return
	end
	
	-- /resetxp - reset XP and level for all players
	if lowerMessage == "/resetxp" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			for _, p in Players:GetPlayers() do
				achievementsSvc.ResetXP(p)
			end
			Log.Info(CONTEXT, string.format("%s reset XP for all players", player.Name))
		else
			Log.Warn(CONTEXT, "AchievementsService not available")
		end
		return
	end
	
	-- /resetall - reset all stats, achievements, and XP for all players
	if lowerMessage == "/resetall" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			for _, p in Players:GetPlayers() do
				achievementsSvc.ResetAllStats(p)
			end
			Log.Info(CONTEXT, string.format("%s reset all stats for all players", player.Name))
		else
			Log.Warn(CONTEXT, "AchievementsService not available")
		end
		return
	end
	
	-- /grantachievement <achievementID> - complete an achievement for yourself
	local grantAchMatch = lowerMessage:match("^/grantachievement%s+([%w_]+)$")
	if grantAchMatch then
		local achievementID = grantAchMatch:upper()
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
			local achievementDef = AchievementRegistry.GetAchievement(achievementID)
			if achievementDef then
				-- Check if player data is initialized
				local achievements = achievementsSvc.GetAchievements(player)
				if not achievements then
					Log.Warn(CONTEXT, string.format("Player %s achievements not initialized - initializing now", player.Name))
					achievementsSvc.InitPlayer(player, nil, nil)
				end
				
				-- Check if already completed
				if achievementsSvc.IsAchievementCompleted(player, achievementID) then
					Log.Warn(CONTEXT, string.format("Achievement %s already completed for %s", achievementID, player.Name))
					return
				end
				
				-- Set progress to target value to complete it
				local success = achievementsSvc.UpdateProgress(player, achievementID, achievementDef.TargetValue)
				if success then
					Log.Info(CONTEXT, string.format("%s granted achievement: %s (%s)", player.Name, achievementID, achievementDef.Name))
				else
					Log.Warn(CONTEXT, string.format("Failed to grant achievement %s - UpdateProgress returned false", achievementID))
				end
			else
				Log.Warn(CONTEXT, string.format("Achievement not found: %s. Use /listachievements to see valid IDs", achievementID))
			end
		else
			Log.Warn(CONTEXT, "AchievementsService not available")
		end
		return
	end
	
	-- /listachievements - list all available achievement IDs
	if lowerMessage == "/listachievements" then
		local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
		Log.Info(CONTEXT, "=== Available Achievements ===")
		for id, def in AchievementRegistry.Achievements do
			local bonusText = def.CoinBonus and string.format(" [+%d%% coins]", def.CoinBonus * 100) or ""
			Log.Info(CONTEXT, string.format("  %s: %s%s", id, def.Name, bonusText))
		end
		return
	end
	
	-- /myachievements - list your current achievement status
	if lowerMessage == "/myachievements" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			local achievements = achievementsSvc.GetAchievements(player)
			local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
			Log.Info(CONTEXT, string.format("=== %s's Achievements ===", player.Name))
			
			local completed = {}
			local inProgress = {}
			
			for id, def in AchievementRegistry.Achievements do
				local progress = achievements and achievements[id]
				if progress and progress.Completed then
					table.insert(completed, string.format("  ✅ %s (%s)", id, def.Name))
				else
					local currentVal = progress and progress.CurrentValue or 0
					table.insert(inProgress, string.format("  ⏳ %s: %d/%d (%s)", id, currentVal, def.TargetValue, def.Name))
				end
			end
			
			Log.Info(CONTEXT, string.format("Completed (%d):", #completed))
			for _, line in completed do
				Log.Info(CONTEXT, line)
			end
			Log.Info(CONTEXT, string.format("In Progress (%d):", #inProgress))
			for _, line in inProgress do
				Log.Info(CONTEXT, line)
			end
		else
			Log.Warn(CONTEXT, "AchievementsService not available")
		end
		return
	end
	
	-- /setachievementprogress <achievementID> <value> - set achievement progress to specific value
	local setAchProgMatch = lowerMessage:match("^/setachievementprogress%s+([%w_]+)%s+(%d+)$")
	if setAchProgMatch then
		local achievementID, valueStr = lowerMessage:match("^/setachievementprogress%s+([%w_]+)%s+(%d+)$")
		achievementID = achievementID:upper()
		local value = tonumber(valueStr)
		if value then
			local achievementsSvc = getAchievementsService()
			if achievementsSvc then
				local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
				local achievementDef = AchievementRegistry.GetAchievement(achievementID)
				if achievementDef then
					-- Ensure player is initialized
					local achievements = achievementsSvc.GetAchievements(player)
					if not achievements then
						Log.Warn(CONTEXT, string.format("Player %s achievements not initialized - initializing now", player.Name))
						achievementsSvc.InitPlayer(player, nil, nil)
					end
					
					achievementsSvc.UpdateProgress(player, achievementID, value)
					Log.Info(CONTEXT, string.format("%s set %s progress to %d/%d", player.Name, achievementID, value, achievementDef.TargetValue))
				else
					Log.Warn(CONTEXT, string.format("Achievement not found: %s. Use /listachievements to see valid IDs", achievementID))
				end
			else
				Log.Warn(CONTEXT, "AchievementsService not available")
			end
		end
		return
	end
	
	-- /grantallbonusachievements - grant all achievements that give coin bonuses
	if lowerMessage == "/grantallbonusachievements" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
			
			-- Ensure player is initialized
			local achievements = achievementsSvc.GetAchievements(player)
			if not achievements then
				Log.Warn(CONTEXT, string.format("Player %s achievements not initialized - initializing now", player.Name))
				achievementsSvc.InitPlayer(player, nil, nil)
			end
			
			local granted = 0
			local skipped = 0
			for id, def in AchievementRegistry.Achievements do
				if def.CoinBonus and def.CoinBonus > 0 then
					if not achievementsSvc.IsAchievementCompleted(player, id) then
						local success = achievementsSvc.UpdateProgress(player, id, def.TargetValue)
						if success then
							granted += 1
						end
					else
						skipped += 1
					end
				end
			end
			Log.Info(CONTEXT, string.format("%s granted %d bonus achievements (skipped %d already completed)", player.Name, granted, skipped))
		else
			Log.Warn(CONTEXT, "AchievementsService not available")
		end
		return
	end
	
	-- /setlevel <level> - set your level directly
	local setLevelMatch = lowerMessage:match("^/setlevel%s+(%d+)$")
	if setLevelMatch then
		local level = tonumber(setLevelMatch)
		if level and level > 0 then
			local achievementsSvc = getAchievementsService()
			if achievementsSvc then
				local stats = achievementsSvc.GetStats(player)
				if stats then
					-- Calculate XP needed for target level
					local targetXP = achievementsSvc.GetTotalXPForLevel(level)
					stats.Level = level
					stats.CurrentXP = 0
					stats.TotalXP = targetXP
					Log.Info(CONTEXT, string.format("%s set level to %d", player.Name, level))
				end
			else
				Log.Warn(CONTEXT, "AchievementsService not available")
			end
		end
		return
	end
	
	-- /setredscore <score> - set Red Team score
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
				else
					Log.Warn(CONTEXT, "Red Team not found")
				end
			else
				Log.Warn(CONTEXT, "TeamService not available")
			end
		end
		return
	end
	
	-- /setbluescore <score> - set Blue Team score
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
				else
					Log.Warn(CONTEXT, "Blue Team not found")
				end
			else
				Log.Warn(CONTEXT, "TeamService not available")
			end
		end
		return
	end
	
	-- /setscore <red> <blue> - set both team scores at once
	local redScore, blueScore = lowerMessage:match("^/setscore%s+(%d+)%s+(%d+)$")
	if redScore and blueScore then
		local rScore = tonumber(redScore)
		local bScore = tonumber(blueScore)
		if rScore and bScore then
			local teamSvc = getTeamService()
			if teamSvc then
				local redTeam = teamSvc.GetTeamByName("Red Team")
				local blueTeam = teamSvc.GetTeamByName("Blue Team")
				if redTeam and blueTeam then
					teamSvc.SetTeamScore(redTeam, rScore)
					teamSvc.SetTeamScore(blueTeam, bScore)
					Log.Info(CONTEXT, string.format("%s set scores: Red=%d, Blue=%d", player.Name, rScore, bScore))
				else
					Log.Warn(CONTEXT, "Teams not found")
				end
			else
				Log.Warn(CONTEXT, "TeamService not available")
			end
		end
		return
	end
	
	-- /resetscores - reset both team scores to 0
	if lowerMessage == "/resetscores" then
		local teamSvc = getTeamService()
		if teamSvc then
			teamSvc.ResetTeamScores()
			Log.Info(CONTEXT, string.format("%s reset team scores", player.Name))
		else
			Log.Warn(CONTEXT, "TeamService not available")
		end
		return
	end
	
	-- /simulateforfeit <red|blue> - simulate a team forfeiting (triggers abandonment)
	local forfeitMatch = lowerMessage:match("^/simulateforfeit%s+(%w+)$")
	if forfeitMatch then
		local teamName = forfeitMatch:lower()
		local teamSvc = getTeamService()
		if teamSvc then
			local redTeam = teamSvc.GetTeamByName("Red Team")
			local blueTeam = teamSvc.GetTeamByName("Blue Team")
			
			local targetTeam: Team? = nil
			if teamName == "red" and redTeam then
				targetTeam = redTeam
			elseif teamName == "blue" and blueTeam then
				targetTeam = blueTeam
			else
				Log.Warn(CONTEXT, "Invalid team name. Use 'red' or 'blue'")
				return
			end
			
			local success = teamSvc.SetTeamForfeit(targetTeam)
			if success then
				Log.Info(CONTEXT, string.format("%s simulated %s Team forfeit", player.Name, teamName:upper()))
			else
				Log.Warn(CONTEXT, "Failed to set team forfeit")
			end
		else
			Log.Warn(CONTEXT, "TeamService not available")
		end
		return
	end
	
	-- /switchteam [red|blue] - switch your team (for testing)
	local switchMatch = lowerMessage:match("^/switchteam%s*(%w*)$")
	if lowerMessage == "/switchteam" or switchMatch then
		local teamSvc = getTeamService()
		if teamSvc then
			local redTeam = teamSvc.GetTeamByName("Red Team")
			local blueTeam = teamSvc.GetTeamByName("Blue Team")
			
			if not redTeam or not blueTeam then
				Log.Warn(CONTEXT, "Teams not found")
				return
			end
			
			local targetTeam: Team? = nil
			if switchMatch == "red" then
				targetTeam = redTeam
			elseif switchMatch == "blue" then
				targetTeam = blueTeam
			else
				-- Toggle to opposite team
				if player.Team == redTeam then
					targetTeam = blueTeam
				else
					targetTeam = redTeam
				end
			end
			
			if targetTeam then
				player.Team = targetTeam
				Log.Info(CONTEXT, string.format("%s switched to %s", player.Name, targetTeam.Name))
			end
		else
			Log.Warn(CONTEXT, "TeamService not available")
		end
		return
	end
	
	-- /teamstatus - show current team player counts
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
				
				-- List players on each team
				local redNames = {}
				for _, p in redTeam:GetPlayers() do
					table.insert(redNames, p.Name)
				end
				local blueNames = {}
				for _, p in blueTeam:GetPlayers() do
					table.insert(blueNames, p.Name)
				end
				
				Log.Info(CONTEXT, string.format("Red Players: %s", #redNames > 0 and table.concat(redNames, ", ") or "none"))
				Log.Info(CONTEXT, string.format("Blue Players: %s", #blueNames > 0 and table.concat(blueNames, ", ") or "none"))
			else
				Log.Warn(CONTEXT, "Teams not found")
			end
		else
			Log.Warn(CONTEXT, "TeamService not available")
		end
		return
	end
	
	-- /setgameactive <true|false> - manually set game active state (for testing abandonment)
	local gameActiveMatch = lowerMessage:match("^/setgameactive%s+(%w+)$")
	if gameActiveMatch then
		local teamSvc = getTeamService()
		if teamSvc then
			local active = gameActiveMatch == "true" or gameActiveMatch == "1"
			teamSvc.SetGameActive(active)
			Log.Info(CONTEXT, string.format("%s set game active to %s", player.Name, tostring(active)))
		else
			Log.Warn(CONTEXT, "TeamService not available")
		end
		return
	end
end

-- Connect chat listener for all players
local function setupPlayer(player: Player): nil
	player.Chatted:Connect(function(message: string)
		onPlayerChatted(player, message)
	end)
end

-- Initialize
Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

Log.Info(CONTEXT, "DebugCommands initialized (use /debughelp for commands)")
