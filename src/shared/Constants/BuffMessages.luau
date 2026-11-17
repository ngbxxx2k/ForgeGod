--!strict

local BuffMessages = {
	NotificationTitle = "Buff",
	ActivatedFormat = "%s activated!",
	UnknownError = "Could not use this item.",
}

BuffMessages.Reasons = {
	NotLoaded = "Your data is still loading.",
	RateLimited = "You're using items too fast.",
	InvalidRequest = "Invalid request.",
	InvalidItem = "This item does not exist.",
	NotUsable = "This item can't be used from the backpack.",
	NotEnoughItems = "You don't have this item.",
}

return BuffMessages
