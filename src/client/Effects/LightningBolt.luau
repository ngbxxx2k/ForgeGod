--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LightningTypes = require(ReplicatedStorage.Shared.Types.LightningTypes)

type BoltStyle = LightningTypes.BoltStyle

type BeamPair = {
	Core: Beam,
	Glow: Beam,
}

type Bolt = {
	Holder: Part,
	Style: BoltStyle,
	Beams: { BeamPair },
	Light: PointLight?,
}

local HOLDER_NAME = "LightningBolt"
local HOLDER_SIZE = Vector3.new(0.2, 0.2, 0.2)
local FULL_TURN = math.pi * 2
local BRANCH_DROP = NumberRange.new(0.4, 0.9)
local BRANCH_START = NumberRange.new(0.15, 0.75)
local BRANCH_SCALE = 0.5
local MAIN_SCALE = 1
local HIDDEN = 1

local LightningBolt = {}

local random = Random.new()

local function createHolder(position: Vector3): Part
	local holder = Instance.new("Part")
	holder.Name = HOLDER_NAME
	holder.Size = HOLDER_SIZE
	holder.Transparency = HIDDEN
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CastShadow = false
	holder.Archivable = false
	holder.CFrame = CFrame.new(position)
	return holder
end

local function randomSideways(): Vector3
	local angle = random:NextNumber(0, FULL_TURN)
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

local function buildPath(start: Vector3, finish: Vector3, segments: number, jitter: number)
	local points = { start }
	for index = 1, segments - 1 do
		local alpha = index / segments
		local taper = math.sin(alpha * math.pi)
		local offset = randomSideways() * random:NextNumber(0, jitter) * taper
		table.insert(points, start:Lerp(finish, alpha) + offset)
	end
	table.insert(points, finish)
	return points
end

local function createBeam(from: Attachment, to: Attachment, texture: string, color: Color3): Beam
	local beam = Instance.new("Beam")
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Texture = texture
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.Color = ColorSequence.new(color)
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 1
	beam.Parent = from.Parent
	return beam
end

local function styleBeam(beam: Beam, width: number, brightness: number)
	beam.Width0 = width
	beam.Width1 = width
	beam.Brightness = brightness
end

local function addSegment(bolt: Bolt, from: Attachment, to: Attachment, scale: number)
	local style = bolt.Style
	local core = createBeam(from, to, style.Texture, style.CoreColor)
	local glow = createBeam(from, to, style.Texture, style.GlowColor)
	styleBeam(core, style.CoreWidth * scale, style.CoreBrightness)
	styleBeam(glow, style.GlowWidth * scale, style.GlowBrightness)
	table.insert(bolt.Beams, { Core = core, Glow = glow })
end

local function drawPath(bolt: Bolt, points: { Vector3 }, scale: number)
	local previous: Attachment? = nil
	for _, point in points do
		local attachment = Instance.new("Attachment")
		attachment.Position = bolt.Holder.CFrame:PointToObjectSpace(point)
		attachment.Parent = bolt.Holder
		if previous then
			addSegment(bolt, previous, attachment, scale)
		end
		previous = attachment
	end
end

local function drawBranches(bolt: Bolt, mainPath: { Vector3 })
	local style = bolt.Style
	local count = random:NextInteger(style.BranchCount.Min, style.BranchCount.Max)
	for _ = 1, count do
		local startAlpha = random:NextNumber(BRANCH_START.Min, BRANCH_START.Max)
		local start = mainPath[math.max(1, math.floor(#mainPath * startAlpha))]
		local length = random:NextNumber(style.BranchLength.Min, style.BranchLength.Max)
		local drop = random:NextNumber(BRANCH_DROP.Min, BRANCH_DROP.Max) * length
		local finish = start + randomSideways() * length - Vector3.new(0, drop, 0)
		local jitter = style.Jitter * BRANCH_SCALE
		drawPath(bolt, buildPath(start, finish, style.BranchSegments, jitter), BRANCH_SCALE)
	end
end

local function createImpactLight(bolt: Bolt)
	local light = Instance.new("PointLight")
	light.Color = bolt.Style.GlowColor
	light.Range = bolt.Style.ImpactLightRange
	light.Shadows = false
	light.Parent = bolt.Holder
	bolt.Light = light
end

local function fadeTransparency(base: number, level: number): NumberSequence
	return NumberSequence.new(base + (HIDDEN - base) * (1 - level))
end

local function setVisibility(bolt: Bolt, level: number)
	local style = bolt.Style
	local core = fadeTransparency(0, level)
	local glow = fadeTransparency(style.GlowTransparency, level)
	for _, pair in bolt.Beams do
		pair.Core.Transparency = core
		pair.Glow.Transparency = glow
	end
	if bolt.Light then
		bolt.Light.Brightness = style.ImpactLightBrightness * level
	end
end

local function animate(bolt: Bolt)
	local startedAt = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.RenderStepped:Connect(function()
		local alpha = (os.clock() - startedAt) / bolt.Style.Lifetime
		if alpha >= 1 then
			if connection then
				connection:Disconnect()
			end
			bolt.Holder:Destroy()
			return
		end
		local flicker = 1 - random:NextNumber(0, bolt.Style.FlickerStrength)
		setVisibility(bolt, (1 - alpha) * flicker)
	end)
end

function LightningBolt.Draw(style: BoltStyle, target: Vector3)
	local top = target + Vector3.new(0, style.StartHeight, 0) + randomSideways() * style.Jitter
	local bolt: Bolt = { Holder = createHolder(target), Style = style, Beams = {}, Light = nil }
	local mainPath = buildPath(top, target, style.Segments, style.Jitter)
	drawPath(bolt, mainPath, MAIN_SCALE)
	drawBranches(bolt, mainPath)
	createImpactLight(bolt)
	setVisibility(bolt, 1)
	bolt.Holder.Parent = Workspace
	animate(bolt)
end

return LightningBolt
