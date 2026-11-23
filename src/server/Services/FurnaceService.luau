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
local StationConfig = require(shared:WaitForChild("Config"):WaitForChild("StationConfig"))
local WeaponCatalog = require(shared:WaitForChild("Constants"):WaitForChild("WeaponCatalog"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local FriendBoostService = require(script.Parent.FriendBoostService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local StationRange = require(script.Parent.Parent.Security.StationRange)
local ScaleRoller = require(script.Parent.Parent.Internal.ScaleRoller)

local lootTables = game:GetService("ServerStorage"):WaitForChild("LootTables")
local SmeltRarityTable = require(lootTables:WaitForChild("SmeltRarityTable"))
local OrePointsTable = require(lootTables:WaitForChild("OrePointsTable"))

-- Random tạo một lần duy nhất cho module (quy tắc file 04).
local rng = Random.new()

local FurnaceService = {}

local ODDS_RATE_LIMIT_KEY = "SmeltOdds"
local PERCENT_SCALE = 100
local PERCENT_PRECISION = 100
local MAX_REQUEST_ID = 2 ^ 31

export type SmeltOdd = {
	Rarity: string,
	Percent: number,
}

local isInitialized = false
local notifySmeltResult: RemoteEvent? = nil
local notifySmeltOdds: RemoteEvent? = nil

-- Thứ tự độ hiếm dùng chung cho roll, khớp với thứ tự trọng số trong LootTable.
local RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

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

local function getWeights(totalPoints: number, luckShift: number): { number }
	local band = findBand(totalPoints)
	assert(band ~= nil, "Tổng điểm luôn nằm trong một khoảng khi công thức hợp lệ")

	local weights = table.clone(band.Weights)
	if luckShift > 0 then
		for i, weight in weights do
			weights[i] = weight * (1 + luckShift) ^ (i - 1)
		end
	end
	return weights
end

local function sumWeights(weights: { number }): number
	local totalWeight = 0
	for _, weight in weights do
		totalWeight += weight
	end
	return totalWeight
end

local function getLuckShift(player: Player, data: any): number
	local potionShift = BuffEffects.GetBonus(data, BuffConfig.EffectIds.SmeltLuckBonus, os.time())
	return potionShift + FriendBoostService.GetLuck(player)
end

-- Roll độ hiếm theo trọng số của khoảng điểm. Nếu có buff may mắn (F3.4),
-- nhân trọng số độ hiếm i với (1 + luckShift)^(i - 1) rồi mới roll.
local function rollRarity(totalPoints: number, luckShift: number): string
	local weights = getWeights(totalPoints, luckShift)
	local totalWeight = sumWeights(weights)

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

	local rarity = rollRarity(totalPoints, getLuckShift(player, data))
	local weaponType = rollWeaponType(rarity)
	local scale = ScaleRoller.Roll(rng)

	local blankValue = math.floor(FurnaceConfig.BaseValues[rarity] * scale)

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
		Scale = scale,
		BaseValue = blankValue,
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
		WeaponTypeId = weaponType.Id,
		Scale = scale,
		Value = weapon.Value,
	}

	return true, nil, summary
end

function FurnaceService.GetOdds(player: Player, ores: any): (boolean, string?, { SmeltOdd }?)
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
	local weights = getWeights(totalPoints, getLuckShift(player, data))
	local totalWeight = sumWeights(weights)
	local odds: { SmeltOdd } = {}
	for i, weight in weights do
		local percent = if totalWeight > 0 then weight / totalWeight * PERCENT_SCALE else 0
		local rounded = math.floor(percent * PERCENT_PRECISION + 0.5) / PERCENT_PRECISION
		table.insert(odds, { Rarity = RARITY_ORDER[i], Percent = rounded })
	end
	return true, nil, odds
end

local function isValidRequestId(requestId: any): boolean
	return type(requestId) == "number" and requestId == requestId and requestId % 1 == 0
		and requestId >= 0 and requestId < MAX_REQUEST_ID
end

local function onRequestSmeltOdds(player: Player, requestId: any, ores: any)
	local remote = notifySmeltOdds
	if remote == nil or not isValidRequestId(requestId) then
		return
	end
	if not DataService.IsLoaded(player) then
		remote:FireClient(player, requestId, false, "NotLoaded", nil)
		return
	end
	if not RateLimiter.Check(player, ODDS_RATE_LIMIT_KEY) then
		remote:FireClient(player, requestId, false, "RateLimited", nil)
		return
	end
	local ok, reason, odds = FurnaceService.GetOdds(player, ores)
	remote:FireClient(player, requestId, ok, reason, odds)
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

	if not StationRange.IsNear(player, StationConfig.FurnaceModelName) then
		if notifySmeltResult ~= nil then
			notifySmeltResult:FireClient(player, false, "TooFar", nil)
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

	local requestSmeltOdds = Instance.new("RemoteEvent")
	requestSmeltOdds.Name = RemoteNames.RequestSmeltOdds
	requestSmeltOdds.Parent = remotesFolder

	local oddsRemote = Instance.new("RemoteEvent")
	oddsRemote.Name = RemoteNames.NotifySmeltOdds
	oddsRemote.Parent = remotesFolder
	notifySmeltOdds = oddsRemote

	requestSmeltOdds.OnServerEvent:Connect(onRequestSmeltOdds)
end

return FurnaceService
