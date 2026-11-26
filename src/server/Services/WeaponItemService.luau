--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "UseWeaponItem"
local MAX_ID_LENGTH = 64

local WeaponItemService = {}

local isInitialized = false
local notifyResult: RemoteEvent? = nil

local function sendResult(player: Player, ok: boolean, reason: string?, itemId: string?)
	local remote = notifyResult
	if remote ~= nil then
		remote:FireClient(player, ok, reason, itemId)
	end
end

local function isValidId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= MAX_ID_LENGTH
end

function WeaponItemService.Use(player: Player, itemId: string, weaponId: string): (boolean, string?)
	return DataActions.TryUseWeaponItem(player, itemId, weaponId)
end

local function onRequest(player: Player, itemId: any, weaponId: any)
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded", nil)
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited", nil)
		return
	end
	if not isValidId(itemId) or not isValidId(weaponId) then
		sendResult(player, false, "InvalidRequest", nil)
		return
	end
	local ok, reason = WeaponItemService.Use(player, itemId, weaponId)
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

function WeaponItemService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestRemote = Instance.new("RemoteEvent")
	requestRemote.Name = RemoteNames.RequestUseWeaponItem
	requestRemote.Parent = remotesFolder

	local resultRemote = Instance.new("RemoteEvent")
	resultRemote.Name = RemoteNames.NotifyUseWeaponItemResult
	resultRemote.Parent = remotesFolder
	notifyResult = resultRemote

	requestRemote.OnServerEvent:Connect(onRequest)
end

return WeaponItemService
