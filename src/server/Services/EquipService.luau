--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "Equip"

local EquipService = {}

local isInitialized = false
local notifyEquipResult: RemoteEvent? = nil

local function sendResult(player: Player, ok: boolean, reason: string?)
	if notifyEquipResult ~= nil then
		notifyEquipResult:FireClient(player, ok, reason)
	end
end

local function canHandle(player: Player, weaponId: any): (boolean, string?)
	if not DataService.IsLoaded(player) then
		return false, "NotLoaded"
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		return false, "RateLimited"
	end
	if type(weaponId) ~= "string" then
		return false, "InvalidRequest"
	end
	return true, nil
end

local function onRequestEquip(player: Player, weaponId: any)
	local canRun, reason = canHandle(player, weaponId)
	if not canRun then
		sendResult(player, false, reason)
		return
	end
	local ok, equipReason = DataActions.TryEquipWeapon(player, weaponId)
	sendResult(player, ok, equipReason)
end

local function onRequestUnequip(player: Player, weaponId: any)
	local canRun, reason = canHandle(player, weaponId)
	if not canRun then
		sendResult(player, false, reason)
		return
	end
	local ok, unequipReason = DataActions.TryUnequipWeapon(player, weaponId)
	sendResult(player, ok, unequipReason)
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

function EquipService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestEquip = createRemote(RemoteNames.RequestEquip, remotesFolder)
	local requestUnequip = createRemote(RemoteNames.RequestUnequip, remotesFolder)
	notifyEquipResult = createRemote(RemoteNames.NotifyEquipResult, remotesFolder)

	requestEquip.OnServerEvent:Connect(onRequestEquip)
	requestUnequip.OnServerEvent:Connect(onRequestUnequip)
end

return EquipService
