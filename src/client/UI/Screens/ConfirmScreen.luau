--!strict

local Players = game:GetService("Players")

local GuiPath = require(script.Parent.Parent.Components.GuiPath)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)

local CONFIRM_GUI_NAME = "ConfirmGui"
local DIALOG_NAME = "Dialog"
local NO_HOVER_SOUND_ATTRIBUTE = "NoHoverSound"
local HOVER_ATTRIBUTE = "HasHoverEffect"
local DIALOG_BUTTON_PATHS = {
	{ "Dialog", "ButtonRow", "CancelButton" },
	{ "Dialog", "ButtonRow", "ConfirmButton" },
}

export type ConfirmRequest = {
	Title: string,
	Message: string,
	ConfirmText: string,
	OnConfirm: () -> (),
}

local ConfirmScreen = {}

local isInitialized = false
local overlay: GuiObject? = nil
local pendingConfirm: (() -> ())? = nil

local function hide()
	pendingConfirm = nil
	if overlay then
		OpenAnimation.Close(overlay)
	end
end

local function confirm()
	local onConfirm = pendingConfirm
	hide()
	if onConfirm then
		onConfirm()
	end
end

local function bindButton(parent: Instance, path: { string }, onActivated: () -> ())
	local button = GuiPath.Find(parent, path)
	if button and button:IsA("GuiButton") then
		button.Activated:Connect(onActivated)
	else
		warn("[ConfirmScreen] Missing", table.concat(path, "."))
	end
end

local function enableHoverEffects(root: Instance)
	for _, path in DIALOG_BUTTON_PATHS do
		local button = GuiPath.Find(root, path)
		if button and button:IsA("GuiButton") then
			button:SetAttribute(HOVER_ATTRIBUTE, true)
		end
	end
end

function ConfirmScreen.Show(request: ConfirmRequest)
	local root = overlay
	if not root then
		warn("[ConfirmScreen] Show called before Init")
		return
	end
	GuiPath.SetText(root, { "Dialog", "TitleLabel" }, request.Title)
	GuiPath.SetText(root, { "Dialog", "MessageLabel" }, request.Message)
	GuiPath.SetText(root, { "Dialog", "ButtonRow", "ConfirmButton" }, request.ConfirmText)
	pendingConfirm = request.OnConfirm
	OpenAnimation.Open(root)
end

function ConfirmScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = playerGui:WaitForChild(CONFIRM_GUI_NAME):WaitForChild("Overlay")
	if not root:IsA("GuiButton") then
		warn("[ConfirmScreen] ConfirmGui has wrong structure")
		return
	end
	root.Visible = false
	overlay = root
	root:SetAttribute(NO_HOVER_SOUND_ATTRIBUTE, true)
	local dialog = root:FindFirstChild(DIALOG_NAME)
	OpenAnimation.Watch(root, if dialog and dialog:IsA("GuiObject") then dialog else nil)
	UiSound.WatchOpen(root)
	enableHoverEffects(root)
	root.Activated:Connect(hide)
	bindButton(root, { "Dialog", "ButtonRow", "CancelButton" }, hide)
	bindButton(root, { "Dialog", "ButtonRow", "ConfirmButton" }, confirm)
end

return ConfirmScreen
