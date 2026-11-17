--!strict

local SellMessages = {
	NotificationTitle = "Backpack",
	SellText = "SELL",
	SellOneText = "SELL 1",
	SellAllText = "SELL ALL",
	SoldFormat = "Sold for $%s",
	ConfirmTitle = "Sell Weapon?",
	ConfirmFormat = "Sell %s for $%s?",
	ConfirmItemTitle = "Sell Item?",
	ConfirmItemFormat = "Sell %sx %s for $%s?",
	UnknownError = "Something went wrong.",
}

SellMessages.Reasons = {
	WeaponEquipped = "Unequip this weapon before selling it.",
	WeaponLocked = "Unlock this weapon before selling it.",
	WeaponNotFound = "Weapon not found.",
	NotEnoughItems = "You don't have enough of that item.",
	InvalidItem = "That item can't be sold.",
	RateLimited = "Slow down!",
	NotLoaded = "Your data is still loading, please wait.",
	InvalidRequest = "Invalid request.",
	InvalidAmount = "Invalid price.",
}

return SellMessages
