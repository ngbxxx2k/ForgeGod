--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local DigFxConfig = require(ReplicatedStorage.Shared.Config.DigFxConfig)
local DigZone = require(ReplicatedStorage.Shared.Utils.DigZone)
local MovementLock = require(script.Parent.Parent.Controllers.MovementLock)
local RevealSound = require(script.Parent.RevealSound)

type Action = {
	Anchor: Part,
	Fill: Frame,
	Emitter: ParticleEmitter,
	Saved: MovementLock.SavedMovement?,
}

local DigActionFx = {}

local current: Action? = nil

local function createAnchor(spot: Vector3): Part
	local part = Instance.new("Part")
	part.Name = "DigSite"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one * 0.2
	part.CFrame = CFrame.new(spot)
	part.Parent = Workspace
	return part
end

local function createEmitter(parent: Instance): ParticleEmitter
	local config = DigFxConfig.Dirt
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = config.Color
	emitter.Speed = config.Speed
	emitter.Lifetime = config.Lifetime
	emitter.Size = config.Size
	emitter.SpreadAngle = config.SpreadAngle
	emitter.Acceleration = config.Acceleration
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Rate = 0
	emitter.Parent = parent
	return emitter
end

local function createProgress(parent: Part): Frame
	local config = DigFxConfig.Progress
	local billboard = Instance.new("BillboardGui")
	billboard.Size = config.Size
	billboard.StudsOffset = config.StudsOffset
	billboard.AlwaysOnTop = true
	billboard.Adornee = parent
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = config.BackColor
	back.BorderSizePixel = 0
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = config.CornerRadius
	backCorner.Parent = back
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = config.FillColor
	fill.BorderSizePixel = 0
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = config.CornerRadius
	fillCorner.Parent = fill
	fill.Parent = back
	back.Parent = billboard
	billboard.Parent = parent
	return fill
end

local function alignCharacter(spot: Vector3)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = DigZone.GetDigRootCFrame(spot, root.CFrame)
	end
end

local function runBursts(action: Action, duration: number)
	local config = DigFxConfig.Dirt
	local elapsed = config.FirstBurstDelay
	task.wait(config.FirstBurstDelay)
	while current == action and elapsed < duration do
		action.Emitter:Emit(config.BurstCount)
		task.wait(config.BurstInterval)
		elapsed += config.BurstInterval
	end
end

function DigActionFx.Start(spot: Vector3, duration: number)
	DigActionFx.Stop()
	local anchor = createAnchor(spot)
	local fill = createProgress(anchor)
	local action: Action = {
		Anchor = anchor,
		Fill = fill,
		Emitter = createEmitter(anchor),
		Saved = nil,
	}
	current = action
	alignCharacter(spot)
	action.Saved = MovementLock.Lock(Players.LocalPlayer.Character)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	TweenService:Create(fill, info, { Size = UDim2.fromScale(1, 1) }):Play()
	RevealSound.Play(DigFxConfig.ScoopSound, anchor)
	task.spawn(runBursts, action, duration)
end

function DigActionFx.IsActive(): boolean
	return current ~= nil
end

function DigActionFx.Stop()
	local action = current
	current = nil
	if action == nil then
		return
	end
	MovementLock.Unlock(action.Saved)
	action.Anchor:Destroy()
end

return DigActionFx
