--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ForgeFrenzyFxConfig = require(ReplicatedStorage.Shared.Config.ForgeFrenzyFxConfig)
local CameraShake = require(script.Parent.CameraShake)
local ForgeStrikeFx = require(script.Parent.ForgeStrikeFx)
local Rainbow = require(ReplicatedStorage.Shared.Utils.Rainbow)
local ForgeResultFx = require(script.Parent.ForgeResultFx)
local FrenzyScreenFlash = require(script.Parent.FrenzyScreenFlash)
local RainbowWeapon = require(script.Parent.RainbowWeapon)

local KICK_STRENGTH = 1
local SUSTAIN_STRENGTH = 1
local FULL_TURN = 360

local ForgeFrenzyFx = {}

local isInitialized = false
local endsAt = 0
local connection: RBXScriptConnection? = nil

function ForgeFrenzyFx.IsLitAt(frenzyEndsAt: number, now: number): boolean
	local timeLeft = frenzyEndsAt - now
	if timeLeft > ForgeFrenzyFxConfig.WarningTime then
		return true
	end
	local blink = math.floor(now * ForgeFrenzyFxConfig.BlinkFrequency * 2)
	return blink % 2 == 0
end

local function onRender()
	local now = os.clock()
	if now >= endsAt then
		ForgeFrenzyFx.Stop()
		return
	end
	local isLit = ForgeFrenzyFx.IsLitAt(endsAt, now)
	RainbowWeapon.Update(ForgeStrikeFx.GetWeapon(), now, isLit)
	FrenzyScreenFlash.Update(now, isLit)
	local config = ForgeFrenzyFxConfig
	local hueOffset = now * config.HueSpeed
	local sequence = Rainbow.Sequence(hueOffset, config.GradientSteps, config.Saturation, config.Brightness)
	ForgeResultFx.UpdateRainbowGlow(sequence, (now * config.GlowSpinSpeed) % FULL_TURN, isLit)
end

local function onHit()
	if connection == nil then
		return
	end
	FrenzyScreenFlash.Pulse()
	CameraShake.Kick(KICK_STRENGTH)
end

function ForgeFrenzyFx.Start(frenzyEndsAt: number)
	if frenzyEndsAt <= os.clock() then
		return
	end
	endsAt = frenzyEndsAt
	if connection then
		return
	end
	ForgeStrikeFx.SetRainbowSparks(true)
	ForgeResultFx.SetRainbowGlow(true)
	CameraShake.SetSustain(SUSTAIN_STRENGTH)
	FrenzyScreenFlash.Pulse()
	CameraShake.Kick(KICK_STRENGTH)
	connection = RunService.RenderStepped:Connect(onRender)
end

function ForgeFrenzyFx.Stop()
	local current = connection
	connection = nil
	endsAt = 0
	if current then
		current:Disconnect()
	end
	RainbowWeapon.Detach()
	ForgeResultFx.SetRainbowGlow(false)
	FrenzyScreenFlash.Hide()
	CameraShake.Reset()
	ForgeStrikeFx.SetRainbowSparks(false)
end

function ForgeFrenzyFx.IsActive(): boolean
	return connection ~= nil
end

function ForgeFrenzyFx.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	ForgeStrikeFx.SetHitHandler(onHit)
	task.spawn(function()
		local textures = ForgeFrenzyFxConfig.BandTextures
		local ok, err = pcall(ContentProvider.PreloadAsync, ContentProvider, { textures.Horizontal, textures.Vertical })
		if not ok then
			warn("[ForgeFrenzyFx] Preload failed:", err)
		end
	end)
end

return ForgeFrenzyFx
