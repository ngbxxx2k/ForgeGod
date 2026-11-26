--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DigFxConfig = require(ReplicatedStorage.Shared.Config.DigFxConfig)
local DigToolConfig = require(ReplicatedStorage.Shared.Config.DigToolConfig)
local DigZone = require(ReplicatedStorage.Shared.Utils.DigZone)

local ANCHOR_NAME = "DigSignalAnchor"
local LAY_FLAT = CFrame.Angles(math.rad(90), 0, 0)
local FULL_SIGNAL = 1
local TWO_PI = math.pi * 2
local PRIMARY_PART_TIMEOUT = 5

local DetectorSignalFx = {}

local isInitialized = false
local anchor: Part? = nil
local groundRing: CylinderHandleAdornment? = nil
local coilRing: CylinderHandleAdornment? = nil
local rootPart: BasePart? = nil
local strength = 0
local radius = 10
local isActive = false
local phase = 0

local function createRing(name: string): CylinderHandleAdornment
	local ring = Instance.new("CylinderHandleAdornment")
	ring.Name = name
	ring.AlwaysOnTop = false
	ring.ZIndex = 1
	ring.Visible = false
	return ring
end

local function createAnchor(): Part
	local part = Instance.new("Part")
	part.Name = ANCHOR_NAME
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.Parent = Workspace
	return part
end

local function getBlinkTransparency(dt: number): number
	local config = DigFxConfig.Ring
	if strength >= FULL_SIGNAL then
		return config.OnSpotTransparency
	end
	local hz = config.BlinkHz.Min + (config.BlinkHz.Max - config.BlinkHz.Min) * strength
	phase = (phase + dt * hz) % 1
	local wave = (math.sin(phase * TWO_PI) + 1) / 2
	local range = config.BlinkTransparency
	return range.Max - (range.Max - range.Min) * wave
end

local function styleRing(ring: CylinderHandleAdornment, transparency: number, isSignal: boolean, idle: number)
	local config = DigFxConfig.Ring
	ring.Color3 = if isSignal then config.SignalColor else config.IdleColor
	ring.Transparency = if isSignal then transparency else idle
	ring.Visible = isSignal or idle < 1
end

local function updateGround(root: BasePart, transparency: number, isSignal: boolean)
	local ring = groundRing
	local part = anchor
	if ring == nil or part == nil then
		return
	end
	local config = DigFxConfig.Ring
	local point = DigZone.GetScanPoint(root.CFrame) + Vector3.yAxis * config.GroundLift
	part.CFrame = CFrame.new(point)
	ring.CFrame = LAY_FLAT
	ring.Radius = radius
	ring.InnerRadius = math.max(radius - config.Thickness, 0)
	ring.Height = config.Height
	styleRing(ring, transparency, isSignal, config.IdleTransparency)
end

local function hideAll()
	if groundRing then
		groundRing.Visible = false
	end
	if coilRing then
		coilRing.Visible = false
	end
end

local function onRender(dt: number)
	local root = rootPart
	if not isActive or root == nil or root.Parent == nil then
		hideAll()
		return
	end
	local isSignal = strength > 0
	local transparency = getBlinkTransparency(dt)
	updateGround(root, transparency, isSignal)
	local coil = coilRing
	if coil and coil.Adornee and coil.Adornee.Parent then
		styleRing(coil, transparency, isSignal, DigFxConfig.Coil.IdleTransparency)
	end
end

local function waitForPrimaryPart(model: Model): BasePart?
	local deadline = os.clock() + PRIMARY_PART_TIMEOUT
	while model.PrimaryPart == nil and model.Parent ~= nil and os.clock() < deadline do
		task.wait()
	end
	return model.PrimaryPart
end

function DetectorSignalFx.BindDetector(model: Model?)
	local ring = coilRing
	if ring == nil then
		return
	end
	local spec = DigToolConfig.Held.Detector
	local body = model and waitForPrimaryPart(model)
	if model == nil or body == nil or spec.CoilOffset == nil then
		ring.Adornee = nil
		ring.Parent = nil
		return
	end
	local config = DigFxConfig.Coil
	local coilCFrame = model:GetPivot() * CFrame.new((spec.CoilOffset :: Vector3) * spec.Scale) * LAY_FLAT
	ring.Adornee = body
	ring.CFrame = body.CFrame:ToObjectSpace(coilCFrame)
	ring.Radius = config.Radius * spec.Scale
	ring.InnerRadius = config.InnerRadius * spec.Scale
	ring.Height = config.Height
	ring.Parent = body
end

function DetectorSignalFx.SetRoot(root: BasePart?)
	rootPart = root
end

function DetectorSignalFx.SetActive(active: boolean)
	isActive = active
	if not active then
		hideAll()
	end
end

function DetectorSignalFx.SetSignal(value: number)
	strength = math.clamp(value, 0, FULL_SIGNAL)
end

function DetectorSignalFx.SetRadius(value: number)
	radius = value
end

function DetectorSignalFx.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local part = createAnchor()
	anchor = part
	local ground = createRing("GroundRing")
	ground.Adornee = part
	ground.Parent = part
	groundRing = ground
	coilRing = createRing("CoilRing")
	RunService.RenderStepped:Connect(onRender)
end

return DetectorSignalFx
