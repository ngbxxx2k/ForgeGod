--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WheelMath = require(ReplicatedStorage.Shared.Utils.WheelMath)

local FULL_TURN = 360

export type TickHandler = (rotation: number) -> ()

type Landing = {
	From: number,
	To: number,
	StartSlope: number,
	Duration: number,
	StartedAt: number,
	OnDone: () -> (),
}

local WheelNeedle = {}

local pivot: GuiObject? = nil
local spinSpeed: number? = nil
local landing: Landing? = nil
local velocity = 0
local connection: RBXScriptConnection? = nil
local tickHandler: TickHandler? = nil

local function disconnect()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function finishLanding(current: Landing, target: GuiObject)
	target.Rotation = current.To
	landing = nil
	velocity = 0
	disconnect()
	current.OnDone()
end

local function stepLanding(current: Landing, target: GuiObject)
	local s = math.clamp((os.clock() - current.StartedAt) / current.Duration, 0, 1)
	if s >= 1 then
		finishLanding(current, target)
		return
	end
	target.Rotation = WheelMath.Hermite(current.From, current.To, current.StartSlope, s)
	local slope = WheelMath.HermiteSlope(current.From, current.To, current.StartSlope, s)
	velocity = slope / current.Duration
end

local function step(dt: number)
	local target = pivot
	if target == nil then
		disconnect()
		return
	end
	local speed = spinSpeed
	local current = landing
	if current then
		stepLanding(current, target)
	elseif speed then
		target.Rotation += speed * dt
		velocity = speed
	end
	local handler = tickHandler
	if handler then
		handler(target.Rotation)
	end
end

local function ensureRunning()
	if connection == nil then
		connection = RunService.RenderStepped:Connect(step)
	end
end

function WheelNeedle.GetRotation(): number
	local target = pivot
	return if target then target.Rotation else 0
end

function WheelNeedle.GetVelocity(): number
	return velocity
end

function WheelNeedle.IsMoving(): boolean
	return connection ~= nil
end

function WheelNeedle.StartSpin(speed: number)
	landing = nil
	spinSpeed = speed
	velocity = speed
	ensureRunning()
end

function WheelNeedle.LandAt(rotation: number, duration: number, onDone: () -> ())
	local target = pivot
	if target == nil then
		onDone()
		return
	end
	spinSpeed = nil
	landing = {
		From = target.Rotation,
		To = rotation,
		StartSlope = velocity * duration,
		Duration = math.max(duration, 1e-3),
		StartedAt = os.clock(),
		OnDone = onDone,
	}
	ensureRunning()
end

function WheelNeedle.Normalize()
	local target = pivot
	if target and connection == nil then
		target.Rotation = target.Rotation % FULL_TURN
	end
end

function WheelNeedle.Stop()
	spinSpeed = nil
	landing = nil
	velocity = 0
	disconnect()
end

function WheelNeedle.Reset(rotation: number)
	WheelNeedle.Stop()
	local target = pivot
	if target then
		target.Rotation = rotation
	end
end

function WheelNeedle.SetTickHandler(handler: TickHandler?)
	tickHandler = handler
end

function WheelNeedle.Bind(needlePivot: GuiObject)
	pivot = needlePivot
end

return WheelNeedle
