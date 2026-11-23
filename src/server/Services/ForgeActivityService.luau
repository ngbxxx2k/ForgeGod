--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerAttributes = require(shared:WaitForChild("Constants"):WaitForChild("PlayerAttributes"))
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local StationConfig = require(shared:WaitForChild("Config"):WaitForChild("StationConfig"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local StationRange = require(script.Parent.Parent.Security.StationRange)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "ForgeStance"
local MAX_WEAPON_ID_LENGTH = 64

export type StrikeInfo = {
	WeaponType: string,
	ShapeStage: number,
	State: string,
	Mutation: string?,
	IsNewMutation: boolean,
	FrenzyTimeLeft: number,
}

local ForgeActivityService = {}

local isInitialized = false
local notifyForgeStrike: RemoteEvent? = nil
local stanceCounters: { [Player]: number } = {}

local function getShapeStage(weapon: any): number
	return weapon.ShapeStage or DataTemplate.Limits.MinShapeStage
end

local function clearStance(player: Player)
	player:SetAttribute(PlayerAttributes.ForgeWeaponType, nil)
	player:SetAttribute(PlayerAttributes.ForgeShapeStage, nil)
	player:SetAttribute(PlayerAttributes.ForgeStanceId, nil)
end

local function nextStanceId(player: Player): number
	local stanceId = (stanceCounters[player] or 0) + 1
	stanceCounters[player] = stanceId
	return stanceId
end

local function setStance(player: Player, weaponId: string)
	if not StationRange.IsNear(player, StationConfig.ForgeModelName) then
		return
	end
	local weapon = DataActions.GetWeapon(player, weaponId)
	if weapon == nil then
		return
	end
	player:SetAttribute(PlayerAttributes.ForgeWeaponType, weapon.WeaponType)
	player:SetAttribute(PlayerAttributes.ForgeShapeStage, getShapeStage(weapon))
	player:SetAttribute(PlayerAttributes.ForgeStanceId, nextStanceId(player))
end

local function onRequestStance(player: Player, weaponId: any)
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		return
	end
	if weaponId == nil then
		clearStance(player)
		return
	end
	if type(weaponId) ~= "string" or #weaponId > MAX_WEAPON_ID_LENGTH then
		return
	end
	if not DataService.IsLoaded(player) then
		return
	end
	setStance(player, weaponId)
end

local function buildStrikeInfo(weapon: any, result: any): StrikeInfo
	return {
		WeaponType = weapon.WeaponType,
		ShapeStage = result.ShapeStage,
		State = result.State,
		Mutation = if result.IsNewMutation then result.Mutation else nil,
		IsNewMutation = result.IsNewMutation == true,
		FrenzyTimeLeft = result.FrenzyTimeLeft,
	}
end

function ForgeActivityService.BroadcastStrike(player: Player, result: any)
	local remote = notifyForgeStrike
	local weapon = DataActions.GetWeapon(player, result.WeaponId)
	if remote == nil or weapon == nil then
		return
	end
	local info = buildStrikeInfo(weapon, result)
	player:SetAttribute(PlayerAttributes.ForgeShapeStage, info.ShapeStage)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			remote:FireClient(other, player.UserId, info)
		end
	end
end

function ForgeActivityService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end
	local requestStance = Instance.new("RemoteEvent")
	requestStance.Name = RemoteNames.RequestForgeStance
	requestStance.Parent = remotesFolder
	local notifyRemote = Instance.new("RemoteEvent")
	notifyRemote.Name = RemoteNames.NotifyForgeStrike
	notifyRemote.Parent = remotesFolder
	notifyForgeStrike = notifyRemote

	requestStance.OnServerEvent:Connect(onRequestStance)
	Players.PlayerRemoving:Connect(function(player: Player)
		stanceCounters[player] = nil
	end)
end

return ForgeActivityService
