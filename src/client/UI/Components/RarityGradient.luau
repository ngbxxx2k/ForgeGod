--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityColors = require(ReplicatedStorage.Shared.Constants.RarityColors)

local RarityGradient = {}

function RarityGradient.Apply(target: GuiObject, rarity: string?)
	local rarityColor = if rarity then RarityColors.Get(rarity) else RarityColors.Default
	local gradient = target:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	gradient.Parent = target
	target.BackgroundColor3 = Color3.new(1, 1, 1)
	gradient.Color = rarityColor.Gradient
	gradient.Rotation = rarityColor.Rotation
end

return RarityGradient
