# GUI Development Workflow

## Overview

This project uses a **hybrid approach** for UI development:
- **GUIs (visual elements)**: Created and maintained in Roblox Studio
- **GUI Controllers (logic)**: Written in Luau and managed via Rojo in the filesystem

## Why This Approach?

Rojo's `.model.json` format has significant limitations:
- ❌ No support for UIGradient ColorSequences
- ❌ Limited Font/FontFace support
- ❌ Complex nested properties don't sync reliably
- ❌ Many GUI properties either ignored or incorrectly interpreted

**Studio's GUI editor is the right tool for visual design.**

## Workflow

### Creating New GUIs

1. **Design in Studio**
   - Create ScreenGuis in `StarterGui` using Studio's GUI editor
   - Use Studio's tools for colors, gradients, fonts, layouts, etc.
   - Name elements consistently for controller access

2. **Export for Backup** (Optional)
   - Right-click ScreenGui → Save to File → `.rbxmx` format
   - Save to project root for version control reference
   - These files are **backups only**, not synced by Rojo

3. **Write Controllers in Filesystem**
   - Create controller modules in `src/client/ui/`
   - Controllers should:
     - Wait for GUI elements using `:WaitForChild()`
     - Bind to events (Activated, MouseButton1Click, etc.)
     - Update properties (Text, Size, BackgroundColor3, etc.)
     - Handle UI state and animations

### Example Controller Structure

```lua
--!strict
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local MyController = {}

function MyController.Init()
    local playerGui = player:WaitForChild("PlayerGui")
    local myGui = playerGui:WaitForChild("MyGui", 5)
    if not myGui then
        warn("MyGui not found in PlayerGui")
        return
    end
    
    local button = myGui:WaitForChild("MyButton")
    button.Activated:Connect(function()
        -- Handle button click
    end)
end

return MyController
```

### Naming Conventions

- **ScreenGuis**: Use descriptive names ending in "Gui" (e.g., `ActionsGui`, `HealthGui`)
- **Controllers**: Name after the GUI they control + "Controller" (e.g., `ActionsController`, `HealthController`)
- **Child Elements**: Use PascalCase for findability (e.g., `RunButton`, `HealthBarBackground`, `HealthFill`)

## File Structure

```
project/
├── src/
│   └── client/
│       └── ui/              # All GUI controllers here
│           ├── MenuController.luau
│           ├── HealthController.luau
│           ├── StaminaController.luau
│           └── ButtonEffects.luau
├── *.rbxmx                  # GUI backups (optional)
└── default.project.json     # No StarterGui mapping!
```

## Version Control

### What to Commit
- ✅ All Luau controller scripts
- ✅ `.rbxmx` GUI backups (for reference/recovery)
- ✅ README/docs describing GUI structure

### What NOT to Commit
- ❌ `.model.json` files for GUIs (they don't work properly)
- ❌ `src/gui/` folder (removed from project)

## Updating GUIs

1. Open Roblox Studio
2. Modify GUIs in `StarterGui` using Studio's editor
3. If significant changes, re-export as `.rbxmx` for backup
4. Update controllers in filesystem if element structure changed
5. Sync Rojo (controllers only)

## Best Practices

- Keep GUI structure simple and consistent
- Document expected GUI hierarchy in controller comments
- Use descriptive names for all GUI elements
- Test controllers after GUI changes
- Keep backup `.rbxmx` files updated for major GUI changes

## Troubleshooting

### Controller can't find GUI
- Verify GUI exists in `StarterGui` in Studio
- Check spelling/capitalization matches exactly
- Ensure `:WaitForChild()` timeout is sufficient
- Check Studio output for warnings

### GUI doesn't appear in game
- Check `ResetOnSpawn` property on ScreenGui
- Verify `Enabled` is true
- Check `DisplayOrder` for layering issues

### Changes not syncing
- GUIs changes require Studio save (not Rojo sync)
- Controller changes sync via Rojo
- Restart Studio if sync issues persist
