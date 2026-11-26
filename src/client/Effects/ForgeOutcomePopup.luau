--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)

local BILLBOARD_NAME = "ForgeOutcomePopup"
local CENTER_X = 0.5
local CENTER_Y = 0.5
local FULL_TURN = math.pi * 2

type Element = {
	Object: GuiObject,
	BasePosition: UDim2,
	Scale: UIScale,
}

type Popup = {
	Billboard: BillboardGui,
	Label: TextLabel,
	Stroke: UIStroke,
	Icon: ImageLabel?,
	Elements: { Element },
	StartedAt: number,
	Connection: RBXScriptConnection?,
}

local ForgeOutcomePopup = {}

local current: Popup? = nil

local function getIconPixels(icon: string?): number
	return if icon then ForgeStrikeConfig.OutcomePopup.IconPixels else 0
end

local function createBillboard(adornee: Attachment, icon: string?): BillboardGui
	local config = ForgeStrikeConfig.OutcomePopup
	local billboard = Instance.new("BillboardGui")
	billboard.Name = BILLBOARD_NAME
	local height = config.HeightPixels + 2 * getIconPixels(icon)
	billboard.Size = UDim2.fromOffset(config.WidthPixels, height)
	billboard.StudsOffsetWorldSpace = config.StudsOffset
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.ClipsDescendants = false
	billboard.Archivable = false
	billboard.Adornee = adornee
	return billboard
end

local function addScale(object: GuiObject): UIScale
	local scale = Instance.new("UIScale")
	scale.Scale = ForgeStrikeConfig.OutcomePopup.StartScale
	scale.Parent = object
	return scale
end

local function createElement(object: GuiObject): Element
	return { Object = object, BasePosition = object.Position, Scale = addScale(object) }
end

local function createLabel(
	billboard: BillboardGui,
	text: string,
	color: Color3
): (TextLabel, UIStroke, Element)
	local config = ForgeStrikeConfig.OutcomePopup
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(CENTER_X, CENTER_Y)
	label.Position = UDim2.fromScale(CENTER_X, CENTER_Y)
	label.Size = UDim2.new(1, 0, 0, config.HeightPixels)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.FontFace = config.Font
	label.Text = text
	label.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Color = config.StrokeColor
	stroke.Thickness = config.StrokeThickness
	stroke.Parent = label
	local element = createElement(label)
	label.Parent = billboard
	return label, stroke, element
end

local function createIcon(billboard: BillboardGui, image: string): (ImageLabel, Element)
	local config = ForgeStrikeConfig.OutcomePopup
	local size = config.IconPixels
	local icon = Instance.new("ImageLabel")
	icon.AnchorPoint = Vector2.new(CENTER_X, 1)
	icon.Position = UDim2.new(CENTER_X, 0, CENTER_Y, -config.HeightPixels / 2)
	icon.Size = UDim2.fromOffset(size, size)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Image = image
	local element = createElement(icon)
	icon.Parent = billboard
	return icon, element
end

local function getTotalTime(): number
	local config = ForgeStrikeConfig.OutcomePopup
	return config.PopTime + config.SettleTime + config.HoldTime + config.FadeTime
end

local function getScale(elapsed: number): number
	local config = ForgeStrikeConfig.OutcomePopup
	if elapsed < config.PopTime then
		local alpha = elapsed / config.PopTime
		local eased = 1 - (1 - alpha) ^ 2
		return config.StartScale + (config.PeakScale - config.StartScale) * eased
	end
	local settle = math.clamp((elapsed - config.PopTime) / config.SettleTime, 0, 1)
	return config.PeakScale + (1 - config.PeakScale) * settle
end

local function destroy(popup: Popup)
	if popup.Connection then
		popup.Connection:Disconnect()
		popup.Connection = nil
	end
	popup.Billboard:Destroy()
	if current == popup then
		current = nil
	end
end

local function applyMotion(element: Element, shake: number, rise: number, scale: number)
	local config = ForgeStrikeConfig.OutcomePopup
	local base = element.BasePosition
	element.Object.Rotation = config.ShakeAngle * shake
	element.Object.Position = UDim2.new(
		base.X.Scale,
		base.X.Offset + config.ShakeOffset * shake,
		base.Y.Scale,
		base.Y.Offset - rise
	)
	element.Scale.Scale = scale
end

local function step(popup: Popup)
	local config = ForgeStrikeConfig.OutcomePopup
	local elapsed = os.clock() - popup.StartedAt
	local total = getTotalTime()
	if elapsed >= total or popup.Billboard.Parent == nil then
		destroy(popup)
		return
	end
	local decay = math.exp(-config.ShakeDecay * elapsed)
	local shake = decay * math.sin(FULL_TURN * config.ShakeFrequency * elapsed)
	local fade = math.clamp((elapsed - (total - config.FadeTime)) / config.FadeTime, 0, 1)
	local scale = getScale(elapsed)
	for _, element in popup.Elements do
		applyMotion(element, shake, config.FadeRise * fade, scale)
	end
	popup.Label.TextTransparency = fade
	popup.Stroke.Transparency = fade
	local icon = popup.Icon
	if icon then
		icon.ImageTransparency = fade
	end
end

function ForgeOutcomePopup.Show(adornee: Attachment?, text: string, color: Color3, icon: string?)
	ForgeOutcomePopup.Stop()
	if adornee == nil or adornee.Parent == nil then
		return
	end
	local billboard = createBillboard(adornee, icon)
	local label, stroke, labelElement = createLabel(billboard, text, color)
	local popup: Popup = {
		Billboard = billboard,
		Label = label,
		Stroke = stroke,
		Icon = nil,
		Elements = { labelElement },
		StartedAt = os.clock(),
		Connection = nil,
	}
	if icon then
		local iconLabel, iconElement = createIcon(billboard, icon)
		popup.Icon = iconLabel
		table.insert(popup.Elements, iconElement)
	end
	billboard.Parent = adornee
	popup.Connection = RunService.RenderStepped:Connect(function()
		step(popup)
	end)
	current = popup
	step(popup)
end

function ForgeOutcomePopup.Stop()
	local popup = current
	if popup then
		destroy(popup)
	end
end

return ForgeOutcomePopup
