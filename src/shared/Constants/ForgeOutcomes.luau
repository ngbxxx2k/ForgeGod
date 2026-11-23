--!strict

export type ForgeOutcome = {
	Id: string,
	DisplayName: string,
	Label: string,
	Color: Color3,
	TextColor: Color3,
}

local ForgeOutcomes: { ForgeOutcome } = {
	{
		Id = "GreatSuccess",
		DisplayName = "GREAT SUCCESS",
		Label = "Great Success",
		Color = Color3.fromRGB(150, 56, 232),
		TextColor = Color3.fromRGB(196, 128, 255),
	},
	{
		Id = "Success",
		DisplayName = "SUCCESS",
		Label = "Success",
		Color = Color3.fromRGB(26, 168, 78),
		TextColor = Color3.fromRGB(70, 224, 116),
	},
	{
		Id = "Keep",
		DisplayName = "NO CHANGE",
		Label = "No Change",
		Color = Color3.fromRGB(38, 108, 236),
		TextColor = Color3.fromRGB(96, 164, 255),
	},
	{
		Id = "Downgrade",
		DisplayName = "DAMAGED",
		Label = "Damaged",
		Color = Color3.fromRGB(230, 190, 20),
		TextColor = Color3.fromRGB(255, 222, 70),
	},
	{
		Id = "Break",
		DisplayName = "BREAK",
		Label = "Break",
		Color = Color3.fromRGB(222, 38, 38),
		TextColor = Color3.fromRGB(255, 92, 92),
	},
}

return ForgeOutcomes
