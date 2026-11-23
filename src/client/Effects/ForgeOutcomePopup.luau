--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)

local BILLBOARD_NAME = "ForgeOutcomePopup"
local CENTER = Vector2.new(0.5, 0.5)
local FULL_TURN = math.pi * 2

type Popup = {
	Billboard: BillboardGui,
	Label: TextLabel,
	Stroke: UIStroke,
	Scale: UIScale,
	StartedAt: number,
	Connection: RBXScriptConnection?,
}

local ForgeOutcomePopup = {}

local current: Popup? = nil

local function createBillboard(adornee: Attachment): BillboardGui
	local config = ForgeStrikeConfig.OutcomePopup
	local billboard = Instance.new("BillboardGui")
	billboard.Name = BILLBOARD_NAME
	billboard.Size = UDim2.fromOffset(config.WidthPixels, config.HeightPixels)
	billboard.StudsOffsetWorldSpace = config.StudsOffset
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.ClipsDescendants = false
	billboard.Archivable = false
	billboard.Adornee = adornee
	return billboard
end

local function createLabel(billboard: BillboardGui, text: string, color: Color3): (TextLabel, UIStroke, UIScale)
	local config = ForgeStrikeConfig.OutcomePopup
	local label = Instance.new("TextLabel")
	label.AnchorPoint = CENTER
	label.Position = UDim2.fromScale(CENTER.X, CENTER.Y)
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.FontFace = config.Font
	label.Text = text
	label.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Color = config.StrokeColor
	stroke.Thickness = config.StrokeThickness
	stroke.Parent = label
	local scale = Instance.new("UIScale")
	scale.Scale = config.StartScale
	scale.Parent = label
	label.Parent = billboard
	return label, stroke, scale
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
	popup.Label.Rotation = config.ShakeAngle * shake
	popup.Label.Position = UDim2.new(CENTER.X, config.ShakeOffset * shake, CENTER.Y, -config.FadeRise * fade)
	popup.Label.TextTransparency = fade
	popup.Stroke.Transparency = fade
	popup.Scale.Scale = getScale(elapsed)
end

function ForgeOutcomePopup.Show(adornee: Attachment?, text: string, color: Color3)
	ForgeOutcomePopup.Stop()
	if adornee == nil or adornee.Parent == nil then
		return
	end
	local billboard = createBillboard(adornee)
	local label, stroke, scale = createLabel(billboard, text, color)
	local popup: Popup = {
		Billboard = billboard,
		Label = label,
		Stroke = stroke,
		Scale = scale,
		StartedAt = os.clock(),
		Connection = nil,
	}
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
