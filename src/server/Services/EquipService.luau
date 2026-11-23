--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local WeaponIncome = require(shared:WaitForChild("Utils"):WaitForChild("WeaponIncome"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "Equip"
local BROKEN_STATE = DataTemplate.WeaponStates.Broken

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

local function getIncome(weapon: any): number
	return WeaponIncome.PerSecond(weapon.Value, weapon.Mutation, weapon.State == BROKEN_STATE)
end

local function pickBestWeapons(data: any): { string }
	local candidates = {}
	for _, weapon in data.Weapons do
		if weapon.State ~= BROKEN_STATE then
			table.insert(candidates, weapon)
		end
	end
	table.sort(candidates, function(a: any, b: any): boolean
		return getIncome(a) > getIncome(b)
	end)
	local slots = data.Capacity.Loadout or DataTemplate.Limits.DefaultLoadoutSlots
	local best = {}
	for index = 1, math.min(slots, #candidates) do
		table.insert(best, candidates[index].Id)
	end
	return best
end

local function onRequestEquipBest(player: Player)
	local canRun, reason = canHandle(player, "")
	if not canRun then
		sendResult(player, false, reason)
		return
	end
	local data = DataService.GetData(player)
	if data == nil then
		sendResult(player, false, "NotLoaded")
		return
	end
	local best = pickBestWeapons(data)
	if #best == 0 then
		sendResult(player, false, "NoWeapons")
		return
	end
	local ok, setReason = DataActions.TrySetLoadout(player, best)
	sendResult(player, ok, setReason)
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
	local requestEquipBest = createRemote(RemoteNames.RequestEquipBest, remotesFolder)
	notifyEquipResult = createRemote(RemoteNames.NotifyEquipResult, remotesFolder)

	requestEquip.OnServerEvent:Connect(onRequestEquip)
	requestUnequip.OnServerEvent:Connect(onRequestUnequip)
	requestEquipBest.OnServerEvent:Connect(onRequestEquipBest)
end

return EquipService
