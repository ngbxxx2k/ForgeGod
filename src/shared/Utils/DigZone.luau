--!strict

local DigZoneConfig = require(script.Parent.Parent.Config.DigZoneConfig)

local DigZone = {}

local function flatten(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

function DigZone.IsInside(position: Vector3): boolean
	return flatten(position - DigZoneConfig.Center).Magnitude <= DigZoneConfig.Radius
end

function DigZone.GetFlatRotation(rootCFrame: CFrame): CFrame
	local look = flatten(rootCFrame.LookVector)
	if look.Magnitude < 1e-3 then
		return CFrame.identity
	end
	return CFrame.lookAt(Vector3.zero, look.Unit)
end

function DigZone.GetScanPoint(rootCFrame: CFrame): Vector3
	local offset = DigZone.GetFlatRotation(rootCFrame):VectorToWorldSpace(DigZoneConfig.ScanOffset)
	local point = rootCFrame.Position + offset
	return Vector3.new(point.X, DigZoneConfig.GroundY, point.Z)
end

function DigZone.FlatDistance(a: Vector3, b: Vector3): number
	return flatten(a - b).Magnitude
end

function DigZone.GetDigRootCFrame(spot: Vector3, rootCFrame: CFrame): CFrame
	local rotation = DigZone.GetFlatRotation(rootCFrame)
	local offset = rotation:VectorToWorldSpace(DigZoneConfig.DigTipOffset)
	local position = Vector3.new(spot.X - offset.X, rootCFrame.Position.Y, spot.Z - offset.Z)
	return CFrame.new(position) * rotation
end

return DigZone
