--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local WeaponModelFinder = require(ReplicatedStorage.Shared.Utils.WeaponModelFinder)

type WeaponSummary = PlayerStateTypes.WeaponSummary

local WeaponModels = {}

function WeaponModels.Find(weapon: WeaponSummary?, shapeStage: number): Model?
	return WeaponModelFinder.Find(if weapon then weapon.WeaponType else nil, shapeStage)
end

return WeaponModels
