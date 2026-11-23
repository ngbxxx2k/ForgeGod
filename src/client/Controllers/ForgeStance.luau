--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local ForgeViewConfig = require(ReplicatedStorage.Shared.Config.ForgeViewConfig)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local ForgeStation = require(script.Parent.Parent.Effects.ForgeStation)
local MovementLock = require(script.Parent.MovementLock)
local CharacterPin = require(script.Parent.CharacterPin)

local HIDDEN_MODIFIER = 1
local SHOWN_MODIFIER = 0

type SavedCamera = {
	CameraType: Enum.CameraType,
	FieldOfView: number,
	PromptsEnabled: boolean,
}

local ForgeStance = {}

local saved: SavedCamera? = nil
local savedMovement: MovementLock.SavedMovement? = nil
local characterPin: CharacterPin.Pin? = nil
local panelPart: BasePart? = nil
local cameraTween: Tween? = nil
local eyeCFrame: CFrame? = nil
local character: Model? = nil

local function lockMovement(model: Model?)
	savedMovement = MovementLock.Lock(model)
end

local function unlockMovement()
	local movement = savedMovement
	savedMovement = nil
	MovementLock.Unlock(movement)
end

local function isHammerPart(part: BasePart, model: Model): boolean
	local hammer = model:FindFirstChild(ForgeStrikeConfig.HammerModelName)
	return hammer ~= nil and part:IsDescendantOf(hammer)
end

local function setBodyModifier(model: Model, modifier: number)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and not isHammerPart(descendant, model) then
			descendant.LocalTransparencyModifier = modifier
		end
	end
end

local function holdCamera()
	local target = eyeCFrame
	local camera = Workspace.CurrentCamera
	if target == nil or camera.CameraType == Enum.CameraType.Scriptable then
		return
	end
	if cameraTween then
		cameraTween:Cancel()
		cameraTween = nil
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = target
	camera.FieldOfView = ForgeViewConfig.FieldOfView
end

local function applyShake()
	local target = eyeCFrame
	local tween = cameraTween
	if target == nil or (tween and tween.PlaybackState == Enum.PlaybackState.Playing) then
		return
	end
	Workspace.CurrentCamera.CFrame = target * CameraShake.GetOffset()
end

local function onRenderStep()
	holdCamera()
	applyShake()
	local model = character
	if model then
		setBodyModifier(model, HIDDEN_MODIFIER)
	end
end

local function createPanelPart(anvilPart: BasePart): BasePart
	local part = Instance.new("Part")
	part.Name = ForgeViewConfig.PanelPartName
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	local size = ForgeViewConfig.PanelSize
	part.Size = Vector3.new(size.X, size.Y, ForgeViewConfig.PanelThickness)
	part.CFrame = ForgeStation.GetPanelCFrame(anvilPart)
	part.Parent = Workspace
	return part
end

local function moveCamera(anvilPart: BasePart)
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	local duration = ForgeViewConfig.CameraTweenTime
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local target = ForgeStation.GetEyeCFrame(anvilPart)
	eyeCFrame = target
	local tween = TweenService:Create(camera, info, {
		CFrame = target,
		FieldOfView = ForgeViewConfig.FieldOfView,
	})
	cameraTween = tween
	tween:Play()
end

function ForgeStance.Enter(anvilPart: BasePart): BasePart
	ForgeStance.Exit()
	local camera = Workspace.CurrentCamera
	saved = {
		CameraType = camera.CameraType,
		FieldOfView = camera.FieldOfView,
		PromptsEnabled = ProximityPromptService.Enabled,
	}
	character = Players.LocalPlayer.Character
	lockMovement(character)
	characterPin = CharacterPin.Pin(character, ForgeStation.GetStandCFrame(anvilPart))
	ProximityPromptService.Enabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	moveCamera(anvilPart)
	local priority = Enum.RenderPriority.Camera.Value + 1
	RunService:BindToRenderStep(ForgeViewConfig.HideBodyStepName, priority, onRenderStep)
	local part = createPanelPart(anvilPart)
	panelPart = part
	return part
end

function ForgeStance.Exit()
	local previous = saved
	if previous == nil then
		return
	end
	saved = nil
	RunService:UnbindFromRenderStep(ForgeViewConfig.HideBodyStepName)
	eyeCFrame = nil
	if cameraTween then
		cameraTween:Cancel()
		cameraTween = nil
	end
	local camera = Workspace.CurrentCamera
	camera.CameraType = previous.CameraType
	camera.FieldOfView = previous.FieldOfView
	ProximityPromptService.Enabled = previous.PromptsEnabled
	CharacterPin.Unpin(characterPin)
	characterPin = nil
	unlockMovement()
	local model = character
	character = nil
	if model and model.Parent then
		setBodyModifier(model, SHOWN_MODIFIER)
	end
	local part = panelPart
	panelPart = nil
	if part then
		part:Destroy()
	end
end

function ForgeStance.IsActive(): boolean
	return saved ~= nil
end

return ForgeStance
