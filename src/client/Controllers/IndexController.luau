--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IndexScreen = require(script.Parent.Parent.UI.Screens.IndexScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local IndexData = require(script.Parent.IndexData)
local PlayerStateController = require(script.Parent.PlayerStateController)
local IndexMessages = require(ReplicatedStorage.Shared.Constants.IndexMessages)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)

type PlayerState = PlayerStateTypes.PlayerState

local REMOTES_FOLDER_NAME = "Remotes"

local IndexController = {}

local isInitialized = false
local isClaimPending = false
local selectedTabId: string? = nil
local currentIndex: { [string]: boolean } = {}
local currentClaims: { [string]: boolean } = {}
local renderedCount = -1
local renderedClaimCount = -1
local requestClaim: RemoteEvent? = nil

local function getCollections(tabId: string)
	return IndexData.GetCollections(tabId, currentIndex, currentClaims)
end

local function render()
	local tabId = selectedTabId
	if tabId == nil then
		return
	end
	IndexScreen.RenderCollections(getCollections(tabId))
	IndexScreen.SetTotalProgress(IndexData.GetTabProgress(tabId, currentIndex))
end

local function refreshRewards()
	local tabId = selectedTabId
	if tabId then
		IndexScreen.RefreshRewards(getCollections(tabId))
	end
end

local function selectTab(tabId: string)
	selectedTabId = tabId
	render()
end

local function onStateChanged(state: PlayerState)
	local index = state.Index or {}
	local claims = state.IndexRewards or {}
	local count = IndexData.CountKeys(index)
	local claimCount = IndexData.CountKeys(claims)
	local isIndexChanged = count ~= renderedCount
	local isClaimsChanged = claimCount ~= renderedClaimCount
	renderedCount, renderedClaimCount = count, claimCount
	currentIndex, currentClaims = index, claims
	if isIndexChanged then
		render()
	elseif isClaimsChanged then
		refreshRewards()
	end
end

local function claim(rarity: string)
	local remote, tabId = requestClaim, selectedTabId
	if remote == nil or tabId == nil or isClaimPending then
		return
	end
	isClaimPending = true
	remote:FireServer(tabId, rarity)
end

local function onClaimResult(ok: any, reason: any, _tabId: any, rarity: any)
	isClaimPending = false
	if ok == true and type(rarity) == "string" then
		Toast.Success(string.format(IndexMessages.ClaimedToastFormat, IndexData.GetRewardText(rarity)))
		return
	end
	local message = type(reason) == "string" and IndexMessages.Reasons[reason]
	Toast.Error(message or IndexMessages.UnknownError)
end

function IndexController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local tabs = IndexData.GetTabs()
	local firstTab = tabs[1]
	selectedTabId = firstTab and firstTab.Id
	IndexScreen.RenderTabs(tabs, selectedTabId, selectTab)
	IndexScreen.SetClaimHandler(claim)
	render()
	PlayerStateController.OnChanged(onStateChanged)
	local state = PlayerStateController.GetState()
	if state then
		onStateChanged(state)
	end

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestClaim = remotes:WaitForChild(RemoteNames.RequestClaimIndexReward) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyClaimIndexRewardResult) :: RemoteEvent
	resultRemote.OnClientEvent:Connect(onClaimResult)
end

return IndexController
