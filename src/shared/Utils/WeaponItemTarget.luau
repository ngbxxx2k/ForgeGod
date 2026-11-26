--!strict

local WeaponItemConfig = require(script.Parent.Parent.Config.WeaponItemConfig)

local BROKEN_STATE = "Broken"

export type TargetWeapon = {
	State: string,
	Mutation: string?,
	IsLocked: boolean?,
}

local WeaponItemTarget = {}

local function checkBroken(weapon: TargetWeapon): (boolean, string?)
	if weapon.State ~= BROKEN_STATE then
		return false, "NotBroken"
	end
	return true, nil
end

local function checkMutated(weapon: TargetWeapon, isEquipped: boolean): (boolean, string?)
	if weapon.State == BROKEN_STATE then
		return false, "WeaponBroken"
	end
	if weapon.Mutation == nil then
		return false, "NoMutation"
	end
	if isEquipped then
		return false, "WeaponEquipped"
	end
	if weapon.IsLocked == true then
		return false, "WeaponLocked"
	end
	return true, nil
end

function WeaponItemTarget.Check(
	itemId: string,
	weapon: TargetWeapon,
	isEquipped: boolean
): (boolean, string?)
	local definition = WeaponItemConfig.ById[itemId]
	if definition == nil then
		return false, "InvalidItem"
	end
	if definition.Target == WeaponItemConfig.Targets.Broken then
		return checkBroken(weapon)
	end
	return checkMutated(weapon, isEquipped)
end

return WeaponItemTarget
