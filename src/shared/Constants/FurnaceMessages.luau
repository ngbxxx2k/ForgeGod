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
FurnaceMessages.StartText = "Start"
FurnaceMessages.SkipText = "Skip"
FurnaceMessages.AmountFormat = "x%d"
FurnaceMessages.ToastTitle = "Furnace"
FurnaceMessages.ResultFormat = "You got %s (%s)!"
FurnaceMessages.UnknownError = "Smelting failed, please try again."
FurnaceMessages.OddsTitle = "Smelt Odds"
FurnaceMessages.OddsHint = "Add 5 ores to see the odds"
FurnaceMessages.PercentFormat = "%s%%"
FurnaceMessages.OddsButtonText = "ODDS"

FurnaceMessages.Reasons = {
	InvalidRequest = "Invalid smelting request.",
	UnknownOre = "That item cannot be smelted.",
	InvalidRecipe = "You must place exactly 5 ores in the furnace.",
	NotEnoughOres = "You don't have enough ores.",
	NotLoaded = "Your data is still loading, please wait.",
	InventoryFull = "Your inventory is full.",
	RateLimited = "You are smelting too fast, slow down.",
	TooFar = "Move closer to your crucible.",
}

return FurnaceMessages
