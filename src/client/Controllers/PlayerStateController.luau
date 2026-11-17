--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)

type PlayerState = PlayerStateTypes.PlayerState

local REMOTES_FOLDER_NAME = "Remotes"

local PlayerStateController = {}

local isInitialized = false
local currentState: PlayerState? = nil
local listeners: { (PlayerState) -> () } = {}

local function isValidState(state: any): boolean
	return type(state) == "table"
		and type(state.Coins) == "number"
		and type(state.Items) == "table"
		and type(state.Weapons) == "table"
		and type(state.Equipped) == "table"
		and type(state.Capacity) == "number"
end

local function onPlayerState(state: any)
	if not isValidState(state) then
		warn("[PlayerStateController] Invalid player state")
		return
	end
	local validState = state :: PlayerState
	currentState = validState
	for _, listener in listeners do
		task.spawn(listener, validState)
	end
end

function PlayerStateController.GetState(): PlayerState?
	return currentState
end

function PlayerStateController.OnChanged(listener: (PlayerState) -> ())
	table.insert(listeners, listener)
end

function PlayerStateController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	local stateRemote = remotes:WaitForChild(RemoteNames.NotifyPlayerState) :: RemoteEvent
	stateRemote.OnClientEvent:Connect(onPlayerState)
end

return PlayerStateController
