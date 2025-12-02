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
    7321086050
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
	
	-- /debughelp - show available commands
	if lowerMessage == "/debughelp" then
		Log.Info(CONTEXT, "Debug commands: /grantcoins <amt>, /grantammo <amt>, /grantbait <amt>, /grantitem <id> <amt>")
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
