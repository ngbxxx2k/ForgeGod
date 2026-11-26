--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationText = require(ReplicatedStorage.Shared.Utils.MutationText)

local BASE_TEXT_COLOR = Color3.new(1, 1, 1)

local MutationLabel = {}

function MutationLabel.Apply(label: Instance?, mutation: string?)
	if not label or not label:IsA("TextLabel") then
		return
	end
	label.RichText = true
	label.TextColor3 = BASE_TEXT_COLOR
	local gradient = label:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Enabled = false
	end
	label.Text = MutationText.Format(mutation)
end

return MutationLabel
