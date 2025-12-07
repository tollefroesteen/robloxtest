--!strict
-- GameEndConfig.luau
-- Configuration for game end rewards and calculations

local GameEndConfig = {}

-- Coin reward multipliers
GameEndConfig.WINNER_COIN_MULTIPLIER = 1.0    -- Winners get 100% of team score as coins
GameEndConfig.LOSER_COIN_MULTIPLIER = 0.25    -- Losers get 25% of team score as coins
GameEndConfig.MINIMUM_LOSER_COINS = 0         -- Minimum coins losers receive (consolation)

-- Bonus multipliers (applied to coin rewards)
-- Achievement bonuses are now defined in AchievementRegistry (CoinBonus field)
GameEndConfig.Bonuses = {
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
