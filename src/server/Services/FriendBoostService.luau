--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local FriendBoostConfig = require(shared:WaitForChild("Config"):WaitForChild("FriendBoostConfig"))

local PERCENT_SCALE = 100

local FriendBoostService = {}

local isInitialized = false
local friendships: { [Player]: { [Player]: boolean } } = {}
local luckByPlayer: { [Player]: number } = {}

local function checkFriends(player: Player, other: Player): (boolean, boolean)
	local ok, result = pcall(function()
		return player:IsFriendsWith(other.UserId)
	end)
	if not ok then
		warn("[FriendBoostService] IsFriendsWith failed:", result)
		return false, false
	end
	return true, result == true
end

local function refreshLuck(player: Player)
	local friends = friendships[player]
	if friends == nil then
		return
	end
	local count = 0
	for _ in friends do
		count += 1
	end
	local luck = math.min(count, FriendBoostConfig.MaxFriends) * FriendBoostConfig.LuckPerFriend
	luckByPlayer[player] = luck
	local percent = math.floor(luck * PERCENT_SCALE + 0.5)
	player:SetAttribute(FriendBoostConfig.LuckPercentAttribute, percent)
end

local function linkFriends(player: Player, other: Player)
	local playerFriends, otherFriends = friendships[player], friendships[other]
	if playerFriends == nil or otherFriends == nil then
		return
	end
	playerFriends[other] = true
	otherFriends[player] = true
	refreshLuck(other)
end

local function retryCheck(player: Player, other: Player)
	if friendships[player] == nil or friendships[other] == nil then
		return
	end
	local ok, isFriend = checkFriends(player, other)
	if ok and isFriend then
		linkFriends(player, other)
		refreshLuck(player)
	end
end

local function onPlayerAdded(player: Player)
	friendships[player] = {}
	refreshLuck(player)
	for _, other in Players:GetPlayers() do
		if other == player then
			continue
		end
		local ok, isFriend = checkFriends(player, other)
		if isFriend then
			linkFriends(player, other)
		elseif not ok then
			task.delay(FriendBoostConfig.FriendCheckRetryDelay, retryCheck, player, other)
		end
	end
	refreshLuck(player)
end

local function onPlayerRemoving(player: Player)
	local friends = friendships[player]
	friendships[player] = nil
	luckByPlayer[player] = nil
	for other in friends or {} do
		local otherFriends = friendships[other]
		if otherFriends then
			otherFriends[player] = nil
			refreshLuck(other)
		end
	end
end

function FriendBoostService.GetLuck(player: Player): number
	return luckByPlayer[player] or 0
end

function FriendBoostService.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return FriendBoostService
