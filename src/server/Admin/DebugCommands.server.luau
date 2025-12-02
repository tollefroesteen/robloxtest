--!strict
-- DebugCommands.server.luau
-- Admin/debug commands for testing (chat commands)
-- Usage: Type "/grantcoins 100" in chat to give all players 100 coins

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

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
		Log.Info(CONTEXT, "Debug commands: /grantcoins <amt>, /grantammo <amt>, /grantbait <amt>, /grantshield <amt>, /grantitem <id> <amt>, /die, /shield, /spawnfood [attract], /spawngift, /endgame, /resetachievements, /resetxp, /resetall")
		return
	end
	
	-- /endgame - force end the game for testing
	if lowerMessage == "/endgame" then
		local gameEndSvc = getGameEndService()
		if gameEndSvc then
			Log.Info(CONTEXT, string.format("%s triggered /endgame command", player.Name))
			task.spawn(function()
				gameEndSvc.ProcessGameEnd()
			end)
		else
			Log.Warn(CONTEXT, "GameEndService not available")
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
