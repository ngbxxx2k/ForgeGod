--!strict

local Rainbow = {}

function Rainbow.At(hue: number, saturation: number, brightness: number): Color3
	return Color3.fromHSV(hue % 1, saturation, brightness)
end

function Rainbow.Sequence(offset: number, steps: number, saturation: number, brightness: number): ColorSequence
	local count = math.max(math.floor(steps), 2)
	local points = {}
	for index = 0, count - 1 do
		local alpha = index / (count - 1)
		local color = Rainbow.At(offset + alpha, saturation, brightness)
		table.insert(points, ColorSequenceKeypoint.new(alpha, color))
	end
	return ColorSequence.new(points)
end

return Rainbow
