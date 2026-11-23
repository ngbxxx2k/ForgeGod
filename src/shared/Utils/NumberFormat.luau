--!strict

local HudMessages = require(script.Parent.Parent.Constants.HudMessages)

local ABBREVIATE_FROM = 1_000_000
local ABBREVIATION_STEP = 1000
local ABBREVIATION_DECIMALS = 2
local THOUSANDS_PATTERN = "^(-?%d+)(%d%d%d)"
local THOUSANDS_REPLACE = "%1,%2"
local COMPACT_STEP = 1000
local COMPACT_DECIMALS = 10
local COMPACT_SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local NumberFormat = {}

function NumberFormat.Compact(value: number): string
	local sign = if value < 0 then "-" else ""
	local amount = math.floor(math.abs(value))
	if amount < COMPACT_STEP then
		return sign .. tostring(amount)
	end
	local index = 0
	local scaled = amount
	while scaled >= COMPACT_STEP and index < #COMPACT_SUFFIXES do
		scaled /= COMPACT_STEP
		index += 1
	end
	local rounded = math.floor(scaled * COMPACT_DECIMALS) / COMPACT_DECIMALS
	local text = if rounded % 1 == 0
		then string.format("%d", rounded)
		else string.format("%.1f", rounded)
	return sign .. text .. COMPACT_SUFFIXES[index]
end

function NumberFormat.WithCommas(value: number): string
	local text = tostring(math.floor(value))
	local count = 1
	while count > 0 do
		text, count = string.gsub(text, THOUSANDS_PATTERN, THOUSANDS_REPLACE)
	end
	return text
end

local function trimDecimals(value: number): string
	local factor = 10 ^ ABBREVIATION_DECIMALS
	local truncated = math.floor(value * factor) / factor
	local text = string.format("%." .. ABBREVIATION_DECIMALS .. "f", truncated)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text
end

function NumberFormat.Abbreviate(value: number): string
	if value < ABBREVIATE_FROM then
		return NumberFormat.WithCommas(value)
	end
	local suffixes = HudMessages.AbbreviationSuffixes
	local scaled = value / ABBREVIATE_FROM
	local index = 1
	while scaled >= ABBREVIATION_STEP and index < #suffixes do
		scaled /= ABBREVIATION_STEP
		index += 1
	end
	return string.format(HudMessages.AbbreviatedFormat, trimDecimals(scaled), suffixes[index])
end

return NumberFormat
