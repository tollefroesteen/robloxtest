--!strict
-- ItemRegistry.luau
-- Central registry of all items in the game
-- Add new items here to make them available in the inventory system

local ItemRegistry = {}

export type ItemDefinition = {
	ID: string,
	Name: string,
	Category: string,
	Description: string,
	MaxStack: number,
	Tradeable: boolean,
	Consumable: boolean,
}

-- Item categories
ItemRegistry.Categories = {
	Ammo = "Ammo",
	Food = "Food",
	Tools = "Tools",
	Materials = "Materials",
	Special = "Special",
}

-- All item definitions
ItemRegistry.Items = {
	-- Ammunition
	AMMO_BASIC = {
		ID = "AMMO_BASIC",
		Name = "Basic Bullets",
		Category = "Ammo",
		Description = "Standard ammunition for basic weapons",
		MaxStack = 100,
		Tradeable = true,
		Consumable = true,
	},
	AMMO_TRANQ = {
		ID = "AMMO_TRANQ",
		Name = "Tranquilizer Darts",
		Category = "Ammo",
		Description = "Non-lethal darts for capturing animals",
		MaxStack = 50,
		Tradeable = true,
		Consumable = true,
	},
	AMMO_NET = {
		ID = "AMMO_NET",
		Name = "Capture Nets",
		Category = "Ammo",
		Description = "Throwable nets for trapping animals",
		MaxStack = 10,
		Tradeable = true,
		Consumable = true,
	},
	
	-- Food
	FOOD_APPLE = {
		ID = "FOOD_APPLE",
		Name = "Apple",
		Category = "Food",
		Description = "Restores a small amount of stamina",
		MaxStack = 20,
		Tradeable = true,
		Consumable = true,
	},
	FOOD_MEAT = {
		ID = "FOOD_MEAT",
		Name = "Cooked Meat",
		Category = "Food",
		Description = "Restores health and stamina",
		MaxStack = 10,
		Tradeable = true,
		Consumable = true,
	},
	FOOD_BAIT = {
		ID = "FOOD_BAIT",
		Name = "Animal Bait",
		Category = "Food",
		Description = "Attracts nearby animals",
		MaxStack = 25,
		Tradeable = true,
		Consumable = true,
	},
	
	-- Tools
	TOOL_TRAP = {
		ID = "TOOL_TRAP",
		Name = "Portable Trap",
		Category = "Tools",
		Description = "A placeable trap for catching animals",
		MaxStack = 5,
		Tradeable = true,
		Consumable = true,
	},
	TOOL_BINOCULARS = {
		ID = "TOOL_BINOCULARS",
		Name = "Binoculars",
		Category = "Tools",
		Description = "See animals from far away",
		MaxStack = 1,
		Tradeable = false,
		Consumable = false,
	},
	
	-- Materials
	MAT_ROPE = {
		ID = "MAT_ROPE",
		Name = "Rope",
		Category = "Materials",
		Description = "Used for crafting traps and nets",
		MaxStack = 50,
		Tradeable = true,
		Consumable = false,
	},
	MAT_WOOD = {
		ID = "MAT_WOOD",
		Name = "Wood",
		Category = "Materials",
		Description = "Basic building material",
		MaxStack = 100,
		Tradeable = true,
		Consumable = false,
	},
	
	-- Currency
	COIN = {
		ID = "COIN",
		Name = "Coins",
		Category = "Special",
		Description = "In-game currency earned from winning games",
		MaxStack = 999999,
		Tradeable = false,
		Consumable = false,
	},
}

-- Get item definition by ID
function ItemRegistry.GetItem(itemID: string): ItemDefinition?
	return ItemRegistry.Items[itemID]
end

-- Get all items in a category
function ItemRegistry.GetItemsByCategory(category: string): { ItemDefinition }
	local result = {}
	for _, item in ItemRegistry.Items do
		if item.Category == category then
			table.insert(result, item)
		end
	end
	return result
end

-- Check if an item exists
function ItemRegistry.Exists(itemID: string): boolean
	return ItemRegistry.Items[itemID] ~= nil
end

return ItemRegistry
