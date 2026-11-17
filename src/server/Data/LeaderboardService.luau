--!strict
--[[
	LeaderboardService
	Trách nhiệm: hiển thị số liệu người chơi lên bảng người chơi (leaderstats).
	Sau này (F9.2) sẽ thêm gửi điểm lên bảng xếp hạng toàn game qua OrderedDataStore.
]]

local Players = game:GetService("Players")

-- Tên thư mục và stat hiển thị trong danh sách người chơi.
local STAT_FOLDER_NAME = "leaderstats"
local COINS_STAT_NAME = "Coins"

local LeaderboardService = {}

local isInitialized = false

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

	folder.Parent = player
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
