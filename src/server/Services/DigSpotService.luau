--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DigZoneConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("DigZoneConfig"))

local DigOreRoller = require(script.Parent.Parent.Internal.DigOreRoller)

local FULL_TURN = math.pi * 2

export type Spot = {
	Position: Vector3,
	OreId: string?,
}

local DigSpotService = {}

local isInitialized = false
local rng = Random.new()
local spotsByPlayer: { [Player]: { Spot } } = {}

local function randomPoint(): Vector3
	local angle = rng:NextNumber(0, FULL_TURN)
	local distance = DigZoneConfig.SpotRadius * math.sqrt(rng:NextNumber())
	local center = DigZoneConfig.Center
	return Vector3.new(
		center.X + math.cos(angle) * distance,
		DigZoneConfig.GroundY,
		center.Z + math.sin(angle) * distance
	)
end

local function isFarEnough(point: Vector3, spots: { Spot }, avoid: Vector3?): boolean
	local spacing = DigZoneConfig.MinSpotSpacing
	if avoid and (point - avoid).Magnitude < spacing then
		return false
	end
	for _, spot in spots do
		if (point - spot.Position).Magnitude < spacing then
			return false
		end
	end
	return true
end

local function pickPoint(spots: { Spot }, avoid: Vector3?): Vector3
	local point = randomPoint()
	for _ = 1, DigZoneConfig.SpotPlacementTries do
		if isFarEnough(point, spots, avoid) then
			return point
		end
		point = randomPoint()
	end
	return point
end

local function fill(spots: { Spot }, avoid: Vector3?)
	while #spots < DigZoneConfig.SpotsPerPlayer do
		table.insert(spots, { Position = pickPoint(spots, avoid), OreId = nil })
	end
end

local function getSpots(player: Player): { Spot }
	local spots = spotsByPlayer[player]
	if spots == nil then
		spots = {}
		fill(spots, nil)
		spotsByPlayer[player] = spots
	end
	return spots
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function scheduleRespawn(player: Player, removed: Vector3)
	task.delay(DigZoneConfig.SpotRespawnSeconds, function()
		local spots = spotsByPlayer[player]
		if spots == nil or player.Parent == nil then
			return
		end
		fill(spots, removed)
	end)
end

function DigSpotService.FindNearest(player: Player, point: Vector3): (Spot?, number)
	local nearest: Spot? = nil
	local bestDistance = math.huge
	for _, spot in getSpots(player) do
		local distance = flatDistance(spot.Position, point)
		if distance < bestDistance then
			nearest = spot
			bestDistance = distance
		end
	end
	return nearest, bestDistance
end

function DigSpotService.GetWithin(player: Player, point: Vector3, radius: number): { Spot }
	local found = {}
	for _, spot in getSpots(player) do
		if flatDistance(spot.Position, point) < radius then
			table.insert(found, spot)
		end
	end
	return found
end

function DigSpotService.EnsureOre(spot: Spot, luck: number): string
	local oreId = spot.OreId
	if oreId == nil then
		oreId = DigOreRoller.Roll(luck)
		spot.OreId = oreId
	end
	return oreId
end

function DigSpotService.Consume(player: Player, spot: Spot): boolean
	local spots = spotsByPlayer[player]
	local index = spots and table.find(spots, spot)
	if spots == nil or index == nil then
		return false
	end
	table.remove(spots, index)
	scheduleRespawn(player, spot.Position)
	return true
end

function DigSpotService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	Players.PlayerRemoving:Connect(function(player: Player)
		spotsByPlayer[player] = nil
	end)
end

return DigSpotService
