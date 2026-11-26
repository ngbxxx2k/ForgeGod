--!strict

local NORMAL_ID = "Normal"
local DEFAULT_STAGE = 1

local IndexKey = {}

IndexKey.NormalId = NORMAL_ID

function IndexKey.Build(mutationId: string?, weaponTypeId: string, shapeStage: number?): string
	return (mutationId or NORMAL_ID) .. "|" .. weaponTypeId .. "|" .. tostring(shapeStage or DEFAULT_STAGE)
end

return IndexKey
