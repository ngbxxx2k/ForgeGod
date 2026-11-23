--!strict

local LOG_SCALE = 1e12

local LeaderboardScore = {}

function LeaderboardScore.Encode(value: number): number
	if value ~= value or value <= 0 then
		return 0
	end
	return math.floor(math.log10(value + 1) * LOG_SCALE + 0.5)
end

function LeaderboardScore.Decode(score: number): number
	if score <= 0 then
		return 0
	end
	return math.floor(10 ^ (score / LOG_SCALE) - 1 + 0.5)
end

return LeaderboardScore
