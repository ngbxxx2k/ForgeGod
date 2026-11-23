--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ShopZoneConfig = require(ReplicatedStorage.Shared.Config.ShopZoneConfig)
local ShopScreen = require(script.Parent.Parent.UI.Screens.ShopScreen)
local ShopZoneRing = require(script.Parent.Parent.Effects.ShopZoneRing)

type ShopCategory = ShopScreen.ShopCategory

local ROOT_PART_NAME = "HumanoidRootPart"
local RING_NAME_SUFFIX = "ShopZone"

local ShopZoneController = {}

local isInitialized = false
local localPlayer = Players.LocalPlayer
local zoneCenters: { [ShopCategory]: CFrame } = {}
local zoneFolder: Folder? = nil
local currentZone: ShopCategory? = nil

local function waitForPath(path: { string }): Instance
	local current: Instance = Workspace
	for _, childName in path do
		current = current:WaitForChild(childName)
	end
	return current
end

local function getFolder(): Folder
	local existing = zoneFolder
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = ShopZoneConfig.FolderName
	folder.Parent = Workspace
	zoneFolder = folder
	return folder
end

local function setupZone(category: ShopCategory, path: { string })
	local stall = waitForPath(path)
	if not stall:IsA("PVInstance") then
		warn("[ShopZoneController] Stall is not a model:", stall:GetFullName())
		return
	end
	local center = stall:GetPivot() * ShopZoneConfig.CenterOffset
	zoneCenters[category] = center
	ShopZoneRing.Build(category .. RING_NAME_SUFFIX, center, getFolder())
end

local function isInsideZone(center: CFrame, position: Vector3): boolean
	local offset = center:PointToObjectSpace(position)
	if offset.Y < 0 or offset.Y > ShopZoneConfig.MaxHeight then
		return false
	end
	return Vector2.new(offset.X, offset.Z).Magnitude <= ShopZoneConfig.Radius
end

local function findZoneAt(position: Vector3): ShopCategory?
	for category, center in zoneCenters do
		if isInsideZone(center, position) then
			return category
		end
	end
	return nil
end

local function getRootPosition(): Vector3?
	local character = localPlayer.Character
	local root = character and character:FindFirstChild(ROOT_PART_NAME)
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

local function onHeartbeat()
	local position = getRootPosition()
	local zone = if position then findZoneAt(position) else nil
	if zone == currentZone then
		return
	end
	local previous = currentZone
	currentZone = zone
	if zone then
		ShopScreen.Open(zone)
	elseif previous and ShopScreen.GetCategory() == previous then
		ShopScreen.Close()
	end
end

function ShopZoneController.GetZoneCenter(category: ShopCategory): CFrame?
	return zoneCenters[category]
end

function ShopZoneController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	for category, path in ShopZoneConfig.StallPaths do
		task.spawn(setupZone, category :: ShopCategory, path)
	end
	RunService.Heartbeat:Connect(onHeartbeat)
end

return ShopZoneController
