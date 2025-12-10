--!strict
-- ShopRegistry.luau
-- Central registry of all shop items and coin bundles

local ShopRegistry = {}

export type ShopItem = {
	ID: string,
	ItemID: string,          -- References ItemRegistry
	Quantity: number,        -- How many you get
	CoinPrice: number,       -- Price in coins
	Category: string,        -- Shop category for organization
	Featured: boolean?,      -- Show in featured section
	Discount: number?,       -- Discount percentage (0-100)
}

export type CoinBundle = {
	ID: string,
	Name: string,
	CoinAmount: number,      -- How many coins you get
	RobuxPrice: number,      -- Price in Robux
	BonusPercent: number?,   -- Bonus coins percentage
	ProductId: number?,      -- Roblox Developer Product ID (set in game)
	Featured: boolean?,
}

-- Shop categories
ShopRegistry.Categories = {
	Ammo = "Ammo",
	Food = "Food",
	Tools = "Tools",
	Materials = "Materials",
	Bundles = "Bundles",
	LuckyBlocks = "LuckyBlocks",
}

-- Items available for purchase with coins
ShopRegistry.Items = {
	-- Ammo
	SHOP_AMMO_BASIC_20 = {
		ID = "SHOP_AMMO_BASIC_20",
		ItemID = "AMMO_BASIC",
		Quantity = 20,
		CoinPrice = 10,
		Category = "Ammo",
	},
	SHOP_AMMO_BASIC_50 = {
		ID = "SHOP_AMMO_BASIC_50",
		ItemID = "AMMO_BASIC",
		Quantity = 50,
		CoinPrice = 20,
		Category = "Ammo",
		Discount = 20,  -- Better value
	},
	SHOP_AMMO_TRANQ_10 = {
		ID = "SHOP_AMMO_TRANQ_10",
		ItemID = "AMMO_TRANQ",
		Quantity = 10,
		CoinPrice = 25,
		Category = "Ammo",
	},
	SHOP_AMMO_TRANQ_25 = {
		ID = "SHOP_AMMO_TRANQ_25",
		ItemID = "AMMO_TRANQ",
		Quantity = 25,
		CoinPrice = 50,
		Category = "Ammo",
		Discount = 20,
	},
	SHOP_AMMO_NET_5 = {
		ID = "SHOP_AMMO_NET_5",
		ItemID = "AMMO_NET",
		Quantity = 5,
		CoinPrice = 40,
		Category = "Ammo",
	},
	
	-- Food
	SHOP_FOOD_APPLE_10 = {
		ID = "SHOP_FOOD_APPLE_10",
		ItemID = "FOOD_APPLE",
		Quantity = 10,
		CoinPrice = 15,
		Category = "Food",
	},
	SHOP_FOOD_MEAT_5 = {
		ID = "SHOP_FOOD_MEAT_5",
		ItemID = "FOOD_MEAT",
		Quantity = 5,
		CoinPrice = 25,
		Category = "Food",
	},
	SHOP_FOOD_BAIT_10 = {
		ID = "SHOP_FOOD_BAIT_10",
		ItemID = "FOOD_BAIT",
		Quantity = 10,
		CoinPrice = 30,
		Category = "Food",
		Featured = true,
	},
	
	-- Lucky Blocks
	SHOP_LUCKY_BLOCK_RARE = {
		ID = "SHOP_LUCKY_BLOCK_RARE",
		ItemID = "LUCKY_BLOCK_RARE",
		Quantity = 1,
		CoinPrice = 1,
		Category = "LuckyBlocks",
		Featured = true,
	},
	SHOP_LUCKY_BLOCK_VERY_RARE = {
		ID = "SHOP_LUCKY_BLOCK_VERY_RARE",
		ItemID = "LUCKY_BLOCK_VERY_RARE",
		Quantity = 1,
		CoinPrice = 1,
		Category = "LuckyBlocks",
		Featured = true,
	},
	SHOP_LUCKY_BLOCK_ULTRA_RARE = {
		ID = "SHOP_LUCKY_BLOCK_ULTRA_RARE",
		ItemID = "LUCKY_BLOCK_ULTRA_RARE",
		Quantity = 1,
		CoinPrice = 1,
		Category = "LuckyBlocks",
		Featured = true,
	},
	
	-- Tools
	SHOP_TOOL_TRAP_1 = {
		ID = "SHOP_TOOL_TRAP_1",
		ItemID = "TOOL_TRAP",
		Quantity = 1,
		CoinPrice = 50,
		Category = "Tools",
	},
	SHOP_TOOL_TRAP_3 = {
		ID = "SHOP_TOOL_TRAP_3",
		ItemID = "TOOL_TRAP",
		Quantity = 3,
		CoinPrice = 120,
		Category = "Tools",
		Discount = 20,
		Featured = true,
	},
	SHOP_TOOL_BINOCULARS = {
		ID = "SHOP_TOOL_BINOCULARS",
		ItemID = "TOOL_BINOCULARS",
		Quantity = 1,
		CoinPrice = 100,
		Category = "Tools",
	},
	SHOP_TOOL_SHIELD_1 = {
		ID = "SHOP_TOOL_SHIELD_1",
		ItemID = "TOOL_SHIELD",
		Quantity = 1,
		CoinPrice = 75,
		Category = "Tools",
	},
	SHOP_TOOL_SHIELD_3 = {
		ID = "SHOP_TOOL_SHIELD_3",
		ItemID = "TOOL_SHIELD",
		Quantity = 3,
		CoinPrice = 180,
		Category = "Tools",
		Discount = 20,
		Featured = true,
	},
	
	-- Materials
	SHOP_MAT_ROPE_20 = {
		ID = "SHOP_MAT_ROPE_20",
		ItemID = "MAT_ROPE",
		Quantity = 20,
		CoinPrice = 15,
		Category = "Materials",
	},
	SHOP_MAT_WOOD_50 = {
		ID = "SHOP_MAT_WOOD_50",
		ItemID = "MAT_WOOD",
		Quantity = 50,
		CoinPrice = 20,
		Category = "Materials",
	},
}

-- Coin bundles available for purchase with Robux
ShopRegistry.CoinBundles = {
	COINS_100 = {
		ID = "COINS_100",
		Name = "Coin Pouch",
		CoinAmount = 100,
		RobuxPrice = 49,
		ProductId = nil,  -- Set this to your Developer Product ID
	},
	COINS_500 = {
		ID = "COINS_500",
		Name = "Coin Bag",
		CoinAmount = 550,  -- 500 + 10% bonus
		RobuxPrice = 199,
		BonusPercent = 10,
		ProductId = nil,
	},
	COINS_1000 = {
		ID = "COINS_1000",
		Name = "Coin Chest",
		CoinAmount = 1200,  -- 1000 + 20% bonus
		RobuxPrice = 399,
		BonusPercent = 20,
		Featured = true,
		ProductId = nil,
	},
	COINS_5000 = {
		ID = "COINS_5000",
		Name = "Coin Vault",
		CoinAmount = 6500,  -- 5000 + 30% bonus
		RobuxPrice = 1699,
		BonusPercent = 30,
		Featured = true,
		ProductId = nil,
	},
}

-- Get shop item by ID
function ShopRegistry.GetShopItem(shopItemID: string): ShopItem?
	return ShopRegistry.Items[shopItemID]
end

-- Get coin bundle by ID
function ShopRegistry.GetCoinBundle(bundleID: string): CoinBundle?
	return ShopRegistry.CoinBundles[bundleID]
end

-- Get all items in a category
function ShopRegistry.GetItemsByCategory(category: string): { ShopItem }
	local result = {}
	for _, item in ShopRegistry.Items do
		if item.Category == category then
			table.insert(result, item)
		end
	end
	return result
end

-- Get featured items
function ShopRegistry.GetFeaturedItems(): { ShopItem }
	local result = {}
	for _, item in ShopRegistry.Items do
		if item.Featured then
			table.insert(result, item)
		end
	end
	return result
end

-- Get all coin bundles
function ShopRegistry.GetAllCoinBundles(): { CoinBundle }
	local result = {}
	for _, bundle in ShopRegistry.CoinBundles do
		table.insert(result, bundle)
	end
	-- Sort by price
	table.sort(result, function(a, b)
		return a.RobuxPrice < b.RobuxPrice
	end)
	return result
end

-- Get coin bundle by product ID
function ShopRegistry.GetBundleByProductId(productId: number): CoinBundle?
	for _, bundle in ShopRegistry.CoinBundles do
		if bundle.ProductId == productId then
			return bundle
		end
	end
	return nil
end

return ShopRegistry
