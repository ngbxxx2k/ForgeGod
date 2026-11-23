--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local WeaponCatalog = require(ReplicatedStorage.Shared.Constants.WeaponCatalog)
local RevealWeapon = require(script.Parent.RevealWeapon)
local RollSchedule = require(script.Parent.RollSchedule)

export type ShapeStep = {
	WeaponTypeId: string,
	Length: number,
	Time: number,
	Progress: number,
	IsFinal: boolean,
}

local ShapeRollEffect = {}

local rng = Random.new()

local function getCandidates(rarity: string, finalTypeId: string): { string }
	local candidates = {}
	for _, weaponType in WeaponCatalog.Types[rarity] or {} do
		table.insert(candidates, weaponType.Id)
	end
	if #candidates == 0 then
		table.insert(candidates, finalTypeId)
	end
	return candidates
end

local function pickDifferent(candidates: { string }, previous: string?, avoid: string?): string
	local pool = {}
	for _, id in candidates do
		if id ~= previous and id ~= avoid then
			table.insert(pool, id)
		end
	end
	if #pool == 0 then
		return candidates[rng:NextInteger(1, #candidates)]
	end
	return pool[rng:NextInteger(1, #pool)]
end

local function getGrowingLength(startLength: number, finalLength: number, progress: number): number
	local style = ForgeAnimationConfig.ShapeRoll.GrowthEasing
	local eased = TweenService:GetValue(progress, style, Enum.EasingDirection.In)
	return startLength + (finalLength - startLength) * eased
end

function ShapeRollEffect.Build(rarity: string, finalTypeId: string, finalScale: number): { ShapeStep }
	local config = ForgeAnimationConfig.ShapeRoll
	local count = math.max(config.SwapCount, 1)
	local times = RollSchedule.BuildTimes(count, config.FirstInterval, config.Duration)
	local candidates = getCandidates(rarity, finalTypeId)
	local finalLength = RevealWeapon.GetVisual(finalTypeId).Length * finalScale
	local startRatio = ForgeAnimationConfig.ShapeRoll.GrowthStartRatio
	local startLength = math.min(ForgeAnimationConfig.DefaultVisual.Length, finalLength) * startRatio
	local steps = {}
	local previous: string? = nil
	for index, time in times do
		local isFinal = index == count
		local isBeforeFinal = index == count - 1
		local typeId = if isFinal then finalTypeId
			else pickDifferent(candidates, previous, if isBeforeFinal then finalTypeId else nil)
		local progress = if count > 1 then (index - 1) / (count - 1) else 1
		table.insert(steps, {
			WeaponTypeId = typeId,
			Length = if isFinal then finalLength else getGrowingLength(startLength, finalLength, progress),
			Time = time,
			Progress = progress,
			IsFinal = isFinal,
		})
		previous = typeId
	end
	return steps
end

return ShapeRollEffect
