# Player Data Systems

This document covers the Inventory and Achievements systems, including how to use, extend, and integrate them.

## Overview

The player data systems consist of three main components:

1. **Inventory System** - Tracks items players own (ammo, food, tools, materials)
2. **Achievements System** - Tracks stats, XP, levels, and achievement progress
3. **Player Data Service** - Handles persistence via DataStore

```
src/
├── shared/data/
│   ├── PlayerDataTypes.luau    # Type definitions
│   ├── ItemRegistry.luau       # Item definitions
│   └── AchievementRegistry.luau # Achievement definitions
└── server/Player/
    ├── InventoryService.luau   # Inventory management
    ├── AchievementsService.luau # Stats & achievements
    ├── PlayerDataService.luau  # Persistence layer
    └── PlayerDataInit.server.luau # Initialization
```

---

## Inventory System

### Item Categories

| Category   | Description                        |
|------------|-----------------------------------|
| Ammo       | Ammunition for weapons            |
| Food       | Consumables for health/stamina    |
| Tools      | Usable equipment                  |
| Materials  | Crafting/building resources       |
| Special    | Unique or event items             |

### API Reference

```lua
local InventoryService = require(ServerScriptService.Server.Player.InventoryService)

-- Add items to player's inventory
local success, message = InventoryService.AddItem(player, "AMMO_BASIC", 50)

-- Remove items from inventory
local success, message = InventoryService.RemoveItem(player, "AMMO_BASIC", 10)

-- Check if player has item
local hasItem = InventoryService.HasItem(player, "AMMO_BASIC", 5)  -- at least 5

-- Get quantity of specific item
local count = InventoryService.GetItemQuantity(player, "AMMO_BASIC")

-- Get all items in a category
local ammoItems = InventoryService.GetItemsByCategory(player, "Ammo")

-- Get full inventory
local inventory = InventoryService.GetInventory(player)
```

### Adding New Items

Edit `src/shared/data/ItemRegistry.luau`:

```lua
ItemRegistry.Items = {
    -- Add your new item here
    NEW_ITEM_ID = {
        ID = "NEW_ITEM_ID",           -- Unique identifier
        Name = "Display Name",         -- Shown to players
        Category = "Tools",            -- One of: Ammo, Food, Tools, Materials, Special
        Description = "What it does",  -- Tooltip text
        MaxStack = 10,                 -- Max quantity per stack (use large number for unlimited)
        Tradeable = true,              -- Can be traded between players
        Consumable = false,            -- Is used up when activated
    },
}
```

### Inventory Limits

- Default max slots: 20 (configurable per player)
- Each unique item type takes one slot
- Stack limits are per-item (defined in ItemRegistry)

---

## Achievements System

### Stat Tracking

The system automatically tracks these player stats:

| Stat                 | Description                          |
|----------------------|--------------------------------------|
| TotalCaptures        | Animals captured (lifetime)          |
| TotalKills           | Enemies defeated                     |
| TotalDeaths          | Times player died                    |
| TotalWins            | Games won                            |
| TotalLosses          | Games lost                           |
| TotalGamesPlayed     | Total matches played                 |
| TotalPlayTime        | Time spent playing (seconds)         |
| ExperiencePoints     | Current XP                           |
| Level                | Current level                        |
| CapturedAnimalIndex  | Which animal types have been caught  |
| AnimalCaptureCount   | Count per animal type                |

### XP & Leveling

- XP required per level increases exponentially
- Formula: `XP_PER_LEVEL * (XP_SCALE_FACTOR ^ (level - 1))`
- Default: 100 XP for level 2, ~150 for level 3, ~225 for level 4, etc.

### Achievement Categories

| Category    | Description                           |
|-------------|---------------------------------------|
| Capture     | Capturing animals                     |
| Combat      | Fighting and defeating enemies        |
| Exploration | Discovering new areas/content         |
| Social      | Playing with others                   |
| Milestones  | General progression (wins, levels)    |
| Collection  | Collecting all of something           |

### API Reference

```lua
local AchievementsService = require(ServerScriptService.Server.Player.AchievementsService)

-- Add XP (handles level ups automatically)
local newLevel, didLevelUp = AchievementsService.AddXP(player, 100)

-- Increment a stat (auto-updates related achievements)
AchievementsService.IncrementStat(player, "TotalWins", 1)

-- Record an animal capture (updates captures + collection achievements)
AchievementsService.RecordAnimalCapture(player, "RR01")

-- Update achievement progress directly
AchievementsService.UpdateProgress(player, "CAPTURE_10", currentCaptures)

-- Check if achievement is completed
local completed = AchievementsService.IsAchievementCompleted(player, "WIN_FIRST")

-- Get achievement progress (0-1)
local progress = AchievementsService.GetAchievementProgress(player, "CAPTURE_100")

-- Get player stats
local stats = AchievementsService.GetStats(player)
print("Level:", stats.Level, "XP:", stats.ExperiencePoints)

-- Subscribe to achievement completions
AchievementsService.OnAchievementCompleted(function(player, achievementID, achievementDef)
    print(player.Name, "unlocked", achievementDef.Name)
end)
```

### Adding New Achievements

Edit `src/shared/data/AchievementRegistry.luau`:

```lua
AchievementRegistry.Achievements = {
    NEW_ACHIEVEMENT_ID = {
        ID = "NEW_ACHIEVEMENT_ID",
        Name = "Achievement Name",
        Description = "How to unlock this",
        Category = "Milestones",        -- See categories above
        TargetValue = 10,               -- Value needed to complete
        RewardXP = 100,                 -- XP awarded on completion
        RewardItems = {                 -- Optional: items awarded
            AMMO_BASIC = 50,
            TOOL_TRAP = 2,
        },
        Hidden = false,                 -- Hidden until unlocked?
        Repeatable = false,             -- Can be completed multiple times?
    },
}
```

### Triggering Achievement Progress

For custom achievements, call `UpdateProgress` when the relevant action occurs:

```lua
-- In your game code
local AchievementsService = require(...)

-- Player did something 5 times
AchievementsService.UpdateProgress(player, "MY_ACHIEVEMENT", 5)
```

---

## Persistence (PlayerDataService)

### How It Works

1. **Player Joins**: Data loaded from DataStore (or created if new)
2. **During Game**: Data stored in memory, services update it
3. **Auto-Save**: Every 2 minutes, all player data is saved
4. **Player Leaves**: Data saved immediately
5. **Server Shutdown**: All data saved via `BindToClose`

### Data Structure

```lua
PlayerData = {
    Version = 1,                    -- Schema version for migrations
    Inventory = { Items = {...} },  -- Player's items
    Stats = { ... },                -- All player stats
    Achievements = { ... },         -- Achievement progress
    LastSaved = 1234567890,         -- Unix timestamp
}
```

### Studio Mode

In Studio without DataStore access:
- Data is stored in memory only
- Warning logged: "DataStore unavailable (Studio mode?)"
- All features work, but data won't persist between sessions

### Manual Save

```lua
local PlayerDataService = require(ServerScriptService.Server.Player.PlayerDataService)

-- Save specific player
PlayerDataService.SavePlayer(player)

-- Save all players
PlayerDataService.SaveAll()
```

---

## Integration Examples

### Award Items on Game Win

```lua
-- In your game end logic
local InventoryService = require(...)
local AchievementsService = require(...)

local function onGameEnd(winningTeam)
    for _, player in winningTeam:GetPlayers() do
        -- Award items
        InventoryService.AddItem(player, "AMMO_BASIC", 25)
        
        -- Update stats (achievements auto-update)
        AchievementsService.IncrementStat(player, "TotalWins", 1)
        AchievementsService.IncrementStat(player, "TotalGamesPlayed", 1)
    end
end
```

### Check Inventory Before Action

```lua
-- Player tries to shoot
local function onShoot(player)
    if not InventoryService.HasItem(player, "AMMO_BASIC", 1) then
        -- No ammo!
        return false
    end
    
    InventoryService.RemoveItem(player, "AMMO_BASIC", 1)
    -- ... do the shooting
    return true
end
```

### Display Achievement Notification (Client)

```lua
-- In a client controller
RemoteEvents.AchievementUnlockedEvent.OnClientEvent:Connect(function(achievementID, achievementName)
    -- Show notification UI
    showAchievementPopup(achievementName)
end)
```

---

## Remote Events

| Event                    | Direction      | Data                              |
|--------------------------|---------------|-----------------------------------|
| AchievementUnlockedEvent | Server→Client | achievementID, achievementName    |
| InventoryUpdatedEvent    | Server→Client | inventory table                   |
| StatsUpdatedEvent        | Server→Client | stats table                       |
| LevelUpEvent             | Server→Client | newLevel                          |

---

## Best Practices

1. **Use ItemRegistry IDs** - Always reference items by their ID constant, not strings
2. **Validate on Server** - Never trust client data; all inventory/achievement logic is server-side
3. **Batch Updates** - When giving multiple items, add them in a loop rather than one call per item
4. **Check Return Values** - `AddItem` and `RemoveItem` return success boolean and message
5. **Use Categories** - Organize items and achievements into categories for cleaner UI

---

## Current Content

### Items (ItemRegistry)

| ID            | Name              | Category  | Max Stack |
|---------------|-------------------|-----------|-----------|
| AMMO_BASIC    | Basic Bullets     | Ammo      | 100       |
| AMMO_TRANQ    | Tranquilizer Darts| Ammo      | 50        |
| AMMO_NET      | Capture Nets      | Ammo      | 10        |
| FOOD_APPLE    | Apple             | Food      | 20        |
| FOOD_MEAT     | Cooked Meat       | Food      | 10        |
| FOOD_BAIT     | Animal Bait       | Food      | 25        |
| TOOL_TRAP     | Portable Trap     | Tools     | 5         |
| TOOL_BINOCULARS | Binoculars      | Tools     | 1         |
| MAT_ROPE      | Rope              | Materials | 50        |
| MAT_WOOD      | Wood              | Materials | 100       |

### Achievements (AchievementRegistry)

| ID                   | Name                | Target | XP Reward |
|----------------------|---------------------|--------|-----------|
| CAPTURE_FIRST        | First Catch         | 1      | 50        |
| CAPTURE_10           | Novice Catcher      | 10     | 100       |
| CAPTURE_50           | Expert Catcher      | 50     | 250       |
| CAPTURE_100          | Master Catcher      | 100    | 500       |
| COLLECT_WHITE_ROVER  | White Rover Found   | 1      | 25        |
| COLLECT_BLUE_BOUNCER | Blue Bouncer Found  | 1      | 50        |
| COLLECT_YELLOW_CRAWLER | Yellow Crawler Found | 1   | 75        |
| COLLECT_ALL          | Gotta Catch 'Em All | 3      | 500       |
| WIN_FIRST            | Victory!            | 1      | 100       |
| WIN_10               | Winning Streak      | 10     | 300       |
| WIN_50               | Champion            | 50     | 1000      |
| GAMES_PLAYED_1       | Getting Started     | 1      | 25        |
| GAMES_PLAYED_25      | Regular Player      | 25     | 200       |
| GAMES_PLAYED_100     | Dedicated           | 100    | 500       |
| LEVEL_5              | Rising Star         | 5      | Items     |
| LEVEL_10             | Experienced         | 10     | Items     |
| LEVEL_25             | Veteran             | 25     | Items     |
