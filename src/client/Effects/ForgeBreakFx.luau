--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeBreakFxConfig = require(ReplicatedStorage.Shared.Config.ForgeBreakFxConfig)

type Source = {
	Part: BasePart,
	Volume: number,
}

local FOLDER_NAME = "ForgeBreakFx"
local HIDDEN = 1
local FULL_TURN = math.pi * 2
local MIN_FRAGMENTS_PER_PART = 1
local PUFF_PART_SIZE = Vector3.new(0.2, 0.2, 0.2)

local ForgeBreakFx = {}

local random = Random.new()

local function collectSources(weapon: Model): ({ Source }, number)
	local sources: { Source } = {}
	local total = 0
	for _, descendant in weapon:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Transparency < HIDDEN then
			local size = descendant.Size
			local volume = size.X * size.Y * size.Z
			table.insert(sources, { Part = descendant, Volume = volume })
			total += volume
		end
	end
	return sources, total
end

local function randomOffset(size: Vector3): Vector3
	return Vector3.new(
		random:NextNumber(-0.5, 0.5) * size.X,
		random:NextNumber(-0.5, 0.5) * size.Y,
		random:NextNumber(-0.5, 0.5) * size.Z
	)
end

local function randomRotation(): CFrame
	local x = random:NextNumber(0, FULL_TURN)
	local y = random:NextNumber(0, FULL_TURN)
	local z = random:NextNumber(0, FULL_TURN)
	return CFrame.Angles(x, y, z)
end

local function fragmentSize(source: BasePart): Vector3
	local range = ForgeBreakFxConfig.FragmentSize
	local function axis(limit: number): number
		return math.min(random:NextNumber(range.Min, range.Max), math.max(limit, range.Min))
	end
	return Vector3.new(axis(source.Size.X), axis(source.Size.Y), axis(source.Size.Z))
end

local function createFragment(source: BasePart): BasePart
	local isWedge = random:NextNumber() < ForgeBreakFxConfig.WedgeChance
	local fragment: BasePart = if isWedge then Instance.new("WedgePart") else Instance.new("Part")
	fragment.Name = ForgeBreakFxConfig.FragmentName
	fragment.Size = fragmentSize(source)
	fragment.Color = source.Color
	fragment.Material = source.Material
	fragment.Reflectance = source.Reflectance
	fragment.CanQuery = false
	fragment.CanTouch = false
	fragment.Archivable = false
	fragment.CFrame = source.CFrame * CFrame.new(randomOffset(source.Size)) * randomRotation()
	return fragment
end

local function launch(fragment: BasePart, center: Vector3)
	local config = ForgeBreakFxConfig
	local away = fragment.Position - center
	local flat = Vector3.new(away.X, 0, away.Z)
	local direction = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.xAxis
	local outward = direction * random:NextNumber(config.OutwardSpeed.Min, config.OutwardSpeed.Max)
	local upward = Vector3.yAxis * random:NextNumber(config.UpwardSpeed.Min, config.UpwardSpeed.Max)
	fragment.AssemblyLinearVelocity = outward + upward
	local spin = random:NextNumber(config.SpinSpeed.Min, config.SpinSpeed.Max)
	fragment.AssemblyAngularVelocity = random:NextUnitVector() * spin
end

local function spawnFragments(sources: { Source }, total: number, folder: Folder, center: Vector3)
	local count = ForgeBreakFxConfig.FragmentCount
	for _, source in sources do
		local share = if total > 0 then source.Volume / total else 1 / #sources
		local amount = math.max(MIN_FRAGMENTS_PER_PART, math.round(count * share))
		for _ = 1, amount do
			local fragment = createFragment(source.Part)
			fragment.Parent = folder
			launch(fragment, center)
		end
	end
end

local function puff(center: Vector3, folder: Folder)
	local config = ForgeBreakFxConfig
	local part = Instance.new("Part")
	part.Size = PUFF_PART_SIZE
	part.Transparency = HIDDEN
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = CFrame.new(center)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = config.PuffTexture
	emitter.Color = ColorSequence.new(config.PuffColor)
	emitter.Size = config.PuffSize
	emitter.Transparency = config.PuffTransparency
	emitter.Speed = config.PuffSpeed
	emitter.Lifetime = config.PuffLifetime
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = part
	part.Parent = folder
	emitter:Emit(config.PuffCount)
end

local function fadeOut(folder: Folder)
	local info = TweenInfo.new(ForgeBreakFxConfig.FadeTime, Enum.EasingStyle.Quad)
	for _, child in folder:GetChildren() do
		if child:IsA("BasePart") and child.Name == ForgeBreakFxConfig.FragmentName then
			TweenService:Create(child, info, { Transparency = HIDDEN }):Play()
		end
	end
	task.delay(ForgeBreakFxConfig.FadeTime, folder.Destroy, folder)
end

function ForgeBreakFx.Shatter(weapon: Model?)
	if weapon == nil or weapon.Parent == nil then
		return
	end
	local sources, total = collectSources(weapon)
	if #sources == 0 then
		return
	end
	local center = weapon:GetBoundingBox().Position
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Archivable = false
	folder.Parent = Workspace
	spawnFragments(sources, total, folder, center)
	puff(center, folder)
	task.delay(ForgeBreakFxConfig.Lifetime, fadeOut, folder)
end

return ForgeBreakFx
