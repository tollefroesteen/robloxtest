# Refactoring Backlog (Prioritized)

Use this checklist to track and complete improvements one-by-one.

## 🚧 Active Tasks

_No active tasks - Shop System complete!_

---

## 📋 New Tasks Template

### High Priority (Critical bugs, blockers, foundational architecture)
- [ ] [HI-5] _Example: Fix critical replication bug in trap capture_
- [ ] [HI-6] _Example: Implement server-authoritative movement validation_

### Medium Priority (Features, refactors, notable improvements)
- [ ] [MI-5] _Example: Add multiplayer team selection UI_
- [ ] [MI-6] _Example: Implement animal AI pathfinding system_

### Low Priority (Polish, optimizations, nice-to-haves)
- [ ] [LO-4] _Example: Add particle effects to trap captures_
- [ ] [LO-5] _Example: Create admin panel for game configuration_

### UI & UX
- [ ] [UX-1] _Example: Add sound effects for button clicks_
- [ ] [UX-2] _Example: Create loading screen with progress bar_

---

## ✅ Completed Tasks

### High Impact: Architecture & Foundation
- [x] [HI-1] Move `src/client/AnimalAnimationController.luau` to `src/client/controllers/AnimalController.luau` and update require path in `MainClient.client.luau`.
- [x] [HI-2] Bootstrap remotes at server startup by requiring `ReplicatedStorage.Shared.RemoteEvents` (e.g., `MainServer.server.luau`).
- [x] [HI-3] Standardize RemoteEvents usage across clients: replace `ReplicatedStorage:WaitForChild("XEvent")` with `require(ReplicatedStorage.Shared.RemoteEvents).XEvent`.
	- Done: `ScoreController`, `StaminaController`, `ResetButtonController`, `MenuController`, `RunButtonController`, and `HealthController` converted to require `Shared.RemoteEvents`.
- [x] [HI-4] Enable `--!strict` and add Luau type annotations in core modules: `TrapController`, `PlayerSprint`, all UI/controllers.
    - Done: `--!strict` enabled in `TrapController`, `PlayerSprint`, and all UI controllers.
    - Done: Added basic type annotations to `TrapController`, `PlayerSprint.server`, and UI controllers (labels, buttons, bars).

### Medium Impact: Config, Services, Reset
- [x] [MI-1] Create `src/shared/config/SprintConfig.luau` with shared constants; use it in `PlayerSprint.server.luau` and `RunButtonController.luau`.
- [x] [MI-2] Throttle `PlayerSprint` update loop to `0.2s` or only fire on state change.
- [x] [MI-3] Extract `ScoreService.server.luau` to own score aggregation/broadcast; call from `TrapController`.
- [x] [MI-4] On reset: call `TrapController.ResetAllTraps()` and `ScoreService.ResetAll()`; broadcast zero-state so HUD clears immediately.

### Medium Impact: UI Init & Paths
- [x] [UI-1] Add `CharacterAdded` re-init hook in `MainClient.client.luau` to rebind controllers after respawn.
- [x] [UI-2] Document GUI hierarchy (names/paths) in `README.md`: `ActionsGui`, `HealthGui`, `StaminaGui`, `ScoreGui`.
- [x] [UI-3] ~~Map GUIs via Rojo~~ **CANCELLED** - See above; documented hybrid Studio/filesystem approach instead.

### Low Impact: Performance & Ergonomics
- [x] [LO-1] Cache animal part references in `AnimalController` (visual, bounce, legs) to avoid per-frame tree scans.
- [x] [LO-2] Enhance `ButtonEffects` with debounce helper and optional scale-based press effect.
- [x] [LO-3] Standardize warning prefixes and add `DEV_MODE` toggle for verbose client logging.

### Phase 1: UFO Spawner System
- [x] [UFO-1] Replace pre-placed Workspace `Flock` animals with dynamic spawning from `ReplicatedStorage.AnimalTemplate`.
- [x] [UFO-2] Apply per-animal properties from `ServerScriptService.Server.Animal.AnimalLibraryModule` to each spawned clone (PointValue, MaxSpeed, Color, etc.).
- [x] [UFO-3] Gate spawning by game state: start on `StartGameEvent`, stop on `TimerEndedEvent`.
    - Created `StartGameService.server.luau` to bridge RemoteEvent to BindableEvent
    - Added `StartButton` to `MenuController` with debounce
    - Added `StartGameEvent` RemoteEvent to `RemoteEvents.luau`
- [x] [UFO-4] Configure pacing: add shared spawn config (interval, max concurrent, burst size) and enforce a cap in `workspace.Flock`.
- [x] [UFO-5] Ownership + replication: set `SetNetworkOwner(nil)` and fire `RemoteEvents.AnimalSpawnedEvent` after parenting to `workspace.Flock`.
- [x] [UFO-6] Lifecycle: despawn animals on capture/reset; ensure `ResetService` clears `Flock` safely.
- [x] [UFO-7] Safety checks: validate `AnimalTemplate` exists; log and skip if missing; fall back color if library is incomplete.
- [x] [UFO-8] UFO behavior: ensure UFO has a valid `PrimaryPart`; add hover/pathing stub for future movement.
- [x] [UFO-9] Performance: avoid per-frame tree scans (client already cached); throttle server loop; protect against memory growth.
- [x] [UFO-10] Telemetry: add `Log.Debug` traces around spawn/stop; count spawns per minute for tuning.
    - Spawns position at UFO's X/Z at ground level (spawnHeight = 10)
    - Blue beam effect activates via `FlockSpawnedEvent`
    - Fixed: SetNetworkOwner must be called after parenting to workspace
    - Fixed: BrickColor.Color conversion for Color3 property

### Phase 2: Player Menu & Shop System
- [x] [MENU-1] Create PlayerMenuController with tabbed UI (Inventory, Shop, Achievements, Stats)
    - Opens with 'I' key or menu button
    - Animated slide-in/out transitions
    - Tab switching with content containers
- [x] [MENU-2] Inventory tab: display items in grid with category colors and quantity badges
- [x] [MENU-3] Achievements tab: grouped by status (In Progress, Locked, Completed)
    - Progress bars and XP reward display
    - Overall achievement summary header
- [x] [MENU-4] Stats tab: Level & XP progress, game statistics, animal collection
    - XP bar with gradient fill
    - Next level reward preview
    - Animal cards showing discovery status
- [x] [MENU-5] Shop tab: purchase items with coins
    - Coin balance display
    - Category-organized item listings
    - Discount badges and affordability indicators
    - Buy buttons with server validation
- [x] [MENU-6] Shop coin bundles: Robux purchase integration
    - Developer Product prompts via MarketplaceService
    - Bonus percentage badges
    - Featured "BEST VALUE" indicators
- [x] [SHOP-1] Create ShopRegistry with item prices and coin bundles
- [x] [SHOP-2] Create ShopService with purchase validation and coin deduction
- [x] [SHOP-3] Create ShopServiceInit with RemoteEvent handling and ProcessReceipt
- [x] [SHOP-4] Add ShopPurchaseRequestEvent, ShopPurchaseResultEvent, ShopBuyCoinsRequestEvent
- [x] [SHOP-5] Toast notifications for purchase success/failure feedback
- [x] [SHOP-6] Auto-refresh shop when inventory changes (coin balance updates)

### Phase 3: Team Abandonment & Forfeit System
- [x] [FORFEIT-1] Detect when all players leave a team during active game
    - TeamService tracks player count per team on PlayerRemoving
    - Fires TeamAbandonedEvent when one team becomes empty
- [x] [FORFEIT-2] Trigger 30-second countdown when team abandons
    - GameTimerService listens for TeamAbandonedEvent
    - Sets remaining time to ABANDONMENT_TIME (30 seconds)
    - Broadcasts timer update to all clients
- [x] [FORFEIT-3] Client forfeit notifications
    - TimerController shows flashing "FORFEIT!" notification
    - GameEndController shows "Wins by Forfeit!" message
    - Losing team sees "Your team forfeited" with no rewards
- [x] [FORFEIT-4] Forfeit reward logic
    - Winner determined by non-abandoned team (ignores score)
    - Forfeited team score set to 0 immediately
    - Winners receive full rewards, losers receive nothing
- [x] [FORFEIT-5] Admin commands for testing forfeit
    - /simulateforfeit <red|blue> - triggers abandonment flow
    - /teaminfo - shows player count per team
    - TeamService.SetTeamForfeit() for programmatic triggers
- [x] [FORFEIT-6] Fixed MINIMUM_LOSER_COINS missing from GameEndConfig

---

## 📝 Notes
- Use short IDs (e.g., `HI-2`, `MI-3`) when referring to tasks in chat or commits.
- Tackle top-to-bottom; each item should be a single PR/commit where practical.
- Keep changes focused; avoid unrelated edits.
- Update tests or quick sanity checks if/when you add them.
- Delete template examples (prefixed with `_Example:`) when adding real tasks.
