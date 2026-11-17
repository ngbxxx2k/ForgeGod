--!strict
--[[
	ShopRestockSystem
	Trách nhiệm: sinh tồn kho shop theo chu kỳ 5 phút một cách deterministic
	(F2.4, F2.5): mọi server dùng mốc thời gian làm seed nên cho cùng kết quả,
	không cần lưu DataStore. Phát hiện đổi chu kỳ rồi đẩy stock vào ShopService.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(shared:WaitForChild("Config"):WaitForChild("ShopConfig"))

local ShopRestockTable = require(
	ServerStorage:WaitForChild("LootTables"):WaitForChild("ShopRestockTable")
)

local ShopService = require(script.Parent.Parent.Services.ShopService)

-- Tần suất kiểm tra đổi chu kỳ (giây). 1 giây đủ mịn để restock đúng lúc.
local POLL_INTERVAL = 1

local ShopRestockSystem = {}

local isInitialized = false

local currentCycle = -1

-- Mốc chu kỳ hiện tại: chia đồng hồ thật theo chu kỳ restock (file 04).
local function getCycleIndex(): number
	return math.floor(os.time() / ShopConfig.RestockInterval)
end

-- Sinh tồn kho cho một chu kỳ từ seed = mốc chu kỳ, nên mọi server
-- cho cùng kết quả (F2.4). Quặng hiếm khó xuất hiện hơn (F2.5).
local function rollStock(cycleIndex: number): { [string]: number }
	local rng = Random.new(cycleIndex)
	local entries = ShopRestockTable.Entries

	-- Duyệt theo thứ tự khoá đã sắp xếp để kết quả không phụ thuộc
	-- thứ tự iteration của table giữa các phiên bản runtime.
	local ids = {}
	for id in entries :: any do
		table.insert(ids, id)
	end
	table.sort(ids)

	local stock: { [string]: number } = {}
	for _, id in ids do
		local entry = entries[id]
		if rng:NextNumber() < entry.AppearanceRate then
			stock[id] = rng:NextInteger(entry.MinAmount, entry.MaxAmount)
		end
	end
	return stock
end

-- Nếu đã sang chu kỳ mới thì restock và broadcast, ngược lại không làm gì.
local function restockIfNeeded()
	local cycle = getCycleIndex()
	if cycle == currentCycle then
		return
	end
	currentCycle = cycle
	ShopService.SetStock(rollStock(cycle), cycle)
end

function ShopRestockSystem.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	-- Restock ngay cho chu kỳ hiện tại khi server khởi động.
	restockIfNeeded()

	-- Vòng lặp nền nhẹ: chỉ kiểm tra mốc chu kỳ mỗi giây (F2.4).
	task.spawn(function()
		while true do
			task.wait(POLL_INTERVAL)
			restockIfNeeded()
		end
	end)
end

return ShopRestockSystem
