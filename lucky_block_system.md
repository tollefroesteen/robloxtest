# Lucky Block System (Arena + Lobby Shop)

## 1. Overview
The Lucky Block system introduces a dynamic reward mechanic in the arena and a monetizable reveal experience in the lobby. Lucky Blocks appear as **gift boxes** with rarity indicators and can be redeemed to spawn animals of varying rarity tiers.

---

## 2. Lucky Block Types
Each Lucky Block has a defined rarity tier, shown visually on the block:

| Lucky Block Type | Indicator |
|------------------|-----------|
| Rare             | “Rare” label / color theme |
| Very Rare        | “Very Rare” label / color theme |
| Ultra Rare       | “Ultra Rare” label / color theme |

All Lucky Blocks display:
- A **gift box model**
- A **floating question mark** above the block

Each type influences what animal the block may give.

---

## 3. Arena-System Behavior

### 3.1 UFO Lucky Block Spawning
While a match is active:
- A UFO periodically spawns Lucky Blocks at random locations in the arena.
- Spawn interval should be configurable (e.g., every 90–180 seconds).
- Only one or a few blocks should be active simultaneously.

Spawn Chance Example:
- 70% Rare  
- 25% Very Rare  
- 5% Ultra Rare  

---

### 3.2 Player Pickup Logic (Updated)
When any player touches a Lucky Block:
- The Lucky Block despawns.
- An animal is spawned **in the arena** at that location.
- Once the animal appears, **all players in the arena** are free to try to capture it.
- The player who triggered the block has **no special advantage** after the animal spawns—except reaching the block first.
- The spawned animal behaves exactly like any other animal in the game until caught.

Animal rarity is influenced by:
1. Lucky Block rarity  
2. Animal rarity defined in AnimalLibraryModule.luau 

Example Table:

| Animal Rarity | Base Chance | Bonus From Matching Block |
|----------------|-------------|---------------------------|
| Common         | 60%         | 0% bonus |
| Medium Rare    | 25%         | 0% bonus |
| Rare           | 10%         | +10–20% |
| Very Rare      | 4%          | +15–25% |
| Ultra Rare     | 1%          | +20–30% |

---

## 4. Lobby Shop Lucky Block Purchases

### 4.1 Purchasing
Players may buy Lucky Blocks **only in the lobby**.

When a Lucky Block is purchased:
- It spawns in front of the purchasing player.
- Only that player may reveal it.
- The block matches the purchased rarity type.
- The player recevies the animal and it is registered to their index/captured list

---

## 5. Reveal Isolation Zone (Lobby Only)

### Purpose
Prevents other players from visually interfering with the reveal.

### Mechanics
Upon reveal:
- A **semi-transparent blocking cylinder** forms around the player.
- Only the owner can enter; other players are blocked.
- The cylinder fades in/out and disappears after reveal ends.

---

## 6. Reveal Sequence
1. Lucky Block animates (bounce, glow, shake).
2. Rarity-themed particles play.
3. Gift box opens or bursts.
4. Animal appears.
5. Lucky Block despawns.

All reward logic is server-side validated.

---

## 7. Backend Data Requirements

- **Lucky Block Type Enum:** Rare, VeryRare, UltraRare  
- **Animal Rarity Enum:** Common, MediumRare, Rare, VeryRare, UltraRare (based on spawnchance in AnimalLibraryModule I suppose?)  
- **RemoteEvents** for buying, spawning, revealing, and rewarding  

---

## 8. Anti-Cheat Considerations
- Rewards must be assigned server-side only.
- Validate that reveals and pickups are legitimate.
- Prevent duplicate block interactions.

---

## 9. Optional Enhancements
- UFO particle trails for lucky blocks
- Unique reveal animations by rarity
- Global notifications for Ultra Rare animals
- Player stat tracking for animal reveals
