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
local BOUNCE_HEIGHT = 3 -- Height above terrain to maintain
local GRAVITY_STRENGTH = 6.5 -- How strongly projectile is pulled down
local BOUNCE_ELASTICITY = 0.7 -- Bounce damping (0-1)

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

	local direction = (root.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit -- Flatten Y component
	local verticalVelocity = 0 -- Track vertical momentum
	local startTime = tick()

	-- Raycast params to ignore the shooting player
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	while tick() - startTime < PROJECTILE_LIFETIME do
		local dt = task.wait()
		
		-- Apply gravity to vertical velocity
		verticalVelocity = verticalVelocity - GRAVITY_STRENGTH
		
		-- Calculate new position with horizontal and vertical components
		local horizontalMovement = direction * PROJECTILE_SPEED * dt
		local verticalMovement = Vector3.new(0, verticalVelocity * dt, 0)
		local newPos = projectile.Position + horizontalMovement + verticalMovement

		-- Check for terrain/ground below
		local downRay = workspace:Raycast(
			projectile.Position,
			Vector3.new(0, -10, 0),
			rayParams
		)

		if downRay then
			local terrainHeight = downRay.Position.Y
			
			-- If projectile would go below bounce height, bounce it back up
			if newPos.Y < terrainHeight + BOUNCE_HEIGHT then
				newPos = Vector3.new(newPos.X, terrainHeight + BOUNCE_HEIGHT, newPos.Z)
				verticalVelocity = math.abs(verticalVelocity) * BOUNCE_ELASTICITY -- Bounce up with damping
			end
		end

		-- Raycast for player hits in horizontal direction
		local forwardRay = workspace:Raycast(
			projectile.Position,
			horizontalMovement,
			rayParams
		)

		if forwardRay then
			local hit = forwardRay.Instance

			-- Player hit
			local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
			if hitPlayer and hitPlayer ~= player then
				lifeModule.damagePlayer(hitPlayer, DAMAGE)
				projectile:Destroy()
				return
			end

			-- Wall/obstacle hit (bounce off)
			local normal = forwardRay.Normal
			direction = (direction - 2 * direction:Dot(normal) * normal).Unit
			projectile.Position = forwardRay.Position
		else
			projectile.Position = newPos
		end

		-- Additional sphere check for nearby players
		local region = Region3.new(projectile.Position - Vector3.new(HIT_RADIUS, HIT_RADIUS, HIT_RADIUS), 
									projectile.Position + Vector3.new(HIT_RADIUS, HIT_RADIUS, HIT_RADIUS))
		region = region:ExpandToGrid(4)
		
		for _, part in workspace:FindPartsInRegion3(region, projectile, 100) do
			local hitPlayer = Players:GetPlayerFromCharacter(part.Parent)
			if hitPlayer and hitPlayer ~= player then
				lifeModule.damagePlayer(hitPlayer, DAMAGE)
				projectile:Destroy()
				return
			end
		end
	end

	projectile:Destroy()
end

ShootEvent.OnServerEvent:Connect(createProjectile)
