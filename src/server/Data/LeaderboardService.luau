--!strict
--[[
	LeaderboardService
	Trách nhiệm: hiển thị số liệu người chơi lên bảng người chơi (leaderstats)
	và đọc/ghi điểm bảng xếp hạng toàn game qua OrderedDataStore (nơi duy nhất).
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local EquipMessages = require(shared:WaitForChild("Constants"):WaitForChild("EquipMessages"))
local NumberFormat = require(shared:WaitForChild("Utils"):WaitForChild("NumberFormat"))

local LeaderboardScore = require(script.Parent.Parent.Internal.LeaderboardScore)

-- Tên thư mục và stat hiển thị trong danh sách người chơi.
local STAT_FOLDER_NAME = "leaderstats"
local COINS_STAT_NAME = "Coins"
local INCOME_STAT_NAME = "Coins/s"

-- Tên OrderedDataStore của từng bảng: tiền tố .. boardId .. hậu tố. Đổi hậu tố để làm lại bảng sạch.
local ORDERED_STORE_PREFIX = "forgeGod_Leaderboard_"
local ORDERED_STORE_SUFFIX = "_v2"
local MAX_PAGE_SIZE = 100

export type RawEntry = {
	UserId: number,
	Score: number,
}

local LeaderboardService = {}

local isInitialized = false
local orderedStores: { [string]: OrderedDataStore } = {}

local function getOrderedStore(boardId: string): OrderedDataStore
	local store = orderedStores[boardId]
	if store == nil then
		store = DataStoreService:GetOrderedDataStore(ORDERED_STORE_PREFIX .. boardId .. ORDERED_STORE_SUFFIX)
		orderedStores[boardId] = store
	end
	return store :: OrderedDataStore
end

local function parseEntry(item: any): RawEntry?
	local userId = tonumber(item.key)
	if userId == nil or type(item.value) ~= "number" then
		return nil
	end
	return { UserId = userId, Score = LeaderboardScore.Decode(item.value) }
end

-- Gửi điểm của một người chơi lên bảng toàn game. Có yield (DataStore).
function LeaderboardService.Submit(boardId: string, userId: number, value: number): boolean
	local score = LeaderboardScore.Encode(value)
	if score <= 0 then
		return false
	end
	local ok, err = pcall(function()
		getOrderedStore(boardId):SetAsync(tostring(userId), score)
	end)
	if not ok then
		warn("[LeaderboardService] Submit failed:", boardId, userId, err)
	end
	return ok
end

-- Lấy top người chơi của một bảng, điểm cao nhất trước. nil nếu DataStore lỗi. Có yield.
function LeaderboardService.FetchTop(boardId: string, count: number): { RawEntry }?
	local ok, result = pcall(function()
		local pages = getOrderedStore(boardId):GetSortedAsync(false, math.min(count, MAX_PAGE_SIZE))
		return pages:GetCurrentPage()
	end)
	if not ok then
		warn("[LeaderboardService] Fetch failed:", boardId, result)
		return nil
	end
	local entries: { RawEntry } = {}
	for _, item in result do
		local entry = parseEntry(item)
		if entry then
			table.insert(entries, entry)
		end
	end
	return entries
end

-- Gắn leaderstats cho người chơi với số coin ban đầu.
-- Gọi lại được nếu cần (hàm tự xoá bản cũ trước khi tạo mới).
function LeaderboardService.AttachStats(player: Player, initialCoins: number)
	local existing = player:FindFirstChild(STAT_FOLDER_NAME)
	if existing ~= nil then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = STAT_FOLDER_NAME

	local coins = Instance.new("IntValue")
	coins.Name = COINS_STAT_NAME
	coins.Value = initialCoins
	coins.Parent = folder

	local income = Instance.new("StringValue")
	income.Name = INCOME_STAT_NAME
	income.Value = string.format(EquipMessages.IncomeFormat, NumberFormat.Abbreviate(0))
	income.Parent = folder

	folder.Parent = player
end

function LeaderboardService.SetIncome(player: Player, perSecond: number)
	local folder = player:FindFirstChild(STAT_FOLDER_NAME)
	local income = folder and folder:FindFirstChild(INCOME_STAT_NAME)
	if income == nil or not income:IsA("StringValue") then
		return
	end
	local text = string.format(EquipMessages.IncomeFormat, NumberFormat.Abbreviate(perSecond))
	if income.Value ~= text then
		income.Value = text
	end
end

-- Cập nhật số coin hiển thị. Không làm gì nếu người chơi đã rời game.
function LeaderboardService.SetCoins(player: Player, amount: number)
	local folder = player:FindFirstChild(STAT_FOLDER_NAME)
	if folder == nil then
		return
	end
	local coins = folder:FindFirstChild(COINS_STAT_NAME)
	if coins ~= nil and coins:IsA("IntValue") then
		coins.Value = amount
	end
end

function LeaderboardService.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	-- Leaderstats được gắn khi profile tải xong (DataService gọi AttachStats).
	-- Không cần lắng nghe PlayerAdded ở đây.
end

return LeaderboardService
