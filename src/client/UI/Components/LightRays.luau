--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MODE_ATTRIBUTE = "LightRays"
local OWNER_ATTRIBUTE = "LightRaysFor"
local MODE_STATIC = "Static"
local MODE_SPIN = "Spin"
local TEMPLATE_NAME = "LightRays"
local SIZE_MULTIPLIER = 1.4
local EDGE_MARGIN = 2
local SPIN_TWEEN_INFO = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)

export type Mode = "Static" | "Spin"

local LightRays = {}

local isInitialized = false
local template: ImageLabel? = nil
local attachedTargets: { [GuiObject]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function getCenterPosition(target: GuiObject): UDim2
	local position, size, anchor = target.Position, target.Size, target.AnchorPoint
	return UDim2.new(
		position.X.Scale + size.X.Scale * (0.5 - anchor.X),
		position.X.Offset + size.X.Offset * (0.5 - anchor.X),
		position.Y.Scale + size.Y.Scale * (0.5 - anchor.Y),
		position.Y.Offset + size.Y.Offset * (0.5 - anchor.Y)
	)
end

local function getMaxSideInParent(target: GuiObject): number
	local parent = target.Parent
	if not parent or not parent:IsA("GuiObject") then
		return math.huge
	end
	local center = target.AbsolutePosition + target.AbsoluteSize / 2
	local parentMin = parent.AbsolutePosition
	local parentMax = parentMin + parent.AbsoluteSize
	local nearest = math.min(
		center.X - parentMin.X,
		parentMax.X - center.X,
		center.Y - parentMin.Y,
		parentMax.Y - center.Y
	)
	return math.max(0, nearest - EDGE_MARGIN) * 2
end

local function updateLayout(target: GuiObject, rays: ImageLabel)
	local desired = math.max(target.AbsoluteSize.X, target.AbsoluteSize.Y) * SIZE_MULTIPLIER
	local side = math.min(desired, getMaxSideInParent(target))
	rays.Size = UDim2.fromOffset(side, side)
	rays.Position = getCenterPosition(target)
	rays.Visible = target.Visible
end

local function removeExisting(target: GuiObject)
	local parent = target.Parent
	if not parent then
		return
	end
	for _, sibling in parent:GetChildren() do
		if sibling.Name == TEMPLATE_NAME and sibling:GetAttribute(OWNER_ATTRIBUTE) == target.Name then
			sibling:Destroy()
		end
	end
end

local function bindToTarget(target: GuiObject, rays: ImageLabel)
	local function refresh()
		updateLayout(target, rays)
	end
	target:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
	target:GetPropertyChangedSignal("AbsolutePosition"):Connect(refresh)
	target:GetPropertyChangedSignal("Position"):Connect(refresh)
	target:GetPropertyChangedSignal("Visible"):Connect(refresh)
	target.Destroying:Connect(function()
		rays:Destroy()
	end)
	refresh()
end

local function tryAttach(instance: Instance)
	if not instance:IsA("GuiObject") then
		return
	end
	local mode = instance:GetAttribute(MODE_ATTRIBUTE)
	if mode ~= MODE_STATIC and mode ~= MODE_SPIN then
		return
	end
	LightRays.Attach(instance, mode :: Mode)
end

function LightRays.Attach(target: GuiObject, mode: Mode)
	local source = template
	if not source or attachedTargets[target] or not target.Parent then
		return
	end
	attachedTargets[target] = true
	removeExisting(target)
	local rays = source:Clone()
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.ZIndex = target.ZIndex - 1
	rays:SetAttribute(OWNER_ATTRIBUTE, target.Name)
	rays.Parent = target.Parent
	bindToTarget(target, rays)
	if mode == MODE_SPIN then
		TweenService:Create(rays, SPIN_TWEEN_INFO, { Rotation = 360 }):Play()
	end
end

function LightRays.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	local found = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild(TEMPLATE_NAME)
	if not found:IsA("ImageLabel") then
		warn("[LightRays] Template is not an ImageLabel")
		return
	end
	template = found
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, descendant in playerGui:GetDescendants() do
		tryAttach(descendant)
	end
	playerGui.DescendantAdded:Connect(tryAttach)
end

return LightRays
