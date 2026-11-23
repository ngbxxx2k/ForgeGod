--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RarityGradient = require(script.Parent.Parent.UI.Components.RarityGradient)
local RevealCleanup = require(script.Parent.RevealCleanup)

local ANCHOR_NAME = "ForgeRevealRarityLabel"
local ANCHOR_SIZE = Vector3.new(0.2, 0.2, 0.2)
local CENTER = Vector2.new(0.5, 0.5)
local HEIGHT_FOR_TOP_HALF = 2
local TOP_HALF_CENTER_Y = 0.25
local FULL_TURN = math.pi * 2

export type Label = {
	Anchor: Part,
	Billboard: BillboardGui,
	Holder: Frame,
	Text: TextLabel,
	Scale: UIScale,
	Tween: Tween?,
	IsWobbling: boolean,
	WobbleStart: number,
	Connection: RBXScriptConnection?,
}

local RarityLabel = {}

local rng = Random.new()

local function createAnchor(position: Vector3): Part
	local anchor = Instance.new("Part")
	anchor.Name = ANCHOR_NAME
	anchor.Size = ANCHOR_SIZE
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(position)
	return anchor
end

local function createBillboard(anchor: Part): BillboardGui
	local config = ForgeAnimationConfig.RarityLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(config.WidthPixels, config.HeightPixels * HEIGHT_FOR_TOP_HALF)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.ClipsDescendants = false
	billboard.Adornee = anchor
	billboard.Parent = anchor
	return billboard
end

local function createHolder(billboard: BillboardGui): (Frame, UIScale)
	local holder = Instance.new("Frame")
	holder.AnchorPoint = CENTER
	holder.Position = UDim2.fromScale(CENTER.X, TOP_HALF_CENTER_Y)
	holder.Size = UDim2.fromScale(1, 1 / HEIGHT_FOR_TOP_HALF)
	holder.BackgroundTransparency = 1
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	holder.Parent = billboard
	return holder, scale
end

local function createText(holder: Frame): TextLabel
	local config = ForgeAnimationConfig.RarityLabel
	local text = Instance.new("TextLabel")
	text.AnchorPoint = CENTER
	text.Position = UDim2.fromScale(CENTER.X, CENTER.Y)
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.FontFace = ForgeAnimationConfig.CutsceneFont
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Text = ""
	local stroke = Instance.new("UIStroke")
	stroke.Color = config.StrokeColor
	stroke.Thickness = config.StrokeThickness
	stroke.Parent = text
	text.Parent = holder
	return text
end

local function resetPose(label: Label)
	label.Text.Rotation = 0
	label.Text.Position = UDim2.fromScale(CENTER.X, CENTER.Y)
end

local function stepWobble(label: Label)
	if not label.IsWobbling then
		return
	end
	local config = ForgeAnimationConfig.RarityLabel
	local elapsed = os.clock() - label.WobbleStart
	label.Text.Rotation = math.sin(elapsed * config.TiltFrequency * FULL_TURN) * config.TiltAngle
	local shake = config.ShakePixels
	local offsetX = rng:NextNumber(-shake, shake)
	local offsetY = rng:NextNumber(-shake, shake)
	label.Text.Position = UDim2.new(CENTER.X, offsetX, CENTER.Y, offsetY)
end

function RarityLabel.Create(position: Vector3, cleanup: RevealCleanup.Cleanup): Label
	local anchor = createAnchor(position)
	local billboard = createBillboard(anchor)
	local holder, scale = createHolder(billboard)
	local text = createText(holder)
	anchor.Parent = Workspace
	RevealCleanup.Add(cleanup, anchor)
	local label: Label = {
		Anchor = anchor,
		Billboard = billboard,
		Holder = holder,
		Text = text,
		Scale = scale,
		Tween = nil,
		IsWobbling = false,
		WobbleStart = 0,
		Connection = nil,
	}
	local connection = RunService.RenderStepped:Connect(function()
		stepWobble(label)
	end)
	label.Connection = connection
	RevealCleanup.Add(cleanup, connection)
	return label
end

function RarityLabel.Show(label: Label, rarity: string, displayName: string, _color: Color3, isFinal: boolean)
	local config = ForgeAnimationConfig.RarityLabel
	label.Text.Text = displayName
	RarityGradient.Apply(label.Text, rarity)
	if not label.IsWobbling and not isFinal then
		label.WobbleStart = os.clock()
	end
	label.IsWobbling = not isFinal
	if isFinal then
		resetPose(label)
	end
	if label.Tween then
		label.Tween:Cancel()
	end
	label.Scale.Scale = if isFinal then config.FinalPopScale else config.PopScale
	local duration = if isFinal then config.FinalPopTime else config.PopTime
	local info = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(label.Scale, info, {
		Scale = if isFinal then config.FinalScale else 1,
	})
	label.Tween = tween
	tween:Play()
end

function RarityLabel.Hide(label: Label)
	label.IsWobbling = false
	if label.Tween then
		label.Tween:Cancel()
	end
	local connection = label.Connection
	if connection then
		connection:Disconnect()
		label.Connection = nil
	end
	label.Anchor:Destroy()
end

return RarityLabel
