--!strict
-- GameEndConfig.luau
-- Configuration for game end rewards and calculations

local GameEndConfig = {}

-- Coin reward multipliers
GameEndConfig.WINNER_COIN_MULTIPLIER = 1.0    -- Winners get 100% of team score as coins
GameEndConfig.LOSER_COIN_MULTIPLIER = 0.25    -- Losers get 25% of team score as coins

-- Bonus multipliers (applied to coin rewards)
-- These can be modified by achievements or special animals
GameEndConfig.Bonuses = {
	-- Achievement-based bonuses (achievement ID -> multiplier bonus)
	-- e.g., having "WIN_10" achievement gives +10% coin bonus
	ACHIEVEMENT_BONUSES = {
		WIN_10 = 0.10,       -- +10% coins
		WIN_50 = 0.25,       -- +25% coins
		CAPTURE_100 = 0.15,  -- +15% coins
		LEVEL_10 = 0.05,     -- +5% coins
		LEVEL_25 = 0.15,     -- +15% coins
	},
	
	-- Special animal bonuses (animal ID -> multiplier bonus when in capture index)
	SPECIAL_ANIMAL_BONUSES = {
		-- Add special/rare animals here that give coin bonuses
		-- e.g., RARE_GOLDEN_DRAGON = 0.50  -- +50% coins if you've ever captured it
	},
}

-- Freeze duration before showing results (seconds)
GameEndConfig.FREEZE_DURATION = 2.0

-- Time to show results before allowing game reset (seconds)
GameEndConfig.RESULTS_DISPLAY_DURATION = 10.0

return GameEndConfig
