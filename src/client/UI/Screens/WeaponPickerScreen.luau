--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeMessages = require(ReplicatedStorage.Shared.Constants.ForgeMessages)
local ItemBrowser = require(script.Parent.Parent.Components.ItemBrowser)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)

local PICKER_GUI_NAME = "WeaponPickerGui"

type BackpackItem = ItemBrowser.BackpackItem

local WeaponPickerScreen = {}

local isInitialized = false
local browser: ItemBrowser.ItemBrowser? = nil
local mainFrame: Frame? = nil
local closeHandler: (() -> ())? = nil
local actionText = ForgeMessages.ForgeText

local function getActionText(_item: BackpackItem): string?
	return actionText
end

local function onClose()
	local handler = closeHandler
	if handler then
		handler()
	end
end

function WeaponPickerScreen.Render(items: { BackpackItem })
	local itemBrowser = browser
	if itemBrowser then
		itemBrowser.Render(items)
	end
end

function WeaponPickerScreen.SetActionText(text: string)
	actionText = text
end

function WeaponPickerScreen.SetVisible(isVisible: boolean)
	local itemBrowser = browser
	local frame = mainFrame
	if isVisible and frame then
		ScreenRegistry.CloseAllExcept(frame)
	end
	if itemBrowser then
		itemBrowser.SetVisible(isVisible)
	end
end

function WeaponPickerScreen.SetEquipHandler(handler: (BackpackItem) -> ())
	local itemBrowser = browser
	if itemBrowser then
		itemBrowser.SetActionHandler(handler)
	end
end

function WeaponPickerScreen.SetCloseHandler(handler: () -> ())
	closeHandler = handler
end

function WeaponPickerScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local main = playerGui:WaitForChild(PICKER_GUI_NAME):WaitForChild("Main")
	if not main:IsA("Frame") then
		warn("[WeaponPickerScreen] WeaponPickerGui has wrong structure")
		return
	end
	main.Visible = false
	mainFrame = main
	browser = ItemBrowser.Create(main, { GetActionText = getActionText, OnClose = onClose })
	HudSlide.TrackScreen(main)
	ScreenRegistry.Register(main, function()
		main.Visible = false
		onClose()
	end)
end

return WeaponPickerScreen
