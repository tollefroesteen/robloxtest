# Refactoring Backlog (Prioritized)

Use this checklist to track and complete improvements one-by-one.

## 🚧 Active Tasks

### UI & Source Control
- [ ] [UI-3] Map GUIs via `default.project.json` under `StarterGui` for consistency and fewer runtime waits.

### Phase 1: UFO Spawner (Gameplay Loop)
- [ ] [UFO-1] Replace pre-placed Workspace `Flock` animals with dynamic spawning from `ReplicatedStorage.AnimalTemplate`.
- [ ] [UFO-2] Apply per-animal properties from `ServerScriptService.Server.Animal.AnimalLibraryModule` to each spawned clone (PointValue, MaxSpeed, Color, etc.).
- [ ] [UFO-3] Gate spawning by game state: start on `StartGameEvent`, stop on `TimerEndedEvent`.
 - [x] [UFO-4] Configure pacing: add shared spawn config (interval, max concurrent, burst size) and enforce a cap in `workspace.Flock`.
- [ ] [UFO-5] Ownership + replication: set `SetNetworkOwner(nil)` and fire `RemoteEvents.AnimalSpawnedEvent` after parenting to `workspace.Flock`.
- [ ] [UFO-6] Lifecycle: despawn animals on capture/reset; ensure `ResetService` clears `Flock` safely.
- [ ] [UFO-7] Safety checks: validate `AnimalTemplate` exists; log and skip if missing; fall back color if library is incomplete.
- [ ] [UFO-8] UFO behavior: ensure UFO has a valid `PrimaryPart`; add hover/pathing stub for future movement.
- [ ] [UFO-9] Performance: avoid per-frame tree scans (client already cached); throttle server loop; protect against memory growth.
- [ ] [UFO-10] Telemetry: add `Log.Debug` traces around spawn/stop; count spawns per minute for tuning.

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

### Low Impact: Performance & Ergonomics
- [x] [LO-1] Cache animal part references in `AnimalController` (visual, bounce, legs) to avoid per-frame tree scans.
- [x] [LO-2] Enhance `ButtonEffects` with debounce helper and optional scale-based press effect.
- [x] [LO-3] Standardize warning prefixes and add `DEV_MODE` toggle for verbose client logging.

---

## 📝 Notes
- Use short IDs (e.g., `HI-2`, `MI-3`) when referring to tasks in chat or commits.
- Tackle top-to-bottom; each item should be a single PR/commit where practical.
- Keep changes focused; avoid unrelated edits.
- Update tests or quick sanity checks if/when you add them.
- Delete template examples (prefixed with `_Example:`) when adding real tasks.
