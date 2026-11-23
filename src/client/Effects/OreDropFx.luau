--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CrucibleViewConfig = require(ReplicatedStorage.Shared.Config.CrucibleViewConfig)
local OreCrucibleFx = require(script.Parent.OreCrucibleFx)
local OreCrucibleRig = require(script.Parent.OreCrucibleRig)

local FULL_TURN = math.pi * 2

local OreDropFx = {}

local rng = Random.new()

local function findTemplate(oreId: string): Model?
	local folder = ReplicatedStorage:FindFirstChild(CrucibleViewConfig.OreFolderName)
	local template = folder and folder:FindFirstChild(oreId)
	if template and template:IsA("Model") then
		return template
	end
	warn("[OreDropFx] Missing ore model", oreId)
	return nil
end

local function prepareClone(template: Model): Model
	local clone = template:Clone()
	clone.Name = CrucibleViewConfig.DropModelName
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.CastShadow = false
		end
	end
	clone:ScaleTo(clone:GetScale() * CrucibleViewConfig.OreScale)
	clone:PivotTo(CFrame.identity)
	return clone
end

local function heightAt(alpha: number): number
	local travel = CrucibleViewConfig.DropHeight + CrucibleViewConfig.SinkDepth
	return CrucibleViewConfig.DropHeight - travel * alpha * alpha
end

function OreDropFx.Drop(oreId: string, crucible: Model)
	local template = findTemplate(oreId)
	if template == nil then
		return
	end
	local ore = prepareClone(template)
	local centerOffset = ore:GetBoundingBox().Position
	local surface = OreCrucibleRig.FindLavaPosition(crucible)
	local startYaw = rng:NextNumber(0, FULL_TURN)
	local elapsed = 0
	local hasSplashed = false
	local connection: RBXScriptConnection? = nil

	local function place()
		local alpha = math.min(elapsed / CrucibleViewConfig.DropDuration, 1)
		local height = heightAt(alpha)
		local yaw = startYaw + elapsed * CrucibleViewConfig.DropSpinSpeed
		local frame = CFrame.new(surface + Vector3.yAxis * height) * CFrame.Angles(0, yaw, 0)
		ore:PivotTo(frame * CFrame.new(-centerOffset))
		if not hasSplashed and height <= 0 then
			hasSplashed = true
			OreCrucibleFx.Splash(crucible)
		end
		if alpha >= 1 then
			if connection then
				connection:Disconnect()
			end
			ore:Destroy()
		end
	end

	place()
	ore.Parent = Workspace
	connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		place()
	end)
end

return OreDropFx
