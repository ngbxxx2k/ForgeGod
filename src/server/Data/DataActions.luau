--!strict
--[[
	DataActions
	Trách nhiệm: nơi DUY NHẤT được sửa trực tiếp dữ liệu người chơi (data).
	Các Service/System gọi hàm ở đây, không tự gán `data.X = ...`.
	Mọi hàm có thể thất bại trả về (ok: boolean, reason: string?).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configFolder = sharedFolder:WaitForChild("Config")
local WeaponWeightConfig = require(configFolder:WaitForChild("WeaponWeightConfig"))
local WeaponItemConfig = require(configFolder:WaitForChild("WeaponItemConfig"))
local DigToolConfig = require(configFolder:WaitForChild("DigToolConfig"))
local ForgeUpgradeConfig = require(configFolder:WaitForChild("ForgeUpgradeConfig"))
local SpinConfig = require(configFolder:WaitForChild("SpinConfig"))
local IndexRewardConfig = require(configFolder:WaitForChild("IndexRewardConfig"))
local TutorialConfig = require(configFolder:WaitForChild("TutorialConfig"))
local IndexCollection = require(sharedFolder:WaitForChild("Utils"):WaitForChild("IndexCollection"))
local IndexKey = require(sharedFolder:WaitForChild("Utils"):WaitForChild("IndexKey"))
local PlotLevel = require(sharedFolder:WaitForChild("Utils"):WaitForChild("PlotLevel"))
local WeaponIncome = require(sharedFolder:WaitForChild("Utils"):WaitForChild("WeaponIncome"))
local WeaponItemTarget = require(sharedFolder:WaitForChild("Utils"):WaitForChild("WeaponItemTarget"))

local DataTemplate = require(script.Parent.DataTemplate)
local DataService = require(script.Parent.DataService)
local LeaderboardService = require(script.Parent.LeaderboardService)

local DataActions = {}

local changedCallbacks: { (Player) -> () } = {}

local Limits = DataTemplate.Limits
local ItemKinds = DataTemplate.ItemKinds

--[[ ===================== Kiểm tra hợp lệ ===================== ]]

-- Số hợp lệ: là số, nguyên, không NaN/inf, nằm trong khoảng cho phép.
local function isValidCount(value: any, minValue: number, maxValue: number): boolean
	return type(value) == "number"
		and value == value -- chặn NaN
		and value ~= math.huge -- chặn inf
		and value % 1 == 0 -- nguyên
		and value >= minValue
		and value <= maxValue
end

-- Chuỗi hợp lệ: kiểu string, rỗng được bỏ, không chứa byte UTF-8 lỗi.
local function isValidString(value: any): boolean
	return type(value) == "string" and value ~= "" and utf8.len(value) ~= nil
end

local function clampCoins(value: number): number
	return math.min(math.floor(value), Limits.MaxCoins)
end

-- ItemId tồn tại trong registry?
local function isValidItemId(itemId: string): boolean
	return DataTemplate.Items[itemId] ~= nil
end

-- Vũ khí đang đeo trên lưng?
local function isWeaponEquipped(data: any, weaponId: string): boolean
	return table.find(data.Equipped, weaponId) ~= nil
end

-- Số chỗ kho đã dùng: chỉ đếm vũ khí trong Weapons (quặng và buff không tính).
local function getUsedSlots(data: any): number
	local used = 0
	for _ in data.Weapons :: any do
		used += 1
	end
	return used
end

-- Vũ khí có cấu trúc tối thiểu hợp lệ để lưu vào kho?
local function isValidScale(scale: any): boolean
	if scale == nil then
		return true
	end
	return type(scale) == "number" and scale == scale
		and scale >= WeaponWeightConfig.MinScale and scale <= WeaponWeightConfig.MaxScale
end

local function isOptionalCount(value: any, minValue: number, maxValue: number): boolean
	return value == nil or isValidCount(value, minValue, maxValue)
end

local function isValidForgeProgress(weapon: any): boolean
	return isOptionalCount(weapon.ShapeStage, Limits.MinShapeStage, Limits.MaxShapeStage)
		and isOptionalCount(weapon.ShapeStrikes, 0, math.huge)
		and isOptionalCount(weapon.FrenzyStrikes, 0, math.huge)
end

local function isValidWeapon(weapon: any): boolean
	if type(weapon) ~= "table" then
		return false
	end
	return isValidString(weapon.Id)
		and isValidString(weapon.Rarity)
		and table.find(DataTemplate.Rarities, weapon.Rarity) ~= nil
		and type(weapon.Tier) == "number"
		and isValidString(weapon.State)
		-- WeaponStates là bảng từ điển nên phải tra theo khoá,
		-- không dùng table.find (chỉ duyệt phần mảng, luôn trả nil ở đây).
		and DataTemplate.WeaponStates[weapon.State] ~= nil
		and isValidCount(weapon.Level, 0, Limits.MaxWeaponLevel)
		and isValidCount(weapon.ForgePoints, 0, Limits.MaxForgePoints)
		and isValidForgeProgress(weapon)
		and (weapon.Mutation == nil or isValidString(weapon.Mutation))
		and isValidScale(weapon.Scale)
		and type(weapon.BaseValue) == "number"
		and weapon.BaseValue >= 0
		and type(weapon.Value) == "number"
		and weapon.Value >= 0
		and type(weapon.Recipe) == "table"
		and (weapon.ValueHistory == nil or type(weapon.ValueHistory) == "table")
		and (weapon.IsLocked == nil or type(weapon.IsLocked) == "boolean")
end

local function recordIndex(data: any, weapon: any)
	if not isValidString(weapon.WeaponType) then
		return
	end
	if data.Index == nil then
		data.Index = {}
	end
	data.Index[IndexKey.Build(weapon.Mutation, weapon.WeaponType, weapon.ShapeStage)] = true
end

local function updateHighestStats(data: any, weapon: any)
	if weapon.Value > data.Stats.HighestWeaponValue then
		data.Stats.HighestWeaponValue = math.floor(weapon.Value)
	end
	if weapon.Level > data.Stats.HighestWeaponLevel then
		data.Stats.HighestWeaponLevel = weapon.Level
	end
	local isBroken = weapon.State == DataTemplate.WeaponStates.Broken
	local income = WeaponIncome.PerSecond(weapon.Value, weapon.Mutation, isBroken)
	if income > data.Stats.HighestWeaponIncome then
		data.Stats.HighestWeaponIncome = income
	end
end

local function isUsableBuff(itemId: string): boolean
	local itemInfo: any = DataTemplate.Items[itemId]
	local kind = itemInfo.Kind
	if kind == ItemKinds.OneUse then
		return true
	end
	return kind == ItemKinds.Timed and type(itemInfo.Duration) == "number"
end

local function applyBuff(data: any, itemId: string, now: number)
	local itemInfo: any = DataTemplate.Items[itemId]
	if itemInfo.Kind == ItemKinds.OneUse then
		data.ArmedBuffs[itemId] = (data.ArmedBuffs[itemId] or 0) + 1
		return
	end
	local current = data.ActiveBuffs[itemId] or 0
	data.ActiveBuffs[itemId] = math.max(current, now) + itemInfo.Duration
end

local function notifyChanged(player: Player)
	for _, callback in changedCallbacks do
		task.spawn(callback, player)
	end
end

--[[ ===================== Hành động ===================== ]]

-- Đọc bản sao dữ liệu để gửi client (server vẫn giữ bản gốc).
-- Trả về (snapshot, nil) hoặc (nil, reason).
function DataActions.GetProfileSnapshot(player: Player): (any?, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return nil, "NotLoaded"
	end
	-- Deep-copy để client không thể tham chiếu ngược vào bảng gốc.
	local snapshot = table.clone(data)
	snapshot.Items = table.clone(data.Items)
	snapshot.Weapons = table.clone(data.Weapons)
	snapshot.Equipped = table.clone(data.Equipped)
	return snapshot, nil
end

-- Cộng tiền. amount nguyên dương.
function DataActions.TryAddCoins(player: Player, amount: number): (boolean, string?)
	if not isValidCount(amount, 1, math.huge) then
		return false, "InvalidAmount"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	data.Coins = clampCoins(data.Coins + amount)
	data.Stats.TotalCoinsEarned = clampCoins(data.Stats.TotalCoinsEarned + amount)
	LeaderboardService.SetCoins(player, data.Coins)
	notifyChanged(player)
	return true
end

-- Trừ tiền. Kiểm tra đủ tiền TRƯỚC khi trừ, không có task.wait xen giữa.
function DataActions.TryRemoveCoins(player: Player, amount: number): (boolean, string?)
	if not isValidCount(amount, 1, math.huge) then
		return false, "InvalidAmount"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if data.Coins < amount then
		return false, "NotEnoughCoins"
	end
	data.Coins = math.floor(data.Coins - amount)
	LeaderboardService.SetCoins(player, data.Coins)
	notifyChanged(player)
	return true
end

-- Thêm vật phẩm/quặng. Kiểm tra sức chứa trước khi tăng số lượng.
function DataActions.TryAddItem(player: Player, itemId: string, amount: number): (boolean, string?)
	if not isValidItemId(itemId) then
		return false, "InvalidItem"
	end
	if not isValidCount(amount, 1, math.huge) then
		return false, "InvalidAmount"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local current = data.Items[itemId] or 0
	data.Items[itemId] = current + amount
	notifyChanged(player)
	return true
end

-- Trừ vật phẩm/quặng.
function DataActions.TryRemoveItem(player: Player, itemId: string, amount: number): (boolean, string?)
	if not isValidItemId(itemId) then
		return false, "InvalidItem"
	end
	if not isValidCount(amount, 1, math.huge) then
		return false, "InvalidAmount"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local current = data.Items[itemId] or 0
	if current < amount then
		return false, "NotEnoughItems"
	end
	data.Items[itemId] = current - amount
	if data.Items[itemId] <= 0 then
		data.Items[itemId] = nil
	end
	notifyChanged(player)
	return true
end

-- Thêm một vũ khí/phôi riêng lẻ vào kho.
function DataActions.TryAddWeapon(player: Player, weapon: any): (boolean, string?)
	if not isValidWeapon(weapon) then
		return false, "InvalidWeapon"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if data.Weapons[weapon.Id] ~= nil then
		return false, "WeaponExists"
	end
	if getUsedSlots(data) + 1 > data.Capacity.Items then
		return false, "InventoryFull"
	end
	data.Weapons[weapon.Id] = weapon
	updateHighestStats(data, weapon)
	recordIndex(data, weapon)
	notifyChanged(player)
	return true
end

function DataActions.TryUpdateWeapon(player: Player, weapon: any): (boolean, string?)
	if not isValidWeapon(weapon) then
		return false, "InvalidWeapon"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if data.Weapons[weapon.Id] == nil then
		return false, "WeaponNotFound"
	end
	data.Weapons[weapon.Id] = weapon
	local equippedIndex = table.find(data.Equipped, weapon.Id)
	if equippedIndex and weapon.State == DataTemplate.WeaponStates.Broken then
		table.remove(data.Equipped, equippedIndex)
	end
	updateHighestStats(data, weapon)
	recordIndex(data, weapon)
	notifyChanged(player)
	return true
end

function DataActions.TryRecordForge(player: Player, isBroken: boolean): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	data.Stats.TotalForges += 1
	if isBroken then
		data.Stats.TotalBroken += 1
	end
	notifyChanged(player)
	return true
end

-- Nhận quà Index: kiểm tra bộ sưu tập đủ và chưa nhận TRƯỚC, rồi cộng quặng và ghi đã nhận cùng một bước.
function DataActions.TryClaimIndexReward(player: Player, tabId: string, rarity: string): (boolean, string?)
	local reward = IndexRewardConfig.ByRarity[rarity]
	if not IndexCollection.IsValidTab(tabId) or reward == nil or not isValidItemId(reward.ItemId) then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if type(data.IndexRewards) ~= "table" then
		data.IndexRewards = {}
	end
	local rewardKey = IndexCollection.BuildRewardKey(tabId, rarity)
	if data.IndexRewards[rewardKey] == true then
		return false, "AlreadyClaimed"
	end
	if not IndexCollection.IsComplete(data.Index or {}, tabId, rarity) then
		return false, "CollectionIncomplete"
	end
	data.IndexRewards[rewardKey] = true
	data.Items[reward.ItemId] = (data.Items[reward.ItemId] or 0) + reward.Amount
	notifyChanged(player)
	return true
end

-- Lấy vũ khí theo Id (bảng gốc; không sửa trực tiếp, dùng DataActions).
function DataActions.GetWeapon(player: Player, weaponId: string): (any?, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return nil, "NotLoaded"
	end
	if not isValidString(weaponId) or data.Weapons[weaponId] == nil then
		return nil, "WeaponNotFound"
	end
	return data.Weapons[weaponId], nil
end

-- Xoá vũ khí khỏi kho. Chặn xoá vũ khí đang treo (F1.1, F7.3).
function DataActions.TryRemoveWeapon(player: Player, weaponId: string): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if not isValidString(weaponId) or data.Weapons[weaponId] == nil then
		return false, "WeaponNotFound"
	end
	if isWeaponEquipped(data, weaponId) then
		return false, "WeaponEquipped"
	end
	data.Weapons[weaponId] = nil
	notifyChanged(player)
	return true
end

-- Bán vũ khí: kiểm tra trước, rồi xoá vũ khí và cộng tiền trong cùng một bước (F7).
function DataActions.TrySellWeapon(
	player: Player,
	weaponId: string,
	price: number
): (boolean, string?)
	if not isValidCount(price, 0, math.huge) then
		return false, "InvalidAmount"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if not isValidString(weaponId) or data.Weapons[weaponId] == nil then
		return false, "WeaponNotFound"
	end
	if isWeaponEquipped(data, weaponId) then
		return false, "WeaponEquipped"
	end
	if data.Weapons[weaponId].IsLocked == true then
		return false, "WeaponLocked"
	end
	data.Weapons[weaponId] = nil
	data.Coins = clampCoins(data.Coins + price)
	data.Stats.TotalCoinsEarned = clampCoins(data.Stats.TotalCoinsEarned + price)
	LeaderboardService.SetCoins(player, data.Coins)
	notifyChanged(player)
	return true
end

local function canSellWeapon(data: any, weaponId: any, price: any): (boolean, string?)
	if not isValidCount(price, 0, math.huge) then
		return false, "InvalidAmount"
	end
	if not isValidString(weaponId) or data.Weapons[weaponId] == nil then
		return false, "WeaponNotFound"
	end
	if isWeaponEquipped(data, weaponId) then
		return false, "WeaponEquipped"
	end
	if data.Weapons[weaponId].IsLocked == true then
		return false, "WeaponLocked"
	end
	return true
end

-- Bán nhiều vũ khí cùng lúc: kiểm tra tất cả trước, rồi mới xoá và cộng tiền.
function DataActions.TrySellWeapons(
	player: Player,
	prices: { [string]: number }
): (boolean, string?, number?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded", nil
	end
	if next(prices) == nil then
		return false, "NothingToSell", nil
	end
	local total = 0
	for weaponId, price in prices do
		local ok, reason = canSellWeapon(data, weaponId, price)
		if not ok then
			return false, reason, nil
		end
		total += price
	end
	for weaponId in prices do
		data.Weapons[weaponId] = nil
	end
	data.Coins = clampCoins(data.Coins + total)
	data.Stats.TotalCoinsEarned = clampCoins(data.Stats.TotalCoinsEarned + total)
	LeaderboardService.SetCoins(player, data.Coins)
	notifyChanged(player)
	return true, nil, total
end

function DataActions.TrySellItem(
	player: Player,
	itemId: string,
	amount: number,
	price: number
): (boolean, string?)
	if not isValidString(itemId) or not isValidItemId(itemId) then
		return false, "InvalidItem"
	end
	if not isValidCount(amount, 1, math.huge) or not isValidCount(price, 0, math.huge) then
		return false, "InvalidAmount"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local current = data.Items[itemId] or 0
	if current < amount then
		return false, "NotEnoughItems"
	end
	data.Items[itemId] = if current - amount > 0 then current - amount else nil
	data.Coins = clampCoins(data.Coins + price)
	data.Stats.TotalCoinsEarned = clampCoins(data.Stats.TotalCoinsEarned + price)
	LeaderboardService.SetCoins(player, data.Coins)
	notifyChanged(player)
	return true
end

-- Khoá hoặc mở khoá vũ khí. Vũ khí khoá không bán và không rèn được.
function DataActions.TrySetWeaponLocked(
	player: Player,
	weaponId: string,
	isLocked: boolean
): (boolean, string?)
	if type(isLocked) ~= "boolean" then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local weapon = if isValidString(weaponId) then data.Weapons[weaponId] else nil
	if weapon == nil then
		return false, "WeaponNotFound"
	end
	weapon.IsLocked = if isLocked then true else nil
	notifyChanged(player)
	return true
end

local function getLoadoutSlots(data: any): number
	return data.Capacity.Loadout or Limits.DefaultLoadoutSlots
end

local function isEquippable(data: any, weaponId: any): boolean
	local weapon = if isValidString(weaponId) then data.Weapons[weaponId] else nil
	return weapon ~= nil and weapon.State ~= DataTemplate.WeaponStates.Broken
end

local function isValidLoadout(data: any, weaponIds: any): boolean
	if type(weaponIds) ~= "table" or #weaponIds > getLoadoutSlots(data) then
		return false
	end
	local seen: { [string]: boolean } = {}
	for _, weaponId in weaponIds do
		if not isEquippable(data, weaponId) or seen[weaponId] then
			return false
		end
		seen[weaponId] = true
	end
	return true
end

-- Thay toàn bộ Loadout bằng danh sách mới (dùng cho nút Equip Best).
function DataActions.TrySetLoadout(player: Player, weaponIds: { string }): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if not isValidLoadout(data, weaponIds) then
		return false, "InvalidRequest"
	end
	data.Equipped = table.clone(weaponIds)
	notifyChanged(player)
	return true
end

-- Đưa vũ khí vào Loadout (tối đa Capacity.Loadout, không trùng).
function DataActions.TryEquipWeapon(player: Player, weaponId: string): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local weapon = data.Weapons[weaponId]
	if not isValidString(weaponId) or weapon == nil then
		return false, "WeaponNotFound"
	end
	if weapon.State == DataTemplate.WeaponStates.Broken then
		-- Vũ khí hỏng không đeo được (F4.6).
		return false, "WeaponBroken"
	end
	local equippedIndex = table.find(data.Equipped, weaponId)
	if equippedIndex then
		table.remove(data.Equipped, equippedIndex)
		table.insert(data.Equipped, weaponId)
		notifyChanged(player)
		return true
	end
	if #data.Equipped >= getLoadoutSlots(data) then
		return false, "EquipLimitReached"
	end
	table.insert(data.Equipped, weaponId)
	notifyChanged(player)
	return true
end

-- Gỡ vũ khí đang treo xuống.
function DataActions.TryUnequipWeapon(player: Player, weaponId: string): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local index = table.find(data.Equipped, weaponId)
	if index == nil then
		return false, "NotEquipped"
	end
	table.remove(data.Equipped, index)
	notifyChanged(player)
	return true
end

local function recordPurchase(data: any, purchaseId: string)
	table.insert(data.ProcessedPurchases, purchaseId)
	while #data.ProcessedPurchases > Limits.MaxProcessedPurchases do
		table.remove(data.ProcessedPurchases, 1)
	end
end

function DataActions.HasProcessedPurchase(player: Player, purchaseId: string): boolean
	local data = DataService.GetData(player)
	return data ~= nil and table.find(data.ProcessedPurchases, purchaseId) ~= nil
end

-- Mua thêm 1 ô Loadout (1 trụ) bằng coins. Giá lấy từ PlotUpgradeConfig theo level hiện tại.
function DataActions.TryBuyLoadoutSlot(player: Player): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local slots = getLoadoutSlots(data)
	local step = PlotLevel.GetNextStep(slots)
	if step == nil then
		return false, "MaxLevel"
	end
	if data.Coins < step.CoinPrice then
		return false, "NotEnoughCoins"
	end
	data.Coins = math.floor(data.Coins - step.CoinPrice)
	data.Capacity.Loadout = slots + 1
	LeaderboardService.SetCoins(player, data.Coins)
	notifyChanged(player)
	return true
end

local function getOwnedDigTiers(data: any, toolId: string): { number }
	if type(data.OwnedDigTiers) ~= "table" then
		data.OwnedDigTiers = {}
	end
	if type(data.OwnedDigTiers[toolId]) ~= "table" then
		data.OwnedDigTiers[toolId] = { DigToolConfig.MinTier }
	end
	return data.OwnedDigTiers[toolId]
end

local function ownsDigTier(data: any, toolId: string, tierIndex: number): boolean
	return tierIndex == DigToolConfig.MinTier or table.find(getOwnedDigTiers(data, toolId), tierIndex) ~= nil
end

local function equipDigTier(data: any, toolId: string, tierIndex: number)
	if type(data.DigTools) ~= "table" then
		data.DigTools = {}
	end
	data.DigTools[toolId] = tierIndex
end

local function unlockDigTier(data: any, toolId: string, tierIndex: number)
	local owned = getOwnedDigTiers(data, toolId)
	if table.find(owned, tierIndex) == nil then
		table.insert(owned, tierIndex)
		table.sort(owned)
	end
	equipDigTier(data, toolId, tierIndex)
end

-- Bậc máy dò / xẻng đang trang bị (1 = bậc mặc định), luôn là bậc đã sở hữu.
function DataActions.GetDigToolTier(player: Player, toolId: string): number?
	local data = DataService.GetData(player)
	if data == nil or DigToolConfig.Tracks[toolId] == nil then
		return nil
	end
	local tiers = data.DigTools or {}
	local equipped = DigToolConfig.ClampTier(toolId, tiers[toolId])
	return if ownsDigTier(data, toolId, equipped) then equipped else DigToolConfig.MinTier
end

-- Đã sở hữu đúng bậc máy dò / xẻng này chưa (bậc 1 luôn có).
function DataActions.OwnsDigToolTier(player: Player, toolId: string, tierIndex: number): boolean
	local data = DataService.GetData(player)
	if data == nil or DigToolConfig.GetTier(toolId, tierIndex) == nil then
		return false
	end
	return ownsDigTier(data, toolId, tierIndex)
end

-- Mua một bậc máy dò / xẻng bằng coins (chỉ mở khoá đúng bậc đó), tự trang bị bậc mới.
function DataActions.TryBuyDigToolTier(player: Player, toolId: string, tierIndex: number): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local tier = DigToolConfig.GetTier(toolId, tierIndex)
	if tier == nil then
		return false, "InvalidRequest"
	end
	if ownsDigTier(data, toolId, tierIndex) then
		return false, "AlreadyOwned"
	end
	if data.Coins < tier.CoinPrice then
		return false, "NotEnoughCoins"
	end
	data.Coins = math.floor(data.Coins - tier.CoinPrice)
	unlockDigTier(data, toolId, tierIndex)
	LeaderboardService.SetCoins(player, data.Coins)
	notifyChanged(player)
	return true
end

-- Cấp đúng một bậc máy dò / xẻng cho giao dịch Robux, ghi PurchaseId để không cấp trùng.
function DataActions.TryGrantDigToolTier(
	player: Player,
	toolId: string,
	tierIndex: number,
	purchaseId: string
): (boolean, string?)
	if DigToolConfig.GetTier(toolId, tierIndex) == nil or not isValidString(purchaseId) then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if table.find(data.ProcessedPurchases, purchaseId) then
		return true
	end
	if not ownsDigTier(data, toolId, tierIndex) then
		unlockDigTier(data, toolId, tierIndex)
	end
	recordPurchase(data, purchaseId)
	notifyChanged(player)
	return true
end

-- Trang bị một bậc máy dò / xẻng đã sở hữu.
function DataActions.TryEquipDigToolTier(player: Player, toolId: string, tierIndex: number): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if DigToolConfig.GetTier(toolId, tierIndex) == nil then
		return false, "InvalidRequest"
	end
	if not ownsDigTier(data, toolId, tierIndex) then
		return false, "NotOwned"
	end
	equipDigTier(data, toolId, tierIndex)
	notifyChanged(player)
	return true
end

local function getForgeTable(data: any, fieldName: string): { [string]: any }
	if type(data[fieldName]) ~= "table" then
		data[fieldName] = {}
	end
	return data[fieldName]
end

local function getOwnedForgeTiers(data: any, trackId: string): { number }
	local ownedTiers = getForgeTable(data, "OwnedForgeTiers")
	if type(ownedTiers[trackId]) ~= "table" then
		ownedTiers[trackId] = { ForgeUpgradeConfig.MinTier }
	end
	return ownedTiers[trackId]
end

local function ownsForgeTier(data: any, trackId: string, tierIndex: number): boolean
	return tierIndex == ForgeUpgradeConfig.MinTier
		or table.find(getOwnedForgeTiers(data, trackId), tierIndex) ~= nil
end

local function unlockForgeTier(data: any, trackId: string, tierIndex: number)
	local owned = getOwnedForgeTiers(data, trackId)
	if table.find(owned, tierIndex) == nil then
		table.insert(owned, tierIndex)
		table.sort(owned)
	end
	getForgeTable(data, "ForgeSkins")[trackId] = tierIndex
end

-- Đã sở hữu đúng bậc đe / búa này chưa (bậc 1 luôn có).
function DataActions.OwnsForgeToolTier(player: Player, trackId: string, tierIndex: number): boolean
	local data = DataService.GetData(player)
	if data == nil or ForgeUpgradeConfig.GetTier(trackId, tierIndex) == nil then
		return false
	end
	return ownsForgeTier(data, trackId, tierIndex)
end

-- Bậc đe / búa đã sở hữu có may mắn cao nhất (1 = bậc mặc định).
function DataActions.GetBestForgeToolTier(player: Player, trackId: string): number?
	local data = DataService.GetData(player)
	if data == nil or ForgeUpgradeConfig.Tracks[trackId] == nil then
		return nil
	end
	local best, bestLuck = ForgeUpgradeConfig.MinTier, -math.huge
	for _, tierIndex in getOwnedForgeTiers(data, trackId) do
		local tier = ForgeUpgradeConfig.GetTier(trackId, tierIndex)
		if tier and tier.Luck > bestLuck then
			best, bestLuck = tierIndex, tier.Luck
		end
	end
	return best
end

-- Bậc texture đe / búa đang dùng, phải là bậc đã sở hữu.
function DataActions.GetForgeSkin(player: Player, trackId: string): number?
	local data = DataService.GetData(player)
	if data == nil or ForgeUpgradeConfig.Tracks[trackId] == nil then
		return nil
	end
	local skin = ForgeUpgradeConfig.ClampTier(trackId, getForgeTable(data, "ForgeSkins")[trackId])
	return if ownsForgeTier(data, trackId, skin) then skin else ForgeUpgradeConfig.MinTier
end

-- Mua một bậc đe / búa bằng coins (chỉ mở khoá đúng bậc đó), tự đổi texture sang bậc mới.
function DataActions.TryBuyForgeToolTier(player: Player, trackId: string, tierIndex: number): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local tier = ForgeUpgradeConfig.GetTier(trackId, tierIndex)
	if tier == nil then
		return false, "InvalidRequest"
	end
	if ownsForgeTier(data, trackId, tierIndex) then
		return false, "AlreadyOwned"
	end
	if data.Coins < tier.CoinPrice then
		return false, "NotEnoughCoins"
	end
	data.Coins = math.floor(data.Coins - tier.CoinPrice)
	unlockForgeTier(data, trackId, tierIndex)
	LeaderboardService.SetCoins(player, data.Coins)
	notifyChanged(player)
	return true
end

-- Cấp đúng một bậc đe / búa cho giao dịch Robux, ghi PurchaseId để không cấp trùng.
function DataActions.TryGrantForgeToolTier(
	player: Player,
	trackId: string,
	tierIndex: number,
	purchaseId: string
): (boolean, string?)
	if ForgeUpgradeConfig.GetTier(trackId, tierIndex) == nil or not isValidString(purchaseId) then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if table.find(data.ProcessedPurchases, purchaseId) then
		return true
	end
	if not ownsForgeTier(data, trackId, tierIndex) then
		unlockForgeTier(data, trackId, tierIndex)
	end
	recordPurchase(data, purchaseId)
	notifyChanged(player)
	return true
end

-- Chọn texture đe / búa trong các bậc đã sở hữu.
function DataActions.TrySetForgeSkin(player: Player, trackId: string, tierIndex: number): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if ForgeUpgradeConfig.GetTier(trackId, tierIndex) == nil then
		return false, "InvalidRequest"
	end
	if not ownsForgeTier(data, trackId, tierIndex) then
		return false, "NotOwned"
	end
	getForgeTable(data, "ForgeSkins")[trackId] = tierIndex
	notifyChanged(player)
	return true
end

-- Cộng quặng / vật phẩm cho giao dịch Robux, ghi PurchaseId để không cộng trùng.
function DataActions.TryGrantPurchasedItem(
	player: Player,
	itemId: string,
	amount: number,
	purchaseId: string
): (boolean, string?)
	if not isValidItemId(itemId) or not isValidCount(amount, 1, math.huge) or not isValidString(purchaseId) then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if table.find(data.ProcessedPurchases, purchaseId) then
		return true
	end
	data.Items[itemId] = (data.Items[itemId] or 0) + amount
	recordPurchase(data, purchaseId)
	notifyChanged(player)
	return true
end

-- Cộng 1 ô Loadout cho giao dịch Robux, ghi PurchaseId để không cộng trùng.
function DataActions.TryGrantLoadoutSlot(player: Player, purchaseId: string): (boolean, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if not isValidString(purchaseId) then
		return false, "InvalidRequest"
	end
	if table.find(data.ProcessedPurchases, purchaseId) then
		return true
	end
	local slots = getLoadoutSlots(data)
	if PlotLevel.IsMax(slots) then
		return false, "MaxLevel"
	end
	data.Capacity.Loadout = slots + 1
	recordPurchase(data, purchaseId)
	notifyChanged(player)
	return true
end

-- Nâng sức chứa kho vũ khí lên slots cho giao dịch Robux, ghi PurchaseId để không cấp trùng.
function DataActions.TryGrantStorageSlots(player: Player, slots: number, purchaseId: string): (boolean, string?)
	if not isValidCount(slots, 1, math.huge) or not isValidString(purchaseId) then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if table.find(data.ProcessedPurchases, purchaseId) then
		return true
	end
	data.Capacity.Items = math.max(data.Capacity.Items, math.floor(slots))
	recordPurchase(data, purchaseId)
	notifyChanged(player)
	return true
end

-- Sức chứa kho vũ khí hiện tại.
function DataActions.GetStorageSlots(player: Player): number?
	local data = DataService.GetData(player)
	return if data then data.Capacity.Items else nil
end

-- Cộng coins cho giao dịch Robux (gói tiền), ghi PurchaseId để không cộng trùng.
function DataActions.TryGrantPurchasedCoins(player: Player, amount: number, purchaseId: string): (boolean, string?)
	if not isValidCount(amount, 1, math.huge) or not isValidString(purchaseId) then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if table.find(data.ProcessedPurchases, purchaseId) then
		return true
	end
	data.Coins = clampCoins(data.Coins + amount)
	recordPurchase(data, purchaseId)
	LeaderboardService.SetCoins(player, data.Coins)
	notifyChanged(player)
	return true
end

-- Ghi PurchaseId vào dữ liệu người mua (dùng khi quà được cấp cho người khác).
function DataActions.TryRecordPurchase(player: Player, purchaseId: string): (boolean, string?)
	if not isValidString(purchaseId) then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if not table.find(data.ProcessedPurchases, purchaseId) then
		recordPurchase(data, purchaseId)
	end
	return true
end

-- Cấp pass được tặng, ghi PurchaseId để không cấp trùng.
function DataActions.TryGrantGiftedPass(player: Player, passId: string, purchaseId: string): (boolean, string?)
	if not isValidString(passId) or not isValidString(purchaseId) then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if table.find(data.ProcessedPurchases, purchaseId) then
		return true
	end
	if type(data.GiftedPasses) ~= "table" then
		data.GiftedPasses = {}
	end
	data.GiftedPasses[passId] = true
	recordPurchase(data, purchaseId)
	notifyChanged(player)
	return true
end

local function getSpinState(data: any): { Tokens: number, LastFreeAt: number }
	if type(data.Spin) ~= "table" then
		data.Spin = { Tokens = 0, LastFreeAt = 0 }
	end
	return data.Spin
end

local function addSpinTokens(data: any, amount: number): (boolean, string?)
	local spin = getSpinState(data)
	local tokens = math.floor(spin.Tokens or 0)
	if tokens + amount > SpinConfig.MaxTokens then
		return false, "MaxTokens"
	end
	spin.Tokens = tokens + amount
	return true
end

-- Cộng lượt quay (trúng ô +1 Spin).
function DataActions.TryAddSpinTokens(player: Player, amount: number): (boolean, string?)
	if not isValidCount(amount, 1, SpinConfig.MaxTokens) then
		return false, "InvalidAmount"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local ok, reason = addSpinTokens(data, amount)
	if ok then
		notifyChanged(player)
	end
	return ok, reason
end

-- Cộng lượt quay cho giao dịch Robux, ghi PurchaseId để không cộng trùng.
function DataActions.TryGrantSpinTokens(player: Player, amount: number, purchaseId: string): (boolean, string?)
	if not isValidCount(amount, 1, SpinConfig.MaxTokens) or not isValidString(purchaseId) then
		return false, "InvalidRequest"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if table.find(data.ProcessedPurchases, purchaseId) then
		return true
	end
	local ok, reason = addSpinTokens(data, amount)
	if not ok then
		return false, reason
	end
	recordPurchase(data, purchaseId)
	notifyChanged(player)
	return true
end

-- Thời điểm (epoch) có lượt quay free kế tiếp.
function DataActions.GetNextFreeSpinAt(player: Player): number?
	local data = DataService.GetData(player)
	if data == nil then
		return nil
	end
	return (getSpinState(data).LastFreeAt or 0) + SpinConfig.FreeSpinCooldown
end

-- Dùng 1 lượt quay: ưu tiên lượt free mỗi ngày, sau đó tới lượt đã có. Trả về (ok, reason, isFree).
function DataActions.TryConsumeSpin(player: Player, now: number): (boolean, string?, boolean)
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded", false
	end
	local spin = getSpinState(data)
	if now >= (spin.LastFreeAt or 0) + SpinConfig.FreeSpinCooldown then
		spin.LastFreeAt = math.floor(now)
		notifyChanged(player)
		return true, nil, true
	end
	if (spin.Tokens or 0) < 1 then
		return false, "NoSpins", false
	end
	spin.Tokens = math.floor(spin.Tokens - 1)
	notifyChanged(player)
	return true, nil, false
end

-- Cộng Robux đã chi cho bảng xếp hạng Donated. Gọi sau khi giao dịch đã được cấp quà.
function DataActions.TryAddRobuxSpent(player: Player, amount: number): (boolean, string?)
	if not isValidCount(amount, 1, math.huge) then
		return false, "InvalidAmount"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	data.Stats.TotalRobuxSpent += amount
	return true
end

-- Tính lại chỉ số cao nhất từ kho hiện tại (bổ sung cho dữ liệu cũ chưa có HighestWeaponIncome).
function DataActions.RefreshHighestStats(player: Player)
	local data = DataService.GetData(player)
	if data == nil then
		return
	end
	for _, weapon in data.Weapons do
		if isValidWeapon(weapon) then
			updateHighestStats(data, weapon)
		end
	end
end

-- Consume một vật phẩm dùng-một-lần (nền cho buff F8).
-- Không dùng ArmedBuffs ở đây: drug chỉ bị trừ khi kích hoạt buff thành công.
function DataActions.TryConsumeItem(player: Player, itemId: string): (boolean, string?)
	if not isValidItemId(itemId) then
		return false, "InvalidItem"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local current = data.Items[itemId] or 0
	if current < 1 then
		return false, "NotEnoughItems"
	end
	data.Items[itemId] = current - 1
	if data.Items[itemId] <= 0 then
		data.Items[itemId] = nil
	end
	notifyChanged(player)
	return true
end

-- Kích hoạt (tiêu hao) một buff đã gắn chờ dùng trong ArmedBuffs (F3.4/F8).
-- Trả về (true, nil) nếu tiêu hao thành công.
function DataActions.TryConsumeArmedBuff(player: Player, itemId: string): (boolean, string?)
	if not isValidItemId(itemId) then
		return false, "InvalidItem"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local count = data.ArmedBuffs[itemId]
	if type(count) ~= "number" or count < 1 then
		return false, "NotArmed"
	end
	data.ArmedBuffs[itemId] = if count > 1 then count - 1 else nil
	notifyChanged(player)
	return true
end

function DataActions.TryUseBuffItem(player: Player, itemId: string): (boolean, string?)
	if not isValidItemId(itemId) then
		return false, "InvalidItem"
	end
	if not isUsableBuff(itemId) then
		return false, "NotUsable"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local current = data.Items[itemId] or 0
	if current < 1 then
		return false, "NotEnoughItems"
	end
	data.Items[itemId] = if current > 1 then current - 1 else nil
	applyBuff(data, itemId, os.time())
	notifyChanged(player)
	return true
end

local function reviveWeapon(weapon: any)
	weapon.State = DataTemplate.WeaponStates.Blank
	weapon.Level = 0
	weapon.ForgePoints = 0
	weapon.Value = weapon.BaseValue
	weapon.ValueHistory = {}
	weapon.ShapeStage = nil
	weapon.ShapeStrikes = nil
	weapon.FrenzyStrikes = nil
	weapon.Mutation = nil
end

local function eraseMutation(weapon: any)
	weapon.Mutation = nil
end

local WEAPON_ITEM_EFFECTS: { [string]: (weapon: any) -> () } = {
	[WeaponItemConfig.Targets.Broken] = reviveWeapon,
	[WeaponItemConfig.Targets.Mutated] = eraseMutation,
}

function DataActions.TryUseWeaponItem(
	player: Player,
	itemId: string,
	weaponId: string
): (boolean, string?)
	local definition = WeaponItemConfig.ById[itemId]
	if definition == nil then
		return false, "InvalidItem"
	end
	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local weapon = if isValidString(weaponId) then data.Weapons[weaponId] else nil
	if weapon == nil then
		return false, "WeaponNotFound"
	end
	local current = data.Items[itemId] or 0
	if current < 1 then
		return false, "NotEnoughItems"
	end
	local isTarget, reason = WeaponItemTarget.Check(itemId, weapon, isWeaponEquipped(data, weaponId))
	if not isTarget then
		return false, reason
	end
	data.Items[itemId] = if current > 1 then current - 1 else nil
	WEAPON_ITEM_EFFECTS[definition.Target](weapon)
	recordIndex(data, weapon)
	notifyChanged(player)
	return true
end

function DataActions.PauseTimedBuffs(player: Player)
	local data = DataService.GetData(player)
	if data == nil then
		return
	end
	local now = os.time()
	for itemId, expiresAt in data.ActiveBuffs do
		local remaining = math.floor(expiresAt - now)
		if remaining > 0 then
			data.PausedBuffs[itemId] = (data.PausedBuffs[itemId] or 0) + remaining
		end
	end
	table.clear(data.ActiveBuffs)
end

function DataActions.ResumeTimedBuffs(player: Player)
	local data = DataService.GetData(player)
	if data == nil or next(data.PausedBuffs) == nil then
		return
	end
	local now = os.time()
	for itemId, remaining in data.PausedBuffs do
		local current = data.ActiveBuffs[itemId] or 0
		data.ActiveBuffs[itemId] = math.max(current, now) + remaining
	end
	table.clear(data.PausedBuffs)
	notifyChanged(player)
end

local function isTutorialStepId(stepId: any): boolean
	if not isValidString(stepId) then
		return false
	end
	for _, step in TutorialConfig.Steps do
		if step.Id == stepId then
			return true
		end
	end
	return false
end

local function getOpenTutorial(player: Player): (any?, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return nil, "NotLoaded"
	end
	local tutorial = data.Tutorial
	if type(tutorial) ~= "table" then
		return nil, "InvalidData"
	end
	if tutorial.IsComplete == true then
		return nil, "TutorialComplete"
	end
	return tutorial, nil
end

function DataActions.TrySetTutorialStep(player: Player, stepId: string): (boolean, string?)
	if not isTutorialStepId(stepId) then
		return false, "InvalidStep"
	end
	local tutorial, reason = getOpenTutorial(player)
	if tutorial == nil then
		return false, reason
	end
	tutorial.StepId = stepId
	tutorial.DigCount = 0
	notifyChanged(player)
	return true
end

function DataActions.TryAddTutorialDig(player: Player): (boolean, string?)
	local tutorial, reason = getOpenTutorial(player)
	if tutorial == nil then
		return false, reason
	end
	local current = if type(tutorial.DigCount) == "number" then tutorial.DigCount else 0
	tutorial.DigCount = math.clamp(math.floor(current) + 1, 0, TutorialConfig.DigTarget)
	notifyChanged(player)
	return true
end

function DataActions.TryCompleteTutorial(player: Player): (boolean, string?)
	local tutorial, reason = getOpenTutorial(player)
	if tutorial == nil then
		return false, reason
	end
	tutorial.IsComplete = true
	tutorial.DigCount = 0
	notifyChanged(player)
	return true
end

function DataActions.OnDataChanged(callback: (Player) -> ())
	table.insert(changedCallbacks, callback)
end

function DataActions.Init()
	-- DataActions không kết nối Remote hay vòng lặp; chỉ cần sẵn sàng
	-- sau khi DataService đã Init trong Bootstrap.
end

return DataActions
