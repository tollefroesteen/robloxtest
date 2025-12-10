--!strict
-- ShopService.luau
-- Shared server-side shop purchase handling
-- Used by both Arena and Lobby places

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopRegistry = require(Shared:WaitForChild("data"):WaitForChild("ShopRegistry"))
local ItemRegistry = require(Shared:WaitForChild("data"):WaitForChild("ItemRegistry"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "ShopService"

local ShopService = {}

-- References to other services (set during init)
local InventoryService: any = nil
local PlayerUpgradesService: any = nil
local LuckyBlockCallback: ((player: Player, shopItemID: string) -> boolean)? = nil

-- Initialize with dependencies
function ShopService.Init(inventoryServiceRef: any, upgradesServiceRef: any?): nil
	InventoryService = inventoryServiceRef
	
	-- Try to load PlayerUpgradesService if not provided
	if upgradesServiceRef then
		PlayerUpgradesService = upgradesServiceRef
	else
		local success, service = pcall(function()
			return require(Shared:WaitForChild("services"):WaitForChild("PlayerUpgradesService"))
		end)
		if success then
			PlayerUpgradesService = service
		end
	end
	
	Log.Info(CONTEXT, "ShopService initialized")
end

-- Set callback for Lucky Block purchases (lobby only)
function ShopService.SetLuckyBlockCallback(callback: (player: Player, shopItemID: string) -> boolean): nil
	LuckyBlockCallback = callback
	Log.Info(CONTEXT, "Lucky Block callback registered")
end

-- Purchase item with coins
function ShopService.PurchaseItem(player: Player, shopItemID: string): (boolean, string)
	if not InventoryService then
		return false, "Shop not initialized"
	end
	
	local shopItem = ShopRegistry.GetShopItem(shopItemID)
	if not shopItem then
		return false, "Invalid shop item"
	end
	
	local itemDef = ItemRegistry.GetItem(shopItem.ItemID)
	if not itemDef then
		return false, "Invalid item definition"
	end
	
	-- Check if this is a Lucky Block - handle specially
	if shopItem.Category == "LuckyBlocks" then
		if not LuckyBlockCallback then
			return false, "Lucky Blocks not available in this place"
		end
		
		-- Check if player has enough coins
		local currentCoins = InventoryService.GetItemQuantity(player, "COIN")
		if currentCoins < shopItem.CoinPrice then
			return false, string.format("Not enough coins (have %d, need %d)", currentCoins, shopItem.CoinPrice)
		end
		
		-- Deduct coins
		local coinSuccess, coinMsg = InventoryService.RemoveItem(player, "COIN", shopItem.CoinPrice)
		if not coinSuccess then
			return false, "Failed to deduct coins: " .. coinMsg
		end
		
		-- Call the lucky block callback to spawn and handle it
		local spawnSuccess = LuckyBlockCallback(player, shopItemID)
		if not spawnSuccess then
			-- Refund coins if spawn fails
			InventoryService.AddItem(player, "COIN", shopItem.CoinPrice)
			return false, "Failed to spawn Lucky Block"
		end
		
		Log.Info(CONTEXT, string.format("%s purchased %s for %d coins", 
			player.Name, itemDef.Name, shopItem.CoinPrice))
		
		-- Success handled by lucky block callback
		return true, "Lucky Block purchased"
	end
	
	-- Normal item purchase flow
	-- Check if player has enough coins
	local currentCoins = InventoryService.GetItemQuantity(player, "COIN")
	if currentCoins < shopItem.CoinPrice then
		return false, string.format("Not enough coins (have %d, need %d)", currentCoins, shopItem.CoinPrice)
	end
	
	-- Check if player can receive the item (stack limits, etc.)
	local currentQuantity = InventoryService.GetItemQuantity(player, shopItem.ItemID)
	local newQuantity = currentQuantity + shopItem.Quantity
	if itemDef.MaxStack and newQuantity > itemDef.MaxStack then
		return false, string.format("Would exceed max stack (%d/%d)", currentQuantity, itemDef.MaxStack)
	end
	
	-- Deduct coins
	local coinSuccess, coinMsg = InventoryService.RemoveItem(player, "COIN", shopItem.CoinPrice)
	if not coinSuccess then
		return false, "Failed to deduct coins: " .. coinMsg
	end
	
	-- Add purchased item
	local itemSuccess, itemMsg = InventoryService.AddItem(player, shopItem.ItemID, shopItem.Quantity)
	if not itemSuccess then
		-- Refund coins if item add fails
		InventoryService.AddItem(player, "COIN", shopItem.CoinPrice)
		return false, "Failed to add item: " .. itemMsg
	end
	
	Log.Info(CONTEXT, string.format("%s purchased %dx %s for %d coins", 
		player.Name, shopItem.Quantity, itemDef.Name, shopItem.CoinPrice))
	
	-- Notify client of successful purchase
	RemoteEvents.ShopPurchaseResultEvent:FireClient(player, true, shopItemID, shopItem.Quantity, itemDef.Name)
	
	return true, "Purchase successful"
end

-- Process Robux purchase (called from MarketplaceService callback)
function ShopService.ProcessRobuxPurchase(player: Player, productId: number): boolean
	if not InventoryService then
		Log.Warn(CONTEXT, "Shop not initialized for Robux purchase")
		return false
	end
	
	-- Check if it's a coin bundle
	local bundle = ShopRegistry.GetBundleByProductId(productId)
	if bundle then
		-- Add coins to player's inventory
		local success, msg = InventoryService.AddItem(player, "COIN", bundle.CoinAmount)
		if success then
			Log.Info(CONTEXT, string.format("%s purchased %d coins (Robux bundle: %s)", 
				player.Name, bundle.CoinAmount, bundle.Name))
			
			-- Notify client
			RemoteEvents.ShopPurchaseResultEvent:FireClient(player, true, bundle.ID, bundle.CoinAmount, "Coins")
			
			return true
		else
			Log.Warn(CONTEXT, string.format("Failed to add coins for %s: %s", player.Name, msg))
			return false
		end
	end
	
	-- Check if it's a permanent upgrade
	local upgrade = ShopRegistry.GetUpgradeByProductId(productId)
	if upgrade then
		if not PlayerUpgradesService then
			Log.Warn(CONTEXT, "PlayerUpgradesService not available for upgrade purchase")
			return false
		end
		
		-- Check if player already has this upgrade
		if upgrade.ID == "UPGRADE_HEAT_SEEKING_AMMO" then
			if PlayerUpgradesService.HasUpgrade(player, "HeatSeekingAmmo") then
				Log.Warn(CONTEXT, string.format("%s already has upgrade: %s", player.Name, upgrade.Name))
				-- Return true to prevent re-prompting purchase
				return true
			end
			
			-- Grant the upgrade
			local success = PlayerUpgradesService.GrantUpgrade(player, "HeatSeekingAmmo")
			if success then
				Log.Info(CONTEXT, string.format("%s purchased upgrade: %s", player.Name, upgrade.Name))
				
				-- Notify client
				RemoteEvents.ShopPurchaseResultEvent:FireClient(player, true, upgrade.ID, 1, upgrade.Name)
				
				return true
			else
				Log.Warn(CONTEXT, string.format("Failed to grant upgrade for %s: %s", player.Name, upgrade.Name))
				return false
			end
		end
	end
	
	Log.Warn(CONTEXT, string.format("Unknown product ID: %d", productId))
	return false
end

-- Prompt Robux purchase for coin bundle
function ShopService.PromptCoinBundlePurchase(player: Player, bundleID: string): (boolean, string)
	local bundle = ShopRegistry.GetCoinBundle(bundleID)
	if not bundle then
		return false, "Invalid bundle"
	end
	
	if not bundle.ProductId then
		return false, "Bundle not configured (no Product ID)"
	end
	
	-- Prompt the purchase through MarketplaceService
	local success, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, bundle.ProductId)
	end)
	
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to prompt purchase for %s: %s", player.Name, tostring(err)))
		return false, "Failed to open purchase dialog"
	end
	
	return true, "Purchase dialog opened"
end

-- Prompt Robux purchase for permanent upgrade
function ShopService.PromptUpgradePurchase(player: Player, upgradeID: string): (boolean, string)
	local upgrade = ShopRegistry.GetPermanentUpgrade(upgradeID)
	if not upgrade then
		return false, "Invalid upgrade"
	end
	
	if not upgrade.ProductId then
		return false, "Upgrade not configured (no Product ID)"
	end
	
	-- Check if player already has this upgrade
	if PlayerUpgradesService then
		if upgrade.ID == "UPGRADE_HEAT_SEEKING_AMMO" then
			if PlayerUpgradesService.HasUpgrade(player, "HeatSeekingAmmo") then
				return false, "You already own this upgrade!"
			end
		end
	end
	
	-- Prompt the purchase through MarketplaceService
	local success, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, upgrade.ProductId)
	end)
	
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to prompt upgrade purchase for %s: %s", player.Name, tostring(err)))
		return false, "Failed to open purchase dialog"
	end
	
	return true, "Purchase dialog opened"
end

-- Get player's coin balance (convenience function)
function ShopService.GetPlayerCoins(player: Player): number
	if not InventoryService then
		return 0
	end
	return InventoryService.GetItemQuantity(player, "COIN")
end

return ShopService
