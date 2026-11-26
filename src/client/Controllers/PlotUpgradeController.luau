--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LoadoutConfig = require(ReplicatedStorage.Shared.Config.LoadoutConfig)
local PlotAttributes = require(ReplicatedStorage.Shared.Constants.PlotAttributes)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local PlotLevel = require(ReplicatedStorage.Shared.Utils.PlotLevel)
local PlotUpgradeConfig = require(ReplicatedStorage.Shared.Config.PlotUpgradeConfig)
local PlotUpgradeMessages = require(ReplicatedStorage.Shared.Constants.PlotUpgradeMessages)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local PlayerStateController = require(script.Parent.PlayerStateController)
local ConfirmScreen = require(script.Parent.Parent.UI.Screens.ConfirmScreen)
local PlotUpgradeSign = require(script.Parent.Parent.UI.Components.PlotUpgradeSign)
local Toast = require(script.Parent.Parent.UI.Components.Toast)

local REMOTES_FOLDER_NAME = "Remotes"

local PlotUpgradeController = {}

local isInitialized = false
local localPlayer = Players.LocalPlayer
local requestUpgrade: RemoteEvent? = nil
local currentSign: PlotUpgradeSign.Sign? = nil
local currentPlot: Model? = nil
local robuxPrices: { [number]: number } = {}
local pendingPrices: { [number]: boolean } = {}

local function getSlots(): number
	local state = PlayerStateController.GetState()
	local slots = if state then state.LoadoutCapacity else nil
	return slots or LoadoutConfig.DefaultSlots
end

local function getRobuxText(step: PlotUpgradeConfig.UpgradeStep): string
	local price = robuxPrices[step.ProductId] or step.RobuxPrice
	return string.format(PlotUpgradeMessages.RobuxPriceFormat, NumberFormat.WithCommas(price))
end

local function render()
	local sign = currentSign
	if sign == nil then
		return
	end
	local slots = getSlots()
	local step = PlotLevel.GetNextStep(slots)
	PlotUpgradeSign.Render(sign, {
		Level = PlotLevel.FromSlots(slots),
		IsMax = step == nil,
		CoinText = if step
			then string.format(PlotUpgradeMessages.CoinPriceFormat, NumberFormat.Abbreviate(step.CoinPrice))
			else "",
		RobuxText = if step then getRobuxText(step) else "",
	})
end

local function fetchRobuxPrice(productId: number)
	if productId <= 0 or robuxPrices[productId] or pendingPrices[productId] then
		return
	end
	pendingPrices[productId] = true
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
	end)
	pendingPrices[productId] = nil
	if not ok or type(info) ~= "table" or type(info.PriceInRobux) ~= "number" then
		warn("[PlotUpgradeController] Could not load product price:", productId)
		return
	end
	robuxPrices[productId] = info.PriceInRobux
	render()
end

local function fetchAllPrices()
	for _, step in PlotUpgradeConfig.Steps do
		task.spawn(fetchRobuxPrice, step.ProductId)
	end
end

local function requestCoins()
	local remote = requestUpgrade
	local slots = getSlots()
	local step = PlotLevel.GetNextStep(slots)
	if remote == nil or step == nil then
		return
	end
	local price = NumberFormat.Abbreviate(step.CoinPrice)
	ConfirmScreen.Show({
		Title = PlotUpgradeMessages.ConfirmTitle,
		Message = string.format(PlotUpgradeMessages.ConfirmFormat, price, slots + 1),
		ConfirmText = PlotUpgradeMessages.ConfirmButton,
		OnConfirm = function()
			remote:FireServer(PlotUpgradeConfig.Currencies.Coins)
		end,
	})
end

local function requestRobux()
	if requestUpgrade then
		requestUpgrade:FireServer(PlotUpgradeConfig.Currencies.Robux)
	end
end

local function clearSign()
	if currentSign then
		PlotUpgradeSign.Destroy(currentSign)
	end
	currentSign = nil
	currentPlot = nil
end

local function buildSign(plot: Model)
	clearSign()
	local sign = PlotUpgradeSign.Build(plot:GetPivot() * PlotConfig.UpgradeSignOffset)
	sign.CoinButton.Activated:Connect(requestCoins)
	sign.RobuxButton.Activated:Connect(requestRobux)
	PlotUpgradeSign.Mount(sign, Workspace)
	currentSign = sign
	currentPlot = plot
	render()
end

local function isOwnPlot(plot: Model): boolean
	return plot:GetAttribute(PlotAttributes.OwnerUserId) == localPlayer.UserId
end

local function refreshPlot(plot: Model)
	if isOwnPlot(plot) then
		if currentPlot ~= plot then
			buildSign(plot)
		end
	elseif currentPlot == plot then
		clearSign()
	end
end

local function watchPlot(child: Instance)
	if not child:IsA("Model") then
		return
	end
	local plot = child
	plot:GetAttributeChangedSignal(PlotAttributes.OwnerUserId):Connect(function()
		refreshPlot(plot)
	end)
	refreshPlot(plot)
end

local function onResult(ok: any, reason: any)
	if ok == true then
		Toast.Success(PlotUpgradeMessages.SuccessText)
		return
	end
	local text = if type(reason) == "string" then PlotUpgradeMessages.Reasons[reason] else nil
	Toast.Error(text or PlotUpgradeMessages.UnknownError)
end

function PlotUpgradeController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	PlayerStateController.OnChanged(function()
		render()
	end)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
		requestUpgrade = remotes:WaitForChild(RemoteNames.RequestPlotUpgrade) :: RemoteEvent
		local resultRemote = remotes:WaitForChild(RemoteNames.NotifyPlotUpgradeResult) :: RemoteEvent
		resultRemote.OnClientEvent:Connect(onResult)
	end)
	task.spawn(function()
		local folder = Workspace:WaitForChild(PlotConfig.PlotsFolderName)
		folder.ChildAdded:Connect(watchPlot)
		for _, child in folder:GetChildren() do
			watchPlot(child)
		end
	end)
	task.spawn(fetchAllPrices)
end

return PlotUpgradeController
