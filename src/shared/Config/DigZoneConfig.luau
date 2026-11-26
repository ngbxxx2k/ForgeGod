--!strict

local DigZoneConfig = {}

DigZoneConfig.Center = Vector3.new(0, 0, 0)
DigZoneConfig.Radius = 42
DigZoneConfig.SpotRadius = 37
DigZoneConfig.GroundY = 0

DigZoneConfig.BadgeName = "DigSiteBadge"
DigZoneConfig.BadgeAnchorName = "DigSiteBadgeAnchor"
-- PLACEHOLDER: độ cao icon bãi dò quặng so với tâm bãi (stud) và kích thước icon (pixel, cố định ở mọi khoảng cách)
DigZoneConfig.BadgeHeight = 24
DigZoneConfig.BadgeIconSize = 110

DigZoneConfig.ScanOffset = Vector3.new(1.05, 0, -1.85)
DigZoneConfig.DigTipOffset = Vector3.new(-0.08, 0, -2.41)

-- PLACEHOLDER: số điểm quặng mỗi người, khoảng cách tối thiểu giữa các điểm, thời gian mọc điểm mới (giây)
DigZoneConfig.SpotsPerPlayer = 4
DigZoneConfig.MinSpotSpacing = 9
DigZoneConfig.SpotRespawnSeconds = 2
DigZoneConfig.SpotPlacementTries = 30

-- PLACEHOLDER: khoảng cách coi là "đúng điểm" (stud) và sai số cho phép phía server
DigZoneConfig.OnSpotDistance = 4
DigZoneConfig.ServerSpotTolerance = 1.5

-- PLACEHOLDER: tầm cảm nhận quặng bên ngoài vòng dò = bán kính vòng x hệ số này (vòng nháy càng nhanh khi càng gần)
DigZoneConfig.SenseRangeMultiplier = 3

DigZoneConfig.ScanInterval = 0.15
DigZoneConfig.SignalSteps = 20

-- PLACEHOLDER: thời gian đào gốc theo độ hiếm quặng (giây), chia cho tốc độ xẻng
DigZoneConfig.DigSeconds = {
	Common = 5,
	Uncommon = 6,
	Rare = 8,
	Epic = 12,
	Legendary = 18,
	Mythic = 28,
} :: { [string]: number }

DigZoneConfig.MinDigSeconds = 1
DigZoneConfig.ResultGraceSeconds = 0.5
DigZoneConfig.MaxDigMoveDistance = 6

function DigZoneConfig.GetDigSeconds(rarity: string, speed: number): number
	local base = DigZoneConfig.DigSeconds[rarity] or DigZoneConfig.DigSeconds.Common
	return math.max(DigZoneConfig.MinDigSeconds, base / math.max(speed, 1))
end

return DigZoneConfig
