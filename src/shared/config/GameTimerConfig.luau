--!strict
-- GameTimerConfig.luau
-- Shared game timer configuration constants for both server and client

local GameTimerConfig = {}

-- Timer duration in seconds
GameTimerConfig.DURATION = 180 -- 3 minutes

-- Update interval in seconds (how often to send timer updates to clients)
GameTimerConfig.UPDATE_INTERVAL = 1

return GameTimerConfig
