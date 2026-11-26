--!strict

local Players = game:GetService("Players")

local HUD_GUI_NAME = "HudGui"
local LABEL_NAME = "Label"
local ICON_NAME = "Icon"

export type ButtonStyle = {
	Text: string?,
	Image: string?,
	Gradient: ColorSequence?,
}

local HudButton = {}

local function connectButton(hud: Instance, buttonName: string, onActivated: () -> ())
	if hud.Name ~= HUD_GUI_NAME then
		return
	end
	local button = hud:FindFirstChild(buttonName, true)
	if not button or not button:IsA("GuiButton") then
		warn("[HudButton] Missing", buttonName)
		return
	end
	button.Activated:Connect(onActivated)
end

local function applyStyle(hud: Instance, buttonName: string, style: ButtonStyle)
	if hud.Name ~= HUD_GUI_NAME then
		return
	end
	local button = hud:FindFirstChild(buttonName, true)
	if button == nil then
		return
	end
	local label = button:FindFirstChild(LABEL_NAME)
	if style.Text and label and label:IsA("TextLabel") then
		label.Text = style.Text
	end
	local icon = button:FindFirstChild(ICON_NAME)
	if style.Image and icon and icon:IsA("ImageLabel") then
		icon.Image = style.Image
	end
	local gradient = button:FindFirstChildOfClass("UIGradient")
	if style.Gradient and gradient then
		gradient.Color = style.Gradient
	end
end

function HudButton.SetStyle(buttonName: string, style: ButtonStyle)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, child in playerGui:GetChildren() do
		applyStyle(child, buttonName, style)
	end
	playerGui.ChildAdded:Connect(function(child: Instance)
		applyStyle(child, buttonName, style)
	end)
end

function HudButton.Bind(buttonName: string, onActivated: () -> ())
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, child in playerGui:GetChildren() do
		connectButton(child, buttonName, onActivated)
	end
	playerGui.ChildAdded:Connect(function(child: Instance)
		connectButton(child, buttonName, onActivated)
	end)
end

return HudButton
