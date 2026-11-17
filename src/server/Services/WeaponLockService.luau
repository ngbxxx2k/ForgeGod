--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "WeaponLock"
local MAX_WEAPON_ID_LENGTH = 64

local WeaponLockService = {}

local isInitialized = false
local notifyLockResult: RemoteEvent? = nil

local function sendResult(player: Player, ok: boolean, reason: string?)
	if notifyLockResult ~= nil then
		notifyLockResult:FireClient(player, ok, reason)
	end
end

local function onRequestSetLock(player: Player, weaponId: any, isLocked: any)
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded")
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited")
		return
	end
	if type(weaponId) ~= "string" or #weaponId > MAX_WEAPON_ID_LENGTH then
		sendResult(player, false, "InvalidRequest")
		return
	end
	if type(isLocked) ~= "boolean" then
		sendResult(player, false, "InvalidRequest")
		return
	end
	local ok, reason = DataActions.TrySetWeaponLocked(player, weaponId, isLocked)
	sendResult(player, ok, reason)
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

function WeaponLockService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestRemote = Instance.new("RemoteEvent")
	requestRemote.Name = RemoteNames.RequestSetWeaponLock
	requestRemote.Parent = remotesFolder

	local resultRemote = Instance.new("RemoteEvent")
	resultRemote.Name = RemoteNames.NotifyWeaponLockResult
	resultRemote.Parent = remotesFolder
	notifyLockResult = resultRemote

	requestRemote.OnServerEvent:Connect(onRequestSetLock)
end

return WeaponLockService
