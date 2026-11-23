--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ForgeUpgradeZoneConfig = require(ReplicatedStorage.Shared.Config.ForgeUpgradeZoneConfig)
local ForgeUpgradeMessages = require(ReplicatedStorage.Shared.Constants.ForgeUpgradeMessages)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local PlotStations = require(ReplicatedStorage.Shared.Utils.PlotStations)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)
local ForgeUpgradeController = require(script.Parent.ForgeUpgradeController)
local ShopZoneRing = require(script.Parent.Parent.Effects.ShopZoneRing)
local ZoneLabel = require(script.Parent.Parent.UI.Components.ZoneLabel)

local ROOT_PART_NAME = "HumanoidRootPart"
local OWNED_PLOT_POLL_INTERVAL = 0.5

local RING_STYLE: ShopZoneRing.RingStyle = {
	Radius = ForgeUpgradeZoneConfig.Radius,
	RingWidth = ForgeUpgradeZoneConfig.RingWidth,
	RingColor = ForgeUpgradeZoneConfig.RingColor,
	DiscColor = ForgeUpgradeZoneConfig.DiscColor,
	StudsColor = ForgeUpgradeZoneConfig.StudsColor,
}

local LABEL_STYLE: ZoneLabel.LabelStyle = {
	Name = ForgeUpgradeZoneConfig.LabelName,
	Text = ForgeUpgradeMessages.ZoneLabel,
	Size = ForgeUpgradeZoneConfig.LabelSize,
	MaxDistance = ForgeUpgradeZoneConfig.LabelMaxDistance,
	Font = ForgeUpgradeZoneConfig.LabelFont,
	TextColor = ForgeUpgradeZoneConfig.LabelTextColor,
	StrokeColor = ForgeUpgradeZoneConfig.LabelStrokeColor,
	StrokeThickness = ForgeUpgradeZoneConfig.LabelStrokeThickness,
}

local ForgeUpgradeZoneController = {}

local isInitialized = false
local localPlayer = Players.LocalPlayer
local zoneCenter: CFrame? = nil
local isInside = false

local function waitForOwnedPlot(): Model
	local plot = PlotStations.FindOwnedPlot(localPlayer.UserId)
	while plot == nil do
		task.wait(OWNED_PLOT_POLL_INTERVAL)
		plot = PlotStations.FindOwnedPlot(localPlayer.UserId)
	end
	return plot
end

local function flatten(vector: Vector3): Vector3
	local flat = Vector3.new(vector.X, 0, vector.Z)
	return if flat.Magnitude > 0 then flat.Unit else Vector3.zAxis
end

local function snapToGrid(value: number, origin: number): number
	local size = ForgeUpgradeZoneConfig.GridSize
	return math.round((value - origin) / size) * size + origin
end

local function isClearOfAnvil(point: Vector3, anvilPosition: Vector3): boolean
	local offset = point - anvilPosition
	return Vector2.new(offset.X, offset.Z).Magnitude >= ForgeUpgradeZoneConfig.MinAnvilClearance
end

local function findGridCorner(target: Vector3, anvilPosition: Vector3): Vector3
	local size = ForgeUpgradeZoneConfig.GridSize
	local origin = ForgeUpgradeZoneConfig.GridOrigin
	local range = ForgeUpgradeZoneConfig.SnapSearchRange
	local baseX = snapToGrid(target.X, origin.X)
	local baseZ = snapToGrid(target.Z, origin.Y)
	local best: Vector3? = nil
	local bestDistance = math.huge
	for stepX = -range, range do
		for stepZ = -range, range do
			local corner = Vector3.new(baseX + stepX * size, anvilPosition.Y, baseZ + stepZ * size)
			local distance = (corner - target).Magnitude
			if distance < bestDistance and isClearOfAnvil(corner, anvilPosition) then
				best, bestDistance = corner, distance
			end
		end
	end
	return best or Vector3.new(target.X, anvilPosition.Y, target.Z)
end

local function computeCenter(anvil: Model): CFrame
	local pivot = anvil:GetPivot()
	local hornDirection = flatten(pivot:VectorToWorldSpace(ForgeUpgradeZoneConfig.HornAxis))
	local sideDirection = flatten(pivot:VectorToWorldSpace(ForgeUpgradeZoneConfig.SideAxis))
	local target = pivot.Position
		+ hornDirection * ForgeUpgradeZoneConfig.Distance
		+ sideDirection * ForgeUpgradeZoneConfig.SideOffset
	return CFrame.new(findGridCorner(target, pivot.Position))
end

local function createFolder(): Folder
	local folder = Instance.new("Folder")
	folder.Name = ForgeUpgradeZoneConfig.FolderName
	folder.Parent = Workspace
	return folder
end

local function createLabel(ring: Model, center: CFrame)
	local host = ring:FindFirstChildWhichIsA("BasePart")
	if host == nil then
		warn("[ForgeUpgradeZoneController] Ring has no part for label")
		return
	end
	local position = center.Position + Vector3.yAxis * ForgeUpgradeZoneConfig.LabelHeight
	ZoneLabel.Build(host, position, LABEL_STYLE)
end

local function setupZone()
	local plot = waitForOwnedPlot()
	local stations = plot:WaitForChild(PlotConfig.StationsFolderName)
	local anvil = stations:WaitForChild(StationConfig.ForgeModelName)
	if not anvil:IsA("Model") then
		warn("[ForgeUpgradeZoneController] Anvil is not a model:", anvil:GetFullName())
		return
	end
	local center = computeCenter(anvil)
	zoneCenter = center
	local ring = ShopZoneRing.Build(ForgeUpgradeZoneConfig.RingName, center, createFolder(), RING_STYLE)
	createLabel(ring, center)
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
	return Vector2.new(offset.X, offset.Z).Magnitude <= ForgeUpgradeZoneConfig.Radius
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

function ForgeUpgradeZoneController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	task.spawn(setupZone)
	RunService.Heartbeat:Connect(onHeartbeat)
end

return ForgeUpgradeZoneController
