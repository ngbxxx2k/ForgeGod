--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local LeaderboardConfig = require(shared:WaitForChild("Config"):WaitForChild("LeaderboardConfig"))
local LeaderboardTypes = require(shared:WaitForChild("Types"):WaitForChild("LeaderboardTypes"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local LeaderboardService = require(script.Parent.Parent.Data.LeaderboardService)
local LeaderboardDisplayService = require(script.Parent.Parent.Services.LeaderboardDisplayService)

local POLL_INTERVAL = 1
local MAX_USER_INFO_BATCH = 200

local LeaderboardSystem = {}

local isInitialized = false
local currentCycle = -1
local nameCache: { [number]: string } = {}
local lastBoards: { [string]: { LeaderboardTypes.Entry } } = {}

local function getCycleIndex(): number
	return math.floor(os.time() / LeaderboardConfig.RefreshInterval)
end

local function collectScores(player: Player): { [string]: number }?
	local data = DataService.GetData(player)
	if data == nil or type(data.Stats) ~= "table" then
		return nil
	end
	local scores: { [string]: number } = {}
	for _, board in LeaderboardConfig.Boards do
		local value = data.Stats[board.StatName]
		if type(value) == "number" then
			scores[board.Id] = value
		end
	end
	return scores
end

local function submitScores(userId: number, scores: { [string]: number })
	for boardId, value in scores do
		LeaderboardService.Submit(boardId, userId, value)
	end
end

local function submitAllPlayers()
	for _, player in Players:GetPlayers() do
		if DataService.IsLoaded(player) then
			local scores = collectScores(player)
			if scores then
				submitScores(player.UserId, scores)
			end
		end
	end
end

local function rememberName(userId: number, name: any)
	if type(name) == "string" and name ~= "" then
		nameCache[userId] = name
	end
end

local function resolveNames(userIds: { number })
	local missing: { number } = {}
	for _, userId in userIds do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			rememberName(userId, player.Name)
		elseif nameCache[userId] == nil and #missing < MAX_USER_INFO_BATCH then
			table.insert(missing, userId)
		end
	end
	if #missing == 0 then
		return
	end
	local ok, result = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(missing)
	end)
	if not ok then
		warn("[LeaderboardSystem] Name lookup failed:", result)
		return
	end
	for _, info in result do
		rememberName(info.Id, info.Username)
	end
end

local function fetchBoards(): { [string]: { LeaderboardService.RawEntry } }
	local fetched: { [string]: { LeaderboardService.RawEntry } } = {}
	for _, board in LeaderboardConfig.Boards do
		local entries = LeaderboardService.FetchTop(board.Id, LeaderboardConfig.TopCount)
		if entries then
			fetched[board.Id] = entries
		end
	end
	return fetched
end

local function collectUserIds(fetched: { [string]: { LeaderboardService.RawEntry } }): { number }
	local seen: { [number]: boolean } = {}
	local userIds: { number } = {}
	for _, entries in fetched do
		for _, entry in entries do
			if not seen[entry.UserId] then
				seen[entry.UserId] = true
				table.insert(userIds, entry.UserId)
			end
		end
	end
	return userIds
end

local function toEntries(rawEntries: { LeaderboardService.RawEntry }): { LeaderboardTypes.Entry }
	local entries: { LeaderboardTypes.Entry } = {}
	for _, raw in rawEntries do
		table.insert(entries, {
			UserId = raw.UserId,
			Name = nameCache[raw.UserId] or "",
			Score = raw.Score,
		})
	end
	return entries
end

local function refresh(cycle: number)
	submitAllPlayers()
	local fetched = fetchBoards()
	resolveNames(collectUserIds(fetched))
	for boardId, rawEntries in fetched do
		lastBoards[boardId] = toEntries(rawEntries)
	end
	LeaderboardDisplayService.SetBoards({
		Cycle = cycle,
		Boards = table.clone(lastBoards),
	})
end

local function refreshIfNeeded()
	local cycle = getCycleIndex()
	if cycle == currentCycle then
		return
	end
	currentCycle = cycle
	refresh(cycle)
end

local function onSessionEnding(player: Player)
	local scores = collectScores(player)
	if scores then
		task.spawn(submitScores, player.UserId, scores)
	end
end

function LeaderboardSystem.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	DataService.OnProfileLoaded(DataActions.RefreshHighestStats)
	DataService.OnSessionEnding(onSessionEnding)

	task.spawn(function()
		while isInitialized do
			refreshIfNeeded()
			task.wait(POLL_INTERVAL)
		end
	end)
end

return LeaderboardSystem
