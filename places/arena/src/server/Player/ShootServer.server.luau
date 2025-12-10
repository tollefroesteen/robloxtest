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

-- Lazy load PlayerUpgradesService
local PlayerUpgradesService: any = nil
local function getPlayerUpgradesService()
	if not PlayerUpgradesService then
		local success, service = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("services"):WaitForChild("PlayerUpgradesService"))
		end)
		if success then
			PlayerUpgradesService = service
		end
	end
	return PlayerUpgradesService
end

-- Find nearest enemy player for heat-seeking
local function findNearestEnemy(shooter: Player, position: Vector3, maxRange: number): Player?
	local nearestPlayer: Player? = nil
	local nearestDistance = maxRange
	
	for _, player in Players:GetPlayers() do
		if player ~= shooter and player.Character then
			local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
			if enemyRoot then
				local distance = (enemyRoot.Position - position).Magnitude
				if distance < nearestDistance then
					nearestPlayer = player
					nearestDistance = distance
				end
			end
		end
	end
	
	return nearestPlayer
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

-- Heat-seeking parameters (adjustable for tuning)
local HEAT_SEEK_RANGE = 50 -- Max range to detect enemies
local HEAT_SEEK_STRENGTH = 0.15 -- How strongly it turns toward target (0-1, lower = more subtle)
local HEAT_SEEK_UPDATE_INTERVAL = 0.1 -- How often to update target

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
	
	-- Check if player has heat-seeking upgrade
	local upgradesService = getPlayerUpgradesService()
	local hasHeatSeeking = upgradesService and upgradesService.HasUpgrade(player, "HeatSeekingAmmo") or false
	local lastSeekUpdate = 0
	local currentTarget: Player? = nil
	while tick() - startTime < PROJECTILE_LIFETIME do
		local dt = task.wait()
		local currentTime = tick()
		
		-- Heat-seeking behavior
		if hasHeatSeeking and currentTime - lastSeekUpdate >= HEAT_SEEK_UPDATE_INTERVAL then
			lastSeekUpdate = currentTime
			currentTarget = findNearestEnemy(player, projectile.Position, HEAT_SEEK_RANGE)
			
			if currentTarget and currentTarget.Character then
				local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					-- Calculate direction to target (flatten Y for ground-hugging)
					local toTarget = (targetRoot.Position - projectile.Position) * Vector3.new(1, 0, 1)
					if toTarget.Magnitude > 0 then
						local targetDirection = toTarget.Unit
						-- Blend current direction with target direction
						direction = (direction + targetDirection * HEAT_SEEK_STRENGTH).Unit
					end
				end
			end
		end
		
		-- Apply gravity to vertical velocity
		verticalVelocity = verticalVelocity - GRAVITY_STRENGTH
		
		-- Calculate new position with horizontal and vertical components
		local horizontalMovement = direction * PROJECTILE_SPEED * dt
		local verticalMovement = Vector3.new(0, verticalVelocity * dt, 0)
		local newPos = projectile.Position + horizontalMovement + verticalMovement
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
