--!strict
--[[
	ShopService
	Trách nhiệm: xử lý yêu cầu mua hàng của client (F2.6), giữ tồn kho hiện tại
	của server, đồng bộ trạng thái shop (tồn kho + mốc restock) cho client.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(shared:WaitForChild("Config"):WaitForChild("ShopConfig"))
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local ShopRange = require(script.Parent.Parent.Security.ShopRange)
local ShopStockRoller = require(script.Parent.Parent.Internal.ShopStockRoller)

local ShopRestockTable = require(
	ServerStorage:WaitForChild("LootTables"):WaitForChild("ShopRestockTable")
)

local ShopService = {}

local isInitialized = false

local notifyBuyResult: RemoteEvent? = nil
local notifyShopState: RemoteEvent? = nil

-- Tồn kho chung của server: [itemId] = số lượng còn lại.
local currentStock: { [string]: number } = {}

-- Chu kỳ restock hiện tại (mốc os.time() chia RestockInterval).
-- Client dùng giá trị này tự tính đếm ngược, không cần server broadcast liên tục.
local currentCycle = 0

local personalStocks: { [Player]: { [string]: number } } = {}
local paidRestockCounts: { [Player]: number } = {}
local rng = Random.new()

local function buildOdds(): { [string]: number }
	local odds = {}
	for itemId, entry in ShopRestockTable.Entries do
		odds[itemId] = entry.AppearanceRate
	end
	return odds
end

local function getStockFor(player: Player): { [string]: number }
	return personalStocks[player] or currentStock
end

local function buildStatePayload(player: Player): { [string]: any }
	return {
		Stock = table.clone(getStockFor(player)),
		Cycle = currentCycle,
		RestockInterval = ShopConfig.RestockInterval,
		Odds = buildOdds(),
		PaidRestockCount = paidRestockCounts[player] or 0,
	}
end

function ShopService.SendShopState(player: Player)
	if notifyShopState ~= nil and player.Parent ~= nil then
		notifyShopState:FireClient(player, buildStatePayload(player))
	end
end

function ShopService.BroadcastShopState()
	for _, player in Players:GetPlayers() do
		ShopService.SendShopState(player)
	end
end

local function broadcastSharedStock()
	for _, player in Players:GetPlayers() do
		if personalStocks[player] == nil then
			ShopService.SendShopState(player)
		end
	end
end

function ShopService.SetStock(stock: { [string]: number }, cycleIndex: number)
	currentStock = table.clone(stock)
	currentCycle = cycleIndex
	table.clear(personalStocks)
	ShopService.BroadcastShopState()
end

function ShopService.ApplyPaidRestock(player: Player)
	if player.Parent == nil then
		return
	end
	personalStocks[player] = ShopStockRoller.Roll(rng)
	paidRestockCounts[player] = (paidRestockCounts[player] or 0) + 1
	ShopService.SendShopState(player)
end

-- Mua hàng: kiểm tra hợp lệ + đủ tiền + còn hàng TRƯỚC, rồi mới đổi
-- tiền/vật phẩm, không có task.wait xen giữa (chống nhân đôi, file 04).
function ShopService.Buy(player: Player, itemId: string, amount: number): (boolean, string?)
	-- Kiểm tra kiểu tham số: client không đáng tin (file 04).
	if type(itemId) ~= "string" or type(amount) ~= "number" then
		return false, "InvalidRequest"
	end
	if amount ~= amount or amount == math.huge or -amount == math.huge then
		return false, "InvalidAmount"
	end
	if amount % 1 ~= 0 or amount < 1 or amount > ShopConfig.MaxBuyPerRequest then
		return false, "InvalidAmount"
	end

	local price = ShopConfig.ItemPrices[itemId]
	if price == nil then
		return false, "InvalidItem"
	end
	if not ShopRange.IsNear(player, itemId) then
		return false, "TooFar"
	end

	local stock = getStockFor(player)
	local inStock = stock[itemId] or 0
	if inStock < amount then
		return false, "OutOfStock"
	end

	local data = DataService.GetData(player)
	if data == nil then
		return false, "NotLoaded"
	end

	local totalCost = price * amount
	if data.Coins < totalCost then
		return false, "NotEnoughCoins"
	end

	-- Thêm vật phẩm trước (hàm tự kiểm tra sức chứa kho), rồi mới trừ tiền.
	local okAdd, reasonAdd = DataActions.TryAddItem(player, itemId, amount)
	if not okAdd then
		return false, reasonAdd
	end

	local okPay, reasonPay = DataActions.TryRemoveCoins(player, totalCost)
	if not okPay then
		-- Trường hợp hiếm: nếu trừ tiền thất bại thì hoàn lại vật phẩm,
		-- tránh người chơi mất tiền mà không có hàng (hoặc ngược lại).
		DataActions.TryRemoveItem(player, itemId, amount)
		return false, reasonPay
	end

	stock[itemId] = inStock - amount
	if stock[itemId] <= 0 then
		stock[itemId] = nil
	end

	if stock == currentStock then
		broadcastSharedStock()
	else
		ShopService.SendShopState(player)
	end
	return true
end

-- Xử lý Remote mua hàng: rate limit rồi gọi Buy, trả kết quả cho người mua.
local function onRequestBuy(player: Player, itemId: any, amount: any)
	if not DataService.IsLoaded(player) then
		if notifyBuyResult ~= nil then
			notifyBuyResult:FireClient(player, false, "NotLoaded")
		end
		return
	end

	if not RateLimiter.Check(player, "ShopBuy") then
		if notifyBuyResult ~= nil then
			notifyBuyResult:FireClient(player, false, "RateLimited")
		end
		return
	end

	local ok, reason = ShopService.Buy(player, itemId, amount)
	if notifyBuyResult ~= nil then
		notifyBuyResult:FireClient(player, ok, reason)
	end
end

-- Gửi trạng thái shop cho người chơi mới vào để UI hiển thị đúng tồn kho.
local function handlePlayerAdded(player: Player)
	ShopService.SendShopState(player)
end

local function handlePlayerRemoving(player: Player)
	personalStocks[player] = nil
	paidRestockCounts[player] = nil
end

function ShopService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	-- Tạo Remotes ở một nơi duy nhất, tên lấy từ shared/Network.
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	local requestBuy = Instance.new("RemoteEvent")
	requestBuy.Name = RemoteNames.RequestBuy
	requestBuy.Parent = remotesFolder

	notifyBuyResult = Instance.new("RemoteEvent")
	notifyBuyResult.Name = RemoteNames.NotifyBuyResult
	notifyBuyResult.Parent = remotesFolder

	notifyShopState = Instance.new("RemoteEvent")
	notifyShopState.Name = RemoteNames.NotifyShopState
	notifyShopState.Parent = remotesFolder

	requestBuy.OnServerEvent:Connect(onRequestBuy)

	Players.PlayerAdded:Connect(handlePlayerAdded)
	Players.PlayerRemoving:Connect(handlePlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(handlePlayerAdded, player)
	end
end

return ShopService
