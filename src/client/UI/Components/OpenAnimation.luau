--!strict

local TweenService = game:GetService("TweenService")

local SCALE_NAME = "OpenScale"
local START_SCALE_RATIO = 0.6
local CLOSED_SCALE_RATIO = 0.6
local OPEN_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)

type FrameState = {
	Scale: UIScale,
	BaseScale: number,
	Token: number,
	Tween: Tween?,
}

local OpenAnimation = {}

local frameStates: { [GuiObject]: FrameState } = setmetatable({}, { __mode = "k" }) :: any

local function getOrCreateScale(frame: GuiObject): UIScale
	local existing = frame:FindFirstChildOfClass("UIScale")
	if existing then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Name = SCALE_NAME
	scale.Parent = frame
	return scale
end

local function playTween(state: FrameState, tweenInfo: TweenInfo, targetScale: number): Tween
	local previous = state.Tween
	if previous then
		previous:Cancel()
	end
	local tween = TweenService:Create(state.Scale, tweenInfo, { Scale = targetScale })
	state.Tween = tween
	tween:Play()
	return tween
end

local function playOpen(state: FrameState)
	state.Token += 1
	state.Scale.Scale = state.BaseScale * START_SCALE_RATIO
	playTween(state, OPEN_TWEEN_INFO, state.BaseScale)
end

function OpenAnimation.Open(frame: GuiObject)
	local state = frameStates[frame]
	if state and frame.Visible then
		playOpen(state)
		return
	end
	frame.Visible = true
end

function OpenAnimation.Watch(frame: GuiObject, scaleTarget: GuiObject?)
	if frameStates[frame] then
		return
	end
	local scale = getOrCreateScale(scaleTarget or frame)
	local state: FrameState = { Scale = scale, BaseScale = scale.Scale, Token = 0, Tween = nil }
	frameStates[frame] = state
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if frame.Visible then
			playOpen(state)
		end
	end)
end

function OpenAnimation.Close(frame: GuiObject, onClosed: (() -> ())?)
	local state = frameStates[frame]
	if not state or not frame.Visible then
		frame.Visible = false
		if onClosed then
			onClosed()
		end
		return
	end
	state.Token += 1
	local closeToken = state.Token
	local tween = playTween(state, CLOSE_TWEEN_INFO, state.BaseScale * CLOSED_SCALE_RATIO)
	tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
		if playbackState ~= Enum.PlaybackState.Completed or state.Token ~= closeToken then
			return
		end
		frame.Visible = false
		state.Scale.Scale = state.BaseScale
		if onClosed then
			onClosed()
		end
	end)
end

return OpenAnimation
