local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local HealthEvent = RemoteEvents.HealthEvent
local RespawnCountdownEvent = RemoteEvents.RespawnCountdownEvent

local MAX_LIFE = 100
local RESPAWN_DELAY = 5 -- Seconds before respawn
local SPAWN_PROTECTION_SHIELD_HP = 200 -- High HP shield for spawn protection (absorbs multiple hits)
local SPAWN_PROTECTION_DURATION = 5 -- Seconds spawn protection lasts (time limit)

-- Disable automatic respawn - we handle it manually with countdown
Players.CharacterAutoLoads = false

-- Lazy load ShieldService to check for active shields
local ShieldService: any = nil
local function getShieldService()
	if not ShieldService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Player.ShieldService)
		end)
		if success then
			ShieldService = service
		end
	end
	return ShieldService
end

-- Lazy load SpawnService for team-based spawning
local SpawnService: any = nil
local function getSpawnService()
	if not SpawnService then
		local success, service = pcall(function()
			return require(ServerScriptService.Server.Game.SpawnService)
		end)
		if success then
			SpawnService = service
		end
	end
	return SpawnService
end

-- Stores each player's life points
local playerLife = {}

-- Track if player is currently in respawn sequence (prevent double-triggering)
local playersRespawning: { [Player]: boolean } = {}

-- Create a BillboardGui to show countdown above dead player
local function createDeathCountdownGui(character: Model): BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "DeathCountdownGui"
	billboardGui.Size = UDim2.new(0, 120, 0, 60)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.MaxDistance = 100
	
	local frame = Instance.new("Frame")
	frame.Name = "Background"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = billboardGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local label = Instance.new("TextLabel")
	label.Name = "CountdownLabel"
	label.Size = UDim2.new(1, 0, 0.6, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.TextScaled = true
	label.Text = "5"
	label.Parent = frame
	
	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "SubLabel"
	subLabel.Size = UDim2.new(1, 0, 0.4, 0)
	subLabel.Position = UDim2.new(0, 0, 0.6, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.Gotham
	subLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	subLabel.TextScaled = true
	subLabel.Text = "RESPAWNING"
	subLabel.Parent = frame
	
	-- Attach to HumanoidRootPart
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		billboardGui.Adornee = rootPart
		billboardGui.Parent = character
	end
	
	return billboardGui
end

-- Update the countdown display
local function updateDeathCountdownGui(character: Model, secondsLeft: number)
	local gui = character:FindFirstChild("DeathCountdownGui")
	if not gui then return end
	
	local frame = gui:FindFirstChild("Background")
	if not frame then return end
	
	local label = frame:FindFirstChild("CountdownLabel")
	if label then
		label.Text = tostring(secondsLeft)
	end
end

-- Remove the countdown GUI
local function removeDeathCountdownGui(character: Model)
	local gui = character:FindFirstChild("DeathCountdownGui")
	if gui then
		gui:Destroy()
	end
end

-- Handle the respawn countdown sequence
local function startRespawnSequence(player: Player)
	-- Prevent double-triggering
	if playersRespawning[player] then return end
	playersRespawning[player] = true
	
	local character = player.Character
	
	-- Create countdown billboard above the dead player
	if character then
		createDeathCountdownGui(character)
	end

	-- Send initial countdown to client UI
	RespawnCountdownEvent:FireClient(player, RESPAWN_DELAY, true) -- true = started

	-- Countdown loop
	for i = RESPAWN_DELAY, 1, -1 do
		-- Update billboard above player
		if character then
			updateDeathCountdownGui(character, i)
		end
		
		-- Update client UI
		RespawnCountdownEvent:FireClient(player, i, true)
		
		task.wait(1)
	end

	-- Clean up billboard
	if character then
		removeDeathCountdownGui(character)
	end

	-- Signal countdown ended
	RespawnCountdownEvent:FireClient(player, 0, false) -- false = ended

	-- Set spawn location based on team before respawning
	local spawnSvc = getSpawnService()
	if spawnSvc then
		spawnSvc.SetPlayerSpawnLocation(player)
	end

	-- Respawn player
	player:LoadCharacter()

	-- Reset life
	playerLife[player] = MAX_LIFE

	-- Send reset health to UI
	HealthEvent:FireClient(player, MAX_LIFE, MAX_LIFE)
	
	-- Grant spawn protection shield (free, no item consumed, time-limited)
	task.delay(0.1, function()  -- Small delay to ensure character is fully loaded
		local shieldSvc = getShieldService()
		if shieldSvc then
			shieldSvc.ActivateShield(player, SPAWN_PROTECTION_SHIELD_HP, SPAWN_PROTECTION_DURATION)
		end
	end)
	
	-- Clear respawning flag
	playersRespawning[player] = nil
end

-- Fired when player joins
Players.PlayerAdded:Connect(function(player)
	playerLife[player] = MAX_LIFE

	player.CharacterAdded:Connect(function(character)
		playerLife[player] = MAX_LIFE

		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Health = MAX_LIFE

		-- Send full life to UI when character spawns
		HealthEvent:FireClient(player, MAX_LIFE, MAX_LIFE)
		
		-- Listen for death from ANY source (damage, /die command, fall damage, etc.)
		humanoid.Died:Connect(function()
			task.spawn(function()
				startRespawnSequence(player)
			end)
		end)
	end)
	
	-- Manually load the character since CharacterAutoLoads is false
	-- Set spawn location based on team (if in game) or default
	local spawnSvc = getSpawnService()
	if spawnSvc then
		spawnSvc.SetPlayerSpawnLocation(player)
	end
	player:LoadCharacter()
end)

-- Handle players already in the game (for late script loading)
for _, player in Players:GetPlayers() do
	if not player.Character then
		playerLife[player] = MAX_LIFE
		local spawnSvc = getSpawnService()
		if spawnSvc then
			spawnSvc.SetPlayerSpawnLocation(player)
		end
		player:LoadCharacter()
	end
end

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	playerLife[player] = nil
end)


-- Damage function (called by projectile script)
local function damagePlayer(targetPlayer, amount)
	if not playerLife[targetPlayer] then return end
	
	-- Don't damage if already respawning
	if playersRespawning[targetPlayer] then return end
	
	-- Check if player has active shield - shield absorbs damage first
	local shieldSvc = getShieldService()
	local damageToApply = amount
	
	if shieldSvc and shieldSvc.HasShield(targetPlayer) then
		-- Shield absorbs damage, returns any remaining damage that passes through
		damageToApply = shieldSvc.DamageShield(targetPlayer, amount)
		
		-- If shield absorbed all damage, we're done
		if damageToApply <= 0 then
			return
		end
	end

	playerLife[targetPlayer] -= damageToApply
	local currentLife = math.clamp(playerLife[targetPlayer], 0, MAX_LIFE)

	local character = targetPlayer.Character
	local humanoid = character and character:FindFirstChild("Humanoid")

	-- Update humanoid HP for consistency
	if humanoid then
		humanoid.Health = currentLife
	end

	-- Send updated life to player UI
	HealthEvent:FireClient(targetPlayer, currentLife, MAX_LIFE)

	-- If dead, the Humanoid.Died event will trigger the respawn sequence
	if currentLife <= 0 then
		playerLife[targetPlayer] = 0
	end
end

return {
	damagePlayer = damagePlayer
}
