--!strict
--[[
	FurnaceMessages
	Trách nhiệm: thông báo hiển thị cho người chơi (tiếng Anh) khi nấu phôi,
	map từ reason code trả về bởi FurnaceService.Smelt.
]]

local FurnaceMessages = {}

FurnaceMessages.SmeltSuccess = "A new weapon blank was forged in the furnace!"
FurnaceMessages.SelectedTitle = "Selected Ores"
FurnaceMessages.BagTitle = "Ore Bag"
FurnaceMessages.StartText = "Start Smelting"
FurnaceMessages.SkipText = "Skip Minigame"
FurnaceMessages.AmountFormat = "x%d"

FurnaceMessages.Reasons = {
	InvalidRequest = "Invalid smelting request.",
	UnknownOre = "That item cannot be smelted.",
	InvalidRecipe = "You must place exactly 5 ores in the furnace.",
	NotEnoughOres = "You don't have enough ores.",
	NotLoaded = "Your data is still loading, please wait.",
	InventoryFull = "Your inventory is full.",
	RateLimited = "You are smelting too fast, slow down.",
}

return FurnaceMessages
