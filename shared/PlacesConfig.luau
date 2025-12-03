--!strict
-- PlacesConfig.luau
-- Shared configuration for all place IDs in the game
-- Update these values after publishing each place

local PlacesConfig = {}

-- Place IDs (set these after publishing each place in Roblox)
-- To find a place ID: Open in Studio → File → Game Settings → Basic Info → Place ID
PlacesConfig.LOBBY_PLACE_ID = 92585011660620      -- TODO: Set after publishing lobby
PlacesConfig.ARENA_PLACE_ID = 136622551290334      -- TODO: Set after publishing arena

-- Universe ID (same for all places in the game)
PlacesConfig.UNIVERSE_ID = 0         -- TODO: Set after publishing

-- Place metadata
PlacesConfig.Places = {
	Lobby = {
		ID = PlacesConfig.LOBBY_PLACE_ID,
		Name = "Lobby",
		Description = "Main hub for matchmaking and shop",
	},
	Arena = {
		ID = PlacesConfig.ARENA_PLACE_ID,
		Name = "Arena",
		Description = "Main gameplay area",
	},
}

-- Helper to check if place IDs are configured
function PlacesConfig.IsConfigured(): boolean
	return PlacesConfig.LOBBY_PLACE_ID ~= 0 and PlacesConfig.ARENA_PLACE_ID ~= 0
end

-- Helper to get current place type
function PlacesConfig.GetCurrentPlaceType(): string?
	local currentPlaceId = game.PlaceId
	if currentPlaceId == PlacesConfig.LOBBY_PLACE_ID then
		return "Lobby"
	elseif currentPlaceId == PlacesConfig.ARENA_PLACE_ID then
		return "Arena"
	end
	return nil
end

return PlacesConfig
