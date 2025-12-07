local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local lifeModule = require(game.ServerScriptService.Server.Player:WaitForChild("LifePointsServer"))

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ShootEvent = RemoteEvents.ShootEvent
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

-- Lazy load InventoryService from shared
local InventoryService: any = nil
local function getInventoryService()
	if not InventoryService then
		local success, service = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("services"):WaitForChild("InventoryService"))
		end)
		if success then
			InventoryService = service
		end
	end
	return InventoryService
end

-- Lazy load GameEndService to check game state
local GameEndService: any = nil
local function getGameEndService()
	if not GameEndService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Game.GameEndService)
		end)
		if success then
			GameEndService = service
		end
	end
	return GameEndService
end

local AMMO_ITEM_ID = "AMMO_BASIC"
local AMMO_PER_SHOT = 1

local PROJECTILE_SPEED = 200
local PROJECTILE_LIFETIME = 2
local DAMAGE = 25
local HIT_RADIUS = 2

local function createProjectile(player)
	-- Check if game is in end-processing state
	local gameEndSvc = getGameEndService()
	if gameEndSvc and gameEndSvc.IsProcessingGameEnd() then
		return -- Silently ignore shots during game end
	end
	
	-- Check and consume ammo
	local invService = getInventoryService()
	if invService then
		if not invService.HasItem(player, AMMO_ITEM_ID, AMMO_PER_SHOT) then
			Log.Info("ShootServer", string.format("%s tried to shoot but has no ammo", player.Name))
			return -- No ammo, don't shoot
		end
		
		-- Consume the ammo
		local success, msg = invService.RemoveItem(player, AMMO_ITEM_ID, AMMO_PER_SHOT)
		if not success then
			Log.Warn("ShootServer", string.format("Failed to consume ammo for %s: %s", player.Name, msg))
			return
		end
	end

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Visual projectile
	local projectile = Instance.new("Part")
	projectile.Shape = Enum.PartType.Ball
	projectile.Size = Vector3.new(2,2,2)
	projectile.Color = Color3.fromRGB(255,50,50)
	projectile.CanCollide = false
	projectile.Anchored = true
	projectile.Material = Enum.Material.Neon
	projectile.Parent = workspace
	projectile.Position = root.Position + root.CFrame.LookVector * 2

	local direction = root.CFrame.LookVector.Unit
	local startTime = tick()
	local lastPos = projectile.Position

	while tick() - startTime < PROJECTILE_LIFETIME do
		local dt = task.wait()
		local newPos = projectile.Position + direction * PROJECTILE_SPEED * dt

		-- Raycast for wall/player hit
		local result = workspace:Raycast(
			projectile.Position,
			(newPos - projectile.Position),
			RaycastParams.new()
		)

		if result then
			local hit = result.Instance

			-- Player hit
			local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
			if hitPlayer and hitPlayer ~= player then
				lifeModule.damagePlayer(hitPlayer, DAMAGE)
				projectile:Destroy()
				return
			end

			-- Wall/obstacle hit
			projectile.Position = result.Position
			projectile:Destroy()
			return
		end

		projectile.Position = newPos
	end

	projectile:Destroy()
end

ShootEvent.OnServerEvent:Connect(createProjectile)
