--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local DigFxConfig = require(ReplicatedStorage.Shared.Config.DigFxConfig)

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local KEY_FORMAT = "%.2f:%.2f"
local TWO_PI = math.pi * 2

export type MarkerData = {
	Position: Vector3,
	Rarity: string,
}

type Pillar = {
	Model: Model,
	Core: Part,
	Glow: Part,
	Rarity: string,
}

local DigMarkerFx = {}

local isInitialized = false
local folder: Folder? = nil
local pillars: { [string]: Pillar } = {}
local phase = 0

local function getColor(rarity: string): Color3
	local colors = DigFxConfig.Reveal.RarityColors
	return colors[rarity] or colors.Common
end

local function createPart(name: string, size: Vector3, cframe: CFrame, color: Color3, transparency: number): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Transparency = transparency
	return part
end

local function createPillar(position: Vector3, rarity: string, parent: Instance): Pillar
	local config = DigFxConfig.Marker
	local color = getColor(rarity)
	local model = Instance.new("Model")
	model.Name = rarity
	local center = CFrame.new(position + Vector3.yAxis * (config.Height / 2 + config.GroundLift)) * UPRIGHT
	local core = createPart("Core", Vector3.new(config.Height, config.CoreWidth, config.CoreWidth), center, color, config.CoreTransparency)
	local glow = createPart("Glow", Vector3.new(config.Height, config.GlowWidth, config.GlowWidth), center, color, config.GlowTransparency)
	local baseCFrame = CFrame.new(position + Vector3.yAxis * config.GroundLift) * UPRIGHT
	local base = createPart("Base", Vector3.new(config.BaseHeight, config.BaseWidth, config.BaseWidth), baseCFrame, color, config.BaseTransparency)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = config.LightRange
	light.Brightness = config.LightBrightness
	light.Parent = base
	core.Parent = model
	glow.Parent = model
	base.Parent = model
	model.Parent = parent
	return { Model = model, Core = core, Glow = glow, Rarity = rarity }
end

local function fadeOutAndDestroy(pillar: Pillar)
	local info = TweenInfo.new(DigFxConfig.Marker.FadeTime)
	for _, child in pillar.Model:GetChildren() do
		if child:IsA("BasePart") then
			TweenService:Create(child, info, { Transparency = 1 }):Play()
		end
	end
	task.delay(DigFxConfig.Marker.FadeTime, function()
		pillar.Model:Destroy()
	end)
end

local function isValidMarker(marker: any): boolean
	return type(marker) == "table" and typeof(marker.Position) == "Vector3" and type(marker.Rarity) == "string"
end

local function onRender(dt: number)
	local config = DigFxConfig.Marker
	phase = (phase + dt * config.PulseHz) % 1
	local pulse = math.sin(phase * TWO_PI) * config.PulseAmount
	for _, pillar in pillars do
		pillar.Core.Transparency = math.clamp(config.CoreTransparency + pulse, 0, 1)
		pillar.Glow.Transparency = math.clamp(config.GlowTransparency + pulse, 0, 1)
	end
end

function DigMarkerFx.Set(markers: { any })
	local parent = folder
	if parent == nil then
		return
	end
	local wanted: { [string]: MarkerData } = {}
	for _, marker in markers do
		if isValidMarker(marker) then
			local position = marker.Position :: Vector3
			wanted[string.format(KEY_FORMAT, position.X, position.Z)] = marker :: MarkerData
		end
	end
	for key, pillar in pillars do
		local marker = wanted[key]
		if marker == nil or marker.Rarity ~= pillar.Rarity then
			pillars[key] = nil
			fadeOutAndDestroy(pillar)
		end
	end
	for key, marker in wanted do
		if pillars[key] == nil then
			pillars[key] = createPillar(marker.Position, marker.Rarity, parent)
		end
	end
end

function DigMarkerFx.Clear()
	DigMarkerFx.Set({})
end

function DigMarkerFx.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local newFolder = Instance.new("Folder")
	newFolder.Name = DigFxConfig.Marker.FolderName
	newFolder.Parent = Workspace
	folder = newFolder
	RunService.RenderStepped:Connect(onRender)
end

return DigMarkerFx
