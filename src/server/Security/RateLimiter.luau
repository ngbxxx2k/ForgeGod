--!strict
--[[
	RateLimiter
	Trách nhiệm: giới hạn tần suất thao tác theo từng người chơi (chống spam
	Remote). Security thuần: không gọi Services, không chứa logic gameplay.
]]

local Players = game:GetService("Players")

-- PLACEHOLDER: ngưỡng rate limit chưa có trong doc, đang dùng giá trị tạm.
local MAX_REQUESTS_PER_WINDOW = 10
local WINDOW_SECONDS = 5
-- PLACEHOLDER: đập búa cần nhanh cho chế độ đập liên tục
local KEY_LIMITS: { [string]: { MaxRequests: number, WindowSeconds: number } } = {
	Forge = { MaxRequests = 12, WindowSeconds = 1 },
	ForgeStance = { MaxRequests = 6, WindowSeconds = 2 },
	ShopBuy = { MaxRequests = 30, WindowSeconds = 5 },
	SmeltOdds = { MaxRequests = 20, WindowSeconds = 5 },
	Dig = { MaxRequests = 4, WindowSeconds = 2 },
	Spin = { MaxRequests = 3, WindowSeconds = 2 },
	PremiumPurchase = { MaxRequests = 5, WindowSeconds = 5 },
	IndexClaim = { MaxRequests = 5, WindowSeconds = 2 },
}

local RateLimiter = {}

local isInitialized = false

-- Lịch sử dấu thời gian: [player] -> [key] -> danh sách os.clock() của các lần gọi.
local history: { [Player]: { [string]: { number } } } = {}
local lastAcceptedAt: { [Player]: { [string]: number } } = {}

-- Kiểm tra và ghi nhận một lần gọi. Trả về false nếu vượt giới hạn.
function RateLimiter.Check(player: Player, key: string): boolean
	local byKey = history[player]
	if byKey == nil then
		byKey = {}
		history[player] = byKey
	end

	local timestamps = byKey[key]
	if timestamps == nil then
		timestamps = {}
		byKey[key] = timestamps
	end

	local keyLimit = KEY_LIMITS[key]
	local maxRequests = if keyLimit then keyLimit.MaxRequests else MAX_REQUESTS_PER_WINDOW
	local windowSeconds = if keyLimit then keyLimit.WindowSeconds else WINDOW_SECONDS

	-- Dồn các dấu thời gian còn nằm trong cửa sổ về đầu danh sách.
	local now = os.clock()
	local writeIndex = 1
	for _, ts in timestamps do
		if now - ts < windowSeconds then
			timestamps[writeIndex] = ts
			writeIndex += 1
		end
	end
	-- Xoá phần đuôi thừa sau khi dồn.
	for i = #timestamps, writeIndex, -1 do
		table.remove(timestamps, i)
	end

	if #timestamps >= maxRequests then
		return false
	end

	table.insert(timestamps, now)
	return true
end

function RateLimiter.CheckInterval(player: Player, key: string, minInterval: number): boolean
	local byPlayer = lastAcceptedAt[player]
	if byPlayer == nil then
		byPlayer = {}
		lastAcceptedAt[player] = byPlayer
	end
	local now = os.clock()
	local last = byPlayer[key]
	if last ~= nil and now - last < minInterval then
		return false
	end
	byPlayer[key] = now
	return true
end

-- Xoá state khi người chơi rời để không rò rỉ bộ nhớ.
local function handlePlayerRemoving(player: Player)
	history[player] = nil
	lastAcceptedAt[player] = nil
end

function RateLimiter.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	Players.PlayerRemoving:Connect(handlePlayerRemoving)
end

return RateLimiter
