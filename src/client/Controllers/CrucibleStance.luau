--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CrucibleViewConfig = require(ReplicatedStorage.Shared.Config.CrucibleViewConfig)
local OreCrucibleRig = require(script.Parent.Parent.Effects.OreCrucibleRig)
local MovementLock = require(script.Parent.MovementLock)
local CharacterPin = require(script.Parent.CharacterPin)

local ROOT_PART_NAME = "HumanoidRootPart"
local HIDDEN_MODIFIER = 1
local SHOWN_MODIFIER = 0

type Session = {
	Character: Model,
	Pin: CharacterPin.Pin?,
	Movement: MovementLock.SavedMovement?,
	CameraType: Enum.CameraType,
	FieldOfView: number,
	PromptsEnabled: boolean,
	EyeCFrame: CFrame,
	Tween: Tween?,
}

local CrucibleStance = {}

local session: Session? = nil

local function getStandCFrame(crucible: Model, humanoid: Humanoid, root: BasePart): CFrame
	local center = crucible:GetPivot().Position
	local front = OreCrucibleRig.FindFrontDirection(crucible)
	local rootHeight = OreCrucibleRig.FindGroundY(crucible) + humanoid.HipHeight + root.Size.Y / 2
	local flatCenter = Vector3.new(center.X, rootHeight, center.Z)
	local position = flatCenter + front * CrucibleViewConfig.StandDistance
	return CFrame.lookAt(position, flatCenter)
end

local function getEyeCFrame(crucible: Model, stand: CFrame): CFrame
	local groundY = OreCrucibleRig.FindGroundY(crucible)
	local eye = Vector3.new(stand.Position.X, groundY + CrucibleViewConfig.EyeHeight, stand.Position.Z)
	local target = OreCrucibleRig.FindLavaPosition(crucible) + CrucibleViewConfig.LookOffset
	local yaw = CFrame.Angles(0, math.rad(CrucibleViewConfig.ScreenYaw), 0)
	return CFrame.lookAt(eye, eye + yaw:VectorToWorldSpace(target - eye))
end

local function setBodyModifier(character: Model, modifier: number)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = modifier
		end
	end
end

local function isTweening(current: Session): boolean
	local tween = current.Tween
	return tween ~= nil and tween.PlaybackState == Enum.PlaybackState.Playing
end

local function onRenderStep()
	local current = session
	if current == nil then
		return
	end
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	if not isTweening(current) then
		camera.CFrame = current.EyeCFrame
		camera.FieldOfView = CrucibleViewConfig.FieldOfView
	end
	setBodyModifier(current.Character, HIDDEN_MODIFIER)
end

local function moveCamera(current: Session)
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	local duration = CrucibleViewConfig.CameraTweenTime
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(camera, info, {
		CFrame = current.EyeCFrame,
		FieldOfView = CrucibleViewConfig.FieldOfView,
	})
	current.Tween = tween
	tween:Play()
end

local function findBody(): (Model?, Humanoid?, BasePart?)
	local character = Players.LocalPlayer.Character
	if character == nil then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild(ROOT_PART_NAME)
	if humanoid == nil or root == nil or not root:IsA("BasePart") then
		return nil, nil, nil
	end
	return character, humanoid, root
end

function CrucibleStance.Enter(crucible: Model): boolean
	CrucibleStance.Exit()
	local character, humanoid, root = findBody()
	if character == nil or humanoid == nil or root == nil then
		warn("[CrucibleStance] Missing character")
		return false
	end
	local camera = Workspace.CurrentCamera
	local stand = getStandCFrame(crucible, humanoid, root)
	local current: Session = {
		Character = character,
		Pin = nil,
		Movement = MovementLock.Lock(character),
		CameraType = camera.CameraType,
		FieldOfView = camera.FieldOfView,
		PromptsEnabled = ProximityPromptService.Enabled,
		EyeCFrame = getEyeCFrame(crucible, stand),
		Tween = nil,
	}
	session = current
	ProximityPromptService.Enabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	current.Pin = CharacterPin.Pin(character, stand)
	moveCamera(current)
	local priority = Enum.RenderPriority.Camera.Value + 1
	RunService:BindToRenderStep(CrucibleViewConfig.RenderStepName, priority, onRenderStep)
	return true
end

function CrucibleStance.Exit()
	local current = session
	if current == nil then
		return
	end
	session = nil
	RunService:UnbindFromRenderStep(CrucibleViewConfig.RenderStepName)
	if current.Tween then
		current.Tween:Cancel()
	end
	local camera = Workspace.CurrentCamera
	camera.CameraType = current.CameraType
	camera.FieldOfView = current.FieldOfView
	ProximityPromptService.Enabled = current.PromptsEnabled
	CharacterPin.Unpin(current.Pin)
	MovementLock.Unlock(current.Movement)
	if current.Character.Parent then
		setBodyModifier(current.Character, SHOWN_MODIFIER)
	end
end

function CrucibleStance.IsActive(): boolean
	return session ~= nil
end

return CrucibleStance
