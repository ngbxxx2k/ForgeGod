--!strict

local HudMessages = require(script.Parent.Parent.Constants.HudMessages)

local SUFFIX_STEP = 1000
local COMPACT_FROM_INDEX = 1
local ABBREVIATE_FROM_INDEX = 2
local COMPACT_DECIMALS = 1
local ABBREVIATION_DECIMALS = 2
local MAX_PLAIN_NUMBER = 1e15
local SCIENTIFIC_BASE = 10
local SNAP_TOLERANCE = 1e-12
local THOUSANDS_PATTERN = "^(-?%d+)(%d%d%d)"
local THOUSANDS_REPLACE = "%1,%2"

local NumberFormat = {}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function formatNonFinite(value: number): string
	if value ~= value then
		return HudMessages.InvalidNumberText
	end
	local sign = if value < 0 then "-" else ""
	return sign .. HudMessages.InfiniteText
end

local function snap(value: number): number
	local rounded = math.round(value)
	if math.abs(value - rounded) <= rounded * SNAP_TOLERANCE then
		return rounded
	end
	return value
end

local function getSign(value: number): string
	return if value < 0 then "-" else ""
end

local function truncateDecimals(value: number, decimals: number): string
	local factor = SCIENTIFIC_BASE ^ decimals
	local truncated = math.floor(snap(value * factor)) / factor
	local text = string.format("%." .. decimals .. "f", truncated)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text
end

local function formatScientific(amount: number, decimals: number): string
	local exponent = math.floor(math.log10(amount))
	local mantissa = snap(amount / SCIENTIFIC_BASE ^ exponent)
	if mantissa >= SCIENTIFIC_BASE then
		mantissa /= SCIENTIFIC_BASE
		exponent += 1
	end
	return string.format(HudMessages.ScientificFormat, truncateDecimals(mantissa, decimals), exponent)
end

local function formatWithSuffix(amount: number, startIndex: number, decimals: number): string
	local suffixes = HudMessages.NumberSuffixes
	local index = startIndex
	local scaled = snap(amount / SUFFIX_STEP ^ startIndex)
	while scaled >= SUFFIX_STEP and index < #suffixes do
		scaled = snap(scaled / SUFFIX_STEP)
		index += 1
	end
	if scaled >= SUFFIX_STEP then
		return formatScientific(amount, decimals)
	end
	return string.format(HudMessages.AbbreviatedFormat, truncateDecimals(scaled, decimals), suffixes[index])
end

function NumberFormat.Compact(value: number): string
	if not isFinite(value) then
		return formatNonFinite(value)
	end
	local amount = math.floor(math.abs(value))
	if amount < SUFFIX_STEP ^ COMPACT_FROM_INDEX then
		return getSign(value) .. string.format("%d", amount)
	end
	return getSign(value) .. formatWithSuffix(amount, COMPACT_FROM_INDEX, COMPACT_DECIMALS)
end

function NumberFormat.WithCommas(value: number): string
	if not isFinite(value) then
		return formatNonFinite(value)
	end
	if math.abs(value) >= MAX_PLAIN_NUMBER then
		return NumberFormat.Abbreviate(value)
	end
	local text = string.format("%.0f", math.floor(value))
	local count = 1
	while count > 0 do
		text, count = string.gsub(text, THOUSANDS_PATTERN, THOUSANDS_REPLACE)
	end
	return text
end

function NumberFormat.Abbreviate(value: number): string
	if not isFinite(value) then
		return formatNonFinite(value)
	end
	local amount = math.abs(value)
	if amount < SUFFIX_STEP ^ ABBREVIATE_FROM_INDEX then
		return NumberFormat.WithCommas(value)
	end
	return getSign(value) .. formatWithSuffix(amount, ABBREVIATE_FROM_INDEX, ABBREVIATION_DECIMALS)
end

return NumberFormat
