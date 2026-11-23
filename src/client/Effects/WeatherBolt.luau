--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WeatherFxTypes = require(ReplicatedStorage.Shared.Types.WeatherFxTypes)
local LightningBolt = require(script.Parent.LightningBolt)

type BoltProfile = WeatherFxTypes.BoltProfile

local FULL_TURN = math.pi * 2

local WeatherBolt = {}

local random = Random.new()

local function randomSideways(): Vector3
	local angle = random:NextNumber(0, FULL_TURN)
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

local function findGround(camera: Camera, profile: BoltProfile): Vector3?
	local distance = random:NextNumber(profile.Distance.Min, profile.Distance.Max)
	local above = Vector3.new(0, profile.Style.StartHeight, 0)
	local origin = camera.CFrame.Position + randomSideways() * distance + above
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local character = Players.LocalPlayer.Character
	params.FilterDescendantsInstances = if character then { character } else {}
	local result = Workspace:Raycast(origin, Vector3.new(0, -profile.RaycastDepth, 0), params)
	return if result then result.Position else nil
end

function WeatherBolt.Strike(profile: BoltProfile)
	if random:NextNumber() >= profile.Chance then
		return
	end
	local camera = Workspace.CurrentCamera
	local ground = if camera then findGround(camera, profile) else nil
	if ground then
		LightningBolt.Draw(profile.Style, ground)
	end
end

return WeatherBolt
