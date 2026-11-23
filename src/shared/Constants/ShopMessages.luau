--!strict
--[[
	ShopMessages
	Trách nhiệm: thông báo hiển thị cho người chơi (tiếng Anh) khi mua ở shop,
	map từ reason code trả về bởi ShopService.Buy.
]]

local ShopMessages = {}

ShopMessages.PurchaseSuccess = "Purchase complete!"
ShopMessages.NotificationTitle = "Shop"
ShopMessages.Restocking = "Restocking..."
ShopMessages.RestockedNotice = "Ore Shop & Item Shop restocked!"
ShopMessages.UnknownError = "Something went wrong."

ShopMessages.Categories = {
	Ore = {
		RestockFormat = "New ores in %d:%02d",
		OddsTitle = "Stock ores",
	},
	Item = {
		RestockFormat = "New items in %d:%02d",
		OddsTitle = "Stock items",
	},
}

ShopMessages.Reasons = {
	InvalidRequest = "Invalid request.",
	InvalidItem = "That item is not for sale.",
	InvalidAmount = "Invalid amount.",
	OutOfStock = "This item is out of stock.",
	NotEnoughCoins = "Not enough coins.",
	InventoryFull = "Your inventory is full.",
	NotLoaded = "Your data is still loading, please wait.",
	RateLimited = "You are buying too fast, slow down.",
	TooFar = "Step into the shop circle to buy.",
}

return ShopMessages
