--!strict

local THOUSANDS_PATTERN = "^(-?%d+)(%d%d%d)"
local THOUSANDS_REPLACE = "%1,%2"

local NumberFormat = {}

function NumberFormat.WithCommas(value: number): string
	local text = tostring(math.floor(value))
	local count = 1
	while count > 0 do
		text, count = string.gsub(text, THOUSANDS_PATTERN, THOUSANDS_REPLACE)
	end
	return text
end

return NumberFormat
