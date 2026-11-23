--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeFrenzyFxConfig = require(ReplicatedStorage.Shared.Config.ForgeFrenzyFxConfig)
local Rainbow = require(ReplicatedStorage.Shared.Utils.Rainbow)

type TintedPart = {
	Part: BasePart,
	Color: Color3,
	Material: Enum.Material,
	Distance: number,
}

type Band = {
	Texture: Texture,
	IsVertical: boolean,
	Shift: number,
}

export type Target = {
	Model: Model,
	Tinted: { TintedPart },
	Bands: { Band },
	Outline: Highlight,
}

type FaceAxes = {
	U: Vector3,
	V: Vector3,
}

local FACE_AXES: { [Enum.NormalId]: FaceAxes } = {
	[Enum.NormalId.Top] = { U = Vector3.xAxis, V = Vector3.zAxis },
	[Enum.NormalId.Bottom] = { U = Vector3.xAxis, V = Vector3.zAxis },
	[Enum.NormalId.Front] = { U = Vector3.xAxis, V = Vector3.yAxis },
	[Enum.NormalId.Back] = { U = Vector3.xAxis, V = Vector3.yAxis },
	[Enum.NormalId.Left] = { U = Vector3.zAxis, V = Vector3.yAxis },
	[Enum.NormalId.Right] = { U = Vector3.zAxis, V = Vector3.yAxis },
}

local RainbowWeapon = {}

local target: Target? = nil

local function getLongAxis(model: Model): (Vector3, Vector3)
	local frame, size = model:GetBoundingBox()
	if size.X >= size.Y and size.X >= size.Z then
		return frame.Position, frame.RightVector
	end
	if size.Y >= size.Z then
		return frame.Position, frame.UpVector
	end
	return frame.Position, frame.LookVector
end

local function hasTexture(part: BasePart): boolean
	return part:IsA("MeshPart") and part.TextureID ~= ""
end

local function createOutline(model: Model): Highlight
	local highlight = Instance.new("Highlight")
	highlight.Archivable = false
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
	highlight.Parent = model
	return highlight
end

local function createBand(part: BasePart, face: Enum.NormalId, axis: Vector3, distance: number): Band
	local config = ForgeFrenzyFxConfig
	local axes = FACE_AXES[face]
	local alongU = math.abs(part.CFrame:VectorToWorldSpace(axes.U):Dot(axis))
	local alongV = math.abs(part.CFrame:VectorToWorldSpace(axes.V):Dot(axis))
	local isVertical = alongV > alongU
	local chosen = if isVertical then axes.V else axes.U
	local texture = Instance.new("Texture")
	texture.Name = config.TextureName
	texture.Archivable = false
	texture.Face = face
	texture.Texture = if isVertical then config.BandTextures.Vertical else config.BandTextures.Horizontal
	texture.StudsPerTileU = if isVertical then config.BandCrossTile else config.BandLength
	texture.StudsPerTileV = if isVertical then config.BandLength else config.BandCrossTile
	texture.Transparency = 1
	texture.Parent = part
	local half = math.abs(part.Size:Dot(chosen)) / 2
	return { Texture = texture, IsVertical = isVertical, Shift = distance + half }
end

local function capture(model: Model): Target
	local center, axis = getLongAxis(model)
	local result: Target = { Model = model, Tinted = {}, Bands = {}, Outline = createOutline(model) }
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Transparency < ForgeFrenzyFxConfig.HiddenTransparency then
			local distance = (descendant.Position - center):Dot(axis)
			for face in FACE_AXES do
				table.insert(result.Bands, createBand(descendant, face, axis, distance))
			end
			if not hasTexture(descendant) then
				table.insert(result.Tinted, {
					Part = descendant,
					Color = descendant.Color,
					Material = descendant.Material,
					Distance = distance,
				})
			end
		end
	end
	return result
end

local function restore(current: Target)
	for _, tinted in current.Tinted do
		tinted.Part.Color = tinted.Color
		tinted.Part.Material = tinted.Material
	end
	for _, band in current.Bands do
		band.Texture.Transparency = 1
	end
	current.Outline.OutlineTransparency = 1
end

local function paint(current: Target, time: number)
	local config = ForgeFrenzyFxConfig
	local length = config.BandLength
	local travel = time * config.HueSpeed * length
	for _, tinted in current.Tinted do
		local hue = (travel - tinted.Distance) / length
		tinted.Part.Color = Rainbow.At(hue, config.Saturation, config.Brightness)
		tinted.Part.Material = config.WeaponMaterial
	end
	for _, band in current.Bands do
		local offset = (travel - band.Shift) % length
		local texture = band.Texture
		texture.Transparency = config.BandTransparency
		if band.IsVertical then
			texture.OffsetStudsV = offset
		else
			texture.OffsetStudsU = offset
		end
	end
	local outline = current.Outline
	outline.OutlineColor = Rainbow.At(time * config.HueSpeed + config.OutlineHueOffset, 1, 1)
	outline.OutlineTransparency = config.OutlineTransparency
end

function RainbowWeapon.Capture(model: Model): Target
	return capture(model)
end

function RainbowWeapon.Paint(current: Target, time: number, isLit: boolean)
	if isLit then
		paint(current, time)
	else
		restore(current)
	end
end

function RainbowWeapon.Release(current: Target)
	restore(current)
	current.Outline:Destroy()
	for _, band in current.Bands do
		band.Texture:Destroy()
	end
end

function RainbowWeapon.Detach()
	local current = target
	target = nil
	if current then
		RainbowWeapon.Release(current)
	end
end

function RainbowWeapon.Update(model: Model?, time: number, isLit: boolean)
	local current = target
	if current and (model ~= current.Model or current.Model.Parent == nil) then
		RainbowWeapon.Detach()
		current = nil
	end
	if model == nil then
		return
	end
	if current == nil then
		current = capture(model)
		target = current
	end
	RainbowWeapon.Paint(current, time, isLit)
end

return RainbowWeapon
