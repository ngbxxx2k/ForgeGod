--!strict

local WeaponItemMessages = {
	NotificationTitle = "Item",
	UsedFormat = "%s used!",
	UnknownError = "Could not use this item.",
}

WeaponItemMessages.NoTargetText = {
	AngelHeart = "You have no broken weapons to revive.",
	MutationEraser = "You have no mutated weapons outside your Loadout.",
}

WeaponItemMessages.Reasons = {
	NotLoaded = "Your data is still loading.",
	RateLimited = "You're using items too fast.",
	InvalidRequest = "Invalid request.",
	InvalidItem = "This item can't be used on a weapon.",
	NotEnoughItems = "You don't have this item.",
	WeaponNotFound = "Weapon not found.",
	NotBroken = "This weapon is not broken.",
	WeaponBroken = "This weapon is broken.",
	NoMutation = "This weapon has no mutation.",
	WeaponEquipped = "Unequip this weapon from your Loadout first.",
	WeaponLocked = "This weapon is locked.",
}

return WeaponItemMessages
