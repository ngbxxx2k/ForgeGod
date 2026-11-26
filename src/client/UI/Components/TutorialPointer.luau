--!strict

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TutorialConfig = require(ReplicatedStorage.Shared.Config.TutorialConfig)

export type PointResolver = () -> Vector2?

local TutorialPointer = {}

local pointer: ImageLabel? = nil
local resolver: PointResolver? = nil
local connection: RBXScriptConnection? = nil

local function toPointerSpace(image: ImageLabel, point: Vector2): Vector2
	local screenGui = image:FindFirstAncestorWhichIsA("ScreenGui")
	return if screenGui then point - screenGui.AbsolutePosition else point
end

function TutorialPointer.FromViewport(viewportPoint: Vector2): Vector2
	local topLeft = GuiService:GetGuiInset()
	return viewportPoint - topLeft
end

local function isShown(target: GuiObject): boolean
	local current: Instance? = target
	while current do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		if current:IsA("LayerCollector") then
			return current.Enabled
		end
		current = current.Parent
	end
	return false
end

function TutorialPointer.GuiCenter(target: GuiObject?): Vector2?
	if target == nil or target.Parent == nil or not isShown(target) then
		return nil
	end
	if target:FindFirstAncestorWhichIsA("ScreenGui") == nil then
		return nil
	end
	return target.AbsolutePosition + target.AbsoluteSize / 2
end

local function update()
	local image = pointer
	if image == nil then
		return
	end
	local getPoint = resolver
	local point = if getPoint then getPoint() else nil
	if point == nil then
		image.Visible = false
		return
	end
	local config = TutorialConfig.Pointer
	local bob = (math.sin(os.clock() * config.BobSpeed) + 1) / 2 * config.BobPixels
	local localPoint = toPointerSpace(image, point)
	image.Position = UDim2.fromOffset(localPoint.X, localPoint.Y - bob)
	image.Visible = true
end

function TutorialPointer.SetTarget(newResolver: PointResolver?)
	resolver = newResolver
	if newResolver == nil and pointer then
		pointer.Visible = false
	end
end

function TutorialPointer.Bind(image: ImageLabel)
	pointer = image
	image.Image = TutorialConfig.Pointer.Image
	image.Size = UDim2.fromOffset(TutorialConfig.Pointer.SizePixels, TutorialConfig.Pointer.SizePixels)
	image.Visible = false
	image.Interactable = false
	image.Active = false
	if connection == nil then
		connection = RunService.RenderStepped:Connect(update)
	end
end

return TutorialPointer
