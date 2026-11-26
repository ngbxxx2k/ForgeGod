--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponIcons = require(ReplicatedStorage.Shared.Constants.WeaponIcons)
local WeaponTypeName = require(ReplicatedStorage.Shared.Utils.WeaponTypeName)

local DEFAULT_STAGE = 1

local WeaponDisplayName = {}

function WeaponDisplayName.GetIcon(weaponTypeId: string, shapeStage: number?): WeaponIcons.WeaponIcon?
	local stage = shapeStage or DEFAULT_STAGE
	while stage >= DEFAULT_STAGE do
		local icon = WeaponIcons.Get(weaponTypeId, stage)
		if icon then
			return icon
		end
		stage -= 1
	end
	return nil
end

function WeaponDisplayName.Get(rarity: string, weaponTypeId: string, shapeStage: number?): string
	local icon = WeaponDisplayName.GetIcon(weaponTypeId, shapeStage)
	if icon then
		return icon.DisplayName
	end
	return WeaponTypeName.Get(rarity, weaponTypeId)
end

return WeaponDisplayName
