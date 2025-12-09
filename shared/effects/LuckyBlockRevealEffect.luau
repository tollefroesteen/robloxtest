--!strict
-- LuckyBlockRevealEffect.luau
-- Cinematic reveal effect for Lucky Blocks
-- Client-side module for dramatic animal reveals

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LuckyBlockRevealEffect = {}

export type RevealConfig = {
	Position: Vector3,
	Rarity: string,
	AnimalModel: Model?,
	OnComplete: (() -> ())?,
}

-- Rarity color schemes
local RARITY_COLORS = {
	Rare = {
		Primary = Color3.fromRGB(0, 120, 255),
		Secondary = Color3.fromRGB(100, 180, 255),
		Glow = Color3.fromRGB(80, 150, 255),
	},
	VeryRare = {
		Primary = Color3.fromRGB(160, 0, 255),
		Secondary = Color3.fromRGB(200, 100, 255),
		Glow = Color3.fromRGB(180, 80, 255),
	},
	UltraRare = {
		Primary = Color3.fromRGB(255, 200, 0),
		Secondary = Color3.fromRGB(255, 255, 150),
		Glow = Color3.fromRGB(255, 220, 100),
	},
}

local EFFECT_DURATION = 4 -- Time for the vortex buildup before reveal
local ANIMAL_REVEAL_DURATION = 3 -- Time to show the animal spinning

-----------------------------------------------------
-- HELPER FUNCTIONS
-----------------------------------------------------
local function createEffectPart(pos: Vector3): Part
	local p = Instance.new("Part")
	p.Size = Vector3.new(1, 1, 1)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Position = pos
	p.Parent = Workspace
	return p
end

local function createAttachment(parent: Instance, worldPos: Vector3?): Attachment
	local att = Instance.new("Attachment")
	if worldPos then
		att.WorldPosition = worldPos
	end
	att.Parent = parent
	return att
end

local function tween(obj: Instance, info: TweenInfo, props: {[string]: any}): Tween
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function getColors(rarity: string)
	return RARITY_COLORS[rarity] or RARITY_COLORS.Rare
end

-----------------------------------------------------
-- MAIN REVEAL EFFECT
-----------------------------------------------------
function LuckyBlockRevealEffect.PlayReveal(config: RevealConfig)
	local spawnPosition = config.Position
	local rarity = config.Rarity
	local animalModel = config.AnimalModel
	local onComplete = config.OnComplete
	local colors = getColors(rarity)
	
	-- Container for all effect parts (for easy cleanup)
	local effectParts: {Instance} = {}
	
	local function addToCleanup(part: Instance)
		table.insert(effectParts, part)
	end
	
	-----------------------------------------------------
	-- ANCHOR + RUNE CIRCLE
	-----------------------------------------------------
	local anchor = createEffectPart(spawnPosition)
	addToCleanup(anchor)
	
	-- Ground rune circle (flat disc that glows & pulses)
	local rune = Instance.new("Part")
	rune.Shape = Enum.PartType.Cylinder
	rune.Size = Vector3.new(0.2, 20, 20)
	rune.CFrame = CFrame.new(spawnPosition - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	rune.Anchored = true
	rune.CanCollide = false
	rune.CanTouch = false
	rune.CanQuery = false
	rune.Material = Enum.Material.Neon
	rune.Color = colors.Primary
	rune.Transparency = 0.7
	rune.Parent = Workspace
	addToCleanup(rune)
	
	-- Soft pulsing light from the rune
	local runeLight = Instance.new("PointLight")
	runeLight.Color = colors.Glow
	runeLight.Range = 20
	runeLight.Brightness = 0
	runeLight.Parent = rune
	
	-- Animate the rune pulsing
	local runePulseActive = true
	task.spawn(function()
		local t = 0
		while runePulseActive and t < EFFECT_DURATION + 1 do
			local pulse = (math.sin(t * 6) + 1) / 2 -- 0–1
			rune.Transparency = 0.5 + (1 - pulse) * 0.3
			runeLight.Brightness = 2 + pulse * 4
			t += task.wait()
		end
	end)
	
	-----------------------------------------------------
	-- LAYERED VORTEX PARTICLES
	-----------------------------------------------------
	local tornadoPart = createEffectPart(spawnPosition)
	local corePart = createEffectPart(spawnPosition)
	local sparkPart = createEffectPart(spawnPosition + Vector3.new(0, 2, 0))
	addToCleanup(tornadoPart)
	addToCleanup(corePart)
	addToCleanup(sparkPart)
	
	local tornadoAtt = createAttachment(tornadoPart)
	local coreAtt = createAttachment(corePart)
	local sparkAtt = createAttachment(sparkPart)
	
	-- Outer swirl (big spinning windy ring)
	local outer = Instance.new("ParticleEmitter")
	outer.Color = ColorSequence.new(colors.Secondary, Color3.fromRGB(255, 255, 255))
	outer.LightEmission = 1
	outer.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.6, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	outer.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 3),
	})
	outer.Rate = 350
	outer.Lifetime = NumberRange.new(0.7, 1.5)
	outer.Speed = NumberRange.new(18, 30)
	outer.SpreadAngle = Vector2.new(360, 60)
	outer.Rotation = NumberRange.new(0, 360)
	outer.RotSpeed = NumberRange.new(150, 400)
	outer.Drag = 2
	outer.Parent = tornadoAtt
	
	-- Inner core column (tight bright beam-ish swirl)
	local core = Instance.new("ParticleEmitter")
	core.Color = ColorSequence.new(colors.Primary, Color3.fromRGB(255, 255, 255))
	core.LightEmission = 1
	core.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	core.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 1.5),
	})
	core.Rate = 250
	core.Lifetime = NumberRange.new(0.5, 1)
	core.Speed = NumberRange.new(10, 18)
	core.SpreadAngle = Vector2.new(40, 40)
	core.Rotation = NumberRange.new(0, 360)
	core.RotSpeed = NumberRange.new(200, 500)
	core.Drag = 1
	core.Parent = coreAtt
	
	-- Floating sparkles
	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), colors.Secondary)
	sparks.LightEmission = 1
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Size = NumberSequence.new(0.2, 0.5)
	sparks.Rate = 120
	sparks.Lifetime = NumberRange.new(1, 2.5)
	sparks.Speed = NumberRange.new(1, 4)
	sparks.SpreadAngle = Vector2.new(360, 360)
	sparks.Acceleration = Vector3.new(0, 3, 0)
	sparks.Parent = sparkAtt
	
	-- Spin + wobble + slow vertical rise of the whole vortex
	local vortexActive = true
	task.spawn(function()
		local t = 0
		while vortexActive and t < EFFECT_DURATION do
			local dt = task.wait()
			t += dt
			local angle = math.rad(18)
			tornadoPart.CFrame = tornadoPart.CFrame * CFrame.Angles(0, angle, 0)
			corePart.CFrame = corePart.CFrame * CFrame.Angles(0, -angle * 1.5, 0)
			local yOffset = math.sin(t * 6) * 0.05
			tornadoPart.CFrame = tornadoPart.CFrame * CFrame.new(0, yOffset, 0)
			corePart.CFrame = corePart.CFrame * CFrame.new(0, yOffset * 1.3, 0)
		end
	end)
	
	-----------------------------------------------------
	-- VERTICAL ENERGY BEAM
	-----------------------------------------------------
	local beamBottom = createEffectPart(spawnPosition)
	local beamTop = createEffectPart(spawnPosition + Vector3.new(0, 18, 0))
	addToCleanup(beamBottom)
	addToCleanup(beamTop)
	
	local beamAtt0 = createAttachment(beamBottom)
	local beamAtt1 = createAttachment(beamTop)
	
	local beam = Instance.new("Beam")
	beam.Attachment0 = beamAtt0
	beam.Attachment1 = beamAtt1
	beam.Color = ColorSequence.new(colors.Secondary, colors.Primary)
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Width0 = 0.8
	beam.Width1 = 0.3
	beam.FaceCamera = true
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureSpeed = 4
	beam.Segments = 10
	beam.Enabled = true
	beam.Parent = beamBottom
	
	local beamActive = true
	task.spawn(function()
		local t = 0
		while beamActive and t < EFFECT_DURATION do
			local dt = task.wait()
			t += dt
			local pulse = math.abs(math.sin(t * 14))
			beam.Width0 = 0.8 + pulse * 1.3
			beam.Width1 = 0.2 + pulse * 0.5
		end
	end)
	
	-----------------------------------------------------
	-- WAIT FOR BUILDUP
	-----------------------------------------------------
	task.wait(EFFECT_DURATION)
	
	-----------------------------------------------------
	-- SHOCKWAVE + ANIMAL REVEAL
	-----------------------------------------------------
	
	-- Shockwave ring (expands then fades)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 4, 4)
	ring.CFrame = CFrame.new(spawnPosition - Vector3.new(0, 2.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 255, 255)
	ring.Transparency = 0.2
	ring.Parent = Workspace
	addToCleanup(ring)
	
	local ringTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	tween(ring, ringTweenInfo, {Size = Vector3.new(0.3, 40, 40), Transparency = 1})
	
	-- Instant burst of particles
	core:Emit(150)
	outer:Emit(200)
	sparks:Emit(180)
	
	-----------------------------------------------------
	-- SPAWN ANIMAL (or placeholder if no model)
	-----------------------------------------------------
	local revealedModel: Model? = nil
	
	if animalModel then
		-- Clone and position the animal model
		revealedModel = animalModel:Clone()
		revealedModel.Name = "RevealedAnimal"
		
		-- Position at reveal point
		if revealedModel.PrimaryPart then
			revealedModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition + Vector3.new(0, 4, 0)))
		else
			-- Try to position by moving all parts
			for _, part in ipairs(revealedModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CFrame = CFrame.new(spawnPosition + Vector3.new(0, 4, 0))
					break
				end
			end
		end
		
		-- Make anchored and add glow
		for _, part in ipairs(revealedModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end
		
		-- Add highlight effect
		local highlight = Instance.new("Highlight")
		highlight.FillColor = colors.Secondary
		highlight.FillTransparency = 0.5
		highlight.OutlineColor = colors.Primary
		highlight.OutlineTransparency = 0
		highlight.Parent = revealedModel
		
		-- Add glowing light
		local animalLight = Instance.new("PointLight")
		animalLight.Color = colors.Glow
		animalLight.Range = 25
		animalLight.Brightness = 10
		if revealedModel.PrimaryPart then
			animalLight.Parent = revealedModel.PrimaryPart
		else
			for _, part in ipairs(revealedModel:GetDescendants()) do
				if part:IsA("BasePart") then
					animalLight.Parent = part
					break
				end
			end
		end
		
		-- Start tiny and scale up
		local originalSizes: {[BasePart]: Vector3} = {}
		for _, part in ipairs(revealedModel:GetDescendants()) do
			if part:IsA("BasePart") then
				originalSizes[part] = part.Size
				part.Size = part.Size * 0.1
				part.Transparency = 1
			end
		end
		
		revealedModel.Parent = Workspace
		
		-- Scale up and fade in with elastic effect
		local revealTweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		for part, origSize in pairs(originalSizes) do
			tween(part, revealTweenInfo, {Size = origSize, Transparency = 0})
		end
		
		-- Spin while revealing
		local spinActive = true
		task.spawn(function()
			local t = 0
			while spinActive and revealedModel and revealedModel.Parent do
				if revealedModel.PrimaryPart then
					revealedModel:SetPrimaryPartCFrame(
						revealedModel.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(3), 0)
					)
				end
				t += task.wait()
				if t > ANIMAL_REVEAL_DURATION then
					break
				end
			end
		end)
	end
	
	-- Fade out effects
	task.wait(0.7)
	runePulseActive = false
	vortexActive = false
	beamActive = false
	
	outer.Enabled = false
	core.Enabled = false
	sparks.Enabled = false
	beam.Enabled = false
	
	-- Gradual cleanup of effect parts
	task.wait(ANIMAL_REVEAL_DURATION - 0.7)
	
	-- Fade out animal highlight and light
	if revealedModel then
		local fadeOutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local modelHighlight = revealedModel:FindFirstChildOfClass("Highlight")
		if modelHighlight then
			tween(modelHighlight, fadeOutInfo, {FillTransparency = 1, OutlineTransparency = 1})
		end
		
		for _, part in ipairs(revealedModel:GetDescendants()) do
			if part:IsA("PointLight") then
				tween(part, fadeOutInfo, {Brightness = 0})
			end
			-- Also fade out all parts
			if part:IsA("BasePart") then
				tween(part, fadeOutInfo, {Transparency = 1})
			end
		end
		
		-- Destroy the revealed model after fade out completes
		task.delay(0.6, function()
			if revealedModel and revealedModel.Parent then
				revealedModel:Destroy()
			end
		end)
	end
	
	-- Clean up all effect parts
	task.delay(1, function()
		for _, part in ipairs(effectParts) do
			if part and part.Parent then
				part:Destroy()
			end
		end
	end)
	
	-- Call completion callback
	if onComplete then
		onComplete()
	end
	
	return revealedModel
end

-----------------------------------------------------
-- SIMPLIFIED QUICK REVEAL (no vortex, just sparkles)
-----------------------------------------------------
function LuckyBlockRevealEffect.PlayQuickReveal(config: RevealConfig)
	local spawnPosition = config.Position
	local rarity = config.Rarity
	local animalModel = config.AnimalModel
	local onComplete = config.OnComplete
	local colors = getColors(rarity)
	
	-- Single burst effect
	local burstPart = createEffectPart(spawnPosition)
	
	local burstAtt = createAttachment(burstPart)
	
	local burst = Instance.new("ParticleEmitter")
	burst.Color = ColorSequence.new(colors.Primary, colors.Secondary)
	burst.LightEmission = 1
	burst.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	burst.Size = NumberSequence.new(1, 2)
	burst.Rate = 0
	burst.Lifetime = NumberRange.new(1, 2)
	burst.Speed = NumberRange.new(15, 25)
	burst.SpreadAngle = Vector2.new(360, 360)
	burst.Parent = burstAtt
	
	-- Emit burst
	burst:Emit(100)
	
	-- Light flash
	local flashLight = Instance.new("PointLight")
	flashLight.Color = colors.Glow
	flashLight.Range = 30
	flashLight.Brightness = 15
	flashLight.Parent = burstPart
	
	tween(flashLight, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0})
	
	-- Spawn animal immediately
	local revealedModel: Model? = nil
	if animalModel then
		revealedModel = animalModel:Clone()
		revealedModel.Name = "RevealedAnimal"
		
		if revealedModel.PrimaryPart then
			revealedModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition + Vector3.new(0, 4, 0)))
		end
		
		for _, part in ipairs(revealedModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end
		
		revealedModel.Parent = Workspace
	end
	
	-- Cleanup
	task.delay(2, function()
		burstPart:Destroy()
		if onComplete then
			onComplete()
		end
	end)
	
	return revealedModel
end

return LuckyBlockRevealEffect
