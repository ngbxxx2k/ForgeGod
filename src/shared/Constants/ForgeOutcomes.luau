--!strict

export type ForgeOutcome = {
	Id: string,
	DisplayName: string,
	Color: Color3,
}

local ForgeOutcomes: { ForgeOutcome } = {
	{ Id = "Break", DisplayName = "BREAK", Color = Color3.fromRGB(240, 110, 90) },
	{ Id = "Downgrade", DisplayName = "DAMAGED", Color = Color3.fromRGB(245, 170, 90) },
	{ Id = "Keep", DisplayName = "NO CHANGE", Color = Color3.fromRGB(190, 230, 120) },
	{ Id = "Success", DisplayName = "SUCCESS", Color = Color3.fromRGB(140, 215, 240) },
	{ Id = "GreatSuccess", DisplayName = "GREAT SUCCESS", Color = Color3.fromRGB(230, 140, 230) },
}

return ForgeOutcomes
