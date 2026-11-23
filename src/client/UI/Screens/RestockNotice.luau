--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HUD_GUI_NAME = "HudGui"
local NOTICE_NAME = "RestockNotice"
local HIDDEN_TRANSPARENCY = 1
local SHOWN_TRANSPARENCY = 0
local POP_START_SCALE = 0.6
local HOLD_SECONDS = 4
local FADE_IN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FADE_OUT_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local RestockNotice = {}

local isInitialized = false
local noticeLabel: TextLabel? = nil
local noticeScale: UIScale? = nil
local noticeStroke: UIStroke? = nil
local showToken = 0

local function setTransparency(transparency: number, tweenInfo: TweenInfo?)
	local label, stroke = noticeLabel, noticeStroke
	if not label then
		return
	end
	if tweenInfo then
		TweenService:Create(label, tweenInfo, { TextTransparency = transparency }):Play()
		if stroke then
			TweenService:Create(stroke, tweenInfo, { Transparency = transparency }):Play()
		end
		return
	end
	label.TextTransparency = transparency
	if stroke then
		stroke.Transparency = transparency
	end
end

local function playPop()
	local scale = noticeScale
	if not scale then
		return
	end
	scale.Scale = POP_START_SCALE
	TweenService:Create(scale, FADE_IN_INFO, { Scale = 1 }):Play()
end

function RestockNotice.Show(text: string)
	local label = noticeLabel
	if not label then
		return
	end
	showToken += 1
	local token = showToken
	label.Text = text
	playPop()
	setTransparency(SHOWN_TRANSPARENCY, FADE_IN_INFO)
	task.delay(HOLD_SECONDS, function()
		if token == showToken then
			setTransparency(HIDDEN_TRANSPARENCY, FADE_OUT_INFO)
		end
	end)
end

local function bindHud(hud: Instance)
	local label = hud:WaitForChild(NOTICE_NAME)
	if not label:IsA("TextLabel") then
		warn("[RestockNotice] RestockNotice must be a TextLabel")
		return
	end
	local scale = label:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = label
	noticeLabel, noticeScale = label, scale
	noticeStroke = label:FindFirstChildOfClass("UIStroke")
	setTransparency(HIDDEN_TRANSPARENCY, nil)
end

function RestockNotice.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child: Instance)
		if child.Name == HUD_GUI_NAME then
			bindHud(child)
		end
	end)
	bindHud(playerGui:WaitForChild(HUD_GUI_NAME))
end

return RestockNotice
