# Flat Zone Commands

The flat zone system allows you to create multiple rectangular flat areas anywhere in the play area. This is useful for setting up lobby areas, spawn points, or other structures that need flat ground.

## Quick Reference

| Command | Description |
|---------|-------------|
| `/flat` | List all flat zones |
| `/flat on` / `/flat off` | Enable/disable all flat zones |
| `/flat enable <name>` | Enable a specific zone |
| `/flat disable <name>` | Disable a specific zone |
| `/flat add <name> <x> <z> <sizeX> <sizeZ> <h> [blend]` | Add a new flat zone |
| `/flat remove <name>` | Remove a flat zone |
| `/flat move <name> <x> <z>` | Move a zone to new position |
| `/flat resize <name> <sizeX> <sizeZ>` | Change zone dimensions |
| `/flat height <name> <h>` | Set zone height |
| `/flat blend <name> <d>` | Set edge blend distance |
| `/flat clear` | Remove all flat zones |

## Detailed Commands

### `/flat`
Lists all defined flat zones with their current settings (position, size, height, blend, enabled state).

### `/flat on` / `/flat off`
Master enable/disable for the entire flat zones system. When off, all zones are ignored.

### `/flat enable <name>` / `/flat disable <name>`
Enable or disable a specific flat zone by name without removing it.

### `/flat add <name> <x> <z> <sizeX> <sizeZ> <height> [blend]`
Creates a new flat zone:
- **name**: Unique identifier (no spaces)
- **x, z**: Center position in world coordinates
- **sizeX, sizeZ**: Dimensions (10-500 studs each)
- **height**: Height above water level (-10 to 100 studs)
- **blend**: Edge transition distance (0-100, default: 10)

Examples:
```
/flat add lobby 0 0 100 120 1 15
/flat add spawn_north 0 -100 40 40 2
/flat add arena_center 50 30 60 60 0 20
```

### `/flat remove <name>`
Permanently removes a flat zone by name.

### `/flat move <name> <x> <z>`
Repositions an existing flat zone to new coordinates.

### `/flat resize <name> <sizeX> [sizeZ]`
Changes the dimensions of an existing zone. If sizeZ is omitted, creates a square.

### `/flat height <name> <value>`
Sets the height of a specific zone (-10 to 100 studs).

### `/flat blend <name> <distance>`
Sets the edge transition distance for a specific zone (0-100 studs).

### `/flat clear`
Removes all flat zones at once.

## Command Bar Functions

For Studio command bar access:

```lua
-- View all zones
_G.FlatZones()

-- Add a new zone
_G.AddFlatZone("lobby", 0, 0, 100, 120, 1, 15)

-- Remove a zone
_G.RemoveFlatZone("lobby")

-- Move a zone
_G.MoveFlatZone("lobby", 50, 0)

-- Resize a zone
_G.ResizeFlatZone("lobby", 80, 100)

-- Set height
_G.SetFlatZoneHeight("lobby", 2)

-- Set blend
_G.SetFlatZoneBlend("lobby", 20)

-- Enable/disable a zone
_G.EnableFlatZone("lobby", true)
_G.EnableFlatZone("lobby", false)

-- Clear all zones
_G.ClearFlatZones()
```

## Configuration File Setup

You can pre-define flat zones in `TestProceduralEnvironment.server.luau`:

```lua
local FLAT_ZONES: {ProceduralConfig.FlatZoneDefinition} = {
    {
        Name = "lobby",
        Enabled = true,
        OriginX = 0,
        OriginZ = 0,
        SizeX = 80,
        SizeZ = 100,
        Height = 1,
        BlendDistance = 10,
    },
    {
        Name = "spawn_north",
        Enabled = true,
        OriginX = 0,
        OriginZ = -120,
        SizeX = 40,
        SizeZ = 40,
        Height = 2,
        BlendDistance = 8,
    },
}
```

## Example Configurations

### Central Lobby with Side Spawns
```
/flat add lobby 0 0 100 120 1 15
/flat add spawn_east 100 0 30 30 1 10
/flat add spawn_west -100 0 30 30 1 10
/regen
```

### Tournament Arena Setup
```
/flat add main_arena 0 0 150 180 0 20
/flat add team_a -80 0 40 40 2 8
/flat add team_b 80 0 40 40 2 8
/regen
```

### Scattered Platforms
```
/flat add platform1 -60 -60 25 25 3 5
/flat add platform2 60 -60 25 25 3 5
/flat add platform3 0 80 25 25 3 5
/regen
```

## Tips

1. **Always run `/regen` after making changes** to see flat zones applied to terrain.

2. **Zone names must be unique** - use descriptive names like "lobby", "spawn_a", "arena_center".

3. **Overlapping zones**: If zones overlap, the first zone found (in definition order) takes priority for the overlapping area.

4. **Blend zones can overlap**: Multiple blend zones will use the closest/strongest influence.

5. **Use `/flat` to see current state** before making changes.

6. **Negative heights work** - use height -5 to create a sunken area.

7. **Zero blend creates sharp edges** - useful for platforms or distinct areas.

## Interaction with Other Features

- **Irish Hills**: Hills are automatically suppressed within flat zones and their blend areas
- **Mountains**: Flat zones only affect the play area, mountains are unaffected
- **Foliage**: Foliage placement is independent (may still spawn in flat zones)
