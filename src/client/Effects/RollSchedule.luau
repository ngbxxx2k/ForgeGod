--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)

export type Strike = {
	Rarity: string,
	Time: number,
	Progress: number,
	IsFinal: boolean,
	PlaybackSpeed: number,
}

local SOLVER_STEPS = 40
local MAX_RATIO = 4

local RollSchedule = {}

local function sumIntervals(first: number, ratio: number, count: number): number
	if math.abs(ratio - 1) < 1e-6 then
		return first * count
	end
	return first * (ratio ^ count - 1) / (ratio - 1)
end

local function solveRatio(first: number, count: number, span: number): number
	if first * count >= span then
		return 1
	end
	local low, high = 1, MAX_RATIO
	for _ = 1, SOLVER_STEPS do
		local middle = (low + high) / 2
		if sumIntervals(first, middle, count) > span then
			high = middle
		else
			low = middle
		end
	end
	return (low + high) / 2
end

local function rarityAt(targetIndex: number, strikeCount: number, strikeIndex: number): string
	local order = ForgeAnimationConfig.RarityOrder
	local index = (targetIndex - strikeCount + strikeIndex - 1) % #order + 1
	return order[index]
end

function RollSchedule.BuildTimes(count: number, firstInterval: number, span: number): { number }
	local intervalCount = count - 1
	local times = { 0 }
	if intervalCount <= 0 then
		return times
	end
	local first = math.min(firstInterval, span / intervalCount)
	local ratio = solveRatio(first, intervalCount, span)
	local elapsed = 0
	for index = 1, intervalCount do
		elapsed += first * ratio ^ (index - 1)
		table.insert(times, elapsed)
	end
	return times
end

local function strikeSpeed(progress: number, isFinal: boolean): number
	local config = ForgeAnimationConfig.Lightning
	if isFinal then
		return config.FinalPlaybackSpeed
	end
	return config.PitchStart + (config.PitchEnd - config.PitchStart) * progress
end

function RollSchedule.Build(targetRarity: string): ({ Strike }, number)
	local info = ForgeAnimationConfig.Rarities[targetRarity] or ForgeAnimationConfig.Rarities.Common
	local roll = ForgeAnimationConfig.RarityRoll
	local targetIndex = table.find(ForgeAnimationConfig.RarityOrder, targetRarity) or 1
	local strikeCount = math.max(info.StrikeCount, 1)
	local strikes = {}
	local elapsed = 0
	for index = 1, strikeCount do
		local isFinal = index == strikeCount
		local progress = if strikeCount > 1 then (index - 1) / (strikeCount - 1) else 1
		local speed = strikeSpeed(progress, isFinal)
		table.insert(strikes, {
			Rarity = rarityAt(targetIndex, strikeCount, index),
			Time = elapsed,
			Progress = progress,
			IsFinal = isFinal,
			PlaybackSpeed = speed,
		})
		if not isFinal then
			elapsed += roll.ThunderLength / speed + roll.StrikeGap
		end
	end
	return strikes, elapsed + roll.FinalHold
end

return RollSchedule
