--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DigFxConfig = require(ReplicatedStorage.Shared.Config.DigFxConfig)
local DigToolConfig = require(ReplicatedStorage.Shared.Config.DigToolConfig)

type HeldListener = (kind: string?, model: Model?) -> ()

local DigToolAnimator = {}

local isInitialized = false
local listeners: { HeldListener } = {}
local currentTrack: AnimationTrack? = nil
local currentModel: Model? = nil
local characterConnections: { RBXScriptConnection } = {}
local trackCache: { [string]: AnimationTrack } = {}

local function stopTrack()
	local track = currentTrack
	currentTrack = nil
	if track then
		track:Stop(DigFxConfig.Animation.FadeTime)
	end
end

local function getTrack(animator: Animator, animationId: string): AnimationTrack?
	local cached = trackCache[animationId]
	if cached then
		return cached
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok then
		warn("[DigToolAnimator] Failed to load animation:", track)
		return nil
	end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	trackCache[animationId] = track
	return track
end

local function playFor(character: Model, kind: string)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local spec = DigToolConfig.Held[kind]
	if animator == nil or spec == nil then
		return
	end
	local track = getTrack(animator, spec.AnimationId)
	if track == nil or track == currentTrack then
		return
	end
	stopTrack()
	track:Play(DigFxConfig.Animation.FadeTime)
	currentTrack = track
end

local function notify(kind: string?, model: Model?)
	for _, listener in listeners do
		task.spawn(listener, kind, model)
	end
end

local function getKind(child: Instance): string?
	if child.Name ~= DigToolConfig.HeldModelName or not child:IsA("Model") then
		return nil
	end
	local kind = child:GetAttribute(DigToolConfig.ToolKindAttribute)
	return if type(kind) == "string" then kind else nil
end

local function onChildAdded(character: Model, child: Instance)
	local kind = getKind(child)
	if kind == nil then
		return
	end
	currentModel = child :: Model
	playFor(character, kind)
	notify(kind, child :: Model)
end

local function onChildRemoved(child: Instance)
	if child ~= currentModel then
		return
	end
	currentModel = nil
	stopTrack()
	notify(nil, nil)
end

local function bindCharacter(character: Model)
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	table.clear(trackCache)
	currentTrack = nil
	currentModel = nil
	notify(nil, nil)
	table.insert(characterConnections, character.ChildAdded:Connect(function(child)
		onChildAdded(character, child)
	end))
	table.insert(characterConnections, character.ChildRemoved:Connect(onChildRemoved))
	for _, child in character:GetChildren() do
		onChildAdded(character, child)
	end
end

function DigToolAnimator.OnHeldChanged(listener: HeldListener)
	table.insert(listeners, listener)
end

function DigToolAnimator.GetHeldKind(): string?
	local model = currentModel
	return if model and model.Parent then getKind(model) else nil
end

function DigToolAnimator.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		bindCharacter(player.Character)
	end
end

return DigToolAnimator
