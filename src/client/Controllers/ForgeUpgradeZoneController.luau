--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ForgeUpgradeZoneConfig = require(ReplicatedStorage.Shared.Config.ForgeUpgradeZoneConfig)
local ShopZoneConfig = require(ReplicatedStorage.Shared.Config.ShopZoneConfig)
local ForgeUpgradeController = require(script.Parent.ForgeUpgradeController)
local ShopZoneRing = require(script.Parent.Parent.Effects.ShopZoneRing)

local ROOT_PART_NAME = "HumanoidRootPart"

local RING_STYLE: ShopZoneRing.RingStyle = {
	Radius = ShopZoneConfig.Radius,
	RingWidth = ShopZoneConfig.RingWidth,
	RingColor = ForgeUpgradeZoneConfig.RingColor,
	DiscColor = ForgeUpgradeZoneConfig.DiscColor,
	StudsColor = ForgeUpgradeZoneConfig.StudsColor,
}

local ForgeUpgradeZoneController = {}

local isInitialized = false
local localPlayer = Players.LocalPlayer
local zoneCenter: CFrame? = nil
local isInside = false

local function waitForPath(path: { string }): Instance
	local current: Instance = Workspace
	for _, childName in path do
		current = current:WaitForChild(childName)
	end
	return current
end

local function createFolder(): Folder
	local folder = Instance.new("Folder")
	folder.Name = ForgeUpgradeZoneConfig.FolderName
	folder.Parent = Workspace
	return folder
end

local function setupZone()
	local stall = waitForPath(ForgeUpgradeZoneConfig.StallPath)
	if not stall:IsA("PVInstance") then
		warn("[ForgeUpgradeZoneController] Stall is not a model:", stall:GetFullName())
		return
	end
	local center = stall:GetPivot() * ShopZoneConfig.CenterOffset
	zoneCenter = center
	ShopZoneRing.Build(ForgeUpgradeZoneConfig.RingName, center, createFolder(), RING_STYLE)
end

local function getRootPosition(): Vector3?
	local character = localPlayer.Character
	local root = character and character:FindFirstChild(ROOT_PART_NAME)
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

local function isInsideZone(position: Vector3?): boolean
	local center = zoneCenter
	if center == nil or position == nil then
		return false
	end
	local offset = center:PointToObjectSpace(position)
	if offset.Y < 0 or offset.Y > ForgeUpgradeZoneConfig.MaxHeight then
		return false
	end
	return Vector2.new(offset.X, offset.Z).Magnitude <= ShopZoneConfig.Radius
end

local function onHeartbeat()
	local inside = isInsideZone(getRootPosition())
	if inside == isInside then
		return
	end
	isInside = inside
	if inside then
		ForgeUpgradeController.Open()
	else
		ForgeUpgradeController.Close()
	end
end

function ForgeUpgradeZoneController.GetZoneCenter(): CFrame?
	return zoneCenter
end

function ForgeUpgradeZoneController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	task.spawn(setupZone)
	RunService.Heartbeat:Connect(onHeartbeat)
end

return ForgeUpgradeZoneController
