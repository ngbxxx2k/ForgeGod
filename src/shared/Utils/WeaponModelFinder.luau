--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeStrikeConfig = require(script.Parent.Parent.Config.ForgeStrikeConfig)
local WeaponCatalog = require(script.Parent.Parent.Constants.WeaponCatalog)

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

local function getFamilyFolder(weaponType: WeaponCatalog.WeaponType): Instance?
	local library = ReplicatedStorage:FindFirstChild(ForgeStrikeConfig.WeaponLibraryFolderName)
	local rarityFolder = library and library:FindFirstChild(weaponType.Rarity)
	return rarityFolder and rarityFolder:FindFirstChild(weaponType.Family)
end

local function findLibraryModel(weaponType: WeaponCatalog.WeaponType, shapeStage: number): Model?
	local folder = getFamilyFolder(weaponType)
	if folder == nil then
		return nil
	end
	local target = math.clamp(shapeStage, 1, weaponType.MaxShapeStage)
	local best: Model? = nil
	local bestStage = 0
	for _, child in folder:GetChildren() do
		local stage = child:GetAttribute(ForgeStrikeConfig.ShapeStageAttribute)
		if child:IsA("Model") and type(stage) == "number" and stage <= target and stage > bestStage then
			best = child
			bestStage = stage
		end
	end
	return best
end

function WeaponModelFinder.Find(weaponType: string?, shapeStage: number?): Model?
	local stage = shapeStage or ForgeStrikeConfig.DefaultShapeStage
	local resolved = WeaponCatalog.Resolve(weaponType)
	local fromLibrary = if resolved then findLibraryModel(resolved, stage) else nil
	if fromLibrary then
		return fromLibrary
	end
	local specific = if weaponType then findModel(getAssetsFolder(), weaponType) else nil
	if specific then
		return specific
	end
	local name = getTestModelName(stage)
	local model = findModel(getAssetsFolder(), name)
	if model == nil then
		warn("[WeaponModelFinder] Missing test model in Assets:", name)
	end
	return model
end

return WeaponModelFinder
