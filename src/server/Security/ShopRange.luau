--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(shared:WaitForChild("Config"):WaitForChild("ShopConfig"))
local ShopZoneConfig = require(shared:WaitForChild("Config"):WaitForChild("ShopZoneConfig"))

local ROOT_PART_NAME = "HumanoidRootPart"

local ShopRange = {}

local isInitialized = false
local categoryByItem: { [string]: string } = {}
local zoneCenters: { [string]: CFrame } = {}

local function findStall(path: { string }): PVInstance?
	local current: Instance? = Workspace
	for _, childName in path do
		current = current and current:FindFirstChild(childName)
	end
	if current and current:IsA("PVInstance") then
		return current
	end
	return nil
end

local function getZoneCenter(category: string): CFrame?
	local cached = zoneCenters[category]
	if cached then
		return cached
	end
	local path = (ShopZoneConfig.StallPaths :: { [string]: { string } })[category]
	local stall = path and findStall(path)
	if stall == nil then
		warn("[ShopRange] Missing stall for category", category)
		return nil
	end
	local center = stall:GetPivot() * ShopZoneConfig.CenterOffset
	zoneCenters[category] = center
	return center
end

local function isInsideZone(center: CFrame, position: Vector3): boolean
	local offset = center:PointToObjectSpace(position)
	local tolerance = ShopZoneConfig.ServerRangeTolerance
	if offset.Y < -tolerance or offset.Y > ShopZoneConfig.MaxHeight + tolerance then
		return false
	end
	return Vector2.new(offset.X, offset.Z).Magnitude <= ShopZoneConfig.Radius + tolerance
end

local function registerCategory(category: string, itemIds: { string })
	for _, itemId in itemIds do
		categoryByItem[itemId] = category
	end
end

function ShopRange.IsNear(player: Player, itemId: string): boolean
	local category = categoryByItem[itemId]
	local character = player.Character
	local rootPart = character and character:FindFirstChild(ROOT_PART_NAME)
	if category == nil or not rootPart or not rootPart:IsA("BasePart") then
		return false
	end
	local center = getZoneCenter(category)
	return center ~= nil and isInsideZone(center, rootPart.Position)
end

function ShopRange.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	registerCategory("Ore", ShopConfig.OreDisplayOrder)
	registerCategory("Item", ShopConfig.BuffDisplayOrder)
end

return ShopRange
