--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeStrikeConfig = require(script.Parent.Parent.Config.ForgeStrikeConfig)

local ASSETS_FOLDER_NAME = "Assets"

local WeaponModelFinder = {}

local function findModel(folder: Instance?, name: string): Model?
	local model = folder and folder:FindFirstChild(name)
	if model and model:IsA("Model") then
		return model
	end
	return nil
end

local function getAssetsFolder(): Instance?
	local assets = ReplicatedStorage:FindFirstChild(ASSETS_FOLDER_NAME)
	return assets and assets:FindFirstChild(ForgeStrikeConfig.WeaponModelsFolderName)
end

local function getTestModelName(shapeStage: number): string
	local stages = ForgeStrikeConfig.TestWeaponModelStages
	local chosen = stages[1].ModelName
	for _, stage in stages do
		if shapeStage >= stage.MinShapeStage then
			chosen = stage.ModelName
		end
	end
	return chosen
end

function WeaponModelFinder.Find(weaponType: string?, shapeStage: number?): Model?
	local specific = if weaponType then findModel(getAssetsFolder(), weaponType) else nil
	if specific then
		return specific
	end
	local stage = shapeStage or ForgeStrikeConfig.DefaultShapeStage
	local name = getTestModelName(stage)
	local model = findModel(getAssetsFolder(), name)
	if model == nil then
		warn("[WeaponModelFinder] Missing test model in Assets:", name)
	end
	return model
end

return WeaponModelFinder
