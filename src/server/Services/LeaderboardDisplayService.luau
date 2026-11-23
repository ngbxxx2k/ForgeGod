--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local LeaderboardTypes = require(shared:WaitForChild("Types"):WaitForChild("LeaderboardTypes"))

local REMOTES_FOLDER_NAME = "Remotes"

local LeaderboardDisplayService = {}

local isInitialized = false
local notifyLeaderboards: RemoteEvent? = nil
local currentPayload: LeaderboardTypes.Payload? = nil

local function getRemotesFolder(): Instance
	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end
	return remotesFolder :: Instance
end

local function sendTo(player: Player)
	local remote = notifyLeaderboards
	if remote and currentPayload then
		remote:FireClient(player, currentPayload)
	end
end

function LeaderboardDisplayService.SetBoards(payload: LeaderboardTypes.Payload)
	currentPayload = payload
	local remote = notifyLeaderboards
	if remote then
		remote:FireAllClients(payload)
	end
end

function LeaderboardDisplayService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remote = Instance.new("RemoteEvent")
	remote.Name = RemoteNames.NotifyLeaderboards
	remote.Parent = getRemotesFolder()
	notifyLeaderboards = remote

	Players.PlayerAdded:Connect(sendTo)
	for _, player in Players:GetPlayers() do
		task.spawn(sendTo, player)
	end
end

return LeaderboardDisplayService
