--!strict
-- LobbyConfig.luau
-- Lobby-specific configuration

local LobbyConfig = {}

-- Matchmaking settings
LobbyConfig.MIN_PLAYERS_TO_START = 2
LobbyConfig.MAX_PLAYERS_PER_GAME = 8
LobbyConfig.QUEUE_COUNTDOWN_SECONDS = 10

-- UI settings  
LobbyConfig.SHOP_ENABLED = true
LobbyConfig.LEADERBOARD_ENABLED = true
LobbyConfig.STATS_DISPLAY_ENABLED = true

return LobbyConfig
