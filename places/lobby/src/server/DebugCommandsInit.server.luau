--!strict
-- DebugCommandsInit.server.luau (Lobby)
-- Initializes shared debug commands with lobby-specific extensions

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DebugCommands = require(Shared:WaitForChild("util"):WaitForChild("DebugCommands"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "DebugCommands:Lobby"

-- Lazy load lobby-specific modules
local LobbyLuckyBlockService: any = nil
local function getLobbyLuckyBlockService()
	if not LobbyLuckyBlockService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.LobbyLuckyBlockService)
		end)
		if success then
			LobbyLuckyBlockService = service
		end
	end
	return LobbyLuckyBlockService
end

local PetBuilder: any = nil
local function getPetBuilder()
	if not PetBuilder then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.PetBuilder)
		end)
		if success then
			PetBuilder = service
		end
	end
	return PetBuilder
end

local PetFollowService: any = nil
local function getPetFollowService()
	if not PetFollowService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.PetFollowService)
		end)
		if success then
			PetFollowService = service
		end
	end
	return PetFollowService
end

local FavoriteAnimalsService: any = nil
local function getFavoriteAnimalsService()
	if not FavoriteAnimalsService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.FavoriteAnimalsService)
		end)
		if success then
			FavoriteAnimalsService = service
		end
	end
	return FavoriteAnimalsService
end

local MatchmakingZoneService: any = nil
local function getMatchmakingZoneService()
	if not MatchmakingZoneService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.MatchmakingZoneService)
		end)
		if success then
			MatchmakingZoneService = service
		end
	end
	return MatchmakingZoneService
end

-- Show lobby-specific help
local function showLobbyHelp(player: Player)
	Log.Info(CONTEXT, "-- LOBBY-SPECIFIC COMMANDS --")
	Log.Info(CONTEXT, "")
	Log.Info(CONTEXT, "Lucky Blocks:")
	Log.Info(CONTEXT, "  /spawnluckyblock [rarity] - Spawn lucky block for you")
	Log.Info(CONTEXT, "  /giveluckyblock [rarity] - Give yourself a lucky block item")
	Log.Info(CONTEXT, "")
	Log.Info(CONTEXT, "Pets:")
	Log.Info(CONTEXT, "  /setactivepet <animalID> - Set your active pet")
	Log.Info(CONTEXT, "  /clearpet - Remove your active pet")
	Log.Info(CONTEXT, "")
	Log.Info(CONTEXT, "Favorites:")
	Log.Info(CONTEXT, "  /addfavorite <animalID> - Add animal to favorites")
	Log.Info(CONTEXT, "  /removefavorite <slot> - Remove favorite from slot")
	Log.Info(CONTEXT, "  /listfavorites - Show your favorite animals")
	Log.Info(CONTEXT, "")
	Log.Info(CONTEXT, "Matchmaking:")
	Log.Info(CONTEXT, "  /joinqueue [mode] - Join matchmaking queue")
	Log.Info(CONTEXT, "  /leavequeue - Leave matchmaking queue")
	Log.Info(CONTEXT, "  /queuestatus - Show queue status")
end

-- Lobby-specific command handler
local function handleLobbyCommand(player: Player, message: string, lowerMessage: string)
	-- /debughelplobby - show lobby-specific commands only
	if lowerMessage == "/debughelplobby" then
		showLobbyHelp(player)
		return
	end
	
	-- /spawnluckyblock [rarity] - spawn a lucky block for the player
	local spawnLuckyMatch = lowerMessage:match("^/spawnluckyblock%s*(%w*)$")
	if lowerMessage == "/spawnluckyblock" or spawnLuckyMatch then
		local luckyBlockSvc = getLobbyLuckyBlockService()
		if luckyBlockSvc then
			local rarity = if spawnLuckyMatch and #spawnLuckyMatch > 0 then spawnLuckyMatch else nil
			local success = luckyBlockSvc.SpawnLuckyBlockForPlayer(player, rarity)
			if success then
				Log.Info(CONTEXT, string.format("%s spawned lucky block (rarity: %s)", player.Name, rarity or "random"))
			else
				Log.Warn(CONTEXT, string.format("Failed to spawn lucky block for %s", player.Name))
			end
		else
			Log.Warn(CONTEXT, "LobbyLuckyBlockService not available")
		end
		return
	end
	
	-- /giveluckyblock [rarity] - give player a free lucky block item
	local giveLuckyMatch = lowerMessage:match("^/giveluckyblock%s*(%w*)$")
	if lowerMessage == "/giveluckyblock" or giveLuckyMatch then
		local rarity = giveLuckyMatch or "rare"
		rarity = rarity:lower()
		
		local itemID = "LUCKY_RARE"
		if rarity == "veryrare" or rarity == "very_rare" then
			itemID = "LUCKY_VERYRARE"
		elseif rarity == "ultrarare" or rarity == "ultra_rare" then
			itemID = "LUCKY_ULTRARARE"
		end
		
		local InventoryService = require(Shared:WaitForChild("services"):WaitForChild("InventoryService"))
		local success, msg = InventoryService.AddItem(player, itemID, 1)
		if success then
			Log.Info(CONTEXT, string.format("%s granted %s to self", player.Name, itemID))
		else
			Log.Warn(CONTEXT, string.format("Failed to grant %s: %s", itemID, msg or "unknown"))
		end
		return
	end
	
	-- /setactivepet <animalID> - set active pet
	local setPetMatch = lowerMessage:match("^/setactivepet%s+([%w_]+)$")
	if setPetMatch then
		local petFollowSvc = getPetFollowService()
		if petFollowSvc and petFollowSvc.SetActivePet then
			petFollowSvc.SetActivePet(player, setPetMatch:upper())
			Log.Info(CONTEXT, string.format("%s set active pet to %s", player.Name, setPetMatch:upper()))
		end
		return
	end
	
	-- /clearpet - remove active pet
	if lowerMessage == "/clearpet" then
		local petFollowSvc = getPetFollowService()
		if petFollowSvc and petFollowSvc.ClearActivePet then
			petFollowSvc.ClearActivePet(player)
			Log.Info(CONTEXT, string.format("%s cleared active pet", player.Name))
		end
		return
	end
	
	-- /addfavorite <animalID>
	local addFavMatch = lowerMessage:match("^/addfavorite%s+([%w_]+)$")
	if addFavMatch then
		local favSvc = getFavoriteAnimalsService()
		if favSvc and favSvc.AddAnimalToIndex then
			local success = favSvc.AddAnimalToIndex(player, addFavMatch:upper())
			if success then
				Log.Info(CONTEXT, string.format("%s added %s to favorites", player.Name, addFavMatch:upper()))
			else
				Log.Warn(CONTEXT, string.format("Failed to add %s to favorites", addFavMatch:upper()))
			end
		end
		return
	end
	
	-- /removefavorite <slot>
	local removeFavMatch = lowerMessage:match("^/removefavorite%s+(%d+)$")
	if removeFavMatch then
		local slot = tonumber(removeFavMatch)
		if slot then
			local favSvc = getFavoriteAnimalsService()
			if favSvc and favSvc.RemoveAnimalFromSlot then
				favSvc.RemoveAnimalFromSlot(player, slot)
				Log.Info(CONTEXT, string.format("%s removed favorite from slot %d", player.Name, slot))
			end
		end
		return
	end
	
	-- /listfavorites
	if lowerMessage == "/listfavorites" then
		local favSvc = getFavoriteAnimalsService()
		if favSvc and favSvc.GetFavorites then
			local favorites = favSvc.GetFavorites(player)
			Log.Info(CONTEXT, string.format("=== %s's Favorite Animals ===", player.Name))
			if favorites and next(favorites) ~= nil then
				for slot = 1, 3 do
					local animalID = favorites[slot]
					if animalID then
						Log.Info(CONTEXT, string.format("  Slot %d: %s", slot, animalID))
					else
						Log.Info(CONTEXT, string.format("  Slot %d: (empty)", slot))
					end
				end
			else
				Log.Info(CONTEXT, "  No favorites set")
			end
		else
			Log.Warn(CONTEXT, "FavoriteAnimalsService or GetFavorites not available")
		end
		return
	end
	
	-- /joinqueue [mode]
	local joinQueueMatch = lowerMessage:match("^/joinqueue%s*(%w*)$")
	if lowerMessage == "/joinqueue" or joinQueueMatch then
		local matchSvc = getMatchmakingZoneService()
		if matchSvc and matchSvc.JoinQueue then
			local mode = if joinQueueMatch and #joinQueueMatch > 0 then joinQueueMatch else "default"
			matchSvc.JoinQueue(player, mode)
			Log.Info(CONTEXT, string.format("%s joined queue for mode: %s", player.Name, mode))
		end
		return
	end
	
	-- /leavequeue
	if lowerMessage == "/leavequeue" then
		local matchSvc = getMatchmakingZoneService()
		if matchSvc and matchSvc.LeaveQueue then
			matchSvc.LeaveQueue(player)
			Log.Info(CONTEXT, string.format("%s left matchmaking queue", player.Name))
		end
		return
	end
	
	-- /queuestatus
	if lowerMessage == "/queuestatus" then
		local matchSvc = getMatchmakingZoneService()
		if matchSvc and matchSvc.GetQueueStatus then
			local status = matchSvc.GetQueueStatus()
			Log.Info(CONTEXT, "Queue Status:")
			Log.Info(CONTEXT, string.format("  Total in queue: %d", status.TotalPlayers or 0))
		end
		return
	end
end

-- Register lobby services and initialize
DebugCommands.RegisterServices({
	PetBuilder = getPetBuilder(),
	handleCommand = handleLobbyCommand,
	showPlaceHelp = showLobbyHelp,
})

DebugCommands.Init()

Log.Info(CONTEXT, "Lobby debug commands initialized. Type /debughelp to see all commands.")
