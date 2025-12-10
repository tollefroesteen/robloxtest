--!strict
-- DebugCommands.luau
-- Shared admin/debug commands for testing (chat commands)
-- Works in both Arena and Lobby
-- Usage: Type "/grantcoins 100" in chat to give all players 100 coins

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local CONTEXT = "DebugCommands"

-- List of admin user IDs (add your Roblox user ID here)
-- In Studio, all players are treated as admins for testing
local ADMIN_USER_IDS: { number } = {
	7321086050,
	9332159012,
	6013582887
	-- Add your user ID here, e.g.: 12345678,
}

local DebugCommands = {}

-- Lazy load services
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

local LuckyBlockService: any = nil
local function getLuckyBlockService()
	if not LuckyBlockService then
		local success, service = pcall(function()
			return require(Shared:WaitForChild("services"):WaitForChild("LuckyBlockService"))
		end)
		if success then
			LuckyBlockService = service
		end
	end
	return LuckyBlockService
end

local LuckyBlockConfig: any = nil
local function getLuckyBlockConfig()
	if not LuckyBlockConfig then
		local success, config = pcall(function()
			return require(Shared:WaitForChild("config"):WaitForChild("LuckyBlockConfig"))
		end)
		if success then
			LuckyBlockConfig = config
		end
	end
	return LuckyBlockConfig
end

-- Place-specific services (set by initializer)
local placeServices: { [string]: any } = {}

-- Lazy load AchievementsService (now in shared)
local AchievementsService: any = nil
local function getAchievementsService()
	if not AchievementsService then
		local success, service = pcall(function()
			return require(Shared:WaitForChild("services"):WaitForChild("AchievementsService"))
		end)
		if success then
			AchievementsService = service
		end
	end
	return AchievementsService
end

-- Lazy load PlayerUpgradesService
local PlayerUpgradesService: any = nil
local function getPlayerUpgradesService()
	if not PlayerUpgradesService then
		local success, service = pcall(function()
			return require(Shared:WaitForChild("services"):WaitForChild("PlayerUpgradesService"))
		end)
		if success then
			PlayerUpgradesService = service
		end
	end
	return PlayerUpgradesService
end

-- Check if player is admin (or in Studio)
local function isAdmin(player: Player): boolean
	-- Always allow in Studio for testing
	if RunService:IsStudio() then
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
local function grantCoinsToAll(amount: number, grantedBy: Player)
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
		else
			Log.Warn(CONTEXT, string.format("Failed to grant %s to %s: %s", itemID, player.Name, msg))
		end
	end
	
	Log.Info(CONTEXT, string.format("%s granted %dx %s to %d players", grantedBy.Name, amount, itemID, count))
end

-- Spawn a lucky block at a position
local function spawnLuckyBlock(player: Player, rarity: string?)
	local lbService = getLuckyBlockService()
	if not lbService then
		Log.Warn(CONTEXT, "LuckyBlockService not available")
		return
	end
	
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		Log.Warn(CONTEXT, "Player has no HumanoidRootPart")
		return
	end
	
	-- Determine rarity
	local blockRarity = rarity or "Rare"
	if blockRarity ~= "Rare" and blockRarity ~= "VeryRare" and blockRarity ~= "UltraRare" then
		blockRarity = "Rare"
	end
	
	-- Spawn position in front of player
	local spawnPos = root.Position + root.CFrame.LookVector * 8 + Vector3.new(0, 2, 0)
	
	-- Create the block
	local blockModel = lbService.CreateLuckyBlockModel(blockRarity, spawnPos)
	blockModel.Parent = Workspace
	
	-- Store block ID for tracking
	local blockID = "LB_DEBUG_" .. player.UserId .. "_" .. os.time()
	blockModel:SetAttribute("BlockID", blockID)
	blockModel:SetAttribute("Rarity", blockRarity)
	blockModel:SetAttribute("DebugBlock", true)
	
	-- Set up proximity prompt for interaction
	local proximityPrompt = blockModel.PrimaryPart:FindFirstChild("PickupPrompt")
	if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
		proximityPrompt.Triggered:Connect(function(triggeringPlayer)
			-- Select an animal
			local selectedAnimal = lbService.SelectAnimalForBlock(blockRarity)
			if selectedAnimal then
				Log.Info(CONTEXT, string.format("%s opened debug lucky block - got %s", triggeringPlayer.Name, selectedAnimal.Name))
				
				-- Try to use place-specific animal builder
				local animalBuilder = placeServices.AnimalBuilder or placeServices.PetBuilder
				if animalBuilder then
					local animalPos = blockModel.PrimaryPart.Position + Vector3.new(0, 2, 0)
					local animalBody = animalBuilder.BuildAnimal and animalBuilder.BuildAnimal(selectedAnimal.Template, selectedAnimal.Color, animalPos)
						or animalBuilder.BuildPet and animalBuilder.BuildPet(selectedAnimal.Template, selectedAnimal.Color, animalPos)
					
					if animalBody then
						local animalModel = Instance.new("Model")
						animalModel.Name = "DebugAnimal_" .. selectedAnimal.Name
						animalBody.Parent = animalModel
						animalModel.PrimaryPart = animalBody
						animalModel.Parent = Workspace
						
						-- Add name label
						local billboardGui = Instance.new("BillboardGui")
						billboardGui.Size = UDim2.new(0, 200, 0, 50)
						billboardGui.StudsOffset = Vector3.new(0, 3, 0)
						billboardGui.AlwaysOnTop = true
						billboardGui.Parent = animalBody
						
						local nameLabel = Instance.new("TextLabel")
						nameLabel.Size = UDim2.new(1, 0, 1, 0)
						nameLabel.BackgroundTransparency = 1
						nameLabel.Text = "🎉 " .. selectedAnimal.Name .. " 🎉"
						nameLabel.TextColor3 = Color3.new(1, 1, 1)
						nameLabel.TextScaled = true
						nameLabel.Font = Enum.Font.GothamBold
						nameLabel.TextStrokeTransparency = 0.5
						nameLabel.Parent = billboardGui
						
						-- Auto-destroy after 10 seconds
						task.delay(10, function()
							if animalModel and animalModel.Parent then
								animalModel:Destroy()
							end
						end)
					end
				end
				
				-- Notify player
				RemoteEvents.LuckyBlockRevealCompleteEvent:FireClient(triggeringPlayer, blockID, selectedAnimal.ID, selectedAnimal.Name)
			end
			
			-- Destroy block
			blockModel:Destroy()
		end)
	end
	
	Log.Info(CONTEXT, string.format("%s spawned debug %s lucky block", player.Name, blockRarity))
end

-- Parse chat commands
local function onPlayerChatted(player: Player, message: string)
	if not isAdmin(player) then return end
	
	local lowerMessage = message:lower()
	
	-- Only process messages that start with /
	if not lowerMessage:match("^/") then return end
	
	-- /grantcoins <amount>
	local coinsMatch = lowerMessage:match("^/grantcoins%s+(%d+)$")
	if coinsMatch then
		local amount = tonumber(coinsMatch)
		if amount and amount > 0 then
			Log.Info(CONTEXT, string.format("%s is granting %d coins to all players...", player.Name, amount))
			grantCoinsToAll(amount, player)
		else
			Log.Warn(CONTEXT, "Invalid amount for /grantcoins")
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
	
	-- === LUCKY BLOCK COMMANDS ===
	-- Note: /spawnluckyblock is handled by place-specific handlers (arena/lobby)
	-- since each place has different spawning logic
	
	-- /spawnlball - spawn one of each rarity lucky block (debug preview only)
	if lowerMessage == "/spawnlball" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local lbService = getLuckyBlockService()
			if lbService then
				local rarities = {"Rare", "VeryRare", "UltraRare"}
				for i, rarity in ipairs(rarities) do
					local offset = (i - 2) * 6 -- -6, 0, 6
					local spawnPos = root.Position + root.CFrame.LookVector * 8 + root.CFrame.RightVector * offset + Vector3.new(0, 2, 0)
					local blockModel = lbService.CreateLuckyBlockModel(rarity, spawnPos)
					blockModel.Parent = Workspace
					blockModel:SetAttribute("DebugBlock", true)
					
					-- Simple pickup handler
					local proximityPrompt = blockModel.PrimaryPart:FindFirstChild("PickupPrompt")
					if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
						local capturedRarity = rarity
						proximityPrompt.Triggered:Connect(function(triggeringPlayer)
							local selectedAnimal = lbService.SelectAnimalForBlock(capturedRarity)
							if selectedAnimal then
								Log.Info(CONTEXT, string.format("%s opened %s lucky block - got %s", triggeringPlayer.Name, capturedRarity, selectedAnimal.Name))
							end
							blockModel:Destroy()
						end)
					end
				end
				Log.Info(CONTEXT, string.format("%s spawned all lucky block rarities", player.Name))
			end
		end
		return
	end
	
	-- /testlbroll [rarity] [count] - test lucky block animal selection without spawning
	local rollMatch = lowerMessage:match("^/testlbroll%s*(%w*)%s*(%d*)$")
	if lowerMessage == "/testlbroll" or rollMatch then
		local rarityInput, countStr = lowerMessage:match("^/testlbroll%s*(%w*)%s*(%d*)$")
		rarityInput = rarityInput or ""
		local count = tonumber(countStr) or 10
		count = math.clamp(count, 1, 100)
		
		local rarity = "Rare"
		if rarityInput == "veryrare" or rarityInput == "vr" then
			rarity = "VeryRare"
		elseif rarityInput == "ultrarare" or rarityInput == "ur" then
			rarity = "UltraRare"
		end
		
		local lbService = getLuckyBlockService()
		if lbService then
			local results: { [string]: number } = {}
			for i = 1, count do
				local animal = lbService.SelectAnimalForBlock(rarity)
				if animal then
					results[animal.Name] = (results[animal.Name] or 0) + 1
				end
			end
			
			Log.Info(CONTEXT, string.format("=== Lucky Block Roll Test (%s, %d rolls) ===", rarity, count))
			-- Sort by count
			local sorted = {}
			for name, cnt in pairs(results) do
				table.insert(sorted, { name = name, count = cnt })
			end
			table.sort(sorted, function(a, b) return a.count > b.count end)
			
			for _, entry in ipairs(sorted) do
				local pct = (entry.count / count) * 100
				Log.Info(CONTEXT, string.format("  %s: %d (%.1f%%)", entry.name, entry.count, pct))
			end
		end
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
			Log.Warn(CONTEXT, "AchievementsService not available in this place")
		end
		return
	end
	
	-- /resetxp - reset XP for all players
	if lowerMessage == "/resetxp" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			for _, p in Players:GetPlayers() do
				achievementsSvc.ResetXP(p)
			end
			Log.Info(CONTEXT, string.format("%s reset XP for all players", player.Name))
		else
			Log.Warn(CONTEXT, "AchievementsService not available in this place")
		end
		return
	end
	
	-- /resetall - reset all stats for all players
	if lowerMessage == "/resetall" then
		local achievementsSvc = getAchievementsService()
		if achievementsSvc then
			for _, p in Players:GetPlayers() do
				achievementsSvc.ResetAllStats(p)
			end
			Log.Info(CONTEXT, string.format("%s reset all stats for all players", player.Name))
		else
			Log.Warn(CONTEXT, "AchievementsService not available in this place")
		end
		return
	end
	
	-- /grantheatseek - grant heat-seeking ammo upgrade to all players
	if lowerMessage == "/grantheatseek" then
		local upgradesSvc = getPlayerUpgradesService()
		if upgradesSvc then
			local count = 0
			for _, p in Players:GetPlayers() do
				if upgradesSvc.GrantUpgrade(p, "HeatSeekingAmmo") then
					count += 1
				end
			end
			Log.Info(CONTEXT, string.format("%s granted Heat-Seeking Ammo to %d players", player.Name, count))
		else
			Log.Warn(CONTEXT, "PlayerUpgradesService not available")
		end
		return
	end
	
	-- /debughelp - show all available commands
	if lowerMessage == "/debughelp" then
		Log.Info(CONTEXT, "=== Debug Commands ===")
		Log.Info(CONTEXT, "")
		Log.Info(CONTEXT, "-- ITEMS & INVENTORY --")
		Log.Info(CONTEXT, "/grantcoins <amt> - Give coins to all players")
		Log.Info(CONTEXT, "/grantammo <amt> - Give basic ammo to all players")
		Log.Info(CONTEXT, "/grantbait <amt> - Give food bait to all players")
		Log.Info(CONTEXT, "/grantitem <id> <amt> - Give any item to all players")
		Log.Info(CONTEXT, "")
		Log.Info(CONTEXT, "-- PLAYER --")
		Log.Info(CONTEXT, "/die - Kill yourself to test respawn")
		Log.Info(CONTEXT, "")
		Log.Info(CONTEXT, "-- ACHIEVEMENTS & PROGRESSION --")
		Log.Info(CONTEXT, "/resetachievements - Reset all achievements for all players")
		Log.Info(CONTEXT, "/resetxp - Reset XP and level for all players")
		Log.Info(CONTEXT, "/resetall - Reset ALL stats and achievements for all players")
		Log.Info(CONTEXT, "")
		Log.Info(CONTEXT, "-- UPGRADES --")
		Log.Info(CONTEXT, "/grantheatseek - Grant Heat-Seeking Ammo upgrade to all players")
		Log.Info(CONTEXT, "")
		Log.Info(CONTEXT, "-- LUCKY BLOCKS (Testing) --")
		Log.Info(CONTEXT, "/spawnlball - Spawn one of each rarity lucky block (preview only)")
		Log.Info(CONTEXT, "/testlbroll [rare|vr|ur] [count] - Test lucky block animal selection")
		Log.Info(CONTEXT, "")
		
		-- Show place-specific commands if handler is registered
		if placeServices.showPlaceHelp then
			placeServices.showPlaceHelp(player)
		else
			Log.Info(CONTEXT, "-- PLACE-SPECIFIC COMMANDS --")
			Log.Info(CONTEXT, "Type /debughelparena or /debughelplobby for place-specific commands")
		end
		return
	end
	
	-- Pass to place-specific handler if registered
	if placeServices.handleCommand then
		placeServices.handleCommand(player, message, lowerMessage)
	end
end

-- Connect chat listener for a player
local function setupPlayer(player: Player)
	player.Chatted:Connect(function(message: string)
		onPlayerChatted(player, message)
	end)
end

-- Register place-specific services
function DebugCommands.RegisterServices(services: { [string]: any })
	for key, service in pairs(services) do
		placeServices[key] = service
	end
end

-- Initialize
function DebugCommands.Init()
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	
	Log.Info(CONTEXT, "DebugCommands initialized (use /debughelp for commands)")
end

return DebugCommands
