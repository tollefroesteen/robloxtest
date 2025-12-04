--!strict
-- GameTimerConfig.luau
-- Shared game timer configuration constants for both server and client

local GameTimerConfig = {}

-- Timer duration in seconds
GameTimerConfig.DURATION = 180 -- 3 minutes

-- Update interval in seconds (how often to send timer updates to clients)
GameTimerConfig.UPDATE_INTERVAL = 1

-- Time given to remaining team when opposing team abandons (all players leave)
GameTimerConfig.ABANDONMENT_TIME = 30 -- 30 seconds to finish up

return GameTimerConfig
