--!strict

local EquipMessages = {
	NotificationTitle = "Loadout",
	HoldTitle = "Backpack",
	UnknownError = "Something went wrong.",
	EquipText = "EQUIP",
	UnequipText = "UNEQUIP",
	IncomeFormat = "$%s/s",
	SlotsFormat = "EQUIPPED: %d/%d",
	EmptyText = "NO WEAPONS YET",
}

EquipMessages.Reasons = {
	WeaponBroken = "Broken weapons cannot be equipped.",
	AlreadyEquipped = "This weapon is already equipped.",
	EquipLimitReached = "Your loadout is full.",
	NoWeapons = "You have no weapons to equip.",
	NoCharacter = "Your character is not ready.",
	NoModel = "This weapon has no model yet.",
	NotEquipped = "This weapon is not equipped.",
	WeaponNotFound = "Weapon not found.",
	RateLimited = "Slow down!",
	NotLoaded = "Your data is still loading, please wait.",
	InvalidRequest = "Invalid request.",
	InDigZone = "You can't hold a weapon at the dig site.",
	TutorialUseEquip = "Press EQUIP on your forged weapon to continue the tutorial.",
}

return EquipMessages
