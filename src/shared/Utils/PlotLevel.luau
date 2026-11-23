--!strict

local PlotUpgradeConfig = require(script.Parent.Parent.Config.PlotUpgradeConfig)

local PlotLevel = {}

function PlotLevel.FromSlots(slots: number): number
	local clamped = math.clamp(slots, PlotUpgradeConfig.BaseSlots, PlotUpgradeConfig.MaxSlots)
	return clamped - PlotUpgradeConfig.BaseSlots + 1
end

function PlotLevel.GetMaxLevel(): number
	return PlotUpgradeConfig.MaxSlots - PlotUpgradeConfig.BaseSlots + 1
end

function PlotLevel.IsMax(slots: number): boolean
	return slots >= PlotUpgradeConfig.MaxSlots
end

function PlotLevel.GetNextStep(slots: number): PlotUpgradeConfig.UpgradeStep?
	if PlotLevel.IsMax(slots) then
		return nil
	end
	return PlotUpgradeConfig.Steps[PlotLevel.FromSlots(slots)]
end

return PlotLevel
