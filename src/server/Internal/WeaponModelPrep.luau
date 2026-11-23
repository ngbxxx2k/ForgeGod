--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HoldConfig = require(ReplicatedStorage.Shared.Config.HoldConfig)

local WeaponModelPrep = {}

local function getLongestSide(model: Model): number
	local _, size = model:GetBoundingBox()
	return math.max(size.X, size.Y, size.Z)
end

local function scaleToLength(model: Model, length: number)
	for _ = 1, HoldConfig.ScalePasses do
		local longest = getLongestSide(model)
		if longest <= 0 or math.abs(longest - length) <= HoldConfig.ScaleTolerance then
			return
		end
		model:ScaleTo(model:GetScale() * (length / longest))
	end
end

function WeaponModelPrep.Prepare(source: Model, name: string, length: number): Model
	local model = source:Clone()
	model.Name = name
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end
	scaleToLength(model, length)
	return model
end

return WeaponModelPrep
