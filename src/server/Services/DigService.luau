--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local DigToolConfig = require(shared:WaitForChild("Config"):WaitForChild("DigToolConfig"))
local DigZoneConfig = require(shared:WaitForChild("Config"):WaitForChild("DigZoneConfig"))
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local TutorialConfig = require(shared:WaitForChild("Config"):WaitForChild("TutorialConfig"))
local DigZone = require(shared:WaitForChild("Utils"):WaitForChild("DigZone"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DigOreRoller = require(script.Parent.Parent.Internal.DigOreRoller)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local DigLuckService = require(script.Parent.DigLuckService)
local DigSpotService = require(script.Parent.DigSpotService)
local DigToolService = require(script.Parent.DigToolService)
local TutorialService = require(script.Parent.TutorialService)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "Dig"
local ROOT_PART_NAME = "HumanoidRootPart"

type Session = {
	Spot: DigSpotService.Spot,
	OreId: string,
}

local DigService = {}

local isInitialized = false
local notifyStarted: RemoteEvent? = nil
local notifyResult: RemoteEvent? = nil
local sessions: { [Player]: Session } = {}

local function sendResult(player: Player, ok: boolean, reason: string?, oreId: string?)
	if notifyResult ~= nil and player.Parent ~= nil then
		notifyResult:FireClient(player, ok, reason, oreId)
	end
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild(ROOT_PART_NAME)
	return if root and root:IsA("BasePart") then root else nil
end

local function getStat(player: Player, toolId: string, field: string): number
	local tier = DataActions.GetDigToolTier(player, toolId) or DigToolConfig.MinTier
	local info = DigToolConfig.GetTier(toolId, tier)
	local value = info and (info :: any)[field]
	return if type(value) == "number" then value else 1
end

local function findSpotUnder(player: Player, root: BasePart): (DigSpotService.Spot?, string?)
	if not DigZone.IsInside(root.Position) then
		return nil, "NotInZone"
	end
	local spot, distance = DigSpotService.FindNearest(player, DigZone.GetScanPoint(root.CFrame))
	if spot == nil or distance > DigZoneConfig.OnSpotDistance + DigZoneConfig.ServerSpotTolerance then
		return nil, "NoSpot"
	end
	return spot, nil
end

local function isStillAtSpot(player: Player, spot: Vector3): boolean
	local root = getRoot(player)
	if root == nil then
		return false
	end
	local reach = DigZoneConfig.DigTipOffset.Magnitude + DigZoneConfig.MaxDigMoveDistance
	return DigZone.FlatDistance(root.Position, spot) <= reach
end

local function finish(player: Player, session: Session)
	if sessions[player] ~= session then
		return
	end
	sessions[player] = nil
	if player.Parent == nil or not DataService.IsLoaded(player) then
		return
	end
	DigToolService.Show(player, DigToolConfig.ToolIds.Detector)
	if not isStillAtSpot(player, session.Spot.Position) or not DigSpotService.Consume(player, session.Spot) then
		sendResult(player, false, "Interrupted")
		return
	end
	local ok, reason = DataActions.TryAddItem(player, session.OreId, 1)
	if not ok then
		warn("[DigService] Failed to add ore:", player.Name, reason)
		sendResult(player, false, reason)
		return
	end
	sendResult(player, true, nil, session.OreId)
	TutorialService.Report(player, TutorialConfig.Events.OreDug)
end

local function startDig(player: Player, root: BasePart): (boolean, string?)
	local spot, reason = findSpotUnder(player, root)
	if spot == nil then
		return false, reason
	end
	if not DigToolService.Show(player, DigToolConfig.ToolIds.Shovel) then
		return false, "NoCharacter"
	end
	local oreId = DigSpotService.EnsureOre(spot, DigLuckService.GetLuck(player))
	local speed = getStat(player, DigToolConfig.ToolIds.Shovel, "Speed")
	local duration = DigZoneConfig.GetDigSeconds(DigOreRoller.GetRarity(oreId), speed)
	local session: Session = { Spot = spot, OreId = oreId }
	sessions[player] = session
	if notifyStarted then
		notifyStarted:FireClient(player, spot.Position, duration)
	end
	task.delay(duration + DigZoneConfig.ResultGraceSeconds, finish, player, session)
	return true, nil
end

local function onRequestDig(player: Player)
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded")
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited")
		return
	end
	if sessions[player] ~= nil then
		sendResult(player, false, "AlreadyDigging")
		return
	end
	local root = getRoot(player)
	if root == nil then
		sendResult(player, false, "NoCharacter")
		return
	end
	local ok, reason = startDig(player, root)
	if not ok then
		sendResult(player, false, reason)
	end
end

function DigService.IsDigging(player: Player): boolean
	return sessions[player] ~= nil
end

local function cancel(player: Player)
	if sessions[player] ~= nil then
		sessions[player] = nil
		sendResult(player, false, "Interrupted")
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterRemoving:Connect(function()
		cancel(player)
	end)
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

local function createRemote(name: string, parent: Instance): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function DigService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestDig = createRemote(RemoteNames.RequestDig, remotesFolder)
	notifyStarted = createRemote(RemoteNames.NotifyDigStarted, remotesFolder)
	notifyResult = createRemote(RemoteNames.NotifyDigResult, remotesFolder)
	requestDig.OnServerEvent:Connect(onRequestDig)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		sessions[player] = nil
	end)
end

return DigService
