--========================================================--
-- SprintWithStaminaServer.lua
--========================================================--
-- Handles all sprinting and stamina logic on the server.
-- Authoritative: Clients can only request to sprint,
-- but the server validates and applies the change.
--========================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 🔹 Create or get the RemoteEvent used for sprint communication
local SprintEvent = ReplicatedStorage:FindFirstChild("SprintEvent") or Instance.new("RemoteEvent")
SprintEvent.Name = "SprintEvent"
SprintEvent.Parent = ReplicatedStorage

-- 🔹 Sprint parameters
local NORMAL_SPEED = 17
local SPRINT_SPEED = 30

-- 🔹 Stamina configuration
local MAX_STAMINA = 100
local STAMINA_DRAIN_RATE = 15        -- points per second while sprinting
local STAMINA_RECOVERY_RATE = 10     -- points per second while not sprinting
local UPDATE_INTERVAL = 0.1          -- seconds between updates
       

-- 🔹 Internal data store
local playerData = {}

------------------------------------------------------------
-- Player Management
------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	playerData[player] = {
		Stamina = MAX_STAMINA,
		IsSprinting = false,
		LastUpdate = tick(),
	}
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
end)

------------------------------------------------------------
-- Handle sprint toggle requests from clients
------------------------------------------------------------

SprintEvent.OnServerEvent:Connect(function(player, wantSprint)
	local data = playerData[player]
	if not data then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- If trying to sprint with no stamina, deny request
	if wantSprint and data.Stamina <= 0 then
		wantSprint = false
	end

	data.IsSprinting = wantSprint
	local newSpeed = wantSprint and SPRINT_SPEED or NORMAL_SPEED
	humanoid.WalkSpeed = newSpeed

	-- 🔹 Tell the client what the server actually applied
	SprintEvent:FireClient(player, data.IsSprinting, data.Stamina)
end)

------------------------------------------------------------
-- Stamina update loop
------------------------------------------------------------

task.spawn(function()
	while true do
		for player, data in pairs(playerData) do
			local now = tick()
			local dt = now - (data.LastUpdate or now)
			data.LastUpdate = now

			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if data.IsSprinting then
				-- Drain stamina
				data.Stamina -= STAMINA_DRAIN_RATE * dt
				if data.Stamina <= 0 then
					data.Stamina = 0
					data.IsSprinting = false
					if humanoid then
						humanoid.WalkSpeed = NORMAL_SPEED
					end
				end
			else
				-- Recover stamina
				data.Stamina = math.min(MAX_STAMINA, data.Stamina + STAMINA_RECOVERY_RATE * dt)

				-- 🔹 If key is still held and stamina refilled above threshold, resume sprint
				-- The client will send a new sprint request automatically when this happens.
			end

			-- 🔹 Send update to the client (for UI + logic)
			SprintEvent:FireClient(player, data.IsSprinting, data.Stamina)
		end

		task.wait(UPDATE_INTERVAL)
	end
end)
