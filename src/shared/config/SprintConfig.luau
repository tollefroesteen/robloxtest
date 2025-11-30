--!strict
-- SprintConfig.luau
-- Shared sprint configuration constants for both server and client

local SprintConfig = {}

-- Movement speeds
SprintConfig.NORMAL_SPEED = 17
SprintConfig.SPRINT_SPEED = 30

-- Stamina system
SprintConfig.MAX_STAMINA = 100
SprintConfig.STAMINA_DRAIN_RATE = 15      -- points per second while sprinting
SprintConfig.STAMINA_RECOVERY_RATE = 10   -- points per second while not sprinting

-- Client-side thresholds
SprintConfig.RESUME_THRESHOLD = 20        -- stamina needed to resume sprinting

-- Server update timing
SprintConfig.UPDATE_INTERVAL = 0.2        -- seconds between server updates (throttled)

return SprintConfig
