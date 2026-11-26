--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local IndexCollection = require(shared:WaitForChild("Utils"):WaitForChild("IndexCollection"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "IndexClaim"

local IndexRewardService = {}

local isInitialized = false
local notifyResult: RemoteEvent? = nil

local function sendResult(player: Player, ok: boolean, reason: string?, tabId: string?, rarity: string?)
	if notifyResult ~= nil and player.Parent ~= nil then
		notifyResult:FireClient(player, ok, reason, tabId, rarity)
	end
end

local function onRequestClaim(player: Player, tabId: any, rarity: any)
	if not IndexCollection.IsValidTab(tabId) or not IndexCollection.IsValidRarity(rarity) then
		sendResult(player, false, "InvalidRequest")
		return
	end
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded")
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited")
		return
	end
	local ok, reason = DataActions.TryClaimIndexReward(player, tabId, rarity)
	sendResult(player, ok, reason, tabId, rarity)
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

function IndexRewardService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestClaim = createRemote(RemoteNames.RequestClaimIndexReward, remotesFolder)
	notifyResult = createRemote(RemoteNames.NotifyClaimIndexRewardResult, remotesFolder)
	requestClaim.OnServerEvent:Connect(onRequestClaim)
end

return IndexRewardService
