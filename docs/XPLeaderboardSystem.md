# XP & Leaderboard System Documentation

## Overview

The XP Leaderboard System provides two types of player rankings based on Experience Points (XP):

1. **Global Leaderboard** - Cross-server rankings using Roblox's **OrderedDataStore** (persistent, shared across all servers in the universe)
2. **Server Leaderboard** - Current lobby/server rankings (in-memory, shows only players in the same server)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SHARED (ReplicatedStorage)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  LeaderboardService.luau                                                    │
│  ├── OrderedDataStore: "Leaderboard_XP_v1" (Global rankings)               │
│  ├── In-memory cache (60s TTL)                                              │
│  ├── Pending updates queue                                                  │
│  └── API: Init, UpdatePlayerXP, SyncPlayerXPNow, GetXPLeaderboard, etc.     │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
┌─────────────────────────────────┐   ┌─────────────────────────────────┐
│           LOBBY PLACE           │   │          ARENA PLACE            │
├─────────────────────────────────┤   ├─────────────────────────────────┤
│  Server:                        │   │  Server:                        │
│  ├── LeaderboardManager         │   │  ├── AchievementsService        │
│  │   ├── Global: OrderedDS      │   │  │   └── Calls UpdatePlayerXP   │
│  │   ├── Server: In-memory      │   │  │       when XP is earned      │
│  │   ├── Global broadcast: 60s  │   │  └── LeaderboardSync            │
│  │   ├── Server broadcast: 10s  │   │      ├── Processes queue (30s)  │
│  │   └── Final sync on leave    │   │      └── Final sync on leave    │
│  └── FavoriteAnimalsService     │   │                                 │
│      └── Stores player data     │   │                                 │
├─────────────────────────────────┤   ├─────────────────────────────────┤
│  Client:                        │   │  Client:                        │
│  └── LeaderboardController      │   │  └── (No leaderboard UI)        │
│      ├── Global Billboard (L)   │   │                                 │
│      └── Server Billboard (R)   │   │                                 │
└─────────────────────────────────┘   └─────────────────────────────────┘
```

---

## Leaderboard Types

### Global Leaderboard (Cross-Server)

| Feature | Description |
|---------|-------------|
| **Storage** | OrderedDataStore (`Leaderboard_XP_v1`) |
| **Scope** | All servers across the entire game/universe |
| **Persistence** | Permanent (survives server restarts) |
| **Update Frequency** | Every 30s (batched) + immediate on player leave |
| **Broadcast Interval** | Every 60 seconds to all clients |
| **Display** | Left billboard (gold header) |

### Server Leaderboard (Current Lobby)

| Feature | Description |
|---------|-------------|
| **Storage** | In-memory (server RAM) |
| **Scope** | Only players in the current server instance |
| **Persistence** | None (resets when server shuts down) |
| **Update Frequency** | Real-time from player data |
| **Broadcast Interval** | Every 10 seconds to all clients |
| **Display** | Right billboard (blue header) |

---

## How XP is Earned

XP is earned in the **Arena** place through the `AchievementsService`:

| Action | XP Awarded |
|--------|------------|
| Completing achievements | Varies by achievement |
| Arena gameplay events | Configured per event |

When XP is added via `AchievementsService.AddXP(player, amount)`:
1. Player's local stats are updated
2. `LeaderboardService.UpdatePlayerXP()` is called to queue the update

---

## Data Flow & Sync Timing

### 1. XP Update Queue (Batched)

```lua
-- When XP changes (e.g., in AchievementsService)
LeaderboardService.UpdatePlayerXP(userId, totalXP)
```

- **What happens:** XP value is added to an in-memory queue
- **Why batched:** Avoids DataStore rate limits (60 writes/min per key)
- **Queue structure:** `{ [userId]: latestXP }` (overwrites duplicate updates)

### 2. Periodic Batch Processing

```
Every 30 seconds (configurable via SYNC_INTERVAL):
┌──────────────────────────────────────────────────────┐
│  LeaderboardService.ProcessPendingUpdates()          │
│  ├── Iterates through pending queue                  │
│  ├── Writes each to OrderedDataStore                 │
│  ├── 0.1s delay between writes (rate limit safety)   │
│  └── Clears queue when done                          │
└──────────────────────────────────────────────────────┘
```

### 3. Immediate Sync (Bypass Queue)

```lua
-- Used for critical moments
LeaderboardService.SyncPlayerXPNow(userId, totalXP)
```

**When immediate sync is used:**
- Player joins lobby (ensures they appear on leaderboard)
- Player leaves any place (final XP save)

### 4. Leaderboard Fetching

```lua
local data = LeaderboardService.GetXPLeaderboard(10)
```

**Caching behavior:**
- Cache TTL: 60 seconds (configurable via `CACHE_DURATION`)
- If cache is fresh → returns cached data (no DataStore call)
- If cache is stale → fetches from OrderedDataStore, updates cache

---

## Cross-Server Behavior

### Why It Works Cross-Server

| Feature | Mechanism |
|---------|-----------|
| **Persistence** | OrderedDataStore is Roblox cloud storage |
| **Cross-place** | Same DataStore name used in all places |
| **Sorted retrieval** | `GetSortedAsync()` returns pre-sorted results |
| **Eventually consistent** | Updates propagate within seconds |

### Sync Timeline Example

```
Time    Server A (Arena)              Server B (Lobby)           OrderedDataStore
────────────────────────────────────────────────────────────────────────────────
0:00    Player earns 50 XP            -                          XP: 100
        → Queued: {userId: 150}       
                                      
0:30    ProcessPendingUpdates()       -                          XP: 150
        → SetAsync(userId, 150)       
                                      
0:35    -                             GetXPLeaderboard()         XP: 150
                                      → Cache miss, fetches      
                                      → Shows player: 150 XP     
                                      
1:00    Player earns 25 XP            -                          XP: 150
        → Queued: {userId: 175}       
                                      
1:30    ProcessPendingUpdates()       -                          XP: 175
        → SetAsync(userId, 175)       
                                      
1:35    -                             Cache expires (60s)        XP: 175
                                      → Next request fetches     
                                      → Shows player: 175 XP     
```

---

## Configuration Reference

Located in `LeaderboardService.luau`:

```lua
local CONFIG = {
    -- DataStore name (changing resets leaderboard!)
    XP_LEADERBOARD_NAME = "Leaderboard_XP_v1",
    
    -- Fetch limits
    DEFAULT_ENTRIES = 10,   -- Default entries per request
    MAX_ENTRIES = 100,      -- Maximum allowed
    
    -- Performance tuning
    CACHE_DURATION = 60,    -- Seconds before refetching
    SYNC_INTERVAL = 30,     -- Seconds between batch syncs
}
```

---

## Remote Events

| Event | Direction | Purpose |
|-------|-----------|---------|
| `LeaderboardUpdatedEvent` | Server → Client | Broadcasts global leaderboard data |
| `ServerLeaderboardUpdatedEvent` | Server → Client | Broadcasts server-specific leaderboard data |
| `RequestLeaderboardEvent` | Client → Server | Client requests both leaderboards refresh |

---

## API Reference

### LeaderboardService (Server-Only)

| Function | Description |
|----------|-------------|
| `Init()` | Initialize OrderedDataStore connection |
| `UpdatePlayerXP(userId, xp)` | Queue XP update for batch processing |
| `SyncPlayerXPNow(userId, xp)` | Immediately write XP to DataStore |
| `ProcessPendingUpdates()` | Flush pending queue to DataStore |
| `GetXPLeaderboard(count?)` | Get top players (cached) |
| `GetPlayerXPRank(userId)` | Get specific player's rank |
| `ClearCache()` | Force fresh fetch on next request |
| `FormatXP(xp)` | Format number (e.g., 1500 → "1.5K") |

### Types

```lua
type LeaderboardEntry = {
    Rank: number,        -- 1-based position
    UserId: number,      -- Roblox UserId
    DisplayName: string, -- Player's display name
    Value: number,       -- XP amount
}

type LeaderboardData = {
    Entries: { LeaderboardEntry },
    LastUpdated: number, -- Unix timestamp
    StatType: string,    -- "XP"
}
```

---

## Lobby Billboards

Two 3D leaderboard billboards are displayed side-by-side in the lobby:

### Global Leaderboard (Left)
- **Position:** `Vector3.new(-12, 15, -50)`
- **Header:** "🌍 GLOBAL LEADERBOARD 🌍" (Gold)
- **Data Source:** OrderedDataStore
- **Updates:** Every 60 seconds

### Server Leaderboard (Right)
- **Position:** `Vector3.new(12, 15, -50)`
- **Header:** "🏠 THIS SERVER 🏠" (Blue)
- **Data Source:** In-memory (current players)
- **Updates:** Every 10 seconds + on player join/leave

### Common Features
- **Size:** 18 × 12 studs each
- Gold/Silver/Bronze colors for top 3
- Current player highlighted in blue
- Formatted XP display (K/M abbreviations)

---

## Troubleshooting

### Player not appearing on leaderboard

1. **Check XP value:** Player must have XP > 0
2. **Wait for sync:** Up to 30 seconds for queued updates
3. **Cache delay:** Up to 60 seconds for other servers to see changes
4. **Studio mode:** DataStores may be unavailable in Studio without API access enabled

### Leaderboard shows stale data

1. Call `LeaderboardService.ClearCache()` to force refresh
2. Check `CACHE_DURATION` setting
3. Verify `ProcessPendingUpdates()` is running

### Rate limit errors

1. Increase `SYNC_INTERVAL` to reduce write frequency
2. Ensure only one place is doing immediate syncs
3. Check for duplicate `Init()` calls

---

## Future Improvements

Potential enhancements:

- [ ] Multiple leaderboard types (TotalCaptures, TotalWins, etc.)
- [ ] Weekly/Monthly reset leaderboards
- [ ] Leaderboard UI in arena place
- [ ] Player rank display in HUD
- [ ] Rewards for top-ranked players
