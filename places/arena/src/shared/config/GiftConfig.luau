--!strict
-- GiftConfig.luau
-- Configuration for UFO gift/freebie spawning

local GiftConfig = {}

-- Spawn timing
GiftConfig.MIN_INTERVAL = 15.0    -- Minimum seconds between gift spawns
GiftConfig.MAX_INTERVAL = 30.0    -- Maximum seconds between gift spawns
GiftConfig.MAX_GIFTS = 5          -- Maximum gifts in world at once
GiftConfig.GIFT_LIFETIME = 60.0   -- Seconds before uncollected gift despawns

-- Gift appearance
GiftConfig.GIFT_SIZE = Vector3.new(2, 2, 2)
GiftConfig.GIFT_COLOR = Color3.fromRGB(255, 215, 0)  -- Gold
GiftConfig.GLOW_COLOR = Color3.fromRGB(255, 255, 150)

-- Possible gift contents (weight determines drop chance)
-- Higher weight = more common
GiftConfig.GiftTable = {
	-- Coins (most common)
	{ ItemID = "COIN", MinAmount = 5, MaxAmount = 25, Weight = 40 },
	{ ItemID = "COIN", MinAmount = 50, MaxAmount = 100, Weight = 10 },  -- Jackpot coins
	
	-- Ammo
	{ ItemID = "AMMO_BASIC", MinAmount = 10, MaxAmount = 30, Weight = 25 },
	{ ItemID = "AMMO_TRANQ", MinAmount = 5, MaxAmount = 15, Weight = 15 },
	{ ItemID = "AMMO_NET", MinAmount = 2, MaxAmount = 5, Weight = 8 },
	
	-- Food/Bait
	{ ItemID = "FOOD_BAIT", MinAmount = 3, MaxAmount = 10, Weight = 20 },
	{ ItemID = "FOOD_APPLE", MinAmount = 5, MaxAmount = 15, Weight = 15 },
	{ ItemID = "FOOD_MEAT", MinAmount = 2, MaxAmount = 8, Weight = 10 },
	
	-- Tools (rare)
	{ ItemID = "TOOL_SHIELD", MinAmount = 1, MaxAmount = 2, Weight = 5 },
	{ ItemID = "TOOL_TRAP", MinAmount = 1, MaxAmount = 2, Weight = 5 },
}

return GiftConfig
