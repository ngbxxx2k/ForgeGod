--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local PlotUpgradeConfig = require(shared:WaitForChild("Config"):WaitForChild("PlotUpgradeConfig"))
local PlotLevel = require(shared:WaitForChild("Utils"):WaitForChild("PlotLevel"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local PurchaseService = require(script.Parent.PurchaseService)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "PlotUpgrade"

local PlotUpgradeService = {}

local isInitialized = false
local notifyResult: RemoteEvent? = nil

local function sendResult(player: Player, ok: boolean, reason: string?)
	if notifyResult ~= nil and player.Parent ~= nil then
		notifyResult:FireClient(player, ok, reason)
	end
end

local function getSlots(player: Player): number?
	local data = DataService.GetData(player)
	if data == nil then
		return nil
	end
	return data.Capacity.Loadout or DataTemplate.Limits.DefaultLoadoutSlots
end

local function promptRobux(player: Player): (boolean, string?)
	local slots = getSlots(player)
	if slots == nil then
		return false, "NotLoaded"
	end
	local step = PlotLevel.GetNextStep(slots)
	if step == nil then
		return false, "MaxLevel"
	end
	return PurchaseService.Prompt(player, step.ProductId)
end

local function onRequestUpgrade(player: Player, currency: any)
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded")
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited")
		return
	end
	if currency == PlotUpgradeConfig.Currencies.Coins then
		local ok, reason = DataActions.TryBuyLoadoutSlot(player)
		sendResult(player, ok, reason)
	elseif currency == PlotUpgradeConfig.Currencies.Robux then
		local ok, reason = promptRobux(player)
		if not ok then
			sendResult(player, false, reason)
		end
	else
		sendResult(player, false, "InvalidRequest")
	end
end

local function grantFromRobux(player: Player, purchaseId: string): boolean
	local ok, reason = DataActions.TryGrantLoadoutSlot(player, purchaseId)
	if not ok then
		warn("[PlotUpgradeService] Robux grant failed:", player.Name, reason)
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

function PlotUpgradeService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestUpgrade = createRemote(RemoteNames.RequestPlotUpgrade, remotesFolder)
	notifyResult = createRemote(RemoteNames.NotifyPlotUpgradeResult, remotesFolder)
	requestUpgrade.OnServerEvent:Connect(onRequestUpgrade)

	for _, step in PlotUpgradeConfig.Steps do
		PurchaseService.RegisterProduct(step.ProductId, grantFromRobux)
	end
end

return PlotUpgradeService
