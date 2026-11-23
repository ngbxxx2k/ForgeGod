--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LeaderboardConfig = require(ReplicatedStorage.Shared.Config.LeaderboardConfig)
local LeaderboardMessages = require(ReplicatedStorage.Shared.Constants.LeaderboardMessages)
local LeaderboardTypes = require(ReplicatedStorage.Shared.Types.LeaderboardTypes)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local LeaderboardBoard = require(script.Parent.Parent.UI.Components.LeaderboardBoard)

local REMOTES_FOLDER_NAME = "Remotes"
local COUNTDOWN_INTERVAL = 1
local SECONDS_PER_MINUTE = 60

local LeaderboardController = {}

local isInitialized = false
local boards: { [string]: LeaderboardBoard.Board } = {}
local latestBoards: { [string]: { LeaderboardTypes.Entry } } = {}

local function isValidEntry(entry: any): boolean
	return type(entry) == "table"
		and type(entry.UserId) == "number"
		and type(entry.Name) == "string"
		and type(entry.Score) == "number"
end

local function sanitizeEntries(entries: any): { LeaderboardTypes.Entry }
	local result: { LeaderboardTypes.Entry } = {}
	if type(entries) ~= "table" then
		return result
	end
	for _, entry in entries do
		if isValidEntry(entry) and #result < LeaderboardConfig.TopCount then
			table.insert(result, entry)
		end
	end
	return result
end

local function renderBoard(boardId: string)
	local board = boards[boardId]
	if board then
		LeaderboardBoard.Render(board, latestBoards[boardId] or {})
	end
end

local function onLeaderboards(payload: any)
	if type(payload) ~= "table" or type(payload.Boards) ~= "table" then
		return
	end
	for _, definition in LeaderboardConfig.Boards do
		local entries = payload.Boards[definition.Id]
		if entries ~= nil then
			latestBoards[definition.Id] = sanitizeEntries(entries)
			renderBoard(definition.Id)
		end
	end
end

local function getCountdownText(): string
	local interval = LeaderboardConfig.RefreshInterval
	local now = Workspace:GetServerTimeNow()
	local remaining = math.max(0, math.ceil((math.floor(now / interval) + 1) * interval - now))
	local minutes = math.floor(remaining / SECONDS_PER_MINUTE)
	return string.format(LeaderboardMessages.UpdateFormat, minutes, remaining % SECONDS_PER_MINUTE)
end

local function updateCountdowns()
	local text = getCountdownText()
	for _, board in boards do
		LeaderboardBoard.SetFooter(board, text)
	end
end

local function findHub(): Instance
	local node: Instance = Workspace
	for _, name in LeaderboardConfig.HubFolderPath do
		node = node:WaitForChild(name)
	end
	return node
end

local function mountBoard(
	hub: Instance,
	definition: LeaderboardConfig.BoardDefinition,
	playerGui: Instance
)
	local model = hub:WaitForChild(definition.ModelName)
	local panel = model:WaitForChild(LeaderboardConfig.PanelName)
	if not panel:IsA("BasePart") then
		warn("[LeaderboardController] Panel is not a part:", definition.ModelName)
		return
	end
	local board = LeaderboardBoard.Build(definition)
	LeaderboardBoard.Mount(board, panel, playerGui)
	boards[definition.Id] = board
	LeaderboardBoard.SetFooter(board, getCountdownText())
	renderBoard(definition.Id)
end

local function mountAll()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local hub = findHub()
	for _, definition in LeaderboardConfig.Boards do
		task.spawn(mountBoard, hub, definition, playerGui)
	end
end

function LeaderboardController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	task.spawn(mountAll)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
		local remote = remotes:WaitForChild(RemoteNames.NotifyLeaderboards) :: RemoteEvent
		remote.OnClientEvent:Connect(onLeaderboards)
	end)
	task.spawn(function()
		while isInitialized do
			updateCountdowns()
			task.wait(COUNTDOWN_INTERVAL)
		end
	end)
end

return LeaderboardController
