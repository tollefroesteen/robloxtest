--!strict
-- ShopServiceInit.server.luau
-- Initializes the shop service and handles purchase events

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopService = require(Shared:WaitForChild("services"):WaitForChild("ShopService"))
local InventoryService = require(Shared:WaitForChild("services"):WaitForChild("InventoryService"))
local ShopRegistry = require(Shared:WaitForChild("data"):WaitForChild("ShopRegistry"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local LobbyLuckyBlockService = require(script.Parent.LobbyLuckyBlockService)

local CONTEXT = "ShopServiceInit"

-- Initialize ShopService with dependencies
ShopService.Init(InventoryService)

-- Register Lucky Block callback
ShopService.SetLuckyBlockCallback(function(player: Player, shopItemID: string): boolean
	return LobbyLuckyBlockService.OnPurchaseRequest(player, shopItemID)
end)

-- Initialize Lucky Block service
LobbyLuckyBlockService.Initialize()

-- Handle coin purchase requests from client
RemoteEvents.ShopPurchaseRequestEvent.OnServerEvent:Connect(function(player: Player, shopItemID: string)
	local success, message = ShopService.PurchaseItem(player, shopItemID)
	if not success then
		-- Pass error message as itemName for display
		RemoteEvents.ShopPurchaseResultEvent:FireClient(player, false, shopItemID, 0, message)
	end
	-- Success is already handled in ShopService.PurchaseItem
end)

-- Handle Robux bundle purchase requests from client
RemoteEvents.ShopBuyCoinsRequestEvent.OnServerEvent:Connect(function(player: Player, bundleID: string)
	local success, message = ShopService.PromptCoinBundlePurchase(player, bundleID)
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to prompt coin purchase for %s: %s", player.Name, message))
	end
end)

-- Handle Robux upgrade purchase requests from client
RemoteEvents.ShopBuyUpgradeRequestEvent.OnServerEvent:Connect(function(player: Player, upgradeID: string)
	local success, message = ShopService.PromptUpgradePurchase(player, upgradeID)
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to prompt upgrade purchase for %s: %s", player.Name, message))
		-- Optionally notify client
		RemoteEvents.ShopPurchaseResultEvent:FireClient(player, false, upgradeID, 0, message)
	end
end)

-- Handle Developer Product purchases (Robux -> Coins)
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left, but we should still grant the purchase on next join
		-- For now, return NotProcessedYet so Roblox will retry
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Process the purchase
	local success = ShopService.ProcessRobuxPurchase(player, receiptInfo.ProductId)
	
	if success then
		Log.Info(CONTEXT, string.format("Processed Robux purchase for %s (ProductId: %d)", 
			player.Name, receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		Log.Warn(CONTEXT, string.format("Failed to process Robux purchase for %s (ProductId: %d)", 
			player.Name, receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

Log.Info(CONTEXT, "Shop system initialized")
