--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VoidheartFxConfig = require(ReplicatedStorage.Shared.Config.VoidheartFxConfig)
local VoidheartRig = require(script.Parent.VoidheartRig)

local ATTACHMENT_NAME = "VoidheartArc"

export type ArcSet = {
	Beams: { Beam },
	Owned: { Instance },
}

local VoidheartArcs = {}

local random = Random.new()

local function newBeam(tip: Attachment, core: Attachment, width: number): Beam
	local colors = VoidheartFxConfig.Colors
	local beam = Instance.new("Beam")
	beam.Attachment0 = tip
	beam.Attachment1 = core
	beam.Segments = VoidheartFxConfig.ClawArcs.Segments
	beam.Width0 = width
	beam.Width1 = width
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Color = ColorSequence.new(colors.Edge, colors.Glow)
	beam.Enabled = false
	beam.Parent = tip.Parent
	return beam
end

local function newAttachment(set: ArcSet, parent: BasePart, worldPosition: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = ATTACHMENT_NAME
	attachment.Parent = parent
	attachment.WorldPosition = worldPosition
	table.insert(set.Owned, attachment)
	return attachment
end

function VoidheartArcs.Create(rig: VoidheartRig.Rig): ArcSet
	local set: ArcSet = { Beams = {}, Owned = {} }
	local frame = VoidheartRig.GetFrame(rig)
	local core = rig.Movers.Core.Parts[1]
	local coreAttachment = newAttachment(set, core, core.Position)
	local width = VoidheartFxConfig.ClawArcs.WidthFraction * rig.Length
	for _, claw in VoidheartFxConfig.Claws do
		local mover = rig.Movers[claw.Name]
		local tipPosition = frame:PointToWorldSpace(mover.Pivot + mover.Radial * mover.Extent)
		local tip = newAttachment(set, mover.Parts[1], tipPosition)
		local beam = newBeam(tip, coreAttachment, width)
		table.insert(set.Beams, beam)
		table.insert(set.Owned, beam)
	end
	return set
end

function VoidheartArcs.Update(set: ArcSet, rig: VoidheartRig.Rig, surge: number)
	local config = VoidheartFxConfig.ClawArcs
	local curve = config.CurveFraction * rig.Length
	for _, beam in set.Beams do
		local isActive = surge > config.MinSurge and random:NextNumber() < config.FlickerChance
		beam.Enabled = isActive
		if isActive then
			beam.CurveSize0 = random:NextNumber(-curve, curve)
			beam.CurveSize1 = random:NextNumber(-curve, curve)
			beam.Transparency = NumberSequence.new(1 - surge)
		end
	end
end

function VoidheartArcs.Destroy(set: ArcSet)
	for _, instance in set.Owned do
		instance:Destroy()
	end
end

return VoidheartArcs
