--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SpinConfig = require(ReplicatedStorage.Shared.Config.SpinConfig)
local SpinMessages = require(ReplicatedStorage.Shared.Constants.SpinMessages)
local UiIcons = require(ReplicatedStorage.Shared.Constants.UiIcons)
local GuiPath = require(script.Parent.Parent.Components.GuiPath)
local HudButton = require(script.Parent.Parent.Components.HudButton)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local PieSlice = require(script.Parent.Parent.Components.PieSlice)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)

local SPIN_GUI_NAME = "SpinWheelGui"
local HUD_BUTTON_NAME = "DailyRewardButton"
local REWARD_TEMPLATE_NAME = "RewardTemplate"
local REWARD_NAME = "Reward"
local DIVIDER_TEMPLATE_NAME = "DividerTemplate"
local DIVIDER_NAME = "Divider"
local BASE_DISC_NAME = "Base"
local SLICE_BASE_Z_INDEX = 1
local ASSETS_FOLDER_NAME = "Assets"
local SOUNDS_FOLDER_NAME = "Sounds"
local HOVER_ATTRIBUTE = "HasHoverEffect"
local FULL_TURN = 360
local DISC_PATH = { "Wheel", "Disc" }
local TOKENS_PATH = { "TokensLabel" }
local FREE_PATH = { "FreeLabel" }
local SPIN_BUTTON_PATH = { "ButtonRow", "SpinButton" }
local HIDE_BUTTON_PATH = { "ButtonRow", "HideButton" }
local BUY_BUTTON_PATH = { "ButtonRow", "BuyButton" }
local BUY_PRICE_PATH = { "ButtonRow", "BuyButton", "PriceRow", "PriceLabel" }
local BUY_ROBUX_ICON_PATH = { "ButtonRow", "BuyButton", "PriceRow", "RobuxIcon" }
local SPIN_TWEEN_STYLE = Enum.EasingStyle.Quint
local SPIN_ENABLED_TRANSPARENCY = 0
local SPIN_DISABLED_TRANSPARENCY = 0.35

export type WheelReward = {
	Id: string,
	Color: Color3,
	Image: string?,
	Text: string,
}

export type StatusView = {
	TokensText: string,
	FreeText: string,
	SpinText: string,
	CanSpin: boolean,
}

type WheelPart = {
	Id: string,
	Slice: PieSlice.Slice,
	Color: Color3,
	Start: number,
	Spoke: GuiObject,
	Divider: GuiObject?,
}

type PartFrames = { Segments: Instance, Rewards: Instance, Dividers: Instance }

type PartTemplates = { Reward: GuiObject?, Divider: GuiObject? }

local SpinWheelScreen = {}

local isInitialized = false
local container: GuiObject? = nil
local disc: GuiObject? = nil
local baseDisc: Frame? = nil
local parts: { WheelPart } = {}
local spinHandler: (() -> ())? = nil
local buyHandler: (() -> ())? = nil
local rotationDriver: NumberValue? = nil
local spinTween: Tween? = nil
local currentRotation = 0
local lastTickIndex = 0
local lastTickAt = 0
local rng = Random.new()

local function getSegmentAngle(): number
	return FULL_TURN / math.max(#parts, 1)
end

local function playTick()
	local now = os.clock()
	if now - lastTickAt < SpinConfig.TickMinInterval then
		return
	end
	lastTickAt = now
	local folder = ReplicatedStorage:FindFirstChild(ASSETS_FOLDER_NAME)
	local sounds = folder and folder:FindFirstChild(SOUNDS_FOLDER_NAME)
	local sound = sounds and sounds:FindFirstChild(SpinConfig.TickSoundName)
	if sound and sound:IsA("Sound") then
		SoundService:PlayLocalSound(sound)
	end
end

local function updateTick(rotation: number)
	local tickIndex = math.floor(rotation / getSegmentAngle())
	if tickIndex ~= lastTickIndex then
		lastTickIndex = tickIndex
		playTick()
	end
end

local function drawSlices(rotation: number)
	local order = table.clone(parts)
	local function getStart(part: WheelPart): number
		return (part.Start + rotation) % FULL_TURN
	end
	table.sort(order, function(a: WheelPart, b: WheelPart): boolean
		return getStart(a) < getStart(b)
	end)
	for index, part in order do
		PieSlice.SetZIndex(part.Slice, SLICE_BASE_Z_INDEX + index)
		PieSlice.SetStart(part.Slice, getStart(part))
	end
	local base = baseDisc
	local wrapping = order[#order]
	if base and wrapping then
		base.BackgroundColor3 = wrapping.Color
	end
end

local function applyRotation(rotation: number)
	currentRotation = rotation
	local halfSegment = getSegmentAngle() / 2
	for _, part in parts do
		part.Spoke.Rotation = part.Start + halfSegment + rotation
		local divider = part.Divider
		if divider then
			divider.Rotation = part.Start + rotation
		end
	end
	drawSlices(rotation)
	updateTick(rotation)
end

local function createBaseDisc(parent: Instance): Frame
	local base = Instance.new("Frame")
	base.Name = BASE_DISC_NAME
	base.BorderSizePixel = 0
	base.Size = UDim2.fromScale(1, 1)
	base.ZIndex = SLICE_BASE_Z_INDEX
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = base
	base.Parent = parent
	return base
end

local function cloneTemplate(template: GuiObject, name: string, parent: Instance): GuiObject
	local clone = template:Clone()
	clone.Name = name
	clone.Visible = true
	clone.Parent = parent
	return clone
end

local function createPart(
	frames: PartFrames,
	templates: PartTemplates,
	reward: WheelReward,
	index: number
): WheelPart
	local spokeTemplate = templates.Reward :: GuiObject
	local spoke = cloneTemplate(spokeTemplate, REWARD_NAME, frames.Rewards)
	GuiPath.SetImage(spoke, { "Icon" }, reward.Image)
	GuiPath.SetText(spoke, { "AmountLabel" }, reward.Text)
	local dividerTemplate = templates.Divider
	return {
		Id = reward.Id,
		Slice = PieSlice.Create(frames.Segments, reward.Id, reward.Color, SLICE_BASE_Z_INDEX + index),
		Color = reward.Color,
		Start = 0,
		Spoke = spoke,
		Divider = if dividerTemplate
			then cloneTemplate(dividerTemplate, DIVIDER_NAME, frames.Dividers)
			else nil,
	}
end

local function findTemplate(parent: Instance?, name: string): GuiObject?
	local template = parent and parent:FindFirstChild(name)
	if template and template:IsA("GuiObject") then
		template.Visible = false
		return template
	end
	return nil
end

local function buildWheel(wheelDisc: Instance, rewards: { WheelReward })
	local segmentsFrame = wheelDisc:FindFirstChild("Segments")
	local rewardsFrame = wheelDisc:FindFirstChild("Rewards")
	local dividersFrame = wheelDisc:FindFirstChild("Dividers")
	if not segmentsFrame or not rewardsFrame or not dividersFrame then
		warn("[SpinWheelScreen] Disc has wrong structure")
		return
	end
	local templates = {
		Reward = findTemplate(rewardsFrame, REWARD_TEMPLATE_NAME),
		Divider = findTemplate(dividersFrame, DIVIDER_TEMPLATE_NAME),
	}
	if templates.Reward == nil then
		warn("[SpinWheelScreen] Missing RewardTemplate")
		return
	end
	local frames = { Segments = segmentsFrame, Rewards = rewardsFrame, Dividers = dividersFrame }
	baseDisc = createBaseDisc(segmentsFrame)
	for index, reward in rewards do
		table.insert(parts, createPart(frames, templates, reward, index))
	end
	local segmentAngle = getSegmentAngle()
	for index, part in parts do
		part.Start = (index - 1) * segmentAngle
	end
	applyRotation(currentRotation)
end

local function findRewardIndex(rewardId: string): number?
	for index, part in parts do
		if part.Id == rewardId then
			return index
		end
	end
	return nil
end

local function getLandingRotation(current: number, rewardIndex: number): number
	local segmentAngle = getSegmentAngle()
	local jitter = rng:NextNumber(-SpinConfig.LandingJitter, SpinConfig.LandingJitter) * segmentAngle
	local center = (rewardIndex - 0.5) * segmentAngle + jitter
	local offset = (-center - current) % FULL_TURN
	return current + offset + SpinConfig.FullTurns * FULL_TURN
end

local function bindButton(root: Instance, path: { string }, onActivated: () -> ())
	local button = GuiPath.Find(root, path)
	if not button or not button:IsA("GuiButton") then
		warn("[SpinWheelScreen] Missing", table.concat(path, "."))
		return
	end
	button:SetAttribute(HOVER_ATTRIBUTE, true)
	button.Activated:Connect(onActivated)
end

local function close()
	local root = container
	if root then
		OpenAnimation.Close(root)
	end
end

local function toggle()
	local root = container
	if root == nil then
		return
	end
	if root.Visible then
		close()
		return
	end
	ScreenRegistry.CloseAllExcept(root)
	root.Visible = true
end

function SpinWheelScreen.SetRewards(rewards: { WheelReward })
	local wheelDisc = disc
	if wheelDisc == nil then
		warn("[SpinWheelScreen] SetRewards called before Init")
		return
	end
	buildWheel(wheelDisc, rewards)
end

function SpinWheelScreen.SpinTo(rewardId: string, onFinished: () -> ())
	local driver = rotationDriver
	local rewardIndex = findRewardIndex(rewardId)
	if driver == nil or rewardIndex == nil then
		onFinished()
		return
	end
	if spinTween then
		spinTween:Cancel()
	end
	local start = currentRotation % FULL_TURN
	driver.Value = start
	lastTickIndex = math.floor(start / getSegmentAngle())
	local target = getLandingRotation(start, rewardIndex)
	local info = TweenInfo.new(SpinConfig.SpinDuration, SPIN_TWEEN_STYLE, Enum.EasingDirection.Out)
	local tween = TweenService:Create(driver, info, { Value = target })
	spinTween = tween
	tween.Completed:Connect(function()
		if spinTween == tween then
			spinTween = nil
		end
		onFinished()
	end)
	tween:Play()
end


function SpinWheelScreen.IsSpinning(): boolean
	return spinTween ~= nil
end

function SpinWheelScreen.SetStatus(view: StatusView)
	local root = container
	if root == nil then
		return
	end
	GuiPath.SetText(root, TOKENS_PATH, view.TokensText)
	GuiPath.SetText(root, FREE_PATH, view.FreeText)
	GuiPath.SetText(root, { "ButtonRow", "SpinButton", "Label" }, view.SpinText)
	local spinButton = GuiPath.Find(root, SPIN_BUTTON_PATH)
	if spinButton and spinButton:IsA("GuiButton") then
		spinButton.AutoButtonColor = view.CanSpin
		spinButton.BackgroundTransparency = if view.CanSpin
			then SPIN_ENABLED_TRANSPARENCY
			else SPIN_DISABLED_TRANSPARENCY
	end
end

function SpinWheelScreen.SetBuyPrice(text: string)
	local root = container
	if root then
		GuiPath.SetText(root, BUY_PRICE_PATH, text)
	end
end

function SpinWheelScreen.IsVisible(): boolean
	return container ~= nil and container.Visible
end

function SpinWheelScreen.SetSpinHandler(handler: () -> ())
	spinHandler = handler
end

function SpinWheelScreen.SetBuyHandler(handler: () -> ())
	buyHandler = handler
end

local function bindButtons(root: Instance)
	bindButton(root, HIDE_BUTTON_PATH, close)
	bindButton(root, SPIN_BUTTON_PATH, function()
		local handler = spinHandler
		if handler then
			handler()
		end
	end)
	bindButton(root, BUY_BUTTON_PATH, function()
		local handler = buyHandler
		if handler then
			handler()
		end
	end)
end

local function applyStaticContent(root: Instance)
	GuiPath.SetText(root, { "Title" }, SpinMessages.Title)
	GuiPath.SetText(root, { "ButtonRow", "HideButton", "Label" }, SpinMessages.HideButton)
	GuiPath.SetText(root, { "ButtonRow", "BuyButton", "Label" }, SpinMessages.BuyButton)
	GuiPath.SetImage(root, BUY_ROBUX_ICON_PATH, UiIcons.Robux)
end

function SpinWheelScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(SPIN_GUI_NAME)
	local root = gui:WaitForChild("Container")
	local wheelDisc = GuiPath.Find(root, DISC_PATH)
	if not root:IsA("GuiObject") or not wheelDisc or not wheelDisc:IsA("GuiObject") then
		warn("[SpinWheelScreen] SpinWheelGui has wrong structure")
		return
	end
	root.Visible = false
	if gui:IsA("ScreenGui") then
		gui.Enabled = true
	end
	container, disc = root, wheelDisc
	local driver = Instance.new("NumberValue")
	driver.Changed:Connect(applyRotation)
	rotationDriver = driver
	UiSound.WatchOpen(root)
	OpenAnimation.Watch(root)
	HudSlide.TrackScreen(root)
	ScreenRegistry.Register(root)
	applyStaticContent(root)
	bindButtons(root)
	HudButton.SetStyle(HUD_BUTTON_NAME, { Text = SpinMessages.HudLabel, Image = UiIcons.SpinWheel.Header })
	HudButton.Bind(HUD_BUTTON_NAME, toggle)
end

return SpinWheelScreen
