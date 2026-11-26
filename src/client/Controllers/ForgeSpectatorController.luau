--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)
local PlayerAttributes = require(ReplicatedStorage.Shared.Constants.PlayerAttributes)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local PlotStations = require(ReplicatedStorage.Shared.Utils.PlotStations)
local ForgeHammerSkin = require(script.Parent.Parent.Effects.ForgeHammerSkin)
local ForgeSpectatorSession = require(script.Parent.Parent.Effects.ForgeSpectatorSession)
local ForgeStation = require(script.Parent.Parent.Effects.ForgeStation)

type Session = ForgeSpectatorSession.Session
type StrikeInfo = ForgeSpectatorSession.StrikeInfo

local REMOTES_FOLDER_NAME = "Remotes"

local ForgeSpectatorController = {}

local isInitialized = false
local sessions: { [Player]: Session } = {}
local connectionsByPlayer: { [Player]: { RBXScriptConnection } } = {}
local stanceIds: { [Player]: any } = {}

local function endSession(player: Player)
	local session = sessions[player]
	sessions[player] = nil
	if session then
		ForgeSpectatorSession.Stop(session)
	end
end

local function beginSession(player: Player, weaponType: string, shapeStage: number): Session?
	local character = player.Character
	local anvil = PlotStations.FindOwnedStation(player.UserId, StationConfig.ForgeModelName)
	local anvilPart = anvil and ForgeStation.GetAnvilPart(anvil)
	local hammer = ForgeHammerSkin.CreateTemplate(player)
	if character == nil or anvilPart == nil or hammer == nil then
		return nil
	end
	local session = ForgeSpectatorSession.Start(character, anvilPart, hammer, weaponType, shapeStage)
	hammer:Destroy()
	sessions[player] = session
	return session
end

local function readShapeStage(player: Player): number
	local stage = player:GetAttribute(PlayerAttributes.ForgeShapeStage)
	return if type(stage) == "number" then stage else ForgeStrikeConfig.DefaultShapeStage
end

local function sync(player: Player)
	local weaponType = player:GetAttribute(PlayerAttributes.ForgeWeaponType)
	local stanceId = player:GetAttribute(PlayerAttributes.ForgeStanceId)
	local current = sessions[player]
	if type(weaponType) ~= "string" then
		endSession(player)
		return
	end
	if current and stanceIds[player] == stanceId and current.Character == player.Character then
		return
	end
	endSession(player)
	stanceIds[player] = stanceId
	beginSession(player, weaponType, readShapeStage(player))
end

local function onStrike(userId: any, info: any)
	local player = if type(userId) == "number" then Players:GetPlayerByUserId(userId) else nil
	if player == nil or player == Players.LocalPlayer or type(info) ~= "table" then
		return
	end
	local session = sessions[player]
	if session == nil and type(info.WeaponType) == "string" then
		session = beginSession(player, info.WeaponType, readShapeStage(player))
	end
	if session then
		ForgeSpectatorSession.Strike(session, info :: StrikeInfo)
	end
end

local function watchPlayer(player: Player)
	if player == Players.LocalPlayer or connectionsByPlayer[player] then
		return
	end
	connectionsByPlayer[player] = {
		player:GetAttributeChangedSignal(PlayerAttributes.ForgeWeaponType):Connect(function()
			sync(player)
		end),
		player:GetAttributeChangedSignal(PlayerAttributes.ForgeStanceId):Connect(function()
			sync(player)
		end),
		player.CharacterRemoving:Connect(function()
			endSession(player)
		end),
		player.CharacterAdded:Connect(function()
			sync(player)
		end),
	}
	sync(player)
end

local function unwatchPlayer(player: Player)
	endSession(player)
	stanceIds[player] = nil
	local connections = connectionsByPlayer[player]
	connectionsByPlayer[player] = nil
	for _, connection in connections or {} do
		connection:Disconnect()
	end
end

function ForgeSpectatorController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(unwatchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
		local strikeRemote = remotes:WaitForChild(RemoteNames.NotifyForgeStrike) :: RemoteEvent
		strikeRemote.OnClientEvent:Connect(onStrike)
	end)
end

return ForgeSpectatorController
