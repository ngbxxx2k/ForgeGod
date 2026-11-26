--!strict
--[[
	ShopRestockSystem
	Trách nhiệm: sinh tồn kho shop theo chu kỳ 5 phút một cách deterministic
	(F2.4, F2.5): mọi server dùng mốc thời gian làm seed nên cho cùng kết quả,
	không cần lưu DataStore. Phát hiện đổi chu kỳ rồi đẩy stock vào ShopService.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(shared:WaitForChild("Config"):WaitForChild("ShopConfig"))

local ShopStockRoller = require(script.Parent.Parent.Internal.ShopStockRoller)
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

-- Nếu đã sang chu kỳ mới thì restock và broadcast, ngược lại không làm gì.
local function restockIfNeeded()
	local cycle = getCycleIndex()
	if cycle == currentCycle then
		return
	end
	currentCycle = cycle
	ShopService.SetStock(ShopStockRoller.Roll(Random.new(cycle)), cycle)
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
