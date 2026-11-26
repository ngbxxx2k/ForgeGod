--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponCatalog = require(ReplicatedStorage.Shared.Constants.WeaponCatalog)

local WeaponTypeName = {}

function WeaponTypeName.Get(rarity: string, weaponTypeId: string): string
	for _, weaponType in WeaponCatalog.Types[rarity] or {} do
		if weaponType.Id == weaponTypeId then
			return weaponType.DisplayName
		end
	end
	local resolved = WeaponCatalog.Resolve(weaponTypeId)
	return if resolved then resolved.DisplayName else weaponTypeId
end

return WeaponTypeName
