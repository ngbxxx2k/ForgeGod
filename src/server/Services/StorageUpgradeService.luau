--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local StorageConfig = require(shared:WaitForChild("Config"):WaitForChild("StorageConfig"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local PurchaseService = require(script.Parent.PurchaseService)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "PremiumPurchase"

local StorageUpgradeService = {}

local isInitialized = false
local notifyResult: RemoteEvent? = nil

local function sendResult(player: Player, ok: boolean, reason: string?)
	if notifyResult ~= nil and player.Parent ~= nil then
		notifyResult:FireClient(player, ok, reason)
	end
end

local function onRequestBuy(player: Player)
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded")
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited")
		return
	end
	local slots = DataActions.GetStorageSlots(player) or 0
	if slots >= StorageConfig.ExpandedSlots then
		sendResult(player, false, "MaxStorage")
		return
	end
	local ok, reason = PurchaseService.Prompt(player, StorageConfig.ProductId)
	if not ok then
		sendResult(player, false, reason)
	end
end

local function grantFromRobux(player: Player, purchaseId: string): boolean
	local ok, reason = DataActions.TryGrantStorageSlots(player, StorageConfig.ExpandedSlots, purchaseId)
	if not ok then
		warn("[StorageUpgradeService] Storage grant failed:", player.Name, reason)
		return false
	end
	sendResult(player, true, nil)
	return true
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

function StorageUpgradeService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestBuy = createRemote(RemoteNames.RequestBuyStorage, remotesFolder)
	notifyResult = createRemote(RemoteNames.NotifyBuyStorageResult, remotesFolder)
	requestBuy.OnServerEvent:Connect(onRequestBuy)
	PurchaseService.RegisterProduct(StorageConfig.ProductId, grantFromRobux)
end

return StorageUpgradeService
