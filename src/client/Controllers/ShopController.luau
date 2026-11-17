--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ItemVisuals = require(ReplicatedStorage.Shared.Constants.ItemVisuals)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local ShopMessages = require(ReplicatedStorage.Shared.Constants.ShopMessages)
local UiIcons = require(ReplicatedStorage.Shared.Constants.UiIcons)
local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local ShopScreen = require(script.Parent.Parent.UI.Screens.ShopScreen)
local OddsScreen = require(script.Parent.Parent.UI.Screens.OddsScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)

type ShopEntry = ShopScreen.ShopEntry
type ShopCategory = ShopScreen.ShopCategory
type OddsEntry = OddsScreen.OddsEntry

local REMOTES_FOLDER_NAME = "Remotes"
local BUY_AMOUNT = 1
local TIMER_TICK_SECONDS = 1
local SECONDS_PER_MINUTE = 60
local DEFAULT_RARITY_LABEL = ""
local DEFAULT_CATEGORY: ShopCategory = "Ore"
local DISPLAY_ORDERS: { [ShopCategory]: { string } } = {
	Ore = ShopConfig.OreDisplayOrder,
	Item = ShopConfig.BuffDisplayOrder,
}

local ShopController = {}

local isInitialized = false
local requestBuy: RemoteEvent? = nil
local currentCycle = 0
local restockInterval = ShopConfig.RestockInterval
local currentCategory: ShopCategory = DEFAULT_CATEGORY
local currentStock: { [string]: number } = {}
local currentOdds: { [string]: number } = {}

local function notify(text: string)
	Toast.Show(ShopMessages.NotificationTitle, text)
end

local function buildEntry(itemId: string, stock: number): ShopEntry
	local visual = ItemVisuals[itemId]
	return {
		Id = itemId,
		DisplayName = BackpackMessages.ItemNames[itemId] or itemId,
		Stock = stock,
		Price = ShopConfig.ItemPrices[itemId] or 0,
		Rarity = if visual and visual.RarityLabel then visual.RarityLabel else DEFAULT_RARITY_LABEL,
		Image = if visual then visual.Image else nil,
		Color = if visual then visual.Color else nil,
	}
end

local function buildOddsEntry(itemId: string): OddsEntry
	local visual = ItemVisuals[itemId]
	return {
		DisplayName = BackpackMessages.ItemNames[itemId] or itemId,
		Chance = currentOdds[itemId] or 0,
		Image = if visual then visual.Image else nil,
		Color = if visual then visual.Color else nil,
	}
end

local function renderCategory()
	local shopEntries = {}
	local oddsEntries = {}
	for _, itemId in DISPLAY_ORDERS[currentCategory] do
		table.insert(shopEntries, buildEntry(itemId, currentStock[itemId] or 0))
		table.insert(oddsEntries, buildOddsEntry(itemId))
	end
	ShopScreen.Render(shopEntries)
	OddsScreen.Render(oddsEntries)
	OddsScreen.SetTitle(ShopMessages.Categories[currentCategory].OddsTitle)
	ShopScreen.SetHeaderIcon(UiIcons.ShopCategories[currentCategory])
	OddsScreen.SetIcon(UiIcons.ShopCategories[currentCategory])
end

local function onCategoryChanged(category: ShopCategory)
	currentCategory = category
	renderCategory()
end

local function onShopState(state: any)
	if type(state) ~= "table" or type(state.Stock) ~= "table" then
		return
	end
	if type(state.Cycle) == "number" then
		currentCycle = state.Cycle
	end
	if type(state.RestockInterval) == "number" then
		restockInterval = state.RestockInterval
	end
	if type(state.Odds) == "table" then
		currentOdds = state.Odds
	end
	currentStock = state.Stock
	renderCategory()
end

local function onBuyResult(ok: any, reason: any)
	if ok == true then
		notify(ShopMessages.PurchaseSuccess)
		return
	end
	local message = type(reason) == "string" and ShopMessages.Reasons[reason]
	notify(message or ShopMessages.UnknownError)
end

local function onBuyRequested(itemId: string)
	if requestBuy then
		requestBuy:FireServer(itemId, BUY_AMOUNT)
	end
end

local function updateRestockTimer()
	local nextRestockAt = (currentCycle + 1) * restockInterval
	local secondsLeft = math.floor(nextRestockAt - Workspace:GetServerTimeNow())
	if secondsLeft <= 0 then
		ShopScreen.SetRestockText(ShopMessages.Restocking)
		return
	end
	local minutes = secondsLeft // SECONDS_PER_MINUTE
	local seconds = secondsLeft % SECONDS_PER_MINUTE
	local restockFormat = ShopMessages.Categories[currentCategory].RestockFormat
	ShopScreen.SetRestockText(string.format(restockFormat, minutes, seconds))
end

local function runRestockTimer()
	while true do
		updateRestockTimer()
		task.wait(TIMER_TICK_SECONDS)
	end
end

function ShopController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	local buyRemote = remotes:WaitForChild(RemoteNames.RequestBuy) :: RemoteEvent
	local stateRemote = remotes:WaitForChild(RemoteNames.NotifyShopState) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyBuyResult) :: RemoteEvent
	requestBuy = buyRemote

	ShopScreen.SetBuyHandler(onBuyRequested)
	ShopScreen.SetCategoryHandler(onCategoryChanged)
	stateRemote.OnClientEvent:Connect(onShopState)
	resultRemote.OnClientEvent:Connect(onBuyResult)
	task.spawn(runRestockTimer)
end

return ShopController
