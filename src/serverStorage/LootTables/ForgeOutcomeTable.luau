--!strict

export type Outcome = {
	Id: string,
	Weight: number,
	PointDelta: number,
	Multipliers: { number },
}

local ForgeOutcomeTable = {}

ForgeOutcomeTable.BreakOutcomeId = "Break"
ForgeOutcomeTable.BreakBaseWeight = 2
ForgeOutcomeTable.BreakWeightPerPoint = 3

ForgeOutcomeTable.Outcomes = {
	{ Id = "Downgrade", Weight = 10, PointDelta = -1, Multipliers = {} },
	{ Id = "Keep", Weight = 25, PointDelta = 0, Multipliers = {} },
	{ Id = "Success", Weight = 40, PointDelta = 1, Multipliers = { 1.5 } },
	{ Id = "GreatSuccess", Weight = 15, PointDelta = 1, Multipliers = { 2.5, 3.5 } },
} :: { Outcome }

-- PLACEHOLDER: doc chưa có hệ số tăng giá mỗi lần đập trong chế độ đập liên tục
ForgeOutcomeTable.FrenzyMultiplier = 1.05

return ForgeOutcomeTable
