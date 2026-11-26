--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local SpinConfig = require(shared:WaitForChild("Config"):WaitForChild("SpinConfig"))
local SpinRewardTable = require(ServerStorage:WaitForChild("LootTables"):WaitForChild("SpinRewardTable"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local WeightedPick = require(script.Parent.Parent.Internal.WeightedPick)
local PurchaseService = require(script.Parent.PurchaseService)

local REMOTES_FOLDER_NAME = "Remotes"
local SPIN_RATE_LIMIT_KEY = "Spin"
local BUY_RATE_LIMIT_KEY = "PremiumPurchase"

local SpinService = {}

local isInitialized = false
local rng = Random.new()
local notifySpinResult: RemoteEvent? = nil
local notifyBuyResult: RemoteEvent? = nil
local spinningUntil: { [Player]: number } = {}

local function sendSpinResult(player: Player, ok: boolean, reason: string?, rewardId: string?)
	if notifySpinResult ~= nil and player.Parent ~= nil then
		notifySpinResult:FireClient(player, ok, reason, rewardId)
	end
end

local function sendBuyResult(player: Player, ok: boolean, reason: string?)
	if notifyBuyResult ~= nil and player.Parent ~= nil then
		notifyBuyResult:FireClient(player, ok, reason)
	end
end

local function grantReward(player: Player, reward: SpinConfig.SpinReward): (boolean, string?)
	if reward.Kind == SpinConfig.RewardKinds.Coins then
		return DataActions.TryAddCoins(player, reward.Amount)
	end
	if reward.Kind == SpinConfig.RewardKinds.Spin then
		return DataActions.TryAddSpinTokens(player, reward.Amount)
	end
	local itemId = reward.ItemId
	if itemId == nil then
		return false, "InvalidItem"
	end
	return DataActions.TryAddItem(player, itemId, reward.Amount)
end

local function rollReward(): SpinConfig.SpinReward?
	local rewardId = WeightedPick.Pick(SpinRewardTable.Weights, rng)
	return if rewardId then SpinConfig.RewardById[rewardId] else nil
end

local function canSpin(player: Player): (boolean, string?)
	if not DataService.IsLoaded(player) then
		return false, "NotLoaded"
	end
	if not RateLimiter.Check(player, SPIN_RATE_LIMIT_KEY) then
		return false, "RateLimited"
	end
	if os.clock() < (spinningUntil[player] or 0) then
		return false, "Spinning"
	end
	return true
end

local function onRequestSpin(player: Player)
	local isAllowed, blockReason = canSpin(player)
	if not isAllowed then
		sendSpinResult(player, false, blockReason)
		return
	end
	local reward = rollReward()
	if reward == nil then
		warn("[SpinService] Reward table is empty")
		sendSpinResult(player, false, "NotAvailable")
		return
	end
	local ok, reason = DataActions.TryConsumeSpin(player, os.time())
	if not ok then
		sendSpinResult(player, false, reason)
		return
	end
	local isGranted, grantReason = grantReward(player, reward)
	if not isGranted then
		warn("[SpinService] Reward grant failed:", player.Name, reward.Id, grantReason)
	end
	spinningUntil[player] = os.clock() + SpinConfig.SpinDuration
	sendSpinResult(player, true, nil, reward.Id)
end

local function onRequestBuySpin(player: Player)
	if not DataService.IsLoaded(player) then
		sendBuyResult(player, false, "NotLoaded")
		return
	end
	if not RateLimiter.Check(player, BUY_RATE_LIMIT_KEY) then
		sendBuyResult(player, false, "RateLimited")
		return
	end
	local ok, reason = PurchaseService.Prompt(player, SpinConfig.SpinProduct.ProductId)
	if not ok then
		sendBuyResult(player, false, reason)
	end
end

local function grantFromRobux(player: Player, purchaseId: string): boolean
	local ok, reason = DataActions.TryGrantSpinTokens(player, SpinConfig.SpinProduct.Spins, purchaseId)
	if not ok then
		warn("[SpinService] Spin purchase grant failed:", player.Name, reason)
		return false
	end
	sendBuyResult(player, true, nil)
	return true
end

local function onPlayerRemoving(player: Player)
	spinningUntil[player] = nil
end

local function getRemotesFolder(): Instance
	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end
	return remotesFolder :: Instance
end

local function createRemote(name: string, parent: Instance): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function SpinService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestSpin = createRemote(RemoteNames.RequestSpin, remotesFolder)
	local requestBuySpin = createRemote(RemoteNames.RequestBuySpin, remotesFolder)
	notifySpinResult = createRemote(RemoteNames.NotifySpinResult, remotesFolder)
	notifyBuyResult = createRemote(RemoteNames.NotifyBuySpinResult, remotesFolder)
	requestSpin.OnServerEvent:Connect(onRequestSpin)
	requestBuySpin.OnServerEvent:Connect(onRequestBuySpin)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	PurchaseService.RegisterProduct(SpinConfig.SpinProduct.ProductId, grantFromRobux)
end

return SpinService
