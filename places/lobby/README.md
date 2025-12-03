# Lobby Place

The lobby is the entry point for players joining the game. It provides a hub for viewing stats, accessing the shop, and queuing for matches.

## Overview

| Feature | Status | Description |
|---------|--------|-------------|
| Stats Display | ✅ Basic | Shows player level, XP, wins, captures |
| Play Button | ✅ Basic | Teleports player to arena |
| Shop | 🔜 Planned | Purchase items with coins |
| Matchmaking | 🔜 Planned | Queue system for balanced games |
| Leaderboards | 🔜 Planned | Global rankings display |

## Folder Structure

```
lobby/
├── default.project.json      -- Rojo project config
└── src/
    ├── client/
    │   ├── MainClient.client.luau      -- Client entry point
    │   └── LobbyUIController.luau      -- Main lobby UI
    ├── server/
    │   ├── MainServer.server.luau      -- Server entry point, teleport handling
    │   └── PlayerDataLoader.server.luau -- Loads player data for display
    └── shared/
        └── LobbyConfig.luau            -- Lobby configuration
```

## Configuration

Edit `src/shared/LobbyConfig.luau` to adjust lobby settings:

```lua
-- Matchmaking settings
LobbyConfig.MIN_PLAYERS_TO_START = 2      -- Minimum players to start a game
LobbyConfig.MAX_PLAYERS_PER_GAME = 8      -- Maximum players per match
LobbyConfig.QUEUE_COUNTDOWN_SECONDS = 10  -- Countdown after min players reached

-- UI settings  
LobbyConfig.SHOP_ENABLED = true           -- Show shop UI
LobbyConfig.LEADERBOARD_ENABLED = true    -- Show leaderboard
LobbyConfig.STATS_DISPLAY_ENABLED = true  -- Show player stats
```

## Setup

### 1. Configure Place IDs

Edit `shared/PlacesConfig.luau` (in the root shared folder) and set your place IDs:

```lua
PlacesConfig.LOBBY_PLACE_ID = 92585011660620  -- Your lobby place ID
PlacesConfig.ARENA_PLACE_ID = 136622551290334  -- Your arena place ID
PlacesConfig.UNIVERSE_ID = 111222333     -- Your universe/game ID
```

To find a place ID:
1. Open the place in Roblox Studio
2. Go to **File → Game Settings → Basic Info**
3. Copy the **Place ID** (not Universe ID)

### 2. Running the Lobby

```bash
cd places/lobby
rojo serve
```

Then open a `.rbxlx` file in Studio and connect to Rojo.

## Architecture

### Data Flow

```
Player joins lobby
    │
    ▼
PlayerDataLoader.server.luau
    │
    ├──► Loads data from DataStore (same keys as arena)
    │
    └──► Fires StatsUpdatedEvent, InventoryUpdatedEvent to client
           │
           ▼
    LobbyUIController.luau
           │
           └──► Updates UI display

Player clicks "Play"
    │
    ▼
LobbyUIController fires PlayRequestEvent
    │
    ▼
MainServer.server.luau
    │
    └──► TeleportService:Teleport(ARENA_PLACE_ID, player)
```

### Shared Code Access

The lobby accesses shared code from `../../shared/`:

| Path in ReplicatedStorage | Source | Contents |
|---------------------------|--------|----------|
| `Shared.data` | `shared/data/` | ItemRegistry, AchievementRegistry, etc. |
| `Shared.util` | `shared/util/` | Log utility |
| `Shared.RemoteEvents` | `shared/RemoteEvents.luau` | All remote events |
| `Shared.PlacesConfig` | `shared/PlacesConfig.luau` | Place IDs for teleportation |
| `Lobby` | `src/shared/` | LobbyConfig |

### Remote Events Used

| Event | Direction | Purpose |
|-------|-----------|---------|
| `PlayRequestEvent` | Client → Server | Request to join arena |
| `StatsUpdatedEvent` | Server → Client | Send player stats for display |
| `InventoryUpdatedEvent` | Server → Client | Send inventory for preview |

## UI Components

### Current: Basic Lobby UI

The `LobbyUIController.luau` creates a simple UI with:
- Title banner
- Player stats display (Level, XP, Wins, etc.)
- Play button

### Planned Enhancements

1. **Shop Panel**
   - Browse items by category
   - Purchase with coins
   - Preview items before buying

2. **Matchmaking Queue**
   - Join queue button
   - Player count display
   - Countdown timer
   - Cancel queue option

3. **Leaderboards**
   - Top players by captures
   - Top players by wins
   - Top players by level

4. **Player Profile**
   - Achievement showcase
   - Animal collection display
   - Customization options

## Teleportation

### From Lobby to Arena

```lua
TeleportService:Teleport(ARENA_PLACE_ID, player)
```

### From Arena back to Lobby (Future)

After a game ends, arena can teleport players back:

```lua
local LOBBY_PLACE_ID = 987654321
TeleportService:Teleport(LOBBY_PLACE_ID, player)
```

### Teleport Data (Future)

Pass data between places using `TeleportOptions`:

```lua
local teleportOptions = Instance.new("TeleportOptions")
teleportOptions:SetTeleportData({
    fromLobby = true,
    queueId = "match_123",
})
TeleportService:TeleportAsync(ARENA_PLACE_ID, {player}, teleportOptions)
```

Receive in arena:
```lua
local teleportData = player:GetJoinData().TeleportData
if teleportData and teleportData.fromLobby then
    -- Player came from lobby
end
```

## Development Workflow

### Testing Locally

1. **Lobby Only**: Run `rojo serve` in `places/lobby/` and test UI
2. **Full Flow**: Publish both places, set place IDs, test teleportation

### Adding New Features

1. **New UI Component**: Add controller in `src/client/`
2. **New Server Logic**: Add script in `src/server/`
3. **New Config Option**: Add to `LobbyConfig.luau`
4. **New Remote Event**: Add to `shared/RemoteEvents.luau` (affects both places)

## Troubleshooting

### "Arena place ID not configured in PlacesConfig!"
Set `ARENA_PLACE_ID` in `shared/PlacesConfig.luau` to your arena's place ID.

### Player data not showing
Ensure `PlayerDataLoader.server.luau` is loading from the same DataStore key that arena uses.

### Teleport fails
- Check that arena place is published and accessible
- Verify place ID is correct (not universe ID)
- Check player has permission to join the arena place

---

## Related Documentation

- [Main README](../../README.md) - Project overview
- [Player Data Systems](../../docs/PlayerDataSystems.md) - Inventory, achievements, shop
- [Arena Documentation](../arena/README.md) - Main gameplay place (if exists)
