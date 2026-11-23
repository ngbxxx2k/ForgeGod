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
	ConfirmAllWeaponsTitle = "Sell All Weapons?",
	ConfirmAllWeaponsFormat = "Sell %s weapons for $%s?\nLocked and equipped weapons are kept.",
	NoWeaponsToSell = "No weapons to sell. Locked and equipped weapons are kept.",
	UnknownError = "Something went wrong.",
}

SellMessages.Reasons = {
	WeaponEquipped = "Unequip this weapon before selling it.",
	WeaponLocked = "Unlock this weapon before selling it.",
	WeaponNotFound = "Weapon not found.",
	NothingToSell = "No weapons to sell.",
	NotEnoughItems = "You don't have enough of that item.",
	InvalidItem = "That item can't be sold.",
	RateLimited = "Slow down!",
	NotLoaded = "Your data is still loading, please wait.",
	InvalidRequest = "Invalid request.",
	InvalidAmount = "Invalid price.",
}

return SellMessages
