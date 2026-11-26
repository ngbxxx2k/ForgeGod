--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local DigToolConfig = require(shared:WaitForChild("Config"):WaitForChild("DigToolConfig"))
local DigZoneConfig = require(shared:WaitForChild("Config"):WaitForChild("DigZoneConfig"))
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local DigZone = require(shared:WaitForChild("Utils"):WaitForChild("DigZone"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DigService = require(script.Parent.Parent.Services.DigService)
local DigLuckService = require(script.Parent.Parent.Services.DigLuckService)
local DigSpotService = require(script.Parent.Parent.Services.DigSpotService)
local DigToolService = require(script.Parent.Parent.Services.DigToolService)
local DigOreRoller = require(script.Parent.Parent.Internal.DigOreRoller)

local REMOTES_FOLDER_NAME = "Remotes"
local ROOT_PART_NAME = "HumanoidRootPart"
local NO_SIGNAL = 0
local FULL_SIGNAL = 1
local ON_SPOT_KEY_OFFSET = 10
local MARKER_KEY_FORMAT = "%.2f:%.2f:%s"
local MARKER_KEY_SEPARATOR = "|"

type Marker = {
	Position: Vector3,
	Rarity: string,
}

local DigScanSystem = {}

local isInitialized = false
local notifySignal: RemoteEvent? = nil
local lastSignal: { [Player]: number } = {}
local notifyMarkers: RemoteEvent? = nil
local lastMarkerKey: { [Player]: string } = {}

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild(ROOT_PART_NAME)
	return if root and root:IsA("BasePart") then root else nil
end

local function getDetector(player: Player): DigToolConfig.ToolTier?
	local tierIndex = DataActions.GetDigToolTier(player, DigToolConfig.ToolIds.Detector) or DigToolConfig.MinTier
	return DigToolConfig.GetTier(DigToolConfig.ToolIds.Detector, tierIndex)
end

local function getRadius(player: Player): number
	local tier = getDetector(player)
	return if tier and tier.Radius then tier.Radius else DigZoneConfig.OnSpotDistance
end

local function computeSignal(player: Player, root: BasePart): (number, boolean)
	local _, distance = DigSpotService.FindNearest(player, DigZone.GetScanPoint(root.CFrame))
	local isOnSpot = distance <= DigZoneConfig.OnSpotDistance
	local radius = getRadius(player)
	if distance <= radius then
		return FULL_SIGNAL, isOnSpot
	end
	local senseRange = radius * DigZoneConfig.SenseRangeMultiplier
	if distance >= senseRange then
		return NO_SIGNAL, false
	end
	local steps = DigZoneConfig.SignalSteps
	local closeness = 1 - (distance - radius) / (senseRange - radius)
	local strength = math.ceil(closeness * steps) / steps
	return math.clamp(strength, 1 / steps, 1 - 1 / steps), false
end

local function sendSignal(player: Player, strength: number, isOnSpot: boolean)
	local key = strength + (if isOnSpot then ON_SPOT_KEY_OFFSET else 0)
	if lastSignal[player] == key then
		return
	end
	lastSignal[player] = key
	if notifySignal then
		notifySignal:FireClient(player, strength, isOnSpot)
	end
end

local function buildMarkers(player: Player, root: BasePart): ({ Marker }, string)
	local markers: { Marker } = {}
	local keys = {}
	local spots = DigSpotService.GetWithin(player, DigZone.GetScanPoint(root.CFrame), getRadius(player))
	for _, spot in spots do
		local rarity = DigOreRoller.GetRarity(DigSpotService.EnsureOre(spot, DigLuckService.GetLuck(player)))
		table.insert(markers, { Position = spot.Position, Rarity = rarity })
		table.insert(keys, string.format(MARKER_KEY_FORMAT, spot.Position.X, spot.Position.Z, rarity))
	end
	table.sort(keys)
	return markers, table.concat(keys, MARKER_KEY_SEPARATOR)
end

local function sendMarkers(player: Player, markers: { Marker }, key: string)
	if lastMarkerKey[player] == key then
		return
	end
	lastMarkerKey[player] = key
	if notifyMarkers then
		notifyMarkers:FireClient(player, markers)
	end
end

local function scanPlayer(player: Player)
	local root = getRoot(player)
	if root == nil or not DataService.IsLoaded(player) or DigService.IsDigging(player) then
		return
	end
	if not DigZone.IsInside(root.Position) then
		if DigToolService.GetShown(player) ~= nil then
			DigToolService.Hide(player)
		end
		sendSignal(player, NO_SIGNAL, false)
		sendMarkers(player, {}, "")
		return
	end
	DigToolService.Show(player, DigToolConfig.ToolIds.Detector)
	sendSignal(player, computeSignal(player, root))
	sendMarkers(player, buildMarkers(player, root))
end

local function runLoop()
	while true do
		for _, player in Players:GetPlayers() do
			local ok, err = pcall(scanPlayer, player)
			if not ok then
				warn("[DigScanSystem] Scan failed:", player.Name, err)
			end
		end
		task.wait(DigZoneConfig.ScanInterval)
	end
end

local function getRemotesFolder(): Instance
	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end
	return remotesFolder :: Instance
end

local function createRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = getRemotesFolder()
	return remote
end

function DigScanSystem.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	notifySignal = createRemote(RemoteNames.NotifyDigSignal)
	notifyMarkers = createRemote(RemoteNames.NotifyDigMarkers)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastSignal[player] = nil
		lastMarkerKey[player] = nil
	end)
	task.spawn(runLoop)
end

return DigScanSystem
