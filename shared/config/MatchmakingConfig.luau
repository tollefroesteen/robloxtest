--!strict
-- MatchmakingConfig.luau
-- Configuration for the matchmaking system (1v1 and 2v2)

local MatchmakingConfig = {}

-- Countdown timing
MatchmakingConfig.COUNTDOWN_SECONDS = 10 -- Time before player is added to queue
MatchmakingConfig.TEAM_FORMATION_GRACE_PERIOD = 2 -- Extra seconds for team formation in 2v2

-- Queue expiration
MatchmakingConfig.QUEUE_ENTRY_TTL = 300 -- 5 minutes in MemoryStore
MatchmakingConfig.STALE_ENTRY_THRESHOLD = 120 -- Consider entry stale after 2 minutes

-- Matchmaking intervals
MatchmakingConfig.MATCHMAKING_TICK_INTERVAL = 1 -- How often to check for matches (seconds)
MatchmakingConfig.QUEUE_CLEANUP_INTERVAL = 30 -- How often to clean stale entries

-- Zone configuration (cylinders)
MatchmakingConfig.ZONE_RADIUS = 6 -- Radius of trigger cylinder
MatchmakingConfig.ZONE_HEIGHT = 20 -- Height of trigger cylinder

-- Multiple zones configuration
MatchmakingConfig.NUM_1V1_ZONES = 3 -- Number of 1v1 cylinders
MatchmakingConfig.NUM_2V2_ZONES = 3 -- Number of 2v2 cylinders

-- Zone layout - zones arranged in two rows
-- 1v1 zones on one side (negative X), 2v2 zones on other side (positive X)
MatchmakingConfig.ZONE_1V1_BASE_POSITION = Vector3.new(-50, 0, 0) -- Center of 1v1 zone area
MatchmakingConfig.ZONE_2V2_BASE_POSITION = Vector3.new(50, 0, 0)  -- Center of 2v2 zone area
MatchmakingConfig.ZONE_SPACING = 40 -- Distance between zone centers (should be > ZONE_RADIUS * 2)
MatchmakingConfig.ZONE_ROW_OFFSET = 20 -- Distance between front and back rows

-- Match modes
export type MatchMode = "1v1" | "2v2"

-- Queue entry types
export type Solo1Entry = {
	type: "solo1",
	playerId: number,
	queuedAt: number,
	serverId: string,
}

export type Solo2Entry = {
	type: "solo2",
	playerId: number,
	queuedAt: number,
	serverId: string,
}

export type Team2Entry = {
	type: "team2",
	players: { number },
	queuedAt: number,
	serverId: string,
}

export type QueueEntry = Solo1Entry | Solo2Entry | Team2Entry

-- Teleport data sent to arena
export type TeleportData = {
	mode: MatchMode,
	teamA: { number },
	teamB: { number },
	matchId: string,
}

-- Queue names for MemoryStore
MatchmakingConfig.QUEUE_NAMES = {
	SOLO_1V1 = "Solo1Queue",
	SOLO_2V2 = "Solo2Queue",
	TEAM_2V2 = "Team2Queue",
}

return MatchmakingConfig
