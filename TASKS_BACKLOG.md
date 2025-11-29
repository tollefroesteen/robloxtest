# Refactoring Backlog (Prioritized)

Use this checklist to track and complete improvements one-by-one.

- [x] [HI-1] Move `src/client/AnimalAnimationController.luau` to `src/client/controllers/AnimalController.luau` and update require path in `MainClient.client.luau`.
- [x] [HI-2] Bootstrap remotes at server startup by requiring `ReplicatedStorage.Shared.RemoteEvents` (e.g., `MainServer.server.luau`).
- [x] [HI-3] Standardize RemoteEvents usage across clients: replace `ReplicatedStorage:WaitForChild("XEvent")` with `require(ReplicatedStorage.Shared.RemoteEvents).XEvent`.
	- Done: `ScoreController`, `StaminaController`, `ResetButtonController`, `MenuController`, `RunButtonController`, and `HealthController` converted to require `Shared.RemoteEvents`.
- [x] [HI-4] Enable `--!strict` and add Luau type annotations in core modules: `TrapController`, `PlayerSprint`, all UI/controllers.
    - Done: `--!strict` enabled in `TrapController`, `PlayerSprint`, and all UI controllers.
    - Done: Added basic type annotations to `TrapController`, `PlayerSprint.server`, and UI controllers (labels, buttons, bars).
## Medium Impact: Config, Services, Reset
- [ ] [MI-1] Create `src/shared/config/SprintConfig.luau` with shared constants; use it in `PlayerSprint.server.luau` and `RunButtonController.luau`.
- [ ] [MI-2] Throttle `PlayerSprint` update loop to `0.2s` or only fire on state change.
- [ ] [MI-3] Extract `ScoreService.server.luau` to own score aggregation/broadcast; call from `TrapController`.
- [ ] [MI-4] On reset: call `TrapController.ResetAllTraps()` and `ScoreService.ResetAll()`; broadcast zero-state so HUD clears immediately.

## Medium Impact: UI Init & Paths
- [ ] [UI-1] Add `CharacterAdded` re-init hook in `MainClient.client.luau` to rebind controllers after respawn.
- [ ] [UI-2] Document GUI hierarchy (names/paths) in `README.md`: `ActionsGui`, `HealthGui`, `StaminaGui`, `ScoreGui`.
- [ ] [UI-3] Optionally map GUIs via `default.project.json` under `StarterGui` for consistency and fewer runtime waits.

## Low Impact: Performance & Ergonomics
- [ ] [LO-1] Cache animal part references in `AnimalAnimationController` (visual, bounce, legs) to avoid per-frame tree scans.
- [ ] [LO-2] Enhance `ButtonEffects` with debounce helper and optional scale-based press effect.
- [ ] [LO-3] Standardize warning prefixes and add `DEV_MODE` toggle for verbose client logging.

## Notes
- Use short IDs (e.g., `HI-2`, `MI-3`) when referring to tasks in chat or commits.
- Tackle top-to-bottom; each item should be a single PR/commit where practical.
- Keep changes focused; avoid unrelated edits.
- Update tests or quick sanity checks if/when you add them.
