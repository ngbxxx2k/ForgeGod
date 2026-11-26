--!strict

local GiftMessages = {}

GiftMessages.Title = "Gift Player"
GiftMessages.SelectButton = "Select"
GiftMessages.UsernameFormat = "@%s"
GiftMessages.EmptyList = "No other players in this server."
GiftMessages.GiftSentFormat = "Gift sent to %s!"
GiftMessages.GiftReceivedFormat = "%s gifted you %s!"
GiftMessages.FallbackToSelf = "The player left, so the gift was given to you."
GiftMessages.UnknownError = "Something went wrong."

GiftMessages.Reasons = {
	InvalidRequest = "Invalid request.",
	InvalidRecipient = "That player is no longer in this server.",
	SelfGift = "You can't gift yourself.",
	AlreadyOwned = "That player already owns this pass.",
	NotAvailable = "This gift is not available yet.",
	PromptFailed = "Could not open the purchase window.",
	NotLoaded = "Data is still loading, please wait.",
	RateLimited = "Slow down a little.",
}

return GiftMessages
