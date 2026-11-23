--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local ForgeRevealMessages = require(ReplicatedStorage.Shared.Constants.ForgeRevealMessages)

local GUI_NAME = "ForgeRevealBack"
local BOTTOM_CENTER = Vector2.new(0.5, 1)

export type BackButton = {
	Gui: ScreenGui,
}

local RevealBackButton = {}

local function createCatcher(gui: ScreenGui): TextButton
	local catcher = Instance.new("TextButton")
	catcher.Name = "ClickAnywhere"
	catcher.Size = UDim2.fromScale(1, 1)
	catcher.BackgroundTransparency = 1
	catcher.AutoButtonColor = false
	catcher.Text = ""
	catcher.Parent = gui
	return catcher
end

local function createButton(gui: ScreenGui): TextButton
	local config = ForgeAnimationConfig.BackButton
	local button = Instance.new("TextButton")
	button.Name = "BackButton"
	button.AnchorPoint = BOTTOM_CENTER
	button.Position = UDim2.new(0.5, 0, 1, -config.BottomMargin)
	button.Size = config.Size
	button.BackgroundColor3 = config.Color
	button.TextColor3 = config.TextColor
	button.FontFace = ForgeAnimationConfig.CutsceneFont
	button.TextScaled = true
	button.Text = ForgeRevealMessages.BackText
	button.ZIndex = 2
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, config.TextPadding)
	padding.PaddingBottom = UDim.new(0, config.TextPadding)
	padding.PaddingLeft = UDim.new(0, config.TextPadding)
	padding.PaddingRight = UDim.new(0, config.TextPadding)
	padding.Parent = button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = config.CornerRadius
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = config.StrokeColor
	stroke.Thickness = config.StrokeThickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = button
	button.Parent = gui
	return button
end

function RevealBackButton.Show(onPressed: () -> ()): BackButton
	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = ForgeAnimationConfig.BackButton.DisplayOrder
	local isPressed = false
	local function press()
		if isPressed then
			return
		end
		isPressed = true
		onPressed()
	end
	createCatcher(gui).Activated:Connect(press)
	createButton(gui).Activated:Connect(press)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return { Gui = gui }
end

function RevealBackButton.Hide(backButton: BackButton)
	backButton.Gui:Destroy()
end

return RevealBackButton
