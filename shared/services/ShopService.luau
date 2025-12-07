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

-- Initialize with dependencies
function ShopService.Init(inventoryServiceRef: any): nil
	InventoryService = inventoryServiceRef
	Log.Info(CONTEXT, "ShopService initialized")
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
	
	local bundle = ShopRegistry.GetBundleByProductId(productId)
	if not bundle then
		Log.Warn(CONTEXT, string.format("Unknown product ID: %d", productId))
		return false
	end
	
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

-- Prompt Robux purchase
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

-- Get player's coin balance (convenience function)
function ShopService.GetPlayerCoins(player: Player): number
	if not InventoryService then
		return 0
	end
	return InventoryService.GetItemQuantity(player, "COIN")
end

return ShopService
