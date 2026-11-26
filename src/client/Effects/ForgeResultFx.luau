--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local ForgeResultFxConfig = require(ReplicatedStorage.Shared.Config.ForgeResultFxConfig)

local SOUNDS_FOLDER_NAME = "Sounds"
local CENTER = 0.5
local FULL_TURN = 360
local PARTICLE_Z_INDEX = 2
local CRACK_Z_INDEX = 1
local RAINBOW_GRADIENT_NAME = "RainbowGlow"
local RAINBOW_DIM_TRANSPARENCY = 0.6

export type Targets = {
	Wheel: Frame,
	Glow: UIStroke,
	FxLayer: Frame,
	Body: GuiObject,
	Flash: Frame,
}

type Particle = {
	Frame: Frame,
	Corner: UICorner,
	IsBusy: boolean,
}

type Crack = {
	Pivot: Frame,
	Line: Frame,
}

local Shapes = ForgeResultFxConfig.ParticleShapes

local ForgeResultFx = {}

local rng = Random.new()
local targets: Targets? = nil
local particles: { Particle } = {}
local cracks: { Crack } = {}
local glowTween: Tween? = nil
local flashTween: Tween? = nil
local shakeConnection: RBXScriptConnection? = nil
local bodyRestPosition: UDim2? = nil
local soundsFolder: Instance? = nil
local lastTickAt = 0
local rainbowGradient: UIGradient? = nil
local isRainbowGlow = false

local function playSound(name: string?)
	local folder = soundsFolder
	if name == nil or folder == nil then
		return
	end
	local sound = folder:FindFirstChild(name)
	if sound and sound:IsA("Sound") then
		SoundService:PlayLocalSound(sound)
	end
end

local function createParticle(layer: Frame): Particle
	local frame = Instance.new("Frame")
	frame.Name = "Particle"
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(CENTER, CENTER)
	frame.Visible = false
	frame.ZIndex = PARTICLE_Z_INDEX
	local corner = Instance.new("UICorner")
	corner.Parent = frame
	frame.Parent = layer
	return { Frame = frame, Corner = corner, IsBusy = false }
end

local function acquireParticle(layer: Frame): Particle?
	for _, particle in particles do
		if not particle.IsBusy then
			return particle
		end
	end
	if #particles >= ForgeResultFxConfig.MaxParticles then
		return nil
	end
	local particle = createParticle(layer)
	table.insert(particles, particle)
	return particle
end

local function shapeParticle(particle: Particle, shape: string, angle: number)
	local frame = particle.Frame
	if shape == Shapes.Spark then
		local size = ForgeResultFxConfig.SparkSize
		frame.Size = UDim2.fromScale(size.X, size.Y)
		frame.Rotation = angle - FULL_TURN / 4
		particle.Corner.CornerRadius = UDim.new(CENTER, 0)
		return
	end
	if shape == Shapes.Shard then
		local size = ForgeResultFxConfig.ShardSize
		frame.Size = UDim2.fromScale(size, size)
		frame.Rotation = rng:NextNumber(0, FULL_TURN)
		particle.Corner.CornerRadius = UDim.new(0, 0)
		return
	end
	local size = ForgeResultFxConfig.DotSize
	frame.Size = UDim2.fromScale(size, size)
	frame.Rotation = 0
	particle.Corner.CornerRadius = UDim.new(CENTER, 0)
end

local function pointAt(angle: number, radius: number): UDim2
	local radians = math.rad(angle)
	return UDim2.fromScale(CENTER + radius * math.sin(radians), CENTER - radius * math.cos(radians))
end

local function launchParticle(particle: Particle, style: ForgeResultFxConfig.FxStyle)
	local frame = particle.Frame
	local angle = rng:NextNumber(0, FULL_TURN)
	local startRadius = ForgeResultFxConfig.ParticleStartRadius
	local distance = rng:NextNumber(style.ParticleDistance.Min, style.ParticleDistance.Max)
	local lifetime = ForgeResultFxConfig.ParticleLifetime
	local duration = rng:NextNumber(lifetime.Min, lifetime.Max)
	shapeParticle(particle, style.ParticleShape, angle)
	frame.BackgroundColor3 = style.ParticleColors[rng:NextInteger(1, #style.ParticleColors)]
	frame.BackgroundTransparency = 0
	frame.Position = pointAt(angle, startRadius)
	frame.Visible = true
	particle.IsBusy = true
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {
		Position = pointAt(angle, startRadius + distance),
		BackgroundTransparency = 1,
		Rotation = frame.Rotation + rng:NextNumber(-90, 90),
	}
	local tween = TweenService:Create(frame, info, goal)
	tween.Completed:Connect(function()
		frame.Visible = false
		particle.IsBusy = false
	end)
	tween:Play()
end

local function burst(style: ForgeResultFxConfig.FxStyle)
	local current = targets
	if current == nil then
		return
	end
	for _ = 1, style.ParticleCount do
		local particle = acquireParticle(current.FxLayer)
		if particle == nil then
			return
		end
		launchParticle(particle, style)
	end
end

local function playGlow(style: ForgeResultFxConfig.FxStyle)
	local current = targets
	if current == nil or isRainbowGlow then
		return
	end
	if glowTween then
		glowTween:Cancel()
	end
	local glow = current.Glow
	glow.Color = style.GlowColor
	glow.Transparency = 0
	glow.Thickness = ForgeResultFxConfig.GlowThickness
	local pulseTime = ForgeResultFxConfig.GlowDuration / math.max(style.GlowPulses, 1)
	local info = TweenInfo.new(pulseTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, style.GlowPulses - 1)
	local tween = TweenService:Create(glow, info, { Transparency = 1, Thickness = 1 })
	glowTween = tween
	tween:Play()
end

local function playFlash(style: ForgeResultFxConfig.FxStyle)
	local current = targets
	local color = style.FlashColor
	if current == nil or color == nil then
		return
	end
	if flashTween then
		flashTween:Cancel()
	end
	local flash = current.Flash
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = style.FlashTransparency
	local info = TweenInfo.new(ForgeResultFxConfig.FlashDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(flash, info, { BackgroundTransparency = 1 })
	flashTween = tween
	tween:Play()
end

local function stopShake()
	if shakeConnection then
		shakeConnection:Disconnect()
		shakeConnection = nil
	end
	local current = targets
	local rest = bodyRestPosition
	if current and rest then
		current.Body.Position = rest
	end
end

local function playShake(strength: number)
	local current = targets
	if current == nil or strength <= 0 then
		return
	end
	stopShake()
	local body = current.Body
	local rest = bodyRestPosition or body.Position
	bodyRestPosition = rest
	local startedAt = os.clock()
	local duration = ForgeResultFxConfig.ShakeDuration
	shakeConnection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startedAt
		if elapsed >= duration then
			stopShake()
			return
		end
		local amplitude = strength * (1 - elapsed / duration)
		local phase = elapsed * ForgeResultFxConfig.ShakeFrequency
		local offset = Vector2.new(math.sin(phase * 1.3), math.cos(phase)) * amplitude
		body.Position = rest + UDim2.fromOffset(offset.X, offset.Y)
	end)
end

local function createCrack(layer: Frame): Crack
	local pivot = Instance.new("Frame")
	pivot.Name = "Crack"
	pivot.BackgroundTransparency = 1
	pivot.Size = UDim2.fromScale(1, 1)
	pivot.ZIndex = CRACK_Z_INDEX
	pivot.Visible = false
	local line = Instance.new("Frame")
	line.Name = "Line"
	line.BorderSizePixel = 0
	line.AnchorPoint = Vector2.new(0, CENTER)
	line.Position = UDim2.fromScale(CENTER, CENTER)
	line.BackgroundColor3 = ForgeResultFxConfig.CrackColor
	line.Parent = pivot
	pivot.Parent = layer
	return { Pivot = pivot, Line = line }
end

local function playCrack(crack: Crack)
	local length = ForgeResultFxConfig.CrackLength
	local thickness = ForgeResultFxConfig.CrackThickness
	crack.Pivot.Rotation = rng:NextNumber(0, FULL_TURN)
	crack.Pivot.Visible = true
	crack.Line.BackgroundTransparency = 0
	crack.Line.Size = UDim2.fromScale(0, thickness)
	local growInfo = TweenInfo.new(ForgeResultFxConfig.CrackGrowTime, Enum.EasingStyle.Quad)
	local grow = TweenService:Create(crack.Line, growInfo, {
		Size = UDim2.fromScale(rng:NextNumber(length.Min, length.Max), thickness),
	})
	local fadeInfo = TweenInfo.new(
		ForgeResultFxConfig.CrackFadeTime,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In,
		0,
		false,
		ForgeResultFxConfig.CrackHoldTime
	)
	local fade = TweenService:Create(crack.Line, fadeInfo, { BackgroundTransparency = 1 })
	grow.Completed:Connect(function()
		fade:Play()
	end)
	fade.Completed:Connect(function(playbackState: Enum.PlaybackState)
		if playbackState == Enum.PlaybackState.Completed then
			crack.Pivot.Visible = false
		end
	end)
	grow:Play()
end

local function playCracks(count: number)
	local current = targets
	if current == nil then
		return
	end
	while #cracks < count do
		table.insert(cracks, createCrack(current.FxLayer))
	end
	for index = 1, count do
		playCrack(cracks[index])
	end
end

function ForgeResultFx.GetStyle(styleId: string): ForgeResultFxConfig.FxStyle?
	return ForgeResultFxConfig.Styles[styleId]
end

function ForgeResultFx.Play(styleId: string)
	local style = ForgeResultFxConfig.Styles[styleId]
	if style == nil then
		warn("[ForgeResultFx] Unknown style:", styleId)
		return
	end
	playGlow(style)
	playFlash(style)
	burst(style)
	playShake(style.ShakeStrength)
	playCracks(style.CrackCount)
	playSound(style.SoundName)
end

function ForgeResultFx.PlaySound(soundName: string)
	playSound(soundName)
end

function ForgeResultFx.PlayTick(soundName: string, minInterval: number)
	local now = os.clock()
	if now - lastTickAt < minInterval then
		return
	end
	lastTickAt = now
	playSound(soundName)
end

local function getRainbowGradient(glow: UIStroke): UIGradient
	local gradient = rainbowGradient
	if gradient == nil or gradient.Parent ~= glow then
		local created = Instance.new("UIGradient")
		created.Name = RAINBOW_GRADIENT_NAME
		created.Enabled = false
		created.Parent = glow
		rainbowGradient = created
		return created
	end
	return gradient
end

function ForgeResultFx.SetRainbowGlow(isActive: boolean)
	isRainbowGlow = isActive
	local current = targets
	if current == nil then
		return
	end
	if glowTween then
		glowTween:Cancel()
		glowTween = nil
	end
	local glow = current.Glow
	getRainbowGradient(glow).Enabled = isActive
	if isActive then
		glow.Color = Color3.new(1, 1, 1)
		glow.Thickness = ForgeResultFxConfig.GlowThickness
	end
	glow.Transparency = if isActive then 0 else 1
end

function ForgeResultFx.UpdateRainbowGlow(sequence: ColorSequence, rotation: number, isLit: boolean)
	local current, gradient = targets, rainbowGradient
	if not isRainbowGlow or current == nil or gradient == nil then
		return
	end
	gradient.Color = sequence
	gradient.Rotation = rotation
	current.Glow.Transparency = if isLit then 0 else RAINBOW_DIM_TRANSPARENCY
end

function ForgeResultFx.StopAll()
	stopShake()
	if isRainbowGlow then
		ForgeResultFx.SetRainbowGlow(false)
	end
	if glowTween then
		glowTween:Cancel()
		glowTween = nil
	end
	if flashTween then
		flashTween:Cancel()
		flashTween = nil
	end
	local current = targets
	if current then
		current.Glow.Transparency = 1
		current.Flash.BackgroundTransparency = 1
	end
end

local function preloadSounds(folder: Instance)
	task.spawn(function()
		local ok, err = pcall(ContentProvider.PreloadAsync, ContentProvider, folder:GetChildren())
		if not ok then
			warn("[ForgeResultFx] Sound preload failed:", err)
		end
	end)
end

function ForgeResultFx.Bind(newTargets: Targets)
	targets = newTargets
	bodyRestPosition = newTargets.Body.Position
	local folder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild(SOUNDS_FOLDER_NAME)
	if soundsFolder ~= folder then
		preloadSounds(folder)
	end
	soundsFolder = folder
end

return ForgeResultFx
