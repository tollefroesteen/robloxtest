# Matchmaking System Implementation

## Overview

This document describes the 1v1 and 2v2 matchmaking system implementation based on `matchmaking_spec.md`.

## Architecture

### Shared Components (`shared/config/`)

- **MatchmakingConfig.luau** - Configuration constants and type definitions for:
  - Countdown timing (10 seconds)
  - Queue entry TTL (5 minutes)
  - Zone dimensions and positions
  - Type definitions for queue entries and teleport data

### Lobby Server (`places/lobby/src/server/`)

#### matchmaking/QueueManager.luau
Handles MemoryStoreService operations for cross-server queues:
- `Solo1Queue` - Solo players queueing for 1v1
- `Solo2Queue` - Solo players queueing for 2v2
- `Team2Queue` - Pre-formed teams of 2 for 2v2

Methods:
- `AddToSolo1Queue(playerId)` - Add player to 1v1 queue
- `AddToSolo2Queue(playerId)` - Add solo player to 2v2 queue  
- `AddToTeam2Queue(player1Id, player2Id)` - Add team to 2v2 queue
- `RemovePlayerFromQueues(playerId)` - Remove player from all queues
- `GetSolo1Entries() / GetSolo2Entries() / GetTeam2Entries()` - Get queue contents
- `CleanupStaleEntries()` - Remove expired entries

#### matchmaking/MatchmakingService.luau
Core matchmaking logic:
- Processes queues on a tick interval
- Handles zone enter/exit events
- Team formation when 2 players in 2v2 zone simultaneously
- Match creation with priority:
  1. team2 + team2
  2. team2 + solo2 + solo2
  3. solo2 x 4
- Teleports matched players to private arena servers

#### MatchmakingZoneService.server.luau
Creates and manages trigger volumes:
- 1v1 zone (red cylinder) at configured position
- 2v2 zone (blue cylinder) at configured position
- Heartbeat detection of player zone entry/exit
- Billboard labels with instructions

### Lobby Client (`places/lobby/src/client/`)

#### MatchmakingController.luau
Client-side UI and feedback:
- Countdown display when entering zone
- Queue status display while searching
- Team formation notifications for 2v2
- Animated "Searching..." indicators

### Arena Server (`places/arena/src/server/`)

#### Game/MatchSetupService.server.luau
Handles incoming matches:
- Reads teleportData from players
- Initializes match mode, teams, and match ID
- Spawns players at team-specific positions
- Team assignment notifications
- Return-to-lobby functionality

## Remote Events Added

| Event | Direction | Purpose |
|-------|-----------|---------|
| `MatchmakingZoneEnteredEvent` | Server → Client | Player entered zone |
| `MatchmakingZoneExitedEvent` | Server → Client | Player exited zone |
| `MatchmakingQueueJoinedEvent` | Server → Client | Player added to queue |
| `MatchmakingTeamFormedEvent` | Server → Client | 2v2 team formed |
| `MatchmakingMatchFoundEvent` | Server → Client | Match found |
| `MatchmakingCountdownCompleteEvent` | Client → Server | Countdown finished |

## Player Flow

### 1v1 Flow
1. Player steps into 1v1 cylinder (red)
2. 10-second countdown starts on client
3. If player stays inside, countdown completes
4. Client notifies server, player added to `Solo1Queue`
5. Matchmaking tick finds two solo1 entries
6. Private arena server reserved, players teleported
7. Arena reads teleportData, spawns players on opposite sides

### 2v2 Flow (Team Formation)
1. Two players step into 2v2 cylinder together
2. Server detects both players, immediately forms team
3. Team added to `Team2Queue`
4. Both players see "Team formed" notification

### 2v2 Flow (Solo Queue)
1. Single player in 2v2 zone completes countdown
2. Added to `Solo2Queue`
3. Matchmaking forms teams from available entries

## Configuration

Edit `shared/config/MatchmakingConfig.luau`:

```lua
-- Zone positions (adjust for your lobby layout)
MatchmakingConfig.ZONE_1V1_POSITION = Vector3.new(-20, 0, 0)
MatchmakingConfig.ZONE_2V2_POSITION = Vector3.new(20, 0, 0)

-- Timing
MatchmakingConfig.COUNTDOWN_SECONDS = 10
MatchmakingConfig.MATCHMAKING_TICK_INTERVAL = 1
```

## Notes

- MemoryStoreService requires Studio access to API services enabled
- Private server teleportation requires the places to be part of the same universe
- Queue entries auto-expire after 5 minutes
- Stale entries cleaned every 30 seconds
