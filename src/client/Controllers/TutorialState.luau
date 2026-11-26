--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TutorialConfig = require(ReplicatedStorage.Shared.Config.TutorialConfig)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local PlayerStateController = require(script.Parent.PlayerStateController)

type TutorialState = PlayerStateTypes.TutorialState

local TutorialState = {}

function TutorialState.Get(): TutorialState?
	local state = PlayerStateController.GetState()
	local tutorial = state and state.Tutorial
	if type(tutorial) ~= "table" or type(tutorial.StepId) ~= "string" then
		return nil
	end
	return tutorial
end

function TutorialState.GetStepId(): string?
	local tutorial = TutorialState.Get()
	if tutorial == nil or tutorial.IsComplete then
		return nil
	end
	return tutorial.StepId
end

function TutorialState.IsStrikeBlocked(): boolean
	return TutorialState.GetStepId() == TutorialConfig.StrikeBlockedStepId
end

return TutorialState
