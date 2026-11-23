--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local SellPrice = require(shared:WaitForChild("Utils"):WaitForChild("SellPrice"))
local SellConfig = require(shared:WaitForChild("Config"):WaitForChild("SellConfig"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "Sell"
local MAX_WEAPON_ID_LENGTH = 64
local MAX_ITEM_ID_LENGTH = 64

local SellService = {}

local isInitialized = false
local notifySellResult: RemoteEvent? = nil

function SellService.GetSellPrice(player: Player, weaponId: string): (number?, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return nil, "NotLoaded"
	end
	local weapon = data.Weapons[weaponId]
	if weapon == nil then
		return nil, "WeaponNotFound"
	end
	local isBroken = weapon.State == DataTemplate.WeaponStates.Broken
	local buffMultiplier = SellPrice.GetBuffMultiplier(data, os.time())
	return SellPrice.Calculate(weapon.Value, weapon.Mutation, isBroken, buffMultiplier), nil
end

function SellService.Sell(player: Player, weaponId: string): (boolean, string?, number?)
	local price, reason = SellService.GetSellPrice(player, weaponId)
	if price == nil then
		return false, reason, nil
	end
	local ok, sellReason = DataActions.TrySellWeapon(player, weaponId, price)
	if not ok then
		return false, sellReason, nil
	end
	return true, nil, price
end

local function isSellableWeapon(data: any, weaponId: string): boolean
	local weapon = data.Weapons[weaponId]
	return weapon ~= nil
		and weapon.IsLocked ~= true
		and table.find(data.Equipped, weaponId) == nil
end

function SellService.SellWeapons(
	player: Player,
	weaponIds: { string }
): (boolean, string?, number?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded", nil
	end
	local buffMultiplier = SellPrice.GetBuffMultiplier(data, os.time())
	local prices: { [string]: number } = {}
	for _, weaponId in weaponIds do
		if prices[weaponId] == nil and isSellableWeapon(data, weaponId) then
			local weapon = data.Weapons[weaponId]
			local isBroken = weapon.State == DataTemplate.WeaponStates.Broken
			prices[weaponId] =
				SellPrice.Calculate(weapon.Value, weapon.Mutation, isBroken, buffMultiplier)
		end
	end
	return DataActions.TrySellWeapons(player, prices)
end

local function sendResult(player: Player, ok: boolean, reason: string?, coins: number?)
	if notifySellResult ~= nil then
		notifySellResult:FireClient(player, ok, reason, coins)
	end
end

local function onRequestSell(player: Player, weaponId: any)
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded", nil)
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited", nil)
		return
	end
	if type(weaponId) ~= "string" or #weaponId > MAX_WEAPON_ID_LENGTH then
		sendResult(player, false, "InvalidRequest", nil)
		return
	end
	local ok, reason, coins = SellService.Sell(player, weaponId)
	sendResult(player, ok, reason, coins)
end

local function isValidWeaponIdList(weaponIds: any): boolean
	if type(weaponIds) ~= "table" then
		return false
	end
	local count = #weaponIds
	if count < 1 or count > SellConfig.MaxWeaponSellPerRequest then
		return false
	end
	for key, weaponId in weaponIds do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > count then
			return false
		end
		if type(weaponId) ~= "string" or #weaponId > MAX_WEAPON_ID_LENGTH then
			return false
		end
	end
	return true
end

local function onRequestSellAllWeapons(player: Player, weaponIds: any)
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded", nil)
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited", nil)
		return
	end
	if not isValidWeaponIdList(weaponIds) then
		sendResult(player, false, "InvalidRequest", nil)
		return
	end
	local ok, reason, coins = SellService.SellWeapons(player, weaponIds)
	sendResult(player, ok, reason, coins)
end

function SellService.SellItem(
	player: Player,
	itemId: string,
	amount: number
): (boolean, string?, number?)
	local price = SellPrice.CalculateItem(itemId, amount)
	if price == nil then
		return false, "InvalidItem", nil
	end
	local ok, reason = DataActions.TrySellItem(player, itemId, amount, price)
	if not ok then
		return false, reason, nil
	end
	return true, nil, price
end

local function isValidSellAmount(amount: any): boolean
	return type(amount) == "number"
		and amount == amount
		and amount % 1 == 0
		and amount >= 1
		and amount <= SellConfig.MaxItemSellPerRequest
end

local function onRequestSellItem(player: Player, itemId: any, amount: any)
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded", nil)
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited", nil)
		return
	end
	if type(itemId) ~= "string" or #itemId > MAX_ITEM_ID_LENGTH or not isValidSellAmount(amount) then
		sendResult(player, false, "InvalidRequest", nil)
		return
	end
	local ok, reason, coins = SellService.SellItem(player, itemId, amount)
	sendResult(player, ok, reason, coins)
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

function SellService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestSell = Instance.new("RemoteEvent")
	requestSell.Name = RemoteNames.RequestSellWeapon
	requestSell.Parent = remotesFolder

	local resultRemote = Instance.new("RemoteEvent")
	resultRemote.Name = RemoteNames.NotifySellResult
	resultRemote.Parent = remotesFolder
	notifySellResult = resultRemote

	requestSell.OnServerEvent:Connect(onRequestSell)

	local requestSellItem = Instance.new("RemoteEvent")
	requestSellItem.Name = RemoteNames.RequestSellItem
	requestSellItem.Parent = remotesFolder
	requestSellItem.OnServerEvent:Connect(onRequestSellItem)

	local requestSellAll = Instance.new("RemoteEvent")
	requestSellAll.Name = RemoteNames.RequestSellAllWeapons
	requestSellAll.Parent = remotesFolder
	requestSellAll.OnServerEvent:Connect(onRequestSellAllWeapons)
end

return SellService
