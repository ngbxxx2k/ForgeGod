--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealWeapon = require(script.Parent.RevealWeapon)

export type Aura = {
	Emitters: { ParticleEmitter },
	Highlight: Highlight,
	Light: PointLight?,
}

local AURA_NAME = "ForgeRevealAura"

local AuraEffect = {}

local function createEmitter(host: BasePart, worldPosition: Vector3, color: Color3, length: number): ParticleEmitter
	local config = ForgeAnimationConfig.Aura
	local attachment = Instance.new("Attachment")
	attachment.Name = AURA_NAME
	attachment.Position = host.CFrame:PointToObjectSpace(worldPosition)
	local size = config.SizePerStud * length
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = config.Texture
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = config.LightEmission
	emitter.LightInfluence = 0
	emitter.Rate = config.Rate
	emitter.Lifetime = config.Lifetime
	emitter.Speed = config.Speed
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(size, 0)
	emitter.Parent = attachment
	attachment.Parent = host
	return emitter
end

local function createHighlight(model: Model, color: Color3): Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = AURA_NAME
	highlight.FillTransparency = 1
	highlight.OutlineColor = color
	highlight.OutlineTransparency = ForgeAnimationConfig.Aura.OutlineTransparency
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = model
	return highlight
end

local function createLight(host: BasePart, color: Color3): PointLight
	local config = ForgeAnimationConfig.Aura
	local light = Instance.new("PointLight")
	light.Name = AURA_NAME
	light.Color = color
	light.Brightness = config.LightBrightness
	light.Range = config.LightRange
	light.Shadows = false
	light.Parent = host
	return light
end

function AuraEffect.Apply(model: Model, color: Color3, length: number): Aura
	local host = RevealWeapon.FindLargestPart(model)
	local aura: Aura = { Emitters = {}, Highlight = createHighlight(model, color), Light = nil }
	if host == nil then
		return aura
	end
	local center = model:GetBoundingBox().Position
	local points = math.max(ForgeAnimationConfig.Aura.Points, 1)
	for index = 1, points do
		local fraction = if points == 1 then 0 else (index - 1) / (points - 1) - 0.5
		local position = center + Vector3.yAxis * (fraction * length)
		table.insert(aura.Emitters, createEmitter(host, position, color, length))
	end
	aura.Light = createLight(host, color)
	return aura
end

function AuraEffect.Stop(aura: Aura)
	for _, emitter in aura.Emitters do
		emitter.Enabled = false
	end
	local light = aura.Light
	if light then
		light.Enabled = false
	end
end

return AuraEffect
