--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local StationConfig = require(shared:WaitForChild("Config"):WaitForChild("StationConfig"))
local TutorialConfig = require(shared:WaitForChild("Config"):WaitForChild("TutorialConfig"))
local DigZone = require(shared:WaitForChild("Utils"):WaitForChild("DigZone"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local StationRange = require(script.Parent.Parent.Security.StationRange)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "TutorialAdvance"
local ROOT_PART_NAME = "HumanoidRootPart"
local MAX_STEP_ID_LENGTH = 32

type Step = TutorialConfig.Step

local TutorialService = {}

local isInitialized = false
local stepsById: { [string]: Step } = {}
local stepIndexById: { [string]: number } = {}

local function getCurrentStep(player: Player): Step?
	local data = DataService.GetData(player)
	local tutorial = data and data.Tutorial
	if type(tutorial) ~= "table" or tutorial.IsComplete == true then
		return nil
	end
	return stepsById[tutorial.StepId]
end

local function getDigCount(player: Player): number
	local data = DataService.GetData(player)
	local tutorial = data and data.Tutorial
	return if type(tutorial) == "table" and type(tutorial.DigCount) == "number" then tutorial.DigCount else 0
end

local function advance(player: Player, step: Step)
	local nextStep = TutorialConfig.Steps[(stepIndexById[step.Id] or 0) + 1]
	local ok, reason
	if nextStep then
		ok, reason = DataActions.TrySetTutorialStep(player, nextStep.Id)
	else
		ok, reason = DataActions.TryCompleteTutorial(player)
	end
	if not ok then
		warn("[TutorialService] Advance failed:", player.Name, step.Id, reason)
	end
end

local function isInDigZone(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild(ROOT_PART_NAME)
	return root ~= nil and root:IsA("BasePart") and DigZone.IsInside(root.Position)
end

local CLIENT_STEP_CHECKS: { [string]: (Player) -> boolean } = {
	GoToDigSite = isInDigZone,
	OpenCrucible = function(player: Player): boolean
		return StationRange.IsNear(player, StationConfig.FurnaceModelName)
	end,
}

function TutorialService.IsStepActive(player: Player, stepId: string): boolean
	local step = getCurrentStep(player)
	return step ~= nil and step.Id == stepId
end

function TutorialService.IsStrikeBlocked(player: Player): boolean
	return TutorialService.IsStepActive(player, TutorialConfig.StrikeBlockedStepId)
end

function TutorialService.IsEquipBestBlocked(player: Player): boolean
	local step = getCurrentStep(player)
	return step ~= nil and table.find(TutorialConfig.EquipBestBlockedStepIds, step.Id) ~= nil
end

function TutorialService.Report(player: Player, eventName: string)
	local step = getCurrentStep(player)
	if step == nil or step.ServerEvent ~= eventName then
		return
	end
	if eventName ~= TutorialConfig.Events.OreDug then
		advance(player, step)
		return
	end
	DataActions.TryAddTutorialDig(player)
	if getDigCount(player) >= TutorialConfig.DigTarget then
		advance(player, step)
	end
end

local function onRequestAdvance(player: Player, stepId: any)
	if type(stepId) ~= "string" or #stepId > MAX_STEP_ID_LENGTH then
		return
	end
	if not DataService.IsLoaded(player) or not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		return
	end
	local step = getCurrentStep(player)
	if step == nil or step.Id ~= stepId or step.ServerEvent ~= nil then
		return
	end
	local check = CLIENT_STEP_CHECKS[step.Id]
	if check and not check(player) then
		return
	end
	advance(player, step)
end

local function isVeteran(data: any): boolean
	local tutorial = data.Tutorial
	return tutorial.StepId == TutorialConfig.FirstStepId
		and (tutorial.DigCount or 0) == 0
		and type(data.Stats) == "table"
		and (data.Stats.TotalForges or 0) > 0
end

local function onProfileLoaded(player: Player)
	local data = DataService.GetData(player)
	if data == nil or type(data.Tutorial) ~= "table" or data.Tutorial.IsComplete == true then
		return
	end
	if isVeteran(data) then
		DataActions.TryCompleteTutorial(player)
		return
	end
	local step = stepsById[data.Tutorial.StepId]
	if step == nil then
		DataActions.TrySetTutorialStep(player, TutorialConfig.FirstStepId)
	elseif step.ResumeStepId then
		DataActions.TrySetTutorialStep(player, step.ResumeStepId)
	end
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

function TutorialService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	for index, step in TutorialConfig.Steps do
		stepsById[step.Id] = step
		stepIndexById[step.Id] = index
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = RemoteNames.RequestTutorialAdvance
	remote.Parent = getRemotesFolder()
	remote.OnServerEvent:Connect(onRequestAdvance)

	DataService.OnProfileLoaded(onProfileLoaded)
end

return TutorialService
