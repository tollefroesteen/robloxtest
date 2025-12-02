--!strict
-- ActionServer.server.luau
-- Handles player action events (Feed, Scare, etc.)
-- Shoot is handled separately in ShootServer.server.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "ActionServer"

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

--============================================================================
-- ACTION CONFIGURATION
--============================================================================

local ActionConfig = {
	FEED = {
		ItemID = "FOOD_BAIT",
		ItemsPerUse = 1,
		Cooldown = 1.0,  -- seconds
	},
	SCARE = {
		ItemID = nil,    -- No item consumed
		ItemsPerUse = 0,
		Cooldown = 3.0,  -- longer cooldown since it's free
	},
}

-- Track cooldowns per player per action
local playerCooldowns: { [Player]: { [string]: number } } = {}

--============================================================================
-- HELPER FUNCTIONS
--============================================================================

local function isOnCooldown(player: Player, actionID: string): boolean
	local cooldowns = playerCooldowns[player]
	if not cooldowns then return false end
	
	local lastUse = cooldowns[actionID]
	if not lastUse then return false end
	
	local config = ActionConfig[actionID]
	if not config then return false end
	
	return (tick() - lastUse) < config.Cooldown
end

local function setCooldown(player: Player, actionID: string): nil
	if not playerCooldowns[player] then
		playerCooldowns[player] = {}
	end
	playerCooldowns[player][actionID] = tick()
end

local function canPerformAction(player: Player, actionID: string): (boolean, string)
	-- Check game state
	local gameEndSvc = getGameEndService()
	if gameEndSvc and gameEndSvc.IsProcessingGameEnd() then
		return false, "Game is ending"
	end
	
	-- Check cooldown
	if isOnCooldown(player, actionID) then
		return false, "Action on cooldown"
	end
	
	-- Check item requirement
	local config = ActionConfig[actionID]
	if not config then
		return false, "Unknown action"
	end
	
	if config.ItemID then
		local invService = getInventoryService()
		if invService then
			if not invService.HasItem(player, config.ItemID, config.ItemsPerUse) then
				return false, "Insufficient items"
			end
		end
	end
	
	return true, "OK"
end

local function consumeActionItem(player: Player, actionID: string): boolean
	local config = ActionConfig[actionID]
	if not config or not config.ItemID then
		return true  -- No item to consume
	end
	
	local invService = getInventoryService()
	if not invService then
		return false
	end
	
	local success, msg = invService.RemoveItem(player, config.ItemID, config.ItemsPerUse)
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to consume item for %s: %s", player.Name, msg))
	end
	return success
end

--============================================================================
-- FEED ACTION
--============================================================================

local function onFeedAction(player: Player)
	local canDo, reason = canPerformAction(player, "FEED")
	if not canDo then
		Log.Info(CONTEXT, string.format("%s cannot feed: %s", player.Name, reason))
		return
	end
	
	-- Consume the bait
	if not consumeActionItem(player, "FEED") then
		return
	end
	
	setCooldown(player, "FEED")
	
	-- Get player position
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	-- TODO: Implement actual feed mechanics
	-- For now, just create a visual indicator
	local feedIndicator = Instance.new("Part")
	feedIndicator.Name = "FeedBait"
	feedIndicator.Shape = Enum.PartType.Cylinder
	feedIndicator.Size = Vector3.new(0.5, 3, 3)
	feedIndicator.Color = Color3.fromRGB(139, 90, 43)  -- Brown
	feedIndicator.Material = Enum.Material.SmoothPlastic
	feedIndicator.Anchored = true
	feedIndicator.CanCollide = false
	feedIndicator.CFrame = CFrame.new(root.Position + root.CFrame.LookVector * 5) * CFrame.Angles(0, 0, math.rad(90))
	feedIndicator.Parent = workspace
	
	Log.Info(CONTEXT, string.format("%s placed bait", player.Name))
	
	-- Remove after 10 seconds
	task.delay(10, function()
		if feedIndicator and feedIndicator.Parent then
			feedIndicator:Destroy()
		end
	end)
end

--============================================================================
-- SCARE ACTION
--============================================================================

local function onScareAction(player: Player)
	local canDo, reason = canPerformAction(player, "SCARE")
	if not canDo then
		Log.Info(CONTEXT, string.format("%s cannot scare: %s", player.Name, reason))
		return
	end
	
	-- No item to consume for scare
	setCooldown(player, "SCARE")
	
	-- Get player position
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	-- TODO: Implement actual scare mechanics (affect nearby animals)
	-- For now, create a visual/audio indicator
	local scareRadius = 15
	
	-- Visual ring effect
	local scareRing = Instance.new("Part")
	scareRing.Name = "ScareRing"
	scareRing.Shape = Enum.PartType.Cylinder
	scareRing.Size = Vector3.new(0.2, scareRadius * 2, scareRadius * 2)
	scareRing.Color = Color3.fromRGB(200, 100, 255)  -- Purple
	scareRing.Material = Enum.Material.Neon
	scareRing.Transparency = 0.5
	scareRing.Anchored = true
	scareRing.CanCollide = false
	scareRing.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, math.rad(90))
	scareRing.Parent = workspace
	
	Log.Info(CONTEXT, string.format("%s used scare", player.Name))
	
	-- Fade out and remove
	task.spawn(function()
		for i = 1, 10 do
			task.wait(0.05)
			scareRing.Transparency = 0.5 + (i * 0.05)
		end
		scareRing:Destroy()
	end)
end

--============================================================================
-- EVENT CONNECTIONS
--============================================================================

RemoteEvents.FeedEvent.OnServerEvent:Connect(onFeedAction)
RemoteEvents.ScareEvent.OnServerEvent:Connect(onScareAction)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player: Player)
	playerCooldowns[player] = nil
end)

Log.Info(CONTEXT, "ActionServer initialized")
