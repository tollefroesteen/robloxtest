--!strict
--========================================================--
-- SprintWithStaminaServer.lua
--========================================================--
-- Handles all sprinting and stamina logic on the server.
-- Authoritative: Clients can only request to sprint,
-- but the server validates and applies the change.
--========================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local SprintConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config"):WaitForChild("SprintConfig"))
local SprintEvent: RemoteEvent = RemoteEvents.SprintEvent

-- 🔹 Sprint parameters from shared config
local NORMAL_SPEED: number = SprintConfig.NORMAL_SPEED
local SPRINT_SPEED: number = SprintConfig.SPRINT_SPEED

-- 🔹 Stamina configuration from shared config
local MAX_STAMINA: number = SprintConfig.MAX_STAMINA
local STAMINA_DRAIN_RATE: number = SprintConfig.STAMINA_DRAIN_RATE
local STAMINA_RECOVERY_RATE: number = SprintConfig.STAMINA_RECOVERY_RATE
local UPDATE_INTERVAL: number = SprintConfig.UPDATE_INTERVAL  -- throttled to 0.2s
       

-- 🔹 Internal data store
type PlayerState = {
	Stamina: number,
	IsSprinting: boolean,
	LastUpdate: number,
}
local playerData: {[Player]: PlayerState} = {}
local hasSubscriber: {[Player]: boolean} = {}

------------------------------------------------------------
-- Player Management
------------------------------------------------------------

Players.PlayerAdded:Connect(function(player: Player)
	playerData[player] = {
		Stamina = MAX_STAMINA,
		IsSprinting = false,
		LastUpdate = tick(),
	}
end)

Players.PlayerRemoving:Connect(function(player: Player)
	playerData[player] = nil
end)

------------------------------------------------------------
-- Handle sprint toggle requests from clients
------------------------------------------------------------

SprintEvent.OnServerEvent:Connect(function(player: Player, wantSprintAny)
	local data = playerData[player]
	if not data then return end

	-- Handle initial subscription signal from client
	if typeof(wantSprintAny) == "string" and wantSprintAny == "subscribe" then
		hasSubscriber[player] = true
		-- Send an immediate state snapshot
		SprintEvent:FireClient(player, data.IsSprinting, data.Stamina)
		return
	end

	local wantSprint: boolean = (typeof(wantSprintAny) == "boolean" and wantSprintAny) or false

	local character: Model? = player.Character
	local humanoid: Humanoid? = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- If trying to sprint with no stamina, deny request
	if wantSprint and data.Stamina <= 0 then
		wantSprint = false
	end

	data.IsSprinting = wantSprint
	local newSpeed: number = wantSprint and SPRINT_SPEED or NORMAL_SPEED
	humanoid.WalkSpeed = newSpeed

	-- 🔹 Tell the client what the server actually applied
	SprintEvent:FireClient(player, data.IsSprinting, data.Stamina)
end)

------------------------------------------------------------
-- Stamina update loop
------------------------------------------------------------

task.spawn(function()
	while true do
		for player: Player, data: PlayerState in pairs(playerData) do
			-- Only send updates if client subscribed (listener connected)
			if not hasSubscriber[player] then
				continue
			end
			local now: number = tick()
			local dt: number = now - (data.LastUpdate or now)
			data.LastUpdate = now

			local character: Model? = player.Character
			local humanoid: Humanoid? = character and character:FindFirstChildOfClass("Humanoid")

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
