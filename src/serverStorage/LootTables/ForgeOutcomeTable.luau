--!strict

export type Outcome = {
	Id: string,
	Weight: number,
	PointDelta: number,
	Multiplier: number,
}

export type DifficultyStep = {
	Level: number,
	Multiplier: number,
}

local ForgeOutcomeTable = {}

ForgeOutcomeTable.BreakOutcomeId = "Break"
ForgeOutcomeTable.BreakBaseWeight = 2
ForgeOutcomeTable.RiskWeightPerPoint = 2

ForgeOutcomeTable.DifficultySteps = {
	{ Level = 10, Multiplier = 1 },
	{ Level = 30, Multiplier = 1.5 },
	{ Level = 50, Multiplier = 2 },
	{ Level = 100, Multiplier = 3 },
} :: { DifficultyStep }

ForgeOutcomeTable.Outcomes = {
	{ Id = "Downgrade", Weight = 10, PointDelta = -1, Multiplier = 1 },
	{ Id = "Keep", Weight = 25, PointDelta = 0, Multiplier = 1 },
	{ Id = "Success", Weight = 40, PointDelta = 1, Multiplier = 1.5 },
	{ Id = "GreatSuccess", Weight = 15, PointDelta = 1, Multiplier = 2 },
} :: { Outcome }

return ForgeOutcomeTable
