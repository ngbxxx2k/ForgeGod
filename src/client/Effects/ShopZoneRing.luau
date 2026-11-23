--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AssetIds = require(ReplicatedStorage.Shared.Constants.AssetIds)
local ShopZoneConfig = require(ReplicatedStorage.Shared.Config.ShopZoneConfig)

local DISC_NAME = "Disc"
local SEGMENT_NAME = "RingSegment"
local FULL_TURN = math.pi * 2
local CYLINDER_UP_ROTATION = CFrame.Angles(0, 0, math.pi / 2)

export type RingStyle = {
	Radius: number?,
	RingWidth: number?,
	RingColor: Color3?,
	DiscColor: Color3?,
	StudsColor: Color3?,
}

type ResolvedStyle = {
	Radius: number,
	RingWidth: number,
	RingColor: Color3,
	DiscColor: Color3,
	StudsColor: Color3,
}

local ShopZoneRing = {}

local function createPart(name: string): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function startPulse(disc: Part)
	local tweenInfo = TweenInfo.new(
		ShopZoneConfig.PulsePeriod / 2,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		true
	)
	disc.Transparency = ShopZoneConfig.DiscTransparencyMin
	TweenService:Create(disc, tweenInfo, { Transparency = ShopZoneConfig.DiscTransparencyMax }):Play()
end

local function resolveStyle(style: RingStyle?): ResolvedStyle
	local overrides: RingStyle = style or {}
	return {
		Radius = overrides.Radius or ShopZoneConfig.Radius,
		RingWidth = overrides.RingWidth or ShopZoneConfig.RingWidth,
		RingColor = overrides.RingColor or ShopZoneConfig.RingColor,
		DiscColor = overrides.DiscColor or ShopZoneConfig.DiscColor,
		StudsColor = overrides.StudsColor or ShopZoneConfig.StudsColor,
	}
end

local function createDisc(center: CFrame, style: ResolvedStyle): Part
	local diameter = style.Radius * 2
	local disc = createPart(DISC_NAME)
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(ShopZoneConfig.DiscThickness, diameter, diameter)
	disc.CFrame = center * CFrame.new(0, ShopZoneConfig.DiscLift, 0) * CYLINDER_UP_ROTATION
	disc.Color = style.DiscColor
	disc.Material = Enum.Material.SmoothPlastic
	local studs = Instance.new("Texture")
	studs.Texture = AssetIds.Textures.GroundStuds
	studs.Face = Enum.NormalId.Right
	studs.StudsPerTileU = ShopZoneConfig.StudsPerTile
	studs.StudsPerTileV = ShopZoneConfig.StudsPerTile
	studs.Color3 = style.StudsColor
	studs.Transparency = ShopZoneConfig.StudsTransparency
	studs.Parent = disc
	startPulse(disc)
	return disc
end

local function createSegment(center: CFrame, index: number, style: ResolvedStyle): Part
	local count = ShopZoneConfig.RingSegments
	local thickness = ShopZoneConfig.RingThickness
	local width = style.RingWidth
	local midRadius = style.Radius - width / 2
	local length = FULL_TURN * midRadius / count + ShopZoneConfig.RingSegmentOverlap
	local angle = (index - 0.5) / count * FULL_TURN
	local segment = createPart(SEGMENT_NAME)
	segment.Size = Vector3.new(length, thickness, width)
	segment.Material = Enum.Material.Neon
	segment.Color = style.RingColor
	local lift = ShopZoneConfig.DiscLift + thickness / 2
	segment.CFrame = center * CFrame.Angles(0, -angle, 0) * CFrame.new(0, lift, -midRadius)
	return segment
end

function ShopZoneRing.Build(name: string, center: CFrame, parent: Instance, style: RingStyle?): Model
	local resolved = resolveStyle(style)
	local ring = Instance.new("Model")
	ring.Name = name
	createDisc(center, resolved).Parent = ring
	for index = 1, ShopZoneConfig.RingSegments do
		createSegment(center, index, resolved).Parent = ring
	end
	ring.Parent = parent
	return ring
end

return ShopZoneRing
