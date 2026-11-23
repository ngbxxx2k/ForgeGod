--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealCleanup = require(script.Parent.RevealCleanup)

local HOLDER_NAME = "ForgeRevealLightning"
local HOLDER_SIZE = Vector3.new(0.2, 0.2, 0.2)
local WHITE = Color3.new(1, 1, 1)
local MIDPOINT = 0.5

type BoltStyle = {
	Color: Color3,
	WidthMultiplier: number,
}

local LightningEffect = {}

local rng = Random.new()

local function createHolder(target: Vector3): Part
	local holder = Instance.new("Part")
	holder.Name = HOLDER_NAME
	holder.Size = HOLDER_SIZE
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CFrame = CFrame.new(target)
	return holder
end

local function randomPerpendicular(direction: Vector3): Vector3
	local random = rng:NextUnitVector()
	local flat = random - direction * random:Dot(direction)
	return if flat.Magnitude > 1e-4 then flat.Unit else Vector3.xAxis
end

local function appendPoints(points: { Vector3 }, start: Vector3, target: Vector3, segments: number, jitter: number)
	local direction = (target - start).Unit
	local firstIndex = if #points == 0 then 0 else 1
	for index = firstIndex, segments do
		local alpha = index / segments
		local taper = math.sin(alpha * math.pi)
		local offset = randomPerpendicular(direction) * rng:NextNumber(0, jitter) * taper
		table.insert(points, start:Lerp(target, alpha) + offset)
	end
end

local function buildPoints(start: Vector3, entry: Vector3, exit: Vector3): { Vector3 }
	local config = ForgeAnimationConfig.Lightning
	local points = {}
	appendPoints(points, start, entry, config.Segments, config.Jitter)
	appendPoints(points, entry, exit, config.PassSegments, config.PassJitter)
	return points
end

local function createAttachment(holder: Part, worldPosition: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Position = holder.CFrame:PointToObjectSpace(worldPosition)
	attachment.Parent = holder
	return attachment
end

local function createBeam(from: Attachment, to: Attachment, color: Color3, width: number, transparency: number)
	local beam = Instance.new("Beam")
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Color = ColorSequence.new(color)
	beam.Transparency = NumberSequence.new(transparency)
	beam.Width0 = width
	beam.Width1 = width
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 1
	beam.Parent = from.Parent
end

local function buildBolt(holder: Part, start: Vector3, entry: Vector3, exit: Vector3, style: BoltStyle)
	local config = ForgeAnimationConfig.Lightning
	local coreColor = style.Color:Lerp(WHITE, config.CoreWhiteness)
	local previous: Attachment? = nil
	for _, point in buildPoints(start, entry, exit) do
		local attachment = createAttachment(holder, point)
		if previous then
			createBeam(previous, attachment, coreColor, config.CoreWidth * style.WidthMultiplier, 0)
			local glowWidth = config.GlowWidth * style.WidthMultiplier
			createBeam(previous, attachment, style.Color, glowWidth, config.GlowTransparency)
		end
		previous = attachment
	end
end

local function pickSkyPoint(target: Vector3): Vector3
	local config = ForgeAnimationConfig.Lightning
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(0, config.SkySpread)
	local horizontal = Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius
	return target + Vector3.yAxis * config.SkyHeight + horizontal
end

local function createImpactLight(holder: Part, color: Color3, multiplier: number)
	local config = ForgeAnimationConfig.Lightning
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = config.ImpactLightRange
	light.Brightness = config.ImpactLightBrightness * multiplier
	light.Shadows = false
	light.Parent = holder
end

function LightningEffect.Strike(
	entry: Vector3,
	exit: Vector3,
	color: Color3,
	isFinal: boolean,
	cleanup: RevealCleanup.Cleanup
)
	local config = ForgeAnimationConfig.Lightning
	local holder = createHolder(entry:Lerp(exit, MIDPOINT))
	local multiplier = if isFinal then config.FinalWidthMultiplier else 1
	local style: BoltStyle = { Color = color, WidthMultiplier = multiplier }
	local boltCount = if isFinal then config.FinalBoltCount else 1
	for _ = 1, boltCount do
		buildBolt(holder, pickSkyPoint(entry), entry, exit, style)
	end
	createImpactLight(holder, color, multiplier)
	holder.Parent = Workspace
	RevealCleanup.Add(cleanup, holder)
	local lifetime = if isFinal then config.FinalLifetime else config.Lifetime
	task.delay(lifetime, function()
		holder:Destroy()
	end)
end

return LightningEffect
