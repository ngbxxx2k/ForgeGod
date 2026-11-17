--!strict

local BuffConfig = require(script.Parent.Parent.Config.BuffConfig)

export type BuffHolder = {
	ActiveBuffs: { [string]: number }?,
	ArmedBuffs: { [string]: number }?,
}

type BuffDefinition = BuffConfig.BuffDefinition

local BuffEffects = {}

local function isArmed(buff: BuffDefinition, holder: BuffHolder): boolean
	local armedBuffs = holder.ArmedBuffs
	local count = if armedBuffs then armedBuffs[buff.Id] else nil
	return type(count) == "number" and count > 0
end

local function isRunning(buff: BuffDefinition, holder: BuffHolder, now: number): boolean
	local activeBuffs = holder.ActiveBuffs
	local expiresAt = if activeBuffs then activeBuffs[buff.Id] else nil
	return type(expiresAt) == "number" and expiresAt > now
end

local function isActive(buff: BuffDefinition, holder: BuffHolder, now: number): boolean
	if buff.Kind == BuffConfig.Kinds.OneUse then
		return isArmed(buff, holder)
	end
	return isRunning(buff, holder, now)
end

function BuffEffects.GetMultiplier(holder: BuffHolder, effectId: string, now: number): number
	local result = 1
	for _, buff in BuffConfig.Buffs do
		local value = buff.Effects[effectId]
		if value ~= nil and isActive(buff, holder, now) then
			result *= value
		end
	end
	return result
end

function BuffEffects.GetBonus(holder: BuffHolder, effectId: string, now: number): number
	local result = 0
	for _, buff in BuffConfig.Buffs do
		local value = buff.Effects[effectId]
		if value ~= nil and isActive(buff, holder, now) then
			result += value
		end
	end
	return result
end

function BuffEffects.FindArmedBuff(holder: BuffHolder, effectId: string): string?
	for _, buff in BuffConfig.Buffs do
		local hasEffect = buff.Effects[effectId] ~= nil
		if hasEffect and buff.Kind == BuffConfig.Kinds.OneUse and isArmed(buff, holder) then
			return buff.Id
		end
	end
	return nil
end

return BuffEffects
