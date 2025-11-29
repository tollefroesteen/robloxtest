# Roblox Project Refactoring & Organization Suggestions

These recommendations aim to improve clarity, maintainability, and robustness across client/server boundaries, following common Roblox + Rojo conventions.

## Folder Structure & Naming
- **Consistent controllers/services:**
  - Client: `src/client/ui/*Controller.luau` (UI-specific) and `src/client/controllers/*Controller.luau` (non-UI client logic like `AnimalAnimationController`).
  - Server: `src/server/services/*Service.luau` (game systems) and `src/server/game/*` (content-specific modules like trap logic).
- **Avoid ambiguous top-level names:** Prefer `Services`, `Controllers`, `Systems` over generic `Game` when possible.
- **Move `AnimalAnimationController.luau` to `src/client/controllers/AnimalController.luau`**: not UI, belongs in controllers.

## Remote & Bindable Event Management
- **Single source of truth:** Keep all RemoteEvents in `src/shared/RemoteEvents.luau` and Bindables in `src/server/ServerEvents.luau`.
- **Server bootstrap:** In `MainServer.server.luau` (or equivalent), `require(ReplicatedStorage.Shared.RemoteEvents)` early to ensure events exist.
- **Event names:** Use consistent verbs: `StartGame`, `ResetGame`, `UpdateScore`, `SprintState`.
- **Avoid tree `WaitForChild` on Remotes:** Prefer `require(RemoteEvents).XEvent` over `ReplicatedStorage:WaitForChild()` to eliminate timing issues.

## Sprint System
- **Client subscription pattern:** Good. Keep listener hookup at module scope before any `require`.
- **Server throttling:** Consider only `FireClient` when state changes or every 0.2–0.25s to reduce traffic.
- **Permissions and validation:** Server should ignore non-boolean sprint requests (except subscription) and clamp speeds via humanoid state.
- **Consolidate config:** Extract sprint and stamina constants to `src/shared/config/SprintConfig.luau` for shared tuning.

## Trap & Scoring System
- **Module ownership:** `TrapController` does capture + scoring; consider splitting:
  - `TrapService` (server): owns trap registration and reset (`ActiveTraps`).
  - `ScoreService` (server): owns score aggregation and broadcasting.
- **Reset flow:** On reset, call `TrapService.ResetAll()` and `ScoreService.ResetAll()`; `ScoreService` should emit zero-state to clients so HUD reflects reset immediately.
- **Data model:** Use a table keyed by `trapType` and possibly `team` to keep structure explicit: `{ ["Team A"] = { score = 0, traps = {"GoalA"} } }`.

## UI Controllers
- **Initialization sequencing:** You already re-init on `PlayerGui.ChildAdded`. Also consider listening for `CharacterAdded` to rebind after respawns.
- **ButtonEffects:** Great reuse. Add an optional debounce helper and support scale-based press (size + position) for 3D-style buttons.
- **MenuController vs specific controllers:** Keep `MenuController` narrow (only menu logic). Action buttons (Run, Shoot, Reset) correctly moved to dedicated controllers.
- **Paths:** Standardize GUI names: `ActionsGui`, `HealthGui`, `StaminaGui`, `ScoreGui`. Document required hierarchy in a README section.

## Error Handling & Diagnostics
- **Warnings:** Standardize warning prefixes: `[RunButtonController]`, `[ScoreController]`, etc.
- **Guard clauses:** Favor early returns when paths fail; you’ve applied this well.
- **Client diagnostics:** Add optional `DEV_MODE` flag to print state transitions for sprinting and scores.

## Performance
- **RenderStepped usage:** In `AnimalAnimationController`, avoid heavy work per frame:
  - Cache references (`visual`, `bounce`, legs) once per animal; refresh only when children change.
  - Consider using `Heartbeat` for non-visual logic; keep RenderStepped minimal.
- **Server loops:** In `PlayerSprint`, lift update interval to `0.2` if acceptable to reduce churn; batch updates with state-change detection.

## Type Safety & Luau Annotations
- **Add types:** Annotate function params and module return types, e.g., `function SetupTrap(trap: BasePart)` and controller tables.
- **Enable strict mode:** Add `--!strict` at top of modules to catch type errors.

## Configuration & Constants
- **Shared config modules:**
  - `src/shared/config/UIConfig.luau` – colors, offsets, tween times.
  - `src/shared/config/GameConfig.luau` – grid sizes, trap spacing.
- **No magic numbers:** Replace hardcoded values (e.g., `GRID_COLS`, `CELL_SPACING_X`) with config imports.

## Security & Authority
- **Reset permissions:** Validate the reset requester on server (`if player.UserId ~= ADMIN_ID then return end`).
- **Server-side validation:** Already present in sprint; similarly ensure trap captures validate animal/root membership (`isFlockRoot`).

## Rojo Project Mapping
- **Explicit mapping for GUIs:** Consider mapping UI via `default.project.json` under `StarterGui` to avoid name mismatches.
- **Consistent server/client folders:** You’ve moved off `init.*`, which is good. Keep folders (`Server`, `Client`) and avoid accidental scripts named after folders.

## Suggested TODOs
1. Move `AnimalAnimationController.luau` to `src/client/controllers/` and update require path.
2. Create `ScoreService.server.luau` to own scoring and zero-broadcast on reset.
3. Add a shared `SprintConfig.luau`; use in both client and server.
4. Add `--!strict` to modules and basic type annotations.
5. Throttle `PlayerSprint` updates to 0.2s or on state change.
6. Add `CharacterAdded` re-init hook to UI `MainClient.client.luau`.
7. Document GUI hierarchy in `README.md` so future changes don’t break paths.

## Example: Shared SprintConfig
```lua
-- src/shared/config/SprintConfig.luau
return {
    NORMAL_SPEED = 17,
    SPRINT_SPEED = 30,
    MAX_STAMINA = 100,
    DRAIN_RATE = 15,
    RECOVERY_RATE = 10,
    UPDATE_INTERVAL = 0.2, -- slower to reduce spam
    RESUME_THRESHOLD = 20,
}
```

## Example: ScoreService Skeleton
```lua
-- src/server/services/ScoreService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local ScoreService = {}
local totalsByTrapType = {}

function ScoreService.Apply(trapType: string, animalType: string, trapName: string)
    local delta = (trapType == animalType) and 1 or -1
    totalsByTrapType[trapType] = (totalsByTrapType[trapType] or 0) + delta
    RemoteEvents.ScoreEvent:FireAllClients({
        delta = delta,
        trapType = trapType,
        animalType = animalType,
        totalForTrapType = totalsByTrapType[trapType],
        trapName = trapName,
    })
end

function ScoreService.ResetAll()
    totalsByTrapType = {}
    -- Broadcast zero-state if you want HUD to clear immediately
    RemoteEvents.ResetGameEvent:FireAllClients()
end

return ScoreService
```

Implementing these changes incrementally will keep your project clean and predictable as it grows. Ready to proceed with moving `AnimalAnimationController` and introducing `SprintConfig`?
