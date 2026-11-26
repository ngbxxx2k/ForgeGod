--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TutorialConfig = require(ReplicatedStorage.Shared.Config.TutorialConfig)
local TutorialMessages = require(ReplicatedStorage.Shared.Constants.TutorialMessages)
local TutorialPointer = require(script.Parent.Parent.Components.TutorialPointer)

local GUI_NAME = "TutorialGui"

export type PanelView = {
	StepNumber: number,
	StepCount: number,
	Title: string,
	Description: string,
	Icon: string,
	Progress: number,
	IsComplete: boolean,
}

export type PanelSide = "Right" | "Left" | "Bottom"

type Elements = {
	Panel: Frame,
	Badge: Frame,
	BadgeLabel: TextLabel,
	IconFrame: Frame,
	Icon: ImageLabel,
	Title: TextLabel,
	Description: TextLabel,
	Fill: Frame,
}

local TutorialScreen = {}

local isInitialized = false
local elements: Elements? = nil
local lastProgress = -1

local function setFill(fill: Frame, progress: number)
	if progress == lastProgress then
		return
	end
	lastProgress = progress
	local tweenInfo = TweenInfo.new(TutorialConfig.Panel.FillTweenSeconds, Enum.EasingStyle.Quad)
	TweenService:Create(fill, tweenInfo, { Size = UDim2.fromScale(progress, 1) }):Play()
end

function TutorialScreen.Show(view: PanelView)
	local target = elements
	if target == nil then
		return
	end
	local panelConfig = TutorialConfig.Panel
	local accent = if view.IsComplete then panelConfig.CompleteBadgeColor else panelConfig.BadgeColor
	target.Badge.BackgroundColor3 = accent
	target.IconFrame.BackgroundColor3 = if view.IsComplete then panelConfig.CompleteIconColor else panelConfig.IconColor
	target.BadgeLabel.Text = string.format(
		TutorialMessages.BadgeFormat,
		panelConfig.BadgeNumberColor,
		view.StepNumber,
		view.StepCount
	)
	target.Title.Text = view.Title
	target.Description.Text = view.Description
	target.Icon.Image = view.Icon
	setFill(target.Fill, math.clamp(view.Progress, 0, 1))
	target.Panel.Visible = true
end

function TutorialScreen.Hide()
	local target = elements
	if target then
		target.Panel.Visible = false
	end
end

function TutorialScreen.SetSide(side: PanelSide)
	local target = elements
	if target == nil then
		return
	end
	local panelConfig = TutorialConfig.Panel
	if side == "Left" then
		target.Panel.AnchorPoint = panelConfig.LeftAnchor
		target.Panel.Position = panelConfig.LeftPosition
	elseif side == "Bottom" then
		target.Panel.AnchorPoint = panelConfig.BottomAnchor
		target.Panel.Position = panelConfig.BottomPosition
	else
		target.Panel.AnchorPoint = panelConfig.RightAnchor
		target.Panel.Position = panelConfig.RightPosition
	end
end

local function findElements(gui: Instance): Elements?
	local panel = gui:FindFirstChild("Panel")
	local badge = panel and panel:FindFirstChild("Badge")
	local badgeLabel = badge and badge:FindFirstChild("Label")
	local iconFrame = panel and panel:FindFirstChild("IconFrame")
	local icon = iconFrame and iconFrame:FindFirstChild("Icon")
	local title = panel and panel:FindFirstChild("Title")
	local description = panel and panel:FindFirstChild("Description")
	local track = panel and panel:FindFirstChild("ProgressTrack")
	local fill = track and track:FindFirstChild("Fill")
	if not (panel and panel:IsA("Frame") and badge and badge:IsA("Frame")) then
		return nil
	end
	if not (badgeLabel and badgeLabel:IsA("TextLabel") and iconFrame and iconFrame:IsA("Frame")) then
		return nil
	end
	if not (icon and icon:IsA("ImageLabel") and title and title:IsA("TextLabel")) then
		return nil
	end
	if not (description and description:IsA("TextLabel") and fill and fill:IsA("Frame")) then
		return nil
	end
	return {
		Panel = panel,
		Badge = badge,
		BadgeLabel = badgeLabel,
		IconFrame = iconFrame,
		Icon = icon,
		Title = title,
		Description = description,
		Fill = fill,
	}
end

function TutorialScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(GUI_NAME)
	local found = findElements(gui)
	if found == nil then
		warn("[TutorialScreen] TutorialGui has wrong structure")
		return
	end
	elements = found
	found.Panel.Visible = false
	local pointer = gui:FindFirstChild("Pointer")
	if pointer and pointer:IsA("ImageLabel") then
		TutorialPointer.Bind(pointer)
	else
		warn("[TutorialScreen] Missing Pointer image")
	end
	TutorialScreen.SetSide("Right")
end

return TutorialScreen
