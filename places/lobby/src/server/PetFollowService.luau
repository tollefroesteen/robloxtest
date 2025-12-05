--!strict
-- PetFollowService.luau (Lobby)
-- Spawns favorite animals as pets that follow the player around in the lobby
-- Pets are visual companions - they don't interact with gameplay

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimalLibraryModule = require(Shared:WaitForChild("data"):WaitForChild("AnimalLibraryModule"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local PetBuilder = require(script.Parent.PetBuilder)

local CONTEXT = "PetFollowService"

-- ============================================================================
-- PET BEHAVIOR TUNING
-- ============================================================================

-- How far pets try to stay from the player
local FOLLOW_DISTANCE = 6
-- How close before pet stops moving toward player
local STOP_DISTANCE = 4
-- How far before pet teleports to catch up
local TELEPORT_DISTANCE = 40
-- Pet movement speed (studs per second)
local PET_SPEED = 8
-- How quickly pets turn to face movement direction
local TURN_SPEED = 0.15
-- Offset angle between multiple pets (radians)
local PET_ANGLE_OFFSET = math.rad(45)
-- Height offset for pets above ground
local PET_HEIGHT = 0.5

-- ============================================================================
-- STATE
-- ============================================================================

-- Folder to hold all pet models
local petsFolder: Folder? = nil

-- Track pets per player: { [Player] = { [animalID] = Model } }
local playerPets: { [Player]: { [string]: BasePart } } = {}

-- Track pet velocities for smooth movement
local petVelocities: { [BasePart]: Vector3 } = {}

local PetFollowService = {}

-- Ensure pets folder exists
local function ensurePetsFolder(): Folder
	if not petsFolder then
		petsFolder = workspace:FindFirstChild("Pets") :: Folder?
		if not petsFolder then
			local folder = Instance.new("Folder")
			folder.Name = "Pets"
			folder.Parent = workspace
			petsFolder = folder
		end
	end
	return petsFolder :: Folder
end

-- Get spawn position for a pet relative to player
local function getPetSpawnPosition(player: Player, petIndex: number, totalPets: number): Vector3?
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return nil end
	
	-- Calculate angle offset for this pet
	-- Pets spread out behind/beside the player
	local baseAngle = math.pi  -- Behind player
	local angleSpread = PET_ANGLE_OFFSET * (totalPets - 1)
	local startAngle = baseAngle - angleSpread / 2
	local petAngle = startAngle + PET_ANGLE_OFFSET * (petIndex - 1)
	
	-- Calculate position
	local offset = Vector3.new(
		math.sin(petAngle) * FOLLOW_DISTANCE,
		PET_HEIGHT,
		math.cos(petAngle) * FOLLOW_DISTANCE
	)
	
	return hrp.Position + hrp.CFrame:VectorToWorldSpace(offset)
end

-- Spawn a pet for a player
local function spawnPet(player: Player, animalID: string, petIndex: number, totalPets: number): BasePart?
	local animalDef = AnimalLibraryModule.GetByID(animalID)
	if not animalDef then
		Log.Warn(CONTEXT, string.format("Animal not found: %s", animalID))
		return nil
	end
	
	local spawnPos = getPetSpawnPosition(player, petIndex, totalPets)
	if not spawnPos then
		Log.Warn(CONTEXT, string.format("Could not get spawn position for %s's pet", player.Name))
		return nil
	end
	
	-- Build the pet
	local templateID = animalDef.Template or "DEFAULT"
	local pet = PetBuilder.BuildPet(templateID, animalDef.Color, spawnPos)
	
	-- Set attributes for identification
	pet.Name = string.format("Pet_%s_%s", player.Name, animalID)
	pet:SetAttribute("OwnerID", player.UserId)
	pet:SetAttribute("AnimalID", animalID)
	pet:SetAttribute("PetIndex", petIndex)
	pet:SetAttribute("TargetPos", spawnPos)
	
	-- Parent to pets folder
	local folder = ensurePetsFolder()
	pet.Parent = folder
	
	-- Initialize velocity
	petVelocities[pet] = Vector3.zero
	
	Log.Info(CONTEXT, string.format("Spawned pet %s for %s", animalDef.Name, player.Name))
	
	return pet
end

-- Remove a specific pet
local function removePet(pet: BasePart)
	petVelocities[pet] = nil
	pet:Destroy()
end

-- Remove all pets for a player
local function removeAllPets(player: Player)
	local pets = playerPets[player]
	if not pets then return end
	
	for animalID, pet in pets do
		removePet(pet)
	end
	
	playerPets[player] = nil
	Log.Info(CONTEXT, string.format("Removed all pets for %s", player.Name))
end

-- Update pets based on favorite animals
function PetFollowService.UpdatePets(player: Player, favoriteAnimals: { string })
	-- Get or create pets table for this player
	local pets = playerPets[player]
	if not pets then
		pets = {}
		playerPets[player] = pets
	end
	
	-- Find which pets to remove (no longer in favorites)
	local toRemove: { string } = {}
	for animalID, pet in pets do
		local stillFavorite = false
		for _, favID in favoriteAnimals do
			if favID == animalID then
				stillFavorite = true
				break
			end
		end
		if not stillFavorite then
			table.insert(toRemove, animalID)
		end
	end
	
	-- Remove unfavorited pets
	for _, animalID in toRemove do
		local pet = pets[animalID]
		if pet then
			removePet(pet)
			pets[animalID] = nil
			Log.Info(CONTEXT, string.format("Removed pet %s for %s (unfavorited)", animalID, player.Name))
		end
	end
	
	-- Spawn new favorite pets
	local totalPets = #favoriteAnimals
	for i, animalID in favoriteAnimals do
		if not pets[animalID] then
			local pet = spawnPet(player, animalID, i, totalPets)
			if pet then
				pets[animalID] = pet
			end
		else
			-- Update pet index for positioning
			pets[animalID]:SetAttribute("PetIndex", i)
		end
	end
end

-- Update pet positions (called every frame on server)
local function updatePetPositions(dt: number)
	for player, pets in playerPets do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then continue end
		
		local playerPos = hrp.Position
		local playerLook = hrp.CFrame.LookVector
		local totalPets = 0
		for _ in pets do totalPets += 1 end
		
		for animalID, pet in pets do
			if not pet or not pet.Parent then continue end
			
			local petIndex = pet:GetAttribute("PetIndex") or 1
			local petPos = pet.Position
			
			-- Calculate target position (behind/beside player)
			local baseAngle = math.pi
			local angleSpread = PET_ANGLE_OFFSET * (totalPets - 1)
			local startAngle = baseAngle - angleSpread / 2
			local petAngle = startAngle + PET_ANGLE_OFFSET * (petIndex - 1)
			
			local localOffset = Vector3.new(
				math.sin(petAngle) * FOLLOW_DISTANCE,
				0,
				math.cos(petAngle) * FOLLOW_DISTANCE
			)
			local targetPos = playerPos + hrp.CFrame:VectorToWorldSpace(localOffset)
			targetPos = Vector3.new(targetPos.X, playerPos.Y + PET_HEIGHT, targetPos.Z)
			
			-- Calculate distance to target
			local toTarget = targetPos - petPos
			local distance = toTarget.Magnitude
			
			-- Teleport if too far
			if distance > TELEPORT_DISTANCE then
				pet.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, petAngle + math.pi, 0)
				pet:SetAttribute("TargetPos", targetPos)
				petVelocities[pet] = Vector3.zero
				continue
			end
			
			-- Calculate desired velocity
			local vel = petVelocities[pet] or Vector3.zero
			
			if distance > STOP_DISTANCE then
				-- Move toward target
				local direction = toTarget.Unit
				local speed = math.min(PET_SPEED, distance * 2)  -- Slow down as we approach
				local desiredVel = direction * speed
				
				-- Smooth velocity change
				vel = vel:Lerp(desiredVel, 0.1)
			else
				-- Slow down when close
				vel = vel * 0.9
				if vel.Magnitude < 0.1 then
					vel = Vector3.zero
				end
			end
			
			petVelocities[pet] = vel
			
			-- Apply movement
			local newPos = petPos + vel * dt
			newPos = Vector3.new(newPos.X, targetPos.Y, newPos.Z)  -- Keep at correct height
			
			-- Calculate facing direction
			local facing: Vector3
			if vel.Magnitude > 0.5 then
				-- Face movement direction
				facing = vel.Unit
			else
				-- Face toward player when idle
				local toPlayer = (playerPos - petPos)
				toPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z)
				if toPlayer.Magnitude > 0.1 then
					facing = toPlayer.Unit
				else
					facing = -playerLook  -- Face same direction as player
				end
			end
			
			-- Smooth rotation
			local currentLook = pet.CFrame.LookVector
			local smoothedLook = currentLook:Lerp(facing, TURN_SPEED)
			if smoothedLook.Magnitude > 0.1 then
				pet.CFrame = CFrame.lookAt(newPos, newPos + smoothedLook)
			else
				pet.Position = newPos
			end
			
			-- Update target position for client animation
			pet:SetAttribute("TargetPos", newPos)
		end
	end
end

-- Initialize for a player (called when favorites are loaded)
function PetFollowService.InitPlayer(player: Player, favoriteAnimals: { string })
	-- Wait for character to exist
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		Log.Warn(CONTEXT, string.format("Could not find HumanoidRootPart for %s", player.Name))
		return
	end
	
	-- Spawn initial pets
	PetFollowService.UpdatePets(player, favoriteAnimals)
	
	-- Re-spawn pets when player respawns
	player.CharacterAdded:Connect(function(newCharacter)
		-- Wait for new character to be ready
		local newHrp = newCharacter:WaitForChild("HumanoidRootPart", 5)
		if newHrp then
			-- Re-position existing pets
			local pets = playerPets[player]
			if pets then
				local totalPets = 0
				for _ in pets do totalPets += 1 end
				
				local i = 1
				for animalID, pet in pets do
					local spawnPos = getPetSpawnPosition(player, i, totalPets)
					if spawnPos and pet and pet.Parent then
						pet.CFrame = CFrame.new(spawnPos)
						pet:SetAttribute("TargetPos", spawnPos)
					end
					i += 1
				end
			end
		end
	end)
end

-- Cleanup for a player
function PetFollowService.CleanupPlayer(player: Player)
	removeAllPets(player)
end

-- Connect to heartbeat for pet movement
RunService.Heartbeat:Connect(updatePetPositions)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	PetFollowService.CleanupPlayer(player)
end)

Log.Info(CONTEXT, "PetFollowService initialized")

return PetFollowService
