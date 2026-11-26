--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local CrucibleViewConfig = require(ReplicatedStorage.Shared.Config.CrucibleViewConfig)
local DigFxConfig = require(ReplicatedStorage.Shared.Config.DigFxConfig)
local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local ItemVisuals = require(ReplicatedStorage.Shared.Constants.ItemVisuals)
local RevealSound = require(script.Parent.RevealSound)

local CENTER = Vector2.new(0.5, 0.5)
local VIEW_DIRECTION = Vector3.new(0, 0.35, 1).Unit
local VIEW_DISTANCE_PER_SIZE = 1.25
local FULL_TURN = math.pi * 2
local SPIN_FULL_DEGREES = 360

local OreRevealPopup = {}

local queue: { string } = {}
local isPlaying = false

local function getConfig()
	return DigFxConfig.Reveal
end

local function getRarity(oreId: string): string
	local visual = ItemVisuals[oreId]
	return if visual and visual.RarityLabel then visual.RarityLabel else "Common"
end

local function getColor(rarity: string): Color3
	local colors = getConfig().RarityColors
	return colors[rarity] or colors.Common
end

local function findOreModel(oreId: string): Model?
	local folder = ReplicatedStorage:FindFirstChild(CrucibleViewConfig.OreFolderName)
	local model = folder and folder:FindFirstChild(oreId)
	return if model and model:IsA("Model") then model else nil
end

local function createGui(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = getConfig().GuiName
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = getConfig().DisplayOrder
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

local function createHolder(gui: ScreenGui): Frame
	local holder = Instance.new("Frame")
	holder.AnchorPoint = CENTER
	holder.Position = UDim2.fromScale(0.5, getConfig().CenterHeight)
	holder.Size = UDim2.fromOffset(getConfig().RingSize, getConfig().RingSize)
	holder.BackgroundTransparency = 1
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = holder
	holder.Parent = gui
	return holder
end

local function createRays(holder: Frame, color: Color3): ImageLabel
	local config = getConfig()
	local rays = Instance.new("ImageLabel")
	rays.AnchorPoint = CENTER
	rays.Position = UDim2.fromScale(0.5, 0.5)
	rays.Size = UDim2.fromOffset(config.RaysSize, config.RaysSize)
	rays.BackgroundTransparency = 1
	rays.Image = config.RaysImage
	rays.ImageColor3 = color
	rays.ImageTransparency = config.RaysTransparency
	rays.ZIndex = 1
	rays.Parent = holder
	local info = TweenInfo.new(config.RaysSpinSeconds, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
	TweenService:Create(rays, info, { Rotation = SPIN_FULL_DEGREES }):Play()
	return rays
end

local function createViewport(holder: Frame, oreId: string): (ViewportFrame, Model?)
	local size = getConfig().ViewportSize
	local viewport = Instance.new("ViewportFrame")
	viewport.AnchorPoint = CENTER
	viewport.Position = UDim2.fromScale(0.5, 0.5)
	viewport.Size = UDim2.fromOffset(size, size)
	viewport.BackgroundTransparency = 1
	viewport.ZIndex = 3
	viewport.Parent = holder
	local source = findOreModel(oreId)
	if source == nil then
		return viewport, nil
	end
	local model = source:Clone()
	model:PivotTo(CFrame.identity)
	local boxCFrame, boxSize = model:GetBoundingBox()
	model:PivotTo(CFrame.new(-boxCFrame.Position))
	local camera = Instance.new("Camera")
	camera.FieldOfView = getConfig().CameraFieldOfView
	camera.CFrame = CFrame.lookAt(VIEW_DIRECTION * boxSize.Magnitude * VIEW_DISTANCE_PER_SIZE, Vector3.zero)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	model.Parent = viewport
	return viewport, model
end

local function createLabel(holder: Frame, text: string, color: Color3, size: number, offsetY: number)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 1, offsetY)
	label.Size = UDim2.fromOffset(getConfig().LabelWidth, size + getConfig().LabelGap * 2)
	label.BackgroundTransparency = 1
	label.FontFace = getConfig().NameFont
	label.TextSize = size
	label.TextColor3 = color
	label.Text = text
	label.ZIndex = 4
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = getConfig().LabelStrokeThickness
	stroke.Parent = label
	label.Parent = holder
end

local function getInventoryPosition(): UDim2?
	local config = getConfig()
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(config.HudGuiName)
	if hud == nil or not hud:IsA("ScreenGui") then
		return nil
	end
	local button = hud:FindFirstChild(config.InventoryButtonName, true)
	if button == nil or not button:IsA("GuiObject") then
		return nil
	end
	local center = button.AbsolutePosition + button.AbsoluteSize / 2
	local inset = if hud.IgnoreGuiInset then Vector2.zero else GuiService:GetGuiInset()
	local point = center + inset
	return UDim2.fromOffset(point.X, point.Y)
end

local function spin(model: Model?): RBXScriptConnection?
	if model == nil then
		return nil
	end
	local base = model:GetPivot()
	local angle = 0
	return RunService.RenderStepped:Connect(function(dt)
		angle = (angle + dt * getConfig().SpinSpeed) % FULL_TURN
		model:PivotTo(CFrame.Angles(0, angle, 0) * base)
	end)
end

local function play(oreId: string)
	local config = getConfig()
	local rarity = getRarity(oreId)
	local color = getColor(rarity)
	local gui = createGui()
	local holder = createHolder(gui)
	local scale = holder:FindFirstChildOfClass("UIScale") :: UIScale
	createRays(holder, color)
	local _, model = createViewport(holder, oreId)
	local displayName = BackpackMessages.ItemNames[oreId] or oreId
	createLabel(holder, string.upper(rarity), color, config.RarityTextSize, config.LabelGap)
	createLabel(holder, displayName, Color3.new(1, 1, 1), config.NameTextSize, config.RarityTextSize + config.LabelGap * 3)
	local spinConnection = spin(model)
	RevealSound.Play(config.PopSound, SoundService)
	local popInfo = TweenInfo.new(config.PopTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(scale, popInfo, { Scale = 1 }):Play()
	task.wait(config.PopTime + config.HoldTime)
	local target = getInventoryPosition()
	local flyInfo = TweenInfo.new(config.FlyTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	if target then
		TweenService:Create(holder, flyInfo, { Position = target }):Play()
	end
	TweenService:Create(scale, flyInfo, { Scale = config.FlyEndScale }):Play()
	RevealSound.Play(config.FlySound, SoundService)
	task.wait(config.FlyTime)
	if spinConnection then
		spinConnection:Disconnect()
	end
	gui:Destroy()
end

local function drain()
	if isPlaying then
		return
	end
	isPlaying = true
	while #queue > 0 do
		local oreId = table.remove(queue, 1) :: string
		local ok, err = pcall(play, oreId)
		if not ok then
			warn("[OreRevealPopup] Failed:", err)
		end
	end
	isPlaying = false
end

function OreRevealPopup.Show(oreId: string)
	table.insert(queue, oreId)
	task.spawn(drain)
end

return OreRevealPopup
