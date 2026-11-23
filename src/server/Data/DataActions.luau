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
local PlotLevel = require(sharedFolder:WaitForChild("Utils"):WaitForChild("PlotLevel"))
local WeaponIncome = require(sharedFolder:WaitForChild("Utils"):WaitForChild("WeaponIncome"))

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
	data.Coins = math.floor(data.Coins + amount)
	data.Stats.TotalCoinsEarned += amount
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
	data.Coins = math.floor(data.Coins + price)
	data.Stats.TotalCoinsEarned += price
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
	data.Coins = math.floor(data.Coins + total)
	data.Stats.TotalCoinsEarned += total
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
	data.Coins = math.floor(data.Coins + price)
	data.Stats.TotalCoinsEarned += price
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

function DataActions.OnDataChanged(callback: (Player) -> ())
	table.insert(changedCallbacks, callback)
end

function DataActions.Init()
	-- DataActions không kết nối Remote hay vòng lặp; chỉ cần sẵn sàng
	-- sau khi DataService đã Init trong Bootstrap.
end

return DataActions
