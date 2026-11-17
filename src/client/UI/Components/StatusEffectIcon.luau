--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatusEffectConfig = require(ReplicatedStorage.Shared.Config.StatusEffectConfig)
local StatusEffectIcons = require(ReplicatedStorage.Shared.Constants.StatusEffectIcons)
local ItemVisuals = require(ReplicatedStorage.Shared.Constants.ItemVisuals)

local ICON_NAME = "Icon"
local LABEL_NAME = "Label"
local TIMER_NAME = "Timer"
local COUNT_NAME = "Count"
local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600

local StatusEffectIcon = {}

local function applyImage(root: GuiObject, effectId: string)
	local icon = root:FindFirstChild(ICON_NAME)
	if not icon or not icon:IsA("ImageLabel") then
		warn("[StatusEffectIcon] Missing", ICON_NAME)
		return
	end
	local visual = ItemVisuals[effectId]
	local image = if visual and visual.Image then visual.Image else StatusEffectIcons.Images[effectId]
	local label = icon:FindFirstChild(LABEL_NAME)
	if image and image ~= "" then
		icon.Image = image
		icon.BackgroundTransparency = 1
		if label and label:IsA("TextLabel") then
			label.Visible = false
		end
	elseif label and label:IsA("TextLabel") then
		label.Text = string.sub(effectId, 1, StatusEffectConfig.PlaceholderLabelLength)
	end
end

function StatusEffectIcon.FormatTime(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	local hours = total // SECONDS_PER_HOUR
	local minutes = (total % SECONDS_PER_HOUR) // SECONDS_PER_MINUTE
	local secs = total % SECONDS_PER_MINUTE
	if hours > 0 then
		return string.format(StatusEffectIcons.TimerHoursFormat, hours, minutes, secs)
	end
	return string.format(StatusEffectIcons.TimerFormat, minutes, secs)
end

local function getCountLabel(icon: ImageLabel): TextLabel
	local existing = icon:FindFirstChild(COUNT_NAME)
	if existing and existing:IsA("TextLabel") then
		return existing
	end
	local label = Instance.new("TextLabel")
	label.Name = COUNT_NAME
	label.AnchorPoint = Vector2.new(1, 1)
	label.Position = UDim2.fromScale(1, 1)
	local scale = StatusEffectConfig.CountLabelScale
	label.Size = UDim2.fromScale(scale, scale)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Font = StatusEffectConfig.CountFont
	label.TextColor3 = StatusEffectConfig.CountTextColor
	label.ZIndex = icon.ZIndex + 1
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = StatusEffectConfig.CountStrokeThickness
	stroke.Parent = label
	label.Parent = icon
	return label
end

function StatusEffectIcon.SetCount(root: GuiObject, count: number?)
	local timer = root:FindFirstChild(TIMER_NAME)
	if timer and timer:IsA("GuiObject") then
		timer.Visible = count == nil
	end
	local icon = root:FindFirstChild(ICON_NAME)
	if not icon or not icon:IsA("ImageLabel") then
		return
	end
	if count == nil then
		local existing = icon:FindFirstChild(COUNT_NAME)
		if existing then
			existing:Destroy()
		end
		return
	end
	getCountLabel(icon).Text = string.format(StatusEffectIcons.CountFormat, count)
end

function StatusEffectIcon.Create(template: GuiObject, effectId: string): (GuiObject, TextLabel?)
	local root = template:Clone()
	root.Name = effectId
	root.Visible = true
	applyImage(root, effectId)
	local timer = root:FindFirstChild(TIMER_NAME)
	if not timer or not timer:IsA("TextLabel") then
		warn("[StatusEffectIcon] Missing", TIMER_NAME)
		return root, nil
	end
	return root, timer
end

return StatusEffectIcon
