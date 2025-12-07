--!strict
-- InventoryService.luau
-- Shared server-side inventory management
-- Used by both Arena and Lobby places

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerDataTypes = require(Shared:WaitForChild("data"):WaitForChild("PlayerDataTypes"))
local ItemRegistry = require(Shared:WaitForChild("data"):WaitForChild("ItemRegistry"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "InventoryService"

local InventoryService = {}

-- In-memory storage (PlayerDataService handles persistence)
-- Using any to avoid cross-file type resolution issues in strict mode
local playerInventories: { [Player]: any } = {}

-- Broadcast inventory update to client
local function broadcastInventoryUpdate(player: Player): nil
	local inventory = playerInventories[player]
	if inventory then
		RemoteEvents.InventoryUpdatedEvent:FireClient(player, inventory)
	end
end

-- Initialize inventory for a player
function InventoryService.InitPlayer(player: Player, inventory: any?): nil
	playerInventories[player] = inventory or PlayerDataTypes.CreateDefaultInventory()
	Log.Info(CONTEXT, string.format("Initialized inventory for %s", player.Name))
end

-- Get player's inventory
function InventoryService.GetInventory(player: Player): any
	return playerInventories[player]
end

-- Clean up when player leaves
function InventoryService.CleanupPlayer(player: Player): nil
	playerInventories[player] = nil
end

-- Add item to player's inventory
function InventoryService.AddItem(player: Player, itemID: string, quantity: number): (boolean, string)
	local inventory = playerInventories[player]
	if not inventory then
		return false, "Inventory not initialized"
	end
	
	local itemDef = ItemRegistry.GetItem(itemID)
	if not itemDef then
		return false, "Invalid item ID: " .. itemID
	end
	
	-- Check if item already exists in inventory
	local existingItem = inventory.Items[itemID]
	if existingItem then
		-- Check max stack
		local newQuantity = existingItem.Quantity + quantity
		if itemDef.MaxStack and newQuantity > itemDef.MaxStack then
			return false, string.format("Would exceed max stack (%d)", itemDef.MaxStack)
		end
		existingItem.Quantity = newQuantity
	else
		-- Check slot limit
		local slotCount = 0
		for _ in inventory.Items do
			slotCount += 1
		end
		if inventory.MaxSlots and slotCount >= inventory.MaxSlots then
			return false, "Inventory full"
		end
		
		-- Add new item
		inventory.Items[itemID] = {
			ID = itemID,
			Category = itemDef.Category,
			Quantity = quantity,
			MaxStack = itemDef.MaxStack,
		}
	end
	
	Log.Info(CONTEXT, string.format("%s received %dx %s", player.Name, quantity, itemDef.Name))
	broadcastInventoryUpdate(player)
	return true, "Success"
end

-- Remove item from player's inventory
function InventoryService.RemoveItem(player: Player, itemID: string, quantity: number): (boolean, string)
	local inventory = playerInventories[player]
	if not inventory then
		return false, "Inventory not initialized"
	end
	
	local existingItem = inventory.Items[itemID]
	if not existingItem then
		return false, "Item not in inventory"
	end
	
	if existingItem.Quantity < quantity then
		return false, string.format("Insufficient quantity (have %d, need %d)", existingItem.Quantity, quantity)
	end
	
	existingItem.Quantity -= quantity
	
	-- Remove item entirely if quantity is 0
	if existingItem.Quantity <= 0 then
		inventory.Items[itemID] = nil
	end
	
	local itemDef = ItemRegistry.GetItem(itemID)
	local itemName = itemDef and itemDef.Name or itemID
	Log.Info(CONTEXT, string.format("%s used %dx %s", player.Name, quantity, itemName))
	broadcastInventoryUpdate(player)
	return true, "Success"
end

-- Check if player has item
function InventoryService.HasItem(player: Player, itemID: string, quantity: number?): boolean
	local inventory = playerInventories[player]
	if not inventory then return false end
	
	local item = inventory.Items[itemID]
	if not item then return false end
	
	return item.Quantity >= (quantity or 1)
end

-- Get quantity of specific item
function InventoryService.GetItemQuantity(player: Player, itemID: string): number
	local inventory = playerInventories[player]
	if not inventory then return 0 end
	
	local item = inventory.Items[itemID]
	return item and item.Quantity or 0
end

-- Get all items in a category
function InventoryService.GetItemsByCategory(player: Player, category: string): { any }
	local inventory = playerInventories[player]
	if not inventory then return {} end
	
	local result = {}
	for _, item in inventory.Items do
		if item.Category == category then
			table.insert(result, item)
		end
	end
	return result
end

return InventoryService
