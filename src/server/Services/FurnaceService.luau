--!strict
--[[
	FurnaceService
	Trách nhiệm: xử lý yêu cầu nấu quặng tạo phôi (F3): kiểm tra công thức,
	roll độ hiếm theo tổng điểm, chọn loại vũ khí, tính giá phôi, lưu phôi
	vào kho người chơi. Mọi random chạy trên server.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local BuffConfig = require(shared:WaitForChild("Config"):WaitForChild("BuffConfig"))
local BuffEffects = require(shared:WaitForChild("Utils"):WaitForChild("BuffEffects"))
local FurnaceConfig = require(shared:WaitForChild("Config"):WaitForChild("FurnaceConfig"))
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local WeaponCatalog = require(shared:WaitForChild("Constants"):WaitForChild("WeaponCatalog"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local FriendBoostService = require(script.Parent.FriendBoostService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)

local lootTables = game:GetService("ServerStorage"):WaitForChild("LootTables")
local SmeltRarityTable = require(lootTables:WaitForChild("SmeltRarityTable"))
local OrePointsTable = require(lootTables:WaitForChild("OrePointsTable"))

-- Random tạo một lần duy nhất cho module (quy tắc file 04).
local rng = Random.new()

local FurnaceService = {}

local isInitialized = false
local notifySmeltResult: RemoteEvent? = nil

-- Thứ tự độ hiếm dùng chung cho roll, khớp với thứ tự trọng số trong LootTable.
local RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

-- Kiểm tra bảng quặng client gửi: phải là table, mọi khoá là quặng hợp lệ,
-- mọi giá là số nguyên dương, tổng đúng RecipeSize (F3.2).
-- Trả về (totalPoints: number?, reason: string?).
local function validateRecipe(ores: any): (number?, string?)
	if type(ores) ~= "table" then
		return nil, "InvalidRequest"
	end

	local totalPoints = 0
	local totalAmount = 0

	for oreId, amount in ores :: any do
		if type(oreId) ~= "string" or OrePointsTable.Points[oreId] == nil then
			return nil, "UnknownOre"
		end
		if type(amount) ~= "number" or amount ~= amount or amount == math.huge then
			return nil, "InvalidRequest"
		end
		if amount % 1 ~= 0 or amount < 1 then
			return nil, "InvalidRequest"
		end
		totalPoints += OrePointsTable.Points[oreId] * amount
		totalAmount += amount
	end

	if totalAmount ~= FurnaceConfig.RecipeSize then
		return nil, "InvalidRecipe"
	end

	return totalPoints, nil
end

-- Tìm khoảng điểm tương ứng trong bảng tỉ lệ (F3.2).
local function findBand(totalPoints: number): any?
	for _, band in SmeltRarityTable.Bands do
		if totalPoints >= band.MinPoints and totalPoints <= band.MaxPoints then
			return band
		end
	end
	return nil
end

-- Roll độ hiếm theo trọng số của khoảng điểm. Nếu có buff may mắn (F3.4),
-- nhân trọng số độ hiếm i với (1 + luckShift)^(i - 1) rồi mới roll.
local function rollRarity(totalPoints: number, luckShift: number): string
	local band = findBand(totalPoints)
	assert(band ~= nil, "Tổng điểm luôn nằm trong một khoảng khi công thức hợp lệ")

	local weights = table.clone(band.Weights)
	if luckShift > 0 then
		for i, weight in weights do
			weights[i] = weight * (1 + luckShift) ^ (i - 1)
		end
	end

	local totalWeight = 0
	for _, weight in weights do
		totalWeight += weight
	end

	-- Weighted roll: cộng dồn trọng số rồi rơi vào ô tương ứng.
	local roll = rng:NextNumber(0, totalWeight)
	local cumulative = 0
	for i, weight in weights do
		cumulative += weight
		if roll < cumulative then
			return RARITY_ORDER[i]
		end
	end
	return RARITY_ORDER[#RARITY_ORDER]
end

-- Chọn ngẫu nhiên 1 trong 5 loại vũ khí của độ hiếm đã roll (F3.5).
local function rollWeaponType(rarity: string): any
	local list = WeaponCatalog.Types[rarity]
	return list[rng:NextInteger(1, #list)]
end

-- Kiểm tra người chơi sở hữu đủ từng loại quặng trong công thức.
local function hasEnoughOres(data: any, ores: { [string]: number }): boolean
	for oreId, amount in ores do
		if (data.Items[oreId] or 0) < amount then
			return false
		end
	end
	return true
end

-- Nấu phôi: kiểm tra mọi thứ TRƯỚC, không có task.wait xen giữa (file 04).
-- Trả về (ok, reason, weapon?) với weapon là bản tóm tắt phôi gửi client.
function FurnaceService.Smelt(player: Player, ores: any): (boolean, string?, any?)
	if not DataService.IsLoaded(player) then
		return false, "NotLoaded", nil
	end

	local totalPoints, reason = validateRecipe(ores)
	if totalPoints == nil then
		return false, reason, nil
	end

	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded", nil
	end

	if not hasEnoughOres(data, ores) then
		return false, "NotEnoughOres", nil
	end

	local potionShift = BuffEffects.GetBonus(data, BuffConfig.EffectIds.SmeltLuckBonus, os.time())
	local rarity = rollRarity(totalPoints, potionShift + FriendBoostService.GetLuck(player))
	local weaponType = rollWeaponType(rarity)
	local multiplier = rng:NextNumber(
		FurnaceConfig.MinValueMultiplier,
		FurnaceConfig.MaxValueMultiplier
	)

	local baseValue = FurnaceConfig.BaseValues[rarity]
	local blankValue = math.floor(baseValue * multiplier)

	-- Dựng WeaponData phôi theo cấu trúc DataTemplate.
	-- Tier là bậc độ hiếm (1..5), WeaponType lưu mã loại trong WeaponCatalog.
	local tier = table.find(RARITY_ORDER, rarity) or 1
	local weapon = {
		-- Id: tổ hợp random + os.clock để tránh trùng giữa các lần nấu.
		Id = string.format("%.14f-%d", rng:NextNumber(), os.clock() * 1000),
		Rarity = rarity,
		Tier = tier,
		WeaponType = weaponType.Id,
		State = "Blank",
		Level = 0,
		ForgePoints = 0,
		Mutation = nil,
		BaseValue = baseValue,
		Value = blankValue,
		Recipe = table.clone(ores),
		CreatedAt = os.time(),
	}

	local okAdd, reasonAdd = DataActions.TryAddWeapon(player, weapon)
	if not okAdd then
		-- Thêm phôi thất bại (kho đầy...): chưa trừ quặng nên không mất gì.
		return false, reasonAdd, nil
	end

	-- Trừ từng loại quặng SAU khi phôi đã vào kho. Nếu trừ thất bại ở
	-- giữa chừng (dữ liệu đổi bất thường) thì hoàn phôi để không mất quặng.
	for oreId, amount in ores :: any do
		local okRemove, reasonRemove = DataActions.TryRemoveItem(player, oreId, amount)
		if not okRemove then
			DataActions.TryRemoveWeapon(player, weapon.Id)
			return false, reasonRemove or "NotEnoughOres", nil
		end
	end

	-- Tóm tắt phôi gửi client (không gửi bảng tỉ lệ - số nhạy cảm).
	local summary = {
		Id = weapon.Id,
		Rarity = rarity,
		WeaponType = weaponType.DisplayName,
		Value = weapon.Value,
	}

	return true, nil, summary
end

-- Xử lý Remote nấu phôi: rate limit rồi gọi Smelt, trả kết quả.
local function onRequestSmelt(player: Player, ores: any)
	if not DataService.IsLoaded(player) then
		if notifySmeltResult ~= nil then
			notifySmeltResult:FireClient(player, false, "NotLoaded", nil)
		end
		return
	end

	if not RateLimiter.Check(player, "Smelt") then
		if notifySmeltResult ~= nil then
			notifySmeltResult:FireClient(player, false, "RateLimited", nil)
		end
		return
	end

	local ok, reason, weapon = FurnaceService.Smelt(player, ores)
	if notifySmeltResult ~= nil then
		notifySmeltResult:FireClient(player, ok, reason, weapon)
	end
end

function FurnaceService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	local requestSmelt = Instance.new("RemoteEvent")
	requestSmelt.Name = RemoteNames.RequestSmelt
	requestSmelt.Parent = remotesFolder

	notifySmeltResult = Instance.new("RemoteEvent")
	notifySmeltResult.Name = RemoteNames.NotifySmeltResult
	notifySmeltResult.Parent = remotesFolder

	requestSmelt.OnServerEvent:Connect(onRequestSmelt)
end

return FurnaceService
