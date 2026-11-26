--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local WeaponWeightConfig = require(shared:WaitForChild("Config"):WaitForChild("WeaponWeightConfig"))
local SpinConfig = require(shared:WaitForChild("Config"):WaitForChild("SpinConfig"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)

local REMOTES_FOLDER_NAME = "Remotes"

local PlayerStateService = {}

local isInitialized = false
local notifyPlayerState: RemoteEvent? = nil
local pendingPlayers: { [Player]: boolean } = {}

local function buildWeaponSummary(weapon: any): { [string]: any }
	return {
		Id = weapon.Id,
		Rarity = weapon.Rarity,
		WeaponType = weapon.WeaponType,
		State = weapon.State,
		Level = weapon.Level,
		ForgePoints = weapon.ForgePoints,
		ShapeStage = weapon.ShapeStage,
		Mutation = weapon.Mutation,
		Scale = weapon.Scale or WeaponWeightConfig.MinScale,
		Value = weapon.Value,
		IsLocked = weapon.IsLocked == true,
	}
end

local function buildActiveBuffs(data: any): { [string]: number }
	local now = os.time()
	local activeBuffs = {}
	for itemId, expiresAt in data.ActiveBuffs do
		if expiresAt > now then
			activeBuffs[itemId] = expiresAt
		end
	end
	return activeBuffs
end

local function buildSpinState(data: any): { [string]: number }
	local spin = if type(data.Spin) == "table" then data.Spin else {}
	return {
		Tokens = spin.Tokens or 0,
		NextFreeAt = (spin.LastFreeAt or 0) + SpinConfig.FreeSpinCooldown,
	}
end

local function cloneOwnedTiers(source: any): { [string]: { number } }
	local ownedTiers = {}
	for trackId, tiers in source or {} do
		ownedTiers[trackId] = table.clone(tiers)
	end
	return ownedTiers
end

local function buildTutorialState(data: any): { [string]: any }
	local tutorial = if type(data.Tutorial) == "table" then data.Tutorial else {}
	return {
		StepId = tutorial.StepId,
		DigCount = tutorial.DigCount or 0,
		IsComplete = tutorial.IsComplete == true,
	}
end

local function buildPayload(data: any): { [string]: any }
	local weapons = {}
	for _, weapon in data.Weapons do
		table.insert(weapons, buildWeaponSummary(weapon))
	end
	return {
		Coins = data.Coins,
		Items = table.clone(data.Items),
		Weapons = weapons,
		Equipped = table.clone(data.Equipped),
		Capacity = data.Capacity.Items,
		LoadoutCapacity = data.Capacity.Loadout,
		ActiveBuffs = buildActiveBuffs(data),
		ArmedBuffs = table.clone(data.ArmedBuffs),
		DigTools = table.clone(data.DigTools or {}),
		OwnedDigTiers = cloneOwnedTiers(data.OwnedDigTiers),
		OwnedForgeTiers = cloneOwnedTiers(data.OwnedForgeTiers),
		ForgeSkins = table.clone(data.ForgeSkins or {}),
		Index = table.clone(data.Index or {}),
		IndexRewards = table.clone(data.IndexRewards or {}),
		Spin = buildSpinState(data),
		Tutorial = buildTutorialState(data),
	}
end

function PlayerStateService.Send(player: Player)
	local remote = notifyPlayerState
	if remote == nil or player.Parent == nil then
		return
	end
	local data = DataService.GetData(player)
	if data == nil then
		return
	end
	remote:FireClient(player, buildPayload(data))
end

local function queueSend(player: Player)
	if pendingPlayers[player] then
		return
	end
	pendingPlayers[player] = true
	task.defer(function()
		pendingPlayers[player] = nil
		PlayerStateService.Send(player)
	end)
end

local function handlePlayerRemoving(player: Player)
	pendingPlayers[player] = nil
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

function PlayerStateService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remote = Instance.new("RemoteEvent")
	remote.Name = RemoteNames.NotifyPlayerState
	remote.Parent = getRemotesFolder()
	notifyPlayerState = remote

	DataService.OnProfileLoaded(queueSend)
	DataActions.OnDataChanged(queueSend)
	Players.PlayerRemoving:Connect(handlePlayerRemoving)
	for _, player in Players:GetPlayers() do
		queueSend(player)
	end
end

return PlayerStateService
