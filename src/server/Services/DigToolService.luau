--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DigToolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("DigToolConfig"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local HoldService = require(script.Parent.HoldService)

type Held = {
	ToolId: string,
	Tier: number,
	Model: Model,
}

local DigToolService = {}

local isInitialized = false
local heldByPlayer: { [Player]: Held } = {}

local function findSource(toolId: string, tier: number): Model?
	local spec = DigToolConfig.Held[toolId]
	local tierInfo = DigToolConfig.GetTier(toolId, tier)
	local root = ReplicatedStorage:FindFirstChild(DigToolConfig.ModelsFolderName)
	local folder = root and spec and root:FindFirstChild(spec.FolderName)
	local model = folder and tierInfo and folder:FindFirstChild(tierInfo.ModelName)
	if model and model:IsA("Model") then
		return model
	end
	warn("[DigToolService] Missing tool model:", toolId, tier)
	return nil
end

local function prepare(source: Model, toolId: string): Model
	local model = source:Clone()
	model.Name = DigToolConfig.HeldModelName
	model:SetAttribute(DigToolConfig.ToolKindAttribute, toolId)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end
	model:ScaleTo(DigToolConfig.Held[toolId].Scale)
	return model
end

local function weldToHand(model: Model, hand: BasePart, grip: CFrame)
	model:PivotTo(hand.CFrame * grip)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hand
			weld.Part1 = descendant
			weld.Parent = descendant
			descendant.Anchored = false
		end
	end
end

local function getHand(player: Player): BasePart?
	local character = player.Character
	local hand = character and character:FindFirstChild(DigToolConfig.HandPartName)
	return if hand and hand:IsA("BasePart") then hand else nil
end

function DigToolService.Hide(player: Player)
	local held = heldByPlayer[player]
	heldByPlayer[player] = nil
	if held then
		held.Model:Destroy()
	end
end

function DigToolService.Show(player: Player, toolId: string): boolean
	local tier = DataActions.GetDigToolTier(player, toolId)
	local hand = getHand(player)
	if tier == nil or hand == nil then
		return false
	end
	local held = heldByPlayer[player]
	if held and held.ToolId == toolId and held.Tier == tier and held.Model.Parent ~= nil then
		return true
	end
	local source = findSource(toolId, tier)
	if source == nil then
		return false
	end
	DigToolService.Hide(player)
	HoldService.Release(player)
	local model = prepare(source, toolId)
	weldToHand(model, hand, DigToolConfig.Held[toolId].Grip)
	model.Parent = hand.Parent
	heldByPlayer[player] = { ToolId = toolId, Tier = tier, Model = model }
	return true
end

function DigToolService.GetShown(player: Player): string?
	local held = heldByPlayer[player]
	return if held and held.Model.Parent ~= nil then held.ToolId else nil
end

local function onPlayerAdded(player: Player)
	player.CharacterRemoving:Connect(function()
		DigToolService.Hide(player)
	end)
end

function DigToolService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		heldByPlayer[player] = nil
	end)
end

return DigToolService
