--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VoidheartFxConfig = require(ReplicatedStorage.Shared.Config.VoidheartFxConfig)
local VoidheartMotion = require(script.Parent.VoidheartMotion)
local VoidheartRig = require(script.Parent.VoidheartRig)

type StepInput = VoidheartMotion.StepInput

local FOLDER_NAME = "VoidheartRibbons"
local CARRIER_SIZE = 0.05
local FULL_CIRCLE = math.pi * 2

type Ribbon = {
	Carrier: Part,
	Upper: Attachment,
	Lower: Attachment,
	Trail: Trail,
}

export type RibbonSet = {
	Folder: Folder,
	Ribbons: { Ribbon },
}

local VoidheartRibbons = {}

local function newCarrier(folder: Folder): Part
	local carrier = Instance.new("Part")
	carrier.Name = FOLDER_NAME
	carrier.Size = Vector3.one * CARRIER_SIZE
	carrier.Anchored = true
	carrier.CanCollide = false
	carrier.CanQuery = false
	carrier.CanTouch = false
	carrier.CastShadow = false
	carrier.Transparency = 1
	carrier.Parent = folder
	return carrier
end

local function newRibbon(folder: Folder): Ribbon
	local colors = VoidheartFxConfig.Colors
	local carrier = newCarrier(folder)
	local upper = Instance.new("Attachment")
	upper.Parent = carrier
	local lower = Instance.new("Attachment")
	lower.Parent = carrier
	local trail = Instance.new("Trail")
	trail.Attachment0 = upper
	trail.Attachment1 = lower
	trail.Lifetime = VoidheartFxConfig.Ribbons.Lifetime
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(colors.Glow, colors.Void)
	trail.Transparency = NumberSequence.new(VoidheartFxConfig.Ribbons.StartTransparency, 1)
	trail.Enabled = false
	trail.Parent = carrier
	return { Carrier = carrier, Upper = upper, Lower = lower, Trail = trail }
end

local function getRibbonOffset(
	rig: VoidheartRig.Rig,
	index: number,
	time: number,
	energy: number
): Vector3
	local config = VoidheartFxConfig.Ribbons
	local phase = (index - 1) / config.Count * FULL_CIRCLE
	local angle = config.AngularSpeed * time + phase
	local heightAlpha = 0.5 + 0.5 * math.sin(time * config.HeightRate + phase)
	local heightFraction = config.HeightMinFraction
		+ (config.HeightMaxFraction - config.HeightMinFraction) * heightAlpha
	local radius = (config.RadiusFraction + config.RadiusEnergyFraction * energy) * rig.Length
	local height = rig.BottomHeight + heightFraction * rig.Length
	return Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
end

function VoidheartRibbons.Create(rig: VoidheartRig.Rig): RibbonSet
	local folder = Instance.new("Folder")
	folder.Archivable = false
	folder.Name = FOLDER_NAME
	local set: RibbonSet = { Folder = folder, Ribbons = {} }
	for _ = 1, VoidheartFxConfig.Ribbons.Count do
		table.insert(set.Ribbons, newRibbon(folder))
	end
	folder.Parent = rig.Model
	return set
end

function VoidheartRibbons.Update(set: RibbonSet, rig: VoidheartRig.Rig, frame: CFrame, input: StepInput)
	local config = VoidheartFxConfig.Ribbons
	local time, energy = input.Time, input.Energy
	local halfWidth = config.WidthFraction * rig.Length * energy / 2
	for index, ribbon in set.Ribbons do
		ribbon.Trail.Enabled = energy > config.FirstEnergy + (index - 1) * config.EnergyStep
		ribbon.Carrier.CFrame = frame * CFrame.new(getRibbonOffset(rig, index, time, energy))
		ribbon.Upper.Position = Vector3.new(0, halfWidth, 0)
		ribbon.Lower.Position = Vector3.new(0, -halfWidth, 0)
	end
end

function VoidheartRibbons.Destroy(set: RibbonSet)
	set.Folder:Destroy()
end

return VoidheartRibbons
