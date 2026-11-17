--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "UseItem"
local MAX_ITEM_ID_LENGTH = 64

local BuffService = {}

local isInitialized = false
local notifyUseItemResult: RemoteEvent? = nil

local function sendResult(player: Player, ok: boolean, reason: string?, itemId: string?)
	if notifyUseItemResult ~= nil then
		notifyUseItemResult:FireClient(player, ok, reason, itemId)
	end
end

function BuffService.UseItem(player: Player, itemId: string): (boolean, string?)
	return DataActions.TryUseBuffItem(player, itemId)
end

local function onRequestUseItem(player: Player, itemId: any)
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded", nil)
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited", nil)
		return
	end
	if type(itemId) ~= "string" or #itemId > MAX_ITEM_ID_LENGTH then
		sendResult(player, false, "InvalidRequest", nil)
		return
	end
	local ok, reason = BuffService.UseItem(player, itemId)
	sendResult(player, ok, reason, itemId)
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

function BuffService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestUseItem = Instance.new("RemoteEvent")
	requestUseItem.Name = RemoteNames.RequestUseItem
	requestUseItem.Parent = remotesFolder

	local resultRemote = Instance.new("RemoteEvent")
	resultRemote.Name = RemoteNames.NotifyUseItemResult
	resultRemote.Parent = remotesFolder
	notifyUseItemResult = resultRemote

	requestUseItem.OnServerEvent:Connect(onRequestUseItem)
	DataService.OnProfileLoaded(DataActions.ResumeTimedBuffs)
	DataService.OnSessionEnding(DataActions.PauseTimedBuffs)
end

return BuffService
