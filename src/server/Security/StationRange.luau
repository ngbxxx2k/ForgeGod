--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local StationConfig = require(shared:WaitForChild("Config"):WaitForChild("StationConfig"))

local ROOT_PART_NAME = "HumanoidRootPart"

local StationRange = {}

local isInitialized = false

local function findStationPart(modelName: string): BasePart?
	local worldFolder = Workspace:FindFirstChild(StationConfig.WorldFolderName)
	local model = worldFolder and worldFolder:FindFirstChild(modelName)
	if model == nil then
		return nil
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

function StationRange.IsNear(player: Player, modelName: string): boolean
	local character = player.Character
	local rootPart = character and character:FindFirstChild(ROOT_PART_NAME)
	if not rootPart or not rootPart:IsA("BasePart") then
		return false
	end
	local stationPart = findStationPart(modelName)
	if stationPart == nil then
		warn("[StationRange] Missing station model:", modelName)
		return false
	end
	local maxDistance = StationConfig.MaxActivationDistance + StationConfig.ServerRangeTolerance
	return (stationPart.Position - rootPart.Position).Magnitude <= maxDistance
end

function StationRange.Init()
	if isInitialized then
		return
	end
	isInitialized = true
end

return StationRange
