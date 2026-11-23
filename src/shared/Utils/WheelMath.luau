--!strict

local FULL_TURN = 360
local PERCENT_SCALE = 100

export type Segment = {
	Id: string,
	Start: number,
	Finish: number,
	Percent: number,
}

local WheelMath = {}

function WheelMath.Normalize(angle: number): number
	return angle % FULL_TURN
end

function WheelMath.BuildSegments(order: { string }, chances: { [string]: number }): { Segment }
	local total = 0
	for _, id in order do
		total += math.max(chances[id] or 0, 0)
	end
	local segments: { Segment } = {}
	if total <= 0 then
		return segments
	end
	local cumulative = 0
	for _, id in order do
		local chance = math.max(chances[id] or 0, 0)
		local start = cumulative / total * FULL_TURN
		cumulative += chance
		table.insert(segments, {
			Id = id,
			Start = start,
			Finish = cumulative / total * FULL_TURN,
			Percent = chance / total * PERCENT_SCALE,
		})
	end
	return segments
end

function WheelMath.FindSegment(segments: { Segment }, id: string): Segment?
	for _, segment in segments do
		if segment.Id == id and segment.Finish > segment.Start then
			return segment
		end
	end
	return nil
end

function WheelMath.SegmentAt(segments: { Segment }, angle: number): Segment?
	local normalized = WheelMath.Normalize(angle)
	for _, segment in segments do
		if normalized >= segment.Start and normalized < segment.Finish then
			return segment
		end
	end
	return nil
end

function WheelMath.PickTargetAngle(segment: Segment, alpha: number, edgeMargin: number): number
	local width = segment.Finish - segment.Start
	local margin = width * math.clamp(edgeMargin, 0, 0.5)
	return segment.Start + margin + math.clamp(alpha, 0, 1) * (width - 2 * margin)
end

function WheelMath.NeedleAngle(rotation: number, restAngle: number): number
	return WheelMath.Normalize(rotation + restAngle)
end

function WheelMath.PlanLanding(
	current: number,
	spinStart: number,
	targetAngle: number,
	restAngle: number,
	minTurns: number,
	minTravel: number
): number
	local base = math.max(spinStart + FULL_TURN * minTurns, current + minTravel)
	local delta = (targetAngle - restAngle - base) % FULL_TURN
	return base + delta
end

function WheelMath.Hermite(from: number, to: number, startSlope: number, s: number): number
	local s2, s3 = s * s, s * s * s
	return (2 * s3 - 3 * s2 + 1) * from + (s3 - 2 * s2 + s) * startSlope + (3 * s2 - 2 * s3) * to
end

function WheelMath.HermiteSlope(from: number, to: number, startSlope: number, s: number): number
	local s2 = s * s
	return (6 * s2 - 6 * s) * from + (3 * s2 - 4 * s + 1) * startSlope + (6 * s - 6 * s2) * to
end

function WheelMath.ClampInside(segment: Segment, angle: number, edgeMargin: number): number
	local width = segment.Finish - segment.Start
	local margin = width * math.clamp(edgeMargin, 0, 0.5)
	local low, high = segment.Start + margin, segment.Finish - margin
	local normalized = WheelMath.Normalize(angle)
	if normalized >= low and normalized <= high then
		return normalized
	end
	local toLow = math.abs((normalized - low + 180) % FULL_TURN - 180)
	local toHigh = math.abs((normalized - high + 180) % FULL_TURN - 180)
	return if toLow <= toHigh then low else high
end

function WheelMath.ShortestDelta(fromAngle: number, toAngle: number): number
	return (toAngle - fromAngle + 180) % FULL_TURN - 180
end

return WheelMath
