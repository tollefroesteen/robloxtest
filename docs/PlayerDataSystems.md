# Player Data Systems

This document covers the Inventory and Achievements systems, including how to use, extend, and integrate them.

## Overview

The player data systems consist of three main components:

1. **Inventory System** - Tracks items players own (ammo, food, tools, materials, coins)
2. **Achievements System** - Tracks stats, XP, levels, and achievement progress
3. **Player Data Service** - Handles persistence via DataStore
4. **Shop System** - Purchase items with coins, buy coins with Robux

```
src/
├── shared/data/
│   ├── PlayerDataTypes.luau    # Type definitions
│   ├── ItemRegistry.luau       # Item definitions
│   ├── AchievementRegistry.luau # Achievement definitions
│   └── ShopRegistry.luau       # Shop items & coin bundles
└── server/Player/
    ├── InventoryService.luau   # Inventory management
    ├── AchievementsService.luau # Stats & achievements
    ├── PlayerDataService.luau  # Persistence layer
    ├── ShopService.luau        # Shop purchase handling
    ├── ShopServiceInit.server.luau # Shop initialization
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

### Default Starting Inventory

New players start with:

| Item       | Quantity | Purpose               |
|------------|----------|-----------------------|
| AMMO_BASIC | 50       | Basic ammunition      |
| FOOD_BAIT  | 10       | Animal bait for Feed  |

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

| Event                    | Direction      | Data                                        |
|--------------------------|---------------|---------------------------------------------|
| AchievementUnlockedEvent | Server→Client | achievementID, achievementName              |
| InventoryUpdatedEvent    | Server→Client | inventory table                             |
| StatsUpdatedEvent        | Server→Client | stats table                                 |
| LevelUpEvent             | Server→Client | newLevel                                    |
| CoinsAwardedEvent        | Server→Client | coinAmount (for animation only)             |
| ShopPurchaseRequestEvent | Client→Server | shopItemID                                  |
| ShopPurchaseResultEvent  | Server→Client | success, itemID, quantity, itemName/message |
| ShopBuyCoinsRequestEvent | Client→Server | bundleID                                    |

---

## Client UI Controllers

The following controllers handle displaying player data in the HUD:

### CoinsController (`src/client/ui/CoinsController.luau`)

Displays the player's coin count in the top-right corner of the screen.

**Features:**
- Shows current coin count from inventory
- Animates coin count changes with a brief highlight effect
- Listens to `InventoryUpdatedEvent` for real-time updates
- Listens to `CoinsAwardedEvent` for visual coin award animation

**Structure:**
```
┌─────────────────┐
│  🪙 1,234       │  ← Top-right corner
└─────────────────┘
```

### XPController (`src/client/ui/XPController.luau`)

Displays the player's XP progress bar and current level.

**Features:**
- Shows current level prominently
- Animated XP progress bar that fills as XP is gained
- Listens to `StatsUpdatedEvent` for real-time updates
- Level-up animation triggered by `LevelUpEvent`

**Structure:**
```
┌─────────────────────────────────┐
│ Lv. 12  [████████░░░░] 850/1000 │
└─────────────────────────────────┘
```

### AchievementNotificationController (`src/client/ui/AchievementNotificationController.luau`)

Displays popup notifications when achievements are unlocked.

**Features:**
- Slide-in animation from the right side of screen
- Auto-dismisses after 3 seconds
- Queue system for multiple achievements
- Listens to `AchievementUnlockedEvent`

**Structure:**
```
                    ┌───────────────────────┐
                    │ 🏆 Achievement!       │
                    │ First Catch           │ ← Slides in from right
                    └───────────────────────┘
```

### Data Flow

```
Server                              Client
──────                              ──────
AchievementsService.AddXP()
    │
    ├──► StatsUpdatedEvent ────────► XPController (updates bar)
    │
    └──► LevelUpEvent ─────────────► XPController (level-up animation)

AchievementsService.UnlockAchievement()
    │
    └──► AchievementUnlockedEvent ─► AchievementNotificationController (popup)

InventoryService.AddItem(COIN)
    │
    └──► InventoryUpdatedEvent ────► CoinsController (updates count)

GameEndService (awards coins)
    │
    └──► CoinsAwardedEvent ────────► CoinsController (animation only)
```

---

## Action System

The game features a multi-mode action button that players can cycle through.

### Action Modes

| Mode   | Required Item | Description                        |
|--------|---------------|------------------------------------|
| SHOOT  | AMMO_BASIC    | Fire projectile (consumes 1 ammo)  |
| FEED   | FOOD_BAIT     | Place bait to attract animals      |
| SCARE  | (none)        | Scare away nearby animals          |
| SHIELD | TOOL_SHIELD   | Activate protective shield         |

### How It Works

1. **Mode Button**: Players press to cycle through available modes
2. **Action Button**: Performs the current mode's action
3. **Item Check**: Button shows disabled if required item is missing
4. **Server Validation**: All actions are validated server-side

### Client Controller (`MenuController.luau`)

The action system lives in `src/client/ui/MenuController.luau`:

```lua
-- Action mode definition
type ActionMode = {
    ID: string,           -- Unique identifier
    Name: string,         -- Display name
    Icon: string,         -- Emoji/icon
    ItemID: string?,      -- Required inventory item (nil = no requirement)
    Color: Color3,        -- Button color when enabled
    DisabledText: string, -- Text shown when item missing
    OnActivate: () -> (), -- Function to execute
}
```

### Server Handlers

| Action | Handler File                  | Remote Event       |
|--------|-------------------------------|--------------------|
| SHOOT  | `ShootServer.server.luau`     | ShootEvent         |
| FEED   | `ActionServer.server.luau`    | FeedEvent          |
| SCARE  | `ActionServer.server.luau`    | ScareEvent         |
| SHIELD | `ShieldServiceInit.server.luau` | ShieldActivateEvent |

### Adding New Action Modes

1. Define the mode in `MenuController.luau`:
```lua
local ACTION_MODES: { ActionMode } = {
    -- ... existing modes ...
    {
        ID = "NEW_ACTION",
        Name = "New Action",
        Icon = "🎯",
        ItemID = "ITEM_ID",  -- or nil for no item requirement
        Color = Color3.fromRGB(100, 100, 255),
        DisabledText = "No items!",
        OnActivate = function()
            RemoteEvents.NewActionEvent:FireServer()
        end,
    },
}
```

2. Create server handler in `src/server/Player/`:
```lua
RemoteEvents.NewActionEvent.OnServerEvent:Connect(function(player)
    -- Validate and process action
end)
```

---

## Debug Commands

For testing purposes, admin chat commands are available in `DebugCommands.server.luau`.

### Available Commands

| Command                    | Description                           |
|----------------------------|---------------------------------------|
| `/grantcoins <amount>`     | Grant coins to all players            |
| `/grantammo <amount>`      | Grant AMMO_BASIC to all players       |
| `/grantbait <amount>`      | Grant FOOD_BAIT to all players        |
| `/grantshield <amount>`    | Grant TOOL_SHIELD to all players      |
| `/grantitem <id> <amount>` | Grant any item to all players         |
| `/die`                     | Kill yourself (test respawn)          |
| `/shield`                  | Activate a free shield                |
| `/spawnfood [attract]`     | Spawn food at your position           |
| `/spawngift`               | Spawn a gift pickup nearby            |
| `/endgame`                 | Force end the current game            |
| `/resetachievements`       | Reset all achievements for all players|
| `/resetxp`                 | Reset XP and level for all players    |
| `/resetall`                | Reset all stats/achievements/XP       |
| `/debughelp`               | Show available commands               |

### Usage Examples

```
/grantcoins 100      -- Give everyone 100 coins
/grantammo 50        -- Give everyone 50 basic ammo
/grantbait 20        -- Give everyone 20 bait
/grantshield 5       -- Give everyone 5 shields
/grantitem mat_rope 25  -- Give everyone 25 rope
/die                 -- Test death/respawn system
/shield              -- Test shield visual effect
/spawnfood           -- Spawn basic food
/spawnfood 80        -- Spawn food with 80 attractiveness
/spawngift           -- Spawn random gift pickup
/endgame             -- Force game to end (shows results, stops timer)
/resetachievements   -- Clear all achievement progress
/resetxp             -- Reset everyone to level 1, 0 XP
/resetall            -- Full stat/achievement wipe
```

### Admin Access

- **In Studio**: All players are treated as admins
- **In Production**: Add user IDs to `ADMIN_USER_IDS` table in `DebugCommands.server.luau`

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
| TOOL_SHIELD   | Protective Shield | Tools     | 10        |
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

---

## Shop System

### Overview

The shop allows players to:
- **Purchase items with coins** (earned through gameplay)
- **Purchase coins with Robux** (Developer Products)

### Shop Categories

| Category   | Items Available                    |
|------------|-----------------------------------|
| Ammo       | Basic Bullets, Tranq Darts, Nets   |
| Food       | Apples, Meat, Animal Bait          |
| Tools      | Portable Traps, Binoculars         |
| Materials  | Rope, Wood                         |

### API Reference (Server)

```lua
local ShopService = require(ServerScriptService.Server.Player.ShopService)

-- Initialize with InventoryService dependency
ShopService.Init(InventoryService)

-- Purchase item with coins
local success, message = ShopService.PurchaseItem(player, "SHOP_AMMO_BASIC_50")

-- Process Robux purchase (called from MarketplaceService callback)
local success = ShopService.ProcessRobuxPurchase(player, productId)

-- Prompt coin bundle purchase dialog
local success, message = ShopService.PromptCoinBundlePurchase(player, "COINS_1000")

-- Get player's coin balance
local coins = ShopService.GetPlayerCoins(player)
```

### Adding New Shop Items

Edit `src/shared/data/ShopRegistry.luau`:

```lua
ShopRegistry.Items = {
    NEW_SHOP_ITEM = {
        ID = "NEW_SHOP_ITEM",
        ItemID = "EXISTING_ITEM_ID",  -- Must exist in ItemRegistry
        Quantity = 10,                 -- Amount player receives
        CoinPrice = 50,                -- Cost in coins
        Category = "Tools",            -- For shop UI organization
        Featured = true,               -- Optional: highlight in shop
        Discount = 20,                 -- Optional: show discount badge
    },
}
```

### Adding Coin Bundles

```lua
ShopRegistry.CoinBundles = {
    COINS_NEW = {
        ID = "COINS_NEW",
        Name = "Mega Coins",
        CoinAmount = 10000,           -- Coins awarded
        RobuxPrice = 999,             -- Display price
        BonusPercent = 50,            -- Optional: show bonus badge
        ProductId = 123456789,        -- Your Developer Product ID
        Featured = true,              -- Optional: "BEST VALUE" badge
    },
}
```

### Developer Products Setup

1. Create Developer Products in Roblox Creator Hub
2. Get the Product IDs
3. Add them to `ShopRegistry.CoinBundles[bundleID].ProductId`
4. The `ShopServiceInit` handles `MarketplaceService.ProcessReceipt`

### Current Shop Items

| ID                  | Item              | Qty | Price |
|---------------------|-------------------|-----|-------|
| SHOP_AMMO_BASIC_20  | Basic Bullets     | 20  | 10    |
| SHOP_AMMO_BASIC_50  | Basic Bullets     | 50  | 20    |
| SHOP_AMMO_TRANQ_10  | Tranquilizer Darts| 10  | 25    |
| SHOP_AMMO_TRANQ_25  | Tranquilizer Darts| 25  | 50    |
| SHOP_AMMO_NET_5     | Capture Nets      | 5   | 40    |
| SHOP_FOOD_APPLE_10  | Apple             | 10  | 15    |
| SHOP_FOOD_MEAT_5    | Cooked Meat       | 5   | 25    |
| SHOP_FOOD_BAIT_10   | Animal Bait       | 10  | 30    |
| SHOP_TOOL_TRAP_1    | Portable Trap     | 1   | 50    |
| SHOP_TOOL_TRAP_3    | Portable Trap     | 3   | 120   |
| SHOP_TOOL_BINOCULARS| Binoculars        | 1   | 100   |
| SHOP_MAT_ROPE_20    | Rope              | 20  | 15    |
| SHOP_MAT_WOOD_50    | Wood              | 50  | 20    |
| SHOP_TOOL_SHIELD_1  | Protective Shield | 1   | 75    |
| SHOP_TOOL_SHIELD_3  | Protective Shield | 3   | 200   |

### Coin Bundles (Robux)

| ID         | Name        | Coins | Robux | Bonus |
|------------|-------------|-------|-------|-------|
| COINS_100  | Coin Pouch  | 100   | 49    | -     |
| COINS_500  | Coin Bag    | 550   | 199   | +10%  |
| COINS_1000 | Coin Chest  | 1200  | 399   | +20%  |
| COINS_5000 | Coin Vault  | 6500  | 1699  | +30%  |

### Client Integration

The Shop tab is available in the Player Menu (press `I`):

```
┌─────────────────────────────────────────────┐
│ Player Menu                              X  │
├─────────────────────────────────────────────┤
│ [Inventory] [Shop] [Achievements] [Stats]   │
├─────────────────────────────────────────────┤
│ 💰 1,234 Coins              Your Balance    │
│                                             │
│ 🔫 Ammo                                     │
│ ┌─────────────────────────────────────────┐ │
│ │ Basic x20      💰 10          [Buy]     │ │
│ │ Basic x50 -20% 💰 20          [Buy]     │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ 💎 Buy Coins with Robux                     │
│ ┌─────────────────────────────────────────┐ │
│ │ Coin Chest  1200 (+20%)      [R$ 399]   │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

---

## Shield System

### Overview

The shield system provides temporary damage protection for players.

### Features

- **Duration**: 10 seconds (configurable per item via `ShieldDuration`)
- **Visual Effect**: Glowing sphere around player with ForceField material
- **Damage Blocking**: All damage is blocked while shield is active
- **Spawn Protection**: 5 seconds of free shield after respawning

### Files

```
src/server/Player/
├── ShieldService.luau        # Shield state management module
├── ShieldServiceInit.server.luau  # Module initializer
└── LifePointsServer.luau     # Checks shield before applying damage
```

### API Reference

```lua
local ShieldService = require(ServerScriptService.Server.Player.ShieldService)

-- Check if player has active shield
local isShielded = ShieldService.HasShield(player)

-- Activate shield for player
ShieldService.ActivateShield(player, duration)  -- duration in seconds

-- Remove active shield
ShieldService.RemoveShield(player)
```

### Shield Item

| Property       | Value              |
|----------------|--------------------|
| ID             | TOOL_SHIELD        |
| Name           | Protective Shield  |
| Category       | Tools              |
| Max Stack      | 10                 |
| ShieldDuration | 10 (seconds)       |
| Consumable     | true               |

### How It Works

1. Player activates SHIELD action mode and presses action button
2. Client fires `ShieldActivateEvent` to server
3. Server validates player has TOOL_SHIELD item
4. Server consumes 1 TOOL_SHIELD from inventory
5. `ShieldService.ActivateShield()` creates visual effect and starts timer
6. `LifePointsServer.damagePlayer()` checks `ShieldService.HasShield()` before applying damage
7. After duration expires, shield is automatically removed

### Visual Effect

The shield visual is a transparent sphere around the player:
- Material: ForceField (glowing)
- Color: Light blue (100, 200, 255)
- Transparency: 0.7
- Size: 6x8x6 studs (covers player)

---

## Respawn System

### Overview

When a player dies, there's a countdown before they respawn.

### Features

- **Countdown Duration**: 5 seconds
- **Billboard Display**: Countdown visible above dead player to others
- **Client Overlay**: Semi-transparent death screen with countdown
- **Spawn Protection**: 5 seconds of free shield after respawn

### Files

```
src/server/Player/
└── LifePointsServer.luau     # Death handling, countdown, respawn

src/client/ui/
└── RespawnController.luau    # Death overlay UI
```

### How It Works

1. Player's health reaches 0
2. `Humanoid.Died` event fires
3. Server creates `BillboardGui` above dead player showing countdown
4. Server fires `RespawnCountdownEvent` to client
5. Client shows death overlay with countdown
6. Player controls are disabled during countdown
7. After countdown, server calls `player:LoadCharacter()`
8. Spawn protection shield activates for 5 seconds

### Configuration

```lua
-- In LifePointsServer.luau
local RESPAWN_DELAY = 5  -- seconds before respawn
local SPAWN_PROTECTION_DURATION = 5  -- seconds of free shield
```

### Remote Events

| Event                | Direction      | Data           |
|----------------------|---------------|----------------|
| RespawnCountdownEvent | Server→Client | secondsLeft    |

---

## Gift Spawner System

### Overview

The UFO periodically spawns collectible gift pickups during gameplay.

### Features

- **Random Items**: Gifts contain coins, ammo, food, or shields
- **Weighted Drops**: Rarer items have lower spawn chance
- **Visual Effects**: Particles, glow, floating animation, billboard label
- **Auto-Despawn**: Uncollected gifts disappear after 60 seconds
- **Spawn Limit**: Maximum 5 gifts in world at once

### Files

```
src/server/UFO/
└── GiftSpawner.server.luau   # Gift spawning logic

src/shared/config/
└── GiftConfig.luau           # Spawner configuration
```

### Configuration (`GiftConfig.luau`)

```lua
return {
    -- Timing
    MIN_INTERVAL = 30,    -- Minimum seconds between spawns
    MAX_INTERVAL = 90,    -- Maximum seconds between spawns
    GIFT_LIFETIME = 60,   -- Seconds before uncollected gift despawns
    MAX_GIFTS = 5,        -- Maximum gifts in world at once
    
    -- Visuals
    GIFT_SIZE = Vector3.new(2, 2, 2),
    GIFT_COLOR = Color3.fromRGB(255, 215, 0),  -- Gold
    GLOW_COLOR = Color3.fromRGB(255, 255, 150),
    
    -- Drop table (Weight determines spawn chance)
    GiftTable = {
        { ItemID = "COIN", MinAmount = 10, MaxAmount = 50, Weight = 40 },
        { ItemID = "AMMO_BASIC", MinAmount = 10, MaxAmount = 30, Weight = 30 },
        { ItemID = "FOOD_BAIT", MinAmount = 5, MaxAmount = 15, Weight = 20 },
        { ItemID = "TOOL_SHIELD", MinAmount = 1, MaxAmount = 2, Weight = 10 },
    },
}
```

### Gift Visual Structure

```
Gift_ITEM_ID (Model)
├── GiftBox (Part)
│   ├── ParticleAttachment (Attachment)
│   │   └── ParticleEmitter
│   └── PointLight
└── GiftLabel (BillboardGui)
    └── Background (Frame)
        └── ItemLabel (TextLabel)
```

### Gift Appearance

- **Part**: Gold neon block, 2x2x2 studs
- **Particles**: Gold sparkles floating upward
- **Light**: Glowing point light (range 8 studs)
- **Billboard**: Shows "🎁 Xx ItemName" above the gift
- **Animation**: Floating up/down + rotating

### Drop Weights

| Item        | Weight | Chance  |
|-------------|--------|---------|
| Coins       | 40     | ~40%    |
| Basic Ammo  | 30     | ~30%    |
| Animal Bait | 20     | ~20%    |
| Shield      | 10     | ~10%    |

### How It Works

1. Game starts, `GiftSpawner` becomes active
2. Random interval (30-90s) timer starts
3. When timer fires:
   - Check if at gift capacity (5 max)
   - Select random gift from weighted table
   - Raycast from UFO to find ground position
   - Create gift model with visuals
   - Connect touch handler
4. Player touches gift:
   - Grant item to inventory
   - Play collection animation
   - Destroy gift
5. Gift uncollected for 60s:
   - Fade out animation
   - Destroy gift
6. Game ends:
   - All remaining gifts destroyed

---

## Game Start & End System

### Overview

The game follows a structured start and end flow with proper state management.

### Game Start Flow

When a player clicks "Start Game":

1. **Clean Up Previous State**
   - Clear all animals from Flock folder
   - Clear Food and Gifts folders
   - Reset trap states
   - Reset team scores
   - Reset GameEndService state

2. **Assign Teams**
   - All players assigned to Red or Blue team
   - Teams are balanced

3. **Enable Team Spawning**
   - Players will spawn at their team's spawn location

4. **Start Achievement Tracking**
   - Begins recording achievements earned during this game

5. **Respawn All Players**
   - All players teleported to their team spawn points

6. **Fire StartGameEvent**
   - Notifies all game systems (timer, animals, UFO, etc.)

### Game End Flow

When timer runs out or `/endgame` is used:

1. **Stop Timer** (if forced via `/endgame`)
2. **Freeze Players & Animals**
   - Players anchored and controls disabled
   - Animals stop moving
3. **Determine Winner**
   - Team with highest score wins
   - Tie-breaker if scores equal
4. **Award Coins**
   - Winners: 100% of team score as coins
   - Losers: 25% of team score as coins
   - Bonus multiplier for achievements
5. **Show Game End UI**
   - Sequential phases: Winner → Scores → Coins (animated) → Achievements → New Animals → Game Over
6. **Reset State**
   - `gameStarted = false`
   - Ready for next game

### Files

```
src/server/Game/
├── StartGameService.server.luau  # Handles game start
├── GameEndService.luau           # Game end logic module
├── GameEndServiceInit.server.luau # Event listeners
├── GameTimerService.server.luau  # Timer management
└── SpawnService.luau             # Team-based spawning

src/client/ui/
└── GameEndController.luau        # Game end UI display
```

### Server Events

| Event              | Purpose                                    |
|--------------------|--------------------------------------------|
| StartGameEvent     | Fired when game starts (BindableEvent)     |
| TimerEndedEvent    | Fired when timer reaches 0 (BindableEvent) |
| ForceEndGameEvent  | Fired by /endgame command (BindableEvent)  |
| GameEndSequenceEvent | Per-player game end data (RemoteEvent)   |

### Achievement Tracking

Achievements earned during the game are tracked from game start to game end:
- `GameEndService.StartGameTracking()` called on game start
- All achievements unlocked during play are recorded
- Displayed in game end sequence UI

---

## Keyboard Controls

### Overview

Players can use keyboard shortcuts in addition to on-screen buttons.

### Key Bindings

| Key | Action                          | Notes                           |
|-----|--------------------------------|--------------------------------|
| E   | Perform current action         | Same as Action Button          |
| Q   | Cycle to next action mode      | SHOOT → FEED → SCARE → SHIELD  |
| Shift | Toggle sprint                | Same as Run Button             |
| I   | Open/close player menu         | Inventory, Shop, Achievements  |

### Implementation

Keyboard input is handled in `MenuController.luau`:

```lua
-- E key = Action
if input.KeyCode == Enum.KeyCode.E then
    performCurrentAction()
end

-- Q key = Cycle Mode (with 200ms debounce)
if input.KeyCode == Enum.KeyCode.Q then
    cycleToNextMode()
end
```

### Debounce

The Q key has a 200ms cooldown to prevent rapid mode cycling from key repeat.

---

## Game End UI

### Overview

When a game ends, players see a sequential animated display of results.

### Phases

1. **Winner Announcement** (1.5s)
   - "🏆 VICTORY!" or "DEFEAT" banner
   - Winning team name
   - Final score

2. **Coins Earned** (2s + animation)
   - Animated count-up from 0 to final amount
   - Shows bonus multiplier if applicable
   - Winner/Loser status

3. **Achievements Unlocked** (variable)
   - Lists achievements earned during the game
   - Up to 5 shown at once

4. **New Animals Discovered** (variable)
   - Shows any new animal types captured

5. **Game Over** (7s)
   - Final screen
   - Auto-dismisses after 7 seconds

### Visual Design

```
┌─────────────────────────────────────────────────┐
│                                                 │
│           🏆 VICTORY! 🏆                        │
│                                                 │
│              Red Team Wins!                     │
│                                                 │
│          Final Score: 45 - 32                   │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Files

```
src/client/ui/
└── GameEndController.luau    # All UI creation and animation

src/shared/
└── RemoteEvents.luau         # GameEndSequenceEvent
```

### Coin Animation

Coins count up smoothly using TweenService:
- Duration: 2 seconds
- Easing: Quad Out (fast start, slow finish)
- Format: "+0" → "+34" (or whatever amount)
