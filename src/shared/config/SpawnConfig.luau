--!strict
-- SpawnConfig.luau
-- Shared configuration for UFO spawner pacing

local SpawnConfig = {
	INTERVAL = 10.0, -- seconds between spawn ticks
	BURST_SIZE = 1,  -- how many animals per tick
	MAX_CONCURRENT = 30, -- max animals allowed in workspace.Flock
	START_DELAY = 0.0, -- optional delay before first spawn after StartGame
}

return SpawnConfig
