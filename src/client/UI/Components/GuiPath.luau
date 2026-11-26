--!strict

local BUTTON_LABEL_NAME = "Label"

local GuiPath = {}

function GuiPath.Find(parent: Instance, path: { string }): Instance?
	local current: Instance? = parent
	for _, name in path do
		if not current then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

function GuiPath.SetText(parent: Instance, path: { string }, text: string)
	local target = GuiPath.Find(parent, path)
	local innerLabel = target and target:IsA("TextButton") and target:FindFirstChild(BUTTON_LABEL_NAME)
	local label = if innerLabel and innerLabel:IsA("TextLabel") then innerLabel else target
	if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
		label.Text = text
	end
end

function GuiPath.SetVisible(parent: Instance, path: { string }, isVisible: boolean)
	local target = GuiPath.Find(parent, path)
	if target and target:IsA("GuiObject") then
		target.Visible = isVisible
	end
end

function GuiPath.SetImage(parent: Instance, path: { string }, image: string?)
	local imageLabel = GuiPath.Find(parent, path)
	if imageLabel and imageLabel:IsA("ImageLabel") then
		imageLabel.Image = image or ""
	end
end

function GuiPath.SetImageRect(parent: Instance, path: { string }, offset: Vector2?, size: Vector2?)
	local imageLabel = GuiPath.Find(parent, path)
	if imageLabel and imageLabel:IsA("ImageLabel") then
		imageLabel.ImageRectOffset = offset or Vector2.zero
		imageLabel.ImageRectSize = size or Vector2.zero
	end
end

function GuiPath.SetImageColor(parent: Instance, path: { string }, color: Color3?)
	local imageLabel = GuiPath.Find(parent, path)
	if not imageLabel or not imageLabel:IsA("ImageLabel") then
		return
	end
	if color then
		imageLabel.BackgroundColor3 = color
	end
	imageLabel.BackgroundTransparency = if color then 0 else 1
end

function GuiPath.SetBorderColor(target: Instance, color: Color3)
	local stroke = target:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end
end

function GuiPath.ClearChildren(parent: Instance, childName: string)
	for _, child in parent:GetChildren() do
		if child.Name == childName then
			child:Destroy()
		end
	end
end

return GuiPath
