# Roblox Game Development Learning Path

## You've Completed ✅
- Basic Rojo project structure
- Client/server separation and communication
- RemoteEvent usage (client → server → client)

## Next Steps

### 1. **Framework (Knit or Aero)**
Structure your game with services (server) and controllers (client).

**Knit Setup:**
```bash
# Install Wally if not already
aftman add UpliftGames/wally

# Create wally.toml
wally init

# Add Knit dependency
[dependencies]
Knit = "sleitnick/knit@1"
```

**Learn:**
- Services (server-side singletons)
- Controllers (client-side singletons)
- Lifecycle methods (Init, Start)
- Cross-service communication

**Resources:**
- [Knit Documentation](https://sleitnick.github.io/Knit/)
- [Knit GitHub](https://github.com/Sleitnick/Knit)

---

### 2. **Package Management (Wally)**
Manage dependencies like a pro.

**Common Packages:**
```toml
[dependencies]
Knit = "sleitnick/knit@1"
Promise = "evaera/promise@4"
Comm = "sleitnick/comm@0"
ProfileService = "madstudioroblox/profileservice@0"
```

**Workflow:**
```bash
wally install  # Install dependencies
rojo serve     # Sync with Studio
```

---

### 3. **Testing (TestEZ)**
Write unit tests for your modules.

**Example Test:**
```lua
return function()
    describe("Calculator", function()
        it("should add two numbers", function()
            local result = Calculator.add(2, 3)
            expect(result).to.equal(5)
        end)
    end)
end
```

**Resources:**
- [TestEZ GitHub](https://github.com/Roblox/testez)

---

### 4. **Data Persistence (ProfileService)**
Save player data across sessions.

**ProfileService Benefits:**
- Session locking (prevents data loss)
- Auto-saves on interval
- Handles player leave/rejoin

**Example:**
```lua
local ProfileService = require(ReplicatedStorage.Packages.ProfileService)

local PlayerStore = ProfileService.GetProfileStore(
    "PlayerData",
    {
        Coins = 0,
        Level = 1,
    }
)

-- Load profile when player joins
PlayerStore:LoadProfileAsync("Player_" .. player.UserId)
```

**Resources:**
- [ProfileService Docs](https://madstudioroblox.github.io/ProfileService/)

---

### 5. **UI (Roact or Fusion)**
Build reactive UI components.

**Roact:** React-like declarative UI
**Fusion:** Lightweight reactive state management

**Example (Fusion):**
```lua
local button = New "TextButton" {
    Text = Computed(function()
        return "Coins: " .. state.coins:get()
    end),
    [OnEvent "Activated"] = function()
        state.coins:set(state.coins:get() + 1)
    end
}
```

**Resources:**
- [Fusion GitHub](https://github.com/Elttob/Fusion)
- [Roact GitHub](https://github.com/Roblox/roact)

---

### 6. **Build Game Systems**

**Inventory System:**
- Client: Display items in UI
- Server: Validate item grants/removals
- Use RemoteEvents for actions

**Combat System:**
- Hitbox detection (spatial query or raycasting)
- Damage calculation on server
- Cooldowns and anti-cheat

**Shop System:**
- RemoteFunction for purchase requests
- Server validates currency
- Returns success/failure

**Leaderboards:**
- Use OrderedDataStore
- Update on interval
- Display top players in UI

---

## Learning Resources

- **[Roblox Creator Hub](https://create.roblox.com/docs)** – Official documentation
- **[Rojo Docs](https://rojo.space/docs/)** – Rojo workflow and project structure
- **[DevForum](https://devforum.roblox.com/)** – Community support and tutorials
- **[Roblox OSS](https://github.com/Roblox)** – Official open-source libraries

---

## Practice Projects

1. **Coin Collector Game**
   - Player collects coins in Workspace
   - Save coin count with ProfileService
   - Display UI with total coins

2. **Simple Obby**
   - Build course with checkpoints
   - Save progress per player
   - Add leaderboard for fastest times

3. **Basic Combat Arena**
   - Sword tool with hitbox detection
   - Health system with respawning
   - Kill/death leaderboard

4. **Shop System**
   - Players buy items with coins
   - Inventory management
   - Equip/unequip items

---

## Tips

- **Always validate on server:** Never trust client input
- **Use WaitForChild():** Ensure instances exist before accessing
- **Avoid while true loops:** Use RunService.Heartbeat or task.wait()
- **Profile your code:** Use MicroProfiler and Script Profiler
- **Read DevForum:** Community is incredibly helpful

Happy developing! 🎮
