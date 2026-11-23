--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealCleanup = require(script.Parent.RevealCleanup)
local RevealSound = require(script.Parent.RevealSound)

local ANCHOR_SIZE = Vector3.new(0.2, 0.2, 0.2)
local ANCHOR_NAME = "ForgeRevealFlare"

local CrucibleFlare = {}

local function createAnchor(position: Vector3): Part
	local anchor = Instance.new("Part")
	anchor.Name = ANCHOR_NAME
	anchor.Size = ANCHOR_SIZE
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(position)
	return anchor
end

local function createLight(anchor: Part): PointLight
	local config = ForgeAnimationConfig.Flare
	local light = Instance.new("PointLight")
	light.Color = config.Color
	light.Range = config.Range
	light.Brightness = 0
	light.Shadows = false
	light.Parent = anchor
	return light
end

function CrucibleFlare.Play(lavaPosition: Vector3, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.Flare
	local anchor = createAnchor(lavaPosition + Vector3.yAxis * config.Lift)
	local light = createLight(anchor)
	anchor.Parent = Workspace
	RevealCleanup.Add(cleanup, anchor)
	RevealSound.Play(config.Sound, anchor)

	local rise = TweenService:Create(light, TweenInfo.new(config.RiseTime), {
		Brightness = config.Brightness,
	})
	local fadeInfo = TweenInfo.new(config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local fade = TweenService:Create(light, fadeInfo, { Brightness = 0 })
	RevealCleanup.Add(cleanup, rise.Completed:Connect(function()
		fade:Play()
	end))
	RevealCleanup.Add(cleanup, rise)
	RevealCleanup.Add(cleanup, fade)
	rise:Play()
end

return CrucibleFlare
