--!strict

export type LabelStyle = {
	Name: string,
	Text: string,
	Size: Vector2,
	MaxDistance: number,
	Font: Enum.Font,
	TextColor: Color3,
	StrokeColor: Color3,
	StrokeThickness: number,
}

local ZoneLabel = {}

local function createText(style: LabelStyle): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = style.Font
	label.Text = style.Text
	label.TextScaled = true
	label.TextColor3 = style.TextColor
	local stroke = Instance.new("UIStroke")
	stroke.Color = style.StrokeColor
	stroke.Thickness = style.StrokeThickness
	stroke.Parent = label
	return label
end

function ZoneLabel.Build(host: BasePart, worldPosition: Vector3, style: LabelStyle): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = style.Name
	local billboard = Instance.new("BillboardGui")
	billboard.Name = style.Name
	billboard.Size = UDim2.fromScale(style.Size.X, style.Size.Y)
	billboard.MaxDistance = style.MaxDistance
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	createText(style).Parent = billboard
	billboard.Adornee = attachment
	billboard.Parent = attachment
	attachment.Parent = host
	attachment.WorldPosition = worldPosition
	return attachment
end

return ZoneLabel
