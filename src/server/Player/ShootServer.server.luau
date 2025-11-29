local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lifeModule = require(game.ServerScriptService.Server.Player:WaitForChild("LifePointsServer"))

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ShootEvent = RemoteEvents.ShootEvent

local PROJECTILE_SPEED = 200
local PROJECTILE_LIFETIME = 2
local DAMAGE = 25
local HIT_RADIUS = 2

local function createProjectile(player)
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
