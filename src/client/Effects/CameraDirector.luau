--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealCleanup = require(script.Parent.RevealCleanup)

type Shot = {
	FromCFrame: CFrame,
	ToCFrame: CFrame,
	FromFov: number,
	ToFov: number,
	StartTime: number,
	Duration: number,
}

type Session = {
	SavedType: Enum.CameraType,
	SavedCFrame: CFrame,
	SavedFov: number,
	CurrentCFrame: CFrame,
	CurrentFov: number,
	Shot: Shot?,
	ShakeStrength: number,
	ShakeAt: number,
	FovPunch: number,
	FovPunchAt: number,
}

local NOISE_SCALE = 2
local NOISE_SEED_X = 0.37
local NOISE_SEED_Y = 7.91
local NOISE_SEED_ROLL = 13.53

local CameraDirector = {}

local session: Session? = nil

local function evaluate(current: Session)
	local shot = current.Shot
	if shot == nil then
		return
	end
	local alpha = 1
	if shot.Duration > 0 then
		alpha = math.clamp((os.clock() - shot.StartTime) / shot.Duration, 0, 1)
	end
	local style = ForgeAnimationConfig.Camera.EasingStyle
	local eased = TweenService:GetValue(alpha, style, Enum.EasingDirection.Out)
	current.CurrentCFrame = shot.FromCFrame:Lerp(shot.ToCFrame, eased)
	current.CurrentFov = shot.FromFov + (shot.ToFov - shot.FromFov) * eased
end

local function getShakeLevel(current: Session): number
	local elapsed = os.clock() - current.ShakeAt
	return current.ShakeStrength * math.exp(-ForgeAnimationConfig.Camera.ShakeDecay * elapsed)
end

local function getShakeOffset(current: Session): CFrame
	local level = getShakeLevel(current)
	if level < 1e-3 then
		return CFrame.identity
	end
	local config = ForgeAnimationConfig.Camera
	local time = os.clock() * config.ShakeFrequency
	local x = math.noise(time, NOISE_SEED_X) * NOISE_SCALE
	local y = math.noise(NOISE_SEED_Y, time) * NOISE_SCALE
	local roll = math.noise(time, NOISE_SEED_ROLL) * NOISE_SCALE
	local position = config.ShakePosition * level
	local rotation = math.rad(config.ShakeRotation * level)
	return CFrame.new(x * position, y * position, 0) * CFrame.Angles(y * rotation, x * rotation, roll * rotation)
end

local function getFovPunch(current: Session): number
	local elapsed = os.clock() - current.FovPunchAt
	return current.FovPunch * math.exp(-ForgeAnimationConfig.Camera.FovPunchDecay * elapsed)
end

local function onRenderStep()
	local current = session
	if current == nil then
		return
	end
	evaluate(current)
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = current.CurrentCFrame * getShakeOffset(current)
	camera.FieldOfView = current.CurrentFov + getFovPunch(current)
end

function CameraDirector.BuildShot(focus: Vector3, front: Vector3, distance: number, height: number): CFrame
	local eye = focus + front * distance + Vector3.yAxis * height
	return CFrame.lookAt(eye, focus)
end

function CameraDirector.Start(cleanup: RevealCleanup.Cleanup)
	CameraDirector.Stop()
	local camera = Workspace.CurrentCamera
	session = {
		SavedType = camera.CameraType,
		SavedCFrame = camera.CFrame,
		SavedFov = camera.FieldOfView,
		CurrentCFrame = camera.CFrame,
		CurrentFov = camera.FieldOfView,
		Shot = nil,
		ShakeStrength = 0,
		ShakeAt = 0,
		FovPunch = 0,
		FovPunchAt = 0,
	}
	local priority = Enum.RenderPriority.Camera.Value + 2
	RunService:BindToRenderStep(ForgeAnimationConfig.Camera.RenderStepName, priority, onRenderStep)
	RevealCleanup.Add(cleanup, CameraDirector.Stop)
end

function CameraDirector.MoveTo(target: CFrame, fieldOfView: number, duration: number)
	local current = session
	if current == nil then
		return
	end
	current.Shot = {
		FromCFrame = current.CurrentCFrame,
		ToCFrame = target,
		FromFov = current.CurrentFov,
		ToFov = fieldOfView,
		StartTime = os.clock(),
		Duration = duration,
	}
end

function CameraDirector.Shake(strength: number)
	local current = session
	if current == nil then
		return
	end
	current.ShakeStrength = math.max(getShakeLevel(current), strength)
	current.ShakeAt = os.clock()
end

function CameraDirector.PunchFov(amount: number)
	local current = session
	if current == nil then
		return
	end
	current.FovPunch = amount
	current.FovPunchAt = os.clock()
end

function CameraDirector.ReturnToStart(duration: number)
	local current = session
	if current == nil then
		return
	end
	CameraDirector.MoveTo(current.SavedCFrame, current.SavedFov, duration)
end

function CameraDirector.Stop()
	local current = session
	if current == nil then
		return
	end
	session = nil
	RunService:UnbindFromRenderStep(ForgeAnimationConfig.Camera.RenderStepName)
	local camera = Workspace.CurrentCamera
	camera.CameraType = current.SavedType
	camera.CFrame = current.SavedCFrame
	camera.FieldOfView = current.SavedFov
end

return CameraDirector
