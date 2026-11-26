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
ShopMessages.RestockedNotice = "Item Shop restocked!"
ShopMessages.PaidRestockNotice = "Your Item Shop was restocked until the next global restock!"
ShopMessages.RestockButtonFormat = "RESTOCK \u{E002}%s"
ShopMessages.RobuxPriceFormat = "\u{E002} %s"
ShopMessages.UnknownError = "Something went wrong."

ShopMessages.Categories = {
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
	NotAvailable = "Robux purchases are coming soon!",
	PromptFailed = "Could not open the purchase window.",
}

return ShopMessages
