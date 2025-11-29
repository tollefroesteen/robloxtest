--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrapController = require(game.ServerScriptService.Server.Game.TrapController)
local Flock = workspace:WaitForChild("Flock")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ResetGameEvent = RemoteEvents.ResetGameEvent

-- Reset all animals to spawn attributes
local function resetFlock()
	for _, part in ipairs(Flock:GetChildren()) do
		if part:IsA("BasePart") then

			local x = part:GetAttribute("SpawnX")
			local y = part:GetAttribute("SpawnY")
			local z = part:GetAttribute("SpawnZ")

			if x and y and z then
				part.Anchored = false
				part:SetAttribute("Captured", false)
				part:SetAttribute("CapturedBy", nil)

				part.CFrame = CFrame.new(x, y, z)
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			else
				warn("Missing spawn attributes for:", part.Name)
			end
		end
	end
end

-- Respawn all players
local function respawnAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter()
	end
end

-- Full reset
local function resetGame()
	print("🔄 Resetting game...")

	resetFlock()
	TrapController.ResetAllTraps() -- ⭐ IMPORTANT ⭐
	respawnAllPlayers()

	print("✅ Game reset finished")
end

-- Remote trigger from GUI or admin
ResetGameEvent.OnServerEvent:Connect(function(player)
	print(player.Name .. " requested restart")
	resetGame()
end)
