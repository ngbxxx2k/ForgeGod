--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local ItemVisuals = require(ReplicatedStorage.Shared.Constants.ItemVisuals)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local SpinConfig = require(ReplicatedStorage.Shared.Config.SpinConfig)
local SpinMessages = require(ReplicatedStorage.Shared.Constants.SpinMessages)
local UiIcons = require(ReplicatedStorage.Shared.Constants.UiIcons)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local PlayerStateController = require(script.Parent.PlayerStateController)
local SpinWheelScreen = require(script.Parent.Parent.UI.Screens.SpinWheelScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)

type WheelReward = SpinWheelScreen.WheelReward

local REMOTES_FOLDER_NAME = "Remotes"
local TIMER_TICK_SECONDS = 1
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_MINUTE = 60

local SpinWheelController = {}

local isInitialized = false
local requestSpin: RemoteEvent? = nil
local requestBuySpin: RemoteEvent? = nil
local isWaitingForResult = false

local function getRewardImage(reward: SpinConfig.SpinReward): string?
	if reward.Kind == SpinConfig.RewardKinds.Coins then
		return UiIcons.SpinWheel.Coins
	end
	if reward.Kind == SpinConfig.RewardKinds.Spin then
		return UiIcons.SpinWheel.ExtraSpin
	end
	local visual = reward.ItemId and ItemVisuals[reward.ItemId]
	return if visual then visual.Image else nil
end

local function getRewardText(reward: SpinConfig.SpinReward): string
	if reward.Kind == SpinConfig.RewardKinds.Coins then
		return string.format(SpinMessages.CoinsFormat, NumberFormat.Compact(reward.Amount))
	end
	if reward.Kind == SpinConfig.RewardKinds.Spin then
		return SpinMessages.ExtraSpinLabel
	end
	local itemId = reward.ItemId or reward.Id
	local name = BackpackMessages.ItemNames[itemId] or itemId
	if reward.Amount > 1 then
		return string.format(SpinMessages.AmountFormat, name, reward.Amount)
	end
	return name
end

local function buildRewards(): { WheelReward }
	local rewards: { WheelReward } = {}
	for _, reward in SpinConfig.Rewards do
		table.insert(rewards, {
			Id = reward.Id,
			Color = reward.Color,
			Image = getRewardImage(reward),
			Text = getRewardText(reward),
		})
	end
	return rewards
end

local function formatCountdown(secondsLeft: number): string
	local hours = secondsLeft // SECONDS_PER_HOUR
	local minutes = (secondsLeft % SECONDS_PER_HOUR) // SECONDS_PER_MINUTE
	local seconds = secondsLeft % SECONDS_PER_MINUTE
	return string.format(SpinMessages.FreeCountdownFormat, hours, minutes, seconds)
end

local function getSpinState(): (number, number?)
	local state = PlayerStateController.GetState()
	local spin = state and state.Spin
	if spin == nil then
		return 0, nil
	end
	return spin.Tokens, spin.NextFreeAt
end

local function getFreeText(isFreeReady: boolean, secondsLeft: number?): string
	if isFreeReady then
		return SpinMessages.FreeReady
	end
	return if secondsLeft then formatCountdown(secondsLeft) else ""
end

local function refreshStatus()
	local tokens, nextFreeAt = getSpinState()
	local secondsLeft = if nextFreeAt then math.ceil(nextFreeAt - Workspace:GetServerTimeNow()) else nil
	local isFreeReady = secondsLeft ~= nil and secondsLeft <= 0
	local isBusy = isWaitingForResult or SpinWheelScreen.IsSpinning()
	local availableSpins = tokens + (if isFreeReady then 1 else 0)
	local spinText = if isBusy
		then SpinMessages.SpinningButton
		elseif isFreeReady then SpinMessages.FreeSpinButton
		else SpinMessages.SpinButton
	SpinWheelScreen.SetStatus({
		TokensText = string.format(SpinMessages.TokensFormat, availableSpins),
		FreeText = getFreeText(isFreeReady, secondsLeft),
		SpinText = spinText,
		CanSpin = not isBusy and (isFreeReady or tokens > 0),
	})
end

local function showReason(reason: any, fallback: string)
	local message = type(reason) == "string" and SpinMessages.Reasons[reason]
	Toast.Error(message or fallback)
end

local function onSpinFinished(rewardId: string)
	local reward = SpinConfig.RewardById[rewardId]
	if reward then
		Toast.Success(string.format(SpinMessages.RewardWonFormat, getRewardText(reward)))
	end
	refreshStatus()
end

local function onSpinResult(ok: any, reason: any, rewardId: any)
	isWaitingForResult = false
	if ok ~= true or type(rewardId) ~= "string" then
		showReason(reason, SpinMessages.UnknownError)
		refreshStatus()
		return
	end
	SpinWheelScreen.SpinTo(rewardId, function()
		onSpinFinished(rewardId)
	end)
	refreshStatus()
end

local function onBuyResult(ok: any, reason: any)
	if ok == true then
		Toast.Success(SpinMessages.PurchaseSuccess)
		return
	end
	showReason(reason, SpinMessages.UnknownError)
end

local function onSpinRequested()
	local remote = requestSpin
	if remote == nil or isWaitingForResult or SpinWheelScreen.IsSpinning() then
		return
	end
	local tokens, nextFreeAt = getSpinState()
	local isFreeReady = nextFreeAt ~= nil and Workspace:GetServerTimeNow() >= nextFreeAt
	if tokens <= 0 and not isFreeReady then
		showReason("NoSpins", SpinMessages.UnknownError)
		return
	end
	isWaitingForResult = true
	refreshStatus()
	remote:FireServer()
end

local function onBuyRequested()
	local remote = requestBuySpin
	if remote then
		remote:FireServer()
	end
end

local function runTimer()
	while isInitialized do
		if SpinWheelScreen.IsVisible() then
			refreshStatus()
		end
		task.wait(TIMER_TICK_SECONDS)
	end
end

function SpinWheelController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestSpin = remotes:WaitForChild(RemoteNames.RequestSpin) :: RemoteEvent
	requestBuySpin = remotes:WaitForChild(RemoteNames.RequestBuySpin) :: RemoteEvent
	local spinResult = remotes:WaitForChild(RemoteNames.NotifySpinResult) :: RemoteEvent
	local buyResult = remotes:WaitForChild(RemoteNames.NotifyBuySpinResult) :: RemoteEvent

	SpinWheelScreen.SetRewards(buildRewards())
	SpinWheelScreen.SetBuyPrice(NumberFormat.WithCommas(SpinConfig.SpinProduct.RobuxPrice))
	SpinWheelScreen.SetSpinHandler(onSpinRequested)
	SpinWheelScreen.SetBuyHandler(onBuyRequested)
	spinResult.OnClientEvent:Connect(onSpinResult)
	buyResult.OnClientEvent:Connect(onBuyResult)
	PlayerStateController.OnChanged(function()
		refreshStatus()
	end)
	refreshStatus()
	task.spawn(runTimer)
end

return SpinWheelController
