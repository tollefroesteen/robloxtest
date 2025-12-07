# Roblox Matchmaking System Specification (1v1 and 2v2)

## 1. Multi-Lobby Architecture
- Multiple **LobbyPlace** servers.
- Matches occur in **ArenaPlace**.
- Matchmaking is global using **MemoryStoreService**.

## 2. Match Type Selection Using Trigger Volumes
Players choose match type by stepping into a semi-transparent cylinder.

### 1v1 Cylinder
- Player enters → 10s countdown starts.
- If still inside at 0 → added to `Solo1Queue`.

### 2v2 Cylinder
- Player enters → 10s countdown starts.
- If two players are inside simultaneously → form a **team2** immediately.
- If one player reaches 0 alone → added to `Solo2Queue`.

## 3. Countdown Behavior
- Each player has an independent 10s countdown.
- Leaving the cylinder cancels the countdown.
- Optional UI: BillboardGui showing remaining seconds.

## 4. MemoryStore Queues
Use global queues:

### `Team2Queue`
For teams of two:
```lua
{ type = "team2", players = {UserId1, UserId2}, queuedAt = os.time() }
```

### `Solo2Queue`
For solo players wanting 2v2:
```lua
{ type = "solo2", player = UserId, queuedAt = os.time() }
```

### `Solo1Queue`
For 1v1 players:
```lua
{ type = "solo1", player = UserId, queuedAt = os.time() }
```

## 5. Matchmaking Rules

### 2v2 Priorities
1. `team2 + team2`
2. `team2 + solo2 + solo2`
3. `solo2 x 4` → two balanced teams

### 1v1
```
solo1 + solo1 → match
```

## 6. Match Server Creation
When players are selected:

```lua
local serverCode = TeleportService:ReserveServer(ArenaPlaceId)
TeleportService:TeleportToPrivateServer(
    ArenaPlaceId,
    serverCode,
    players,
    nil,
    teleportData
)
```

### Teleport Data Example
```lua
{
  mode = "1v1" or "2v2",
  teamA = {UserIdA1, UserIdA2 or nil},
  teamB = {UserIdB1, UserIdB2 or nil}
}
```

## 7. Arena Responsibilities
- Read `teleportData`.
- Spawn players on correct sides.
- Run match logic.
- Report results (optional).
- Teleport players back to lobby afterward.

## 8. Return Flow
After match:
```lua
TeleportService:Teleport(LobbyPlaceId, player)
```

## 9. Full Player Flow Summary

### 1v1
1. Step into 1v1 cylinder.
2. 10s countdown.
3. If inside at 0 → enter Solo1Queue.
4. Matched with another solo → teleport to arena.

### 2v2
#### Case A: Two players inside cylinder together
- Instantly form a team.
- Enter Team2Queue.

#### Case B: One player alone at countdown 0
- Enter Solo2Queue.

#### Case C: Four solos accumulate globally
- Create two temporary teams.
- Start match.

## 10. System Overview
This spec includes:
- Trigger-volume based match selection  
- Countdown timers  
- Solo and team queueing  
- Cross-server matchmaking  
- 1v1 & 2v2 support  
- Private match server creation  
- Arena match handling  
- Lobby return flow  
