local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HealthEvent = ReplicatedStorage:WaitForChild("HealthEvent")

local MAX_LIFE = 100

-- Stores each player's life points
local playerLife = {}

-- Fired when player joins
Players.PlayerAdded:Connect(function(player)
	playerLife[player] = MAX_LIFE

	player.CharacterAdded:Connect(function(character)
		playerLife[player] = MAX_LIFE

		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Health = MAX_LIFE

		-- Send full life to UI when character spawns
		HealthEvent:FireClient(player, MAX_LIFE, MAX_LIFE)
	end)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	playerLife[player] = nil
end)

-- Damage function (called by projectile script)
local function damagePlayer(targetPlayer, amount)
	if not playerLife[targetPlayer] then return end

	playerLife[targetPlayer] -= amount
	local currentLife = math.clamp(playerLife[targetPlayer], 0, MAX_LIFE)

	local character = targetPlayer.Character
	local humanoid = character and character:FindFirstChild("Humanoid")

	-- Update humanoid HP for consistency
	if humanoid then
		humanoid.Health = currentLife
	end

	-- Send updated life to player UI
	HealthEvent:FireClient(targetPlayer, currentLife, MAX_LIFE)

	-- If dead
	if currentLife <= 0 then
		playerLife[targetPlayer] = 0

		-- Kill humanoid to trigger animation
		if humanoid then
			humanoid.Health = 0
		end

		-- Wait before respawn
		task.wait(2)

		-- Respawn player
		targetPlayer:LoadCharacter()

		-- Reset life
		playerLife[targetPlayer] = MAX_LIFE

		-- Send reset health to UI
		HealthEvent:FireClient(targetPlayer, MAX_LIFE, MAX_LIFE)
	end
end

return {
	damagePlayer = damagePlayer
}
