--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)

export type Impact = {
	Weapon: Model,
	BasePivot: CFrame,
	StartedAt: number,
	Connection: RBXScriptConnection,
}

local ForgeWeaponImpact = {}

local current: Impact? = nil

local function offsetAt(elapsed: number): CFrame
	local config = ForgeStrikeConfig.Impact
	local decay = math.exp(-config.Decay * elapsed)
	local dip = -config.Dip * decay * math.cos(config.BounceFrequency * elapsed)
	local wobble = math.rad(config.WobbleAngle) * decay * math.sin(config.WobbleFrequency * elapsed)
	return CFrame.new(0, dip, 0) * CFrame.Angles(wobble, 0, wobble * config.WobbleRollRatio)
end

local function finish(impact: Impact)
	impact.Connection:Disconnect()
	if impact.Weapon.Parent then
		impact.Weapon:PivotTo(impact.BasePivot)
	end
	if current == impact then
		current = nil
	end
end

local function step(impact: Impact)
	local elapsed = os.clock() - impact.StartedAt
	if elapsed >= ForgeStrikeConfig.Impact.Duration or impact.Weapon.Parent == nil then
		finish(impact)
		return
	end
	local base = impact.BasePivot
	local offset = offsetAt(elapsed)
	impact.Weapon:PivotTo(CFrame.new(offset.Position) * base * offset.Rotation)
end

function ForgeWeaponImpact.Start(weapon: Model, basePivot: CFrame): Impact
	local impact: Impact = {
		Weapon = weapon,
		BasePivot = basePivot,
		StartedAt = os.clock(),
		Connection = nil :: any,
	}
	impact.Connection = RunService.RenderStepped:Connect(function()
		step(impact)
	end)
	step(impact)
	return impact
end

function ForgeWeaponImpact.Cancel(impact: Impact)
	if impact.Connection.Connected then
		finish(impact)
	end
end

function ForgeWeaponImpact.Play(weapon: Model, basePivot: CFrame)
	ForgeWeaponImpact.Stop()
	current = ForgeWeaponImpact.Start(weapon, basePivot)
end

function ForgeWeaponImpact.Stop()
	local impact = current
	if impact then
		finish(impact)
	end
end

return ForgeWeaponImpact
