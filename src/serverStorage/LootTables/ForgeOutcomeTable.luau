--!strict

export type WeightedMultiplier = {
	Value: number,
	Weight: number,
}

export type Outcome = {
	Id: string,
	Weight: number,
	PointDelta: number,
	Multipliers: { WeightedMultiplier },
}

local ForgeOutcomeTable = {}

ForgeOutcomeTable.BreakOutcomeId = "Break"
ForgeOutcomeTable.BreakBaseWeight = 2
ForgeOutcomeTable.BreakWeightPerPoint = 3
ForgeOutcomeTable.MinBreakLevel = 1

ForgeOutcomeTable.Outcomes = {
	{ Id = "Downgrade", Weight = 10, PointDelta = -1, Multipliers = {} },
	{ Id = "Keep", Weight = 25, PointDelta = 0, Multipliers = {} },
	{ Id = "Success", Weight = 40, PointDelta = 1, Multipliers = { { Value = 1.5, Weight = 1 } } },
	{
		Id = "GreatSuccess",
		Weight = 15,
		PointDelta = 1,
		Multipliers = {
			{ Value = 2.5, Weight = 80 },
			{ Value = 3.5, Weight = 20 },
		},
	},
} :: { Outcome }

return ForgeOutcomeTable
