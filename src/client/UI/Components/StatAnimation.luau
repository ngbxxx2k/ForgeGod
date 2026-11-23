--!strict

local TweenService = game:GetService("TweenService")

local SCALE_NAME = "StatScale"
local COUNT_DURATION = 0.45
local POP_SCALE = 1.18
local POP_DURATION = 0.3
local FLASH_HOLD = 0.25
local FLASH_FADE = 0.35
local FADE_OUT_TIME = 0.08
local UP_COLOR = Color3.fromRGB(90, 235, 120)
local DOWN_COLOR = Color3.fromRGB(255, 110, 70)
local COUNT_TWEEN_INFO = TweenInfo.new(COUNT_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_OUT_INFO = TweenInfo.new(FADE_OUT_TIME, Enum.EasingStyle.Linear)

export type Formatter = (value: number) -> string

export type SwapStyle = {
	StartScale: number,
	Duration: number,
	EasingStyle: Enum.EasingStyle,
	Wobble: number,
}

type CountState = {
	Value: number,
	BaseColor: Color3,
	Driver: NumberValue,
	Tween: Tween?,
	ColorTween: Tween?,
	Token: number,
}

type GuiTweens = {
	Scale: Tween?,
	Fade: Tween?,
	Rotation: Tween?,
	Token: number,
}

local StatAnimation = {}

local countStates: { [TextLabel]: CountState } = {}
local guiTweens: { [GuiObject]: GuiTweens } = {}

local function getScale(target: GuiObject): UIScale
	local existing = target:FindFirstChild(SCALE_NAME)
	if existing and existing:IsA("UIScale") then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Name = SCALE_NAME
	scale.Parent = target
	return scale
end

local function getTweens(target: GuiObject): GuiTweens
	local tweens = guiTweens[target]
	if tweens then
		return tweens
	end
	local created: GuiTweens = { Scale = nil, Fade = nil, Rotation = nil, Token = 0 }
	guiTweens[target] = created
	target.Destroying:Connect(function()
		guiTweens[target] = nil
	end)
	return created
end

local function cancel(tween: Tween?)
	if tween then
		tween:Cancel()
	end
end

local function getCountState(label: TextLabel, value: number): CountState
	local state = countStates[label]
	if state then
		return state
	end
	local driver = Instance.new("NumberValue")
	driver.Value = value
	local created: CountState = {
		Value = value,
		BaseColor = label.TextColor3,
		Driver = driver,
		Tween = nil,
		ColorTween = nil,
		Token = 0,
	}
	countStates[label] = created
	label.Destroying:Connect(function()
		countStates[label] = nil
		driver:Destroy()
	end)
	return created
end

local function flashColor(label: TextLabel, state: CountState, color: Color3)
	cancel(state.ColorTween)
	label.TextColor3 = color
	local info = TweenInfo.new(FLASH_FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, FLASH_HOLD)
	local tween = TweenService:Create(label, info, { TextColor3 = state.BaseColor })
	state.ColorTween = tween
	tween:Play()
end

function StatAnimation.Pop(target: GuiObject, peakScale: number?, duration: number?)
	local tweens = getTweens(target)
	local scale = getScale(target)
	cancel(tweens.Scale)
	scale.Scale = peakScale or POP_SCALE
	local info = TweenInfo.new(duration or POP_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(scale, info, { Scale = 1 })
	tweens.Scale = tween
	tween:Play()
end

function StatAnimation.SetNumber(label: TextLabel, value: number, format: Formatter)
	local state = getCountState(label, value)
	cancel(state.Tween)
	state.Token += 1
	state.Value = value
	state.Driver.Value = value
	label.Text = format(value)
end

function StatAnimation.CountTo(label: TextLabel, value: number, format: Formatter)
	local state = getCountState(label, value)
	if state.Value == value then
		label.Text = format(value)
		return
	end
	local isUp = value > state.Value
	cancel(state.Tween)
	state.Token += 1
	local token = state.Token
	state.Value = value
	local driver = state.Driver
	local tween = TweenService:Create(driver, COUNT_TWEEN_INFO, { Value = value })
	local connection = driver.Changed:Connect(function(current: number)
		if state.Token == token then
			label.Text = format(math.round(current))
		end
	end)
	tween.Completed:Connect(function()
		connection:Disconnect()
		if state.Token == token then
			label.Text = format(value)
		end
	end)
	state.Tween = tween
	tween:Play()
	flashColor(label, state, if isUp then UP_COLOR else DOWN_COLOR)
	StatAnimation.Pop(label)
end

function StatAnimation.SetBaseColor(label: TextLabel, color: Color3)
	local state = countStates[label]
	if state then
		state.BaseColor = color
	end
	label.TextColor3 = color
end

function StatAnimation.SwapText(label: TextLabel, text: string, color: Color3, style: SwapStyle)
	local tweens = getTweens(label)
	tweens.Token += 1
	local token = tweens.Token
	cancel(tweens.Fade)
	local fadeOut = TweenService:Create(label, FADE_OUT_INFO, { TextTransparency = 1 })
	tweens.Fade = fadeOut
	fadeOut.Completed:Connect(function(playbackState: Enum.PlaybackState)
		if playbackState ~= Enum.PlaybackState.Completed or tweens.Token ~= token then
			return
		end
		label.Text = text
		label.TextColor3 = color
		local info = TweenInfo.new(style.Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fadeIn = TweenService:Create(label, info, { TextTransparency = 0 })
		tweens.Fade = fadeIn
		fadeIn:Play()
		local popInfo = TweenInfo.new(style.Duration, style.EasingStyle, Enum.EasingDirection.Out)
		local scale = getScale(label)
		cancel(tweens.Scale)
		scale.Scale = style.StartScale
		local popTween = TweenService:Create(scale, popInfo, { Scale = 1 })
		tweens.Scale = popTween
		popTween:Play()
		StatAnimation.Wobble(label, style.Wobble, style.Duration)
	end)
	fadeOut:Play()
end

function StatAnimation.Wobble(target: GuiObject, degrees: number, duration: number)
	local tweens = getTweens(target)
	cancel(tweens.Rotation)
	target.Rotation = 0
	if degrees <= 0 then
		return
	end
	target.Rotation = degrees
	local info = TweenInfo.new(duration, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	local tween = TweenService:Create(target, info, { Rotation = 0 })
	tweens.Rotation = tween
	tween:Play()
end

return StatAnimation
