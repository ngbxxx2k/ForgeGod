--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeUpgradeColors = require(ReplicatedStorage.Shared.Constants.ForgeUpgradeColors)
local GuiPath = require(script.Parent.Parent.Components.GuiPath)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ModelViewport = require(script.Parent.Parent.Components.ModelViewport)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local RarityGradient = require(script.Parent.Parent.Components.RarityGradient)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)

local GUI_NAME = "ForgeUpgradeGui"
local TEMPLATE_NAME = "CardTemplate"
local CARD_NAME = "UpgradeCard"
local TAB_ID_ATTRIBUTE = "TabId"
local COIN_BUTTON_PATH = { "PriceRow", "CoinButton" }
local ROBUX_BUTTON_PATH = { "PriceRow", "RobuxButton" }

export type Currency = "Coins" | "Robux"

export type UpgradeCard = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	StatText: string,
	CoinText: string,
	RobuxText: string?,
	PreviewModel: Model?,
}

local ForgeUpgradeScreen = {}

local isInitialized = false
local mainFrame: Frame? = nil
local cardList: ScrollingFrame? = nil
local cardTemplate: Frame? = nil
local tabButtons: { [string]: GuiButton } = {}
local activeTabGradients: { [GuiButton]: ColorSequence } = {}
local tabHandler: ((tabId: string) -> ())? = nil
local buyHandler: ((cardId: string, currency: Currency) -> ())? = nil

local function styleTab(button: GuiButton, isSelected: boolean)
	local gradient = button:FindFirstChildOfClass("UIGradient")
	local activeGradient = activeTabGradients[button]
	if gradient and activeGradient then
		gradient.Color = if isSelected then activeGradient else ForgeUpgradeColors.InactiveTabGradient
	end
end

local function bindBuyButton(card: Frame, path: { string }, cardId: string, currency: Currency)
	local button = GuiPath.Find(card, path)
	if not button or not button:IsA("GuiButton") then
		warn("[ForgeUpgradeScreen] Missing buy button:", table.concat(path, "."))
		return
	end
	button.Activated:Connect(function()
		if buyHandler then
			buyHandler(cardId, currency)
		end
	end)
end

local function fillCard(card: Frame, entry: UpgradeCard)
	RarityGradient.Apply(card, entry.Rarity)
	GuiPath.SetText(card, { "NameLabel" }, entry.DisplayName)
	GuiPath.SetText(card, { "TierLabel" }, entry.Rarity)
	GuiPath.SetText(card, { "StatPill", "StatLabel" }, entry.StatText)
	GuiPath.SetText(card, COIN_BUTTON_PATH, entry.CoinText)
	GuiPath.SetText(card, ROBUX_BUTTON_PATH, entry.RobuxText or "")
	GuiPath.SetVisible(card, ROBUX_BUTTON_PATH, entry.RobuxText ~= nil)
	local preview = card:FindFirstChild("Preview")
	if preview and preview:IsA("ViewportFrame") then
		ModelViewport.Show(preview, entry.PreviewModel)
	end
end

local function createCard(template: Frame, entry: UpgradeCard, order: number): Frame
	local card = template:Clone()
	card.Name = CARD_NAME
	card.LayoutOrder = order
	card.Visible = true
	fillCard(card, entry)
	bindBuyButton(card, COIN_BUTTON_PATH, entry.Id, "Coins")
	bindBuyButton(card, ROBUX_BUTTON_PATH, entry.Id, "Robux")
	return card
end

local function bindTabs(tabBar: Instance)
	for _, child in tabBar:GetChildren() do
		local tabId = child:GetAttribute(TAB_ID_ATTRIBUTE)
		if not child:IsA("GuiButton") or type(tabId) ~= "string" then
			continue
		end
		local gradient = child:FindFirstChildOfClass("UIGradient")
		if gradient then
			activeTabGradients[child] = gradient.Color
		end
		tabButtons[tabId] = child
		child.Activated:Connect(function()
			if tabHandler then
				tabHandler(tabId)
			end
		end)
	end
end

local function bindCloseButton(main: Instance)
	local closeButton = main:WaitForChild("Header"):WaitForChild("CloseButton")
	if closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(ForgeUpgradeScreen.Close)
	end
end

function ForgeUpgradeScreen.Render(entries: { UpgradeCard })
	local list = cardList
	local template = cardTemplate
	if not list or not template then
		warn("[ForgeUpgradeScreen] Render called before Init")
		return
	end
	GuiPath.ClearChildren(list, CARD_NAME)
	for index, entry in entries do
		createCard(template, entry, index).Parent = list
	end
	list.CanvasPosition = Vector2.zero
end

function ForgeUpgradeScreen.SelectTab(tabId: string)
	for id, button in tabButtons do
		styleTab(button, id == tabId)
	end
end

function ForgeUpgradeScreen.SetTabHandler(handler: (tabId: string) -> ())
	tabHandler = handler
end

function ForgeUpgradeScreen.SetBuyHandler(handler: (cardId: string, currency: Currency) -> ())
	buyHandler = handler
end

function ForgeUpgradeScreen.IsOpen(): boolean
	local frame = mainFrame
	return frame ~= nil and frame.Visible
end

function ForgeUpgradeScreen.Open()
	local frame = mainFrame
	if not frame then
		return
	end
	ScreenRegistry.CloseAllExcept(frame)
	OpenAnimation.Open(frame)
end

function ForgeUpgradeScreen.Close()
	local frame = mainFrame
	if frame and frame.Visible then
		OpenAnimation.Close(frame)
	end
end

function ForgeUpgradeScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local main = playerGui:WaitForChild(GUI_NAME):WaitForChild("Main")
	local list = main:WaitForChild("CardList")
	local template = list:WaitForChild(TEMPLATE_NAME)
	if not main:IsA("Frame") or not list:IsA("ScrollingFrame") or not template:IsA("Frame") then
		warn("[ForgeUpgradeScreen] ForgeUpgradeGui has wrong structure")
		return
	end
	template.Visible = false
	main.Visible = false
	mainFrame = main
	cardList = list
	cardTemplate = template
	UiSound.WatchOpen(main)
	OpenAnimation.Watch(main)
	HudSlide.TrackScreen(main)
	ScreenRegistry.Register(main)
	bindTabs(main:WaitForChild("TabBar"))
	bindCloseButton(main)
end

return ForgeUpgradeScreen
