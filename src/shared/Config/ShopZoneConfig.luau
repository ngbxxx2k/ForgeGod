--!strict

local ShopZoneConfig = {}

ShopZoneConfig.FolderName = "ShopZones"
ShopZoneConfig.StallPaths = {
	Ore = { "Map", "Hub", "OreShopStall" },
	Item = { "Map", "Hub", "ItemShopStall" },
}

-- PLACEHOLDER: tâm vòng so với pivot quầy (Y -1.75 là mặt đất, -Z là phía trước quầy), bán kính vòng (stud)
ShopZoneConfig.CenterOffset = CFrame.new(0, -1.75, -2)
ShopZoneConfig.Radius = 7.5
-- PLACEHOLDER: độ cao tối đa của HumanoidRootPart so với mặt vòng vẫn tính là đứng trong vòng (stud)
ShopZoneConfig.MaxHeight = 10
-- PLACEHOLDER: khoảng cách server cho phép thêm ngoài vòng để bù độ trễ mạng khi mua (stud)
ShopZoneConfig.ServerRangeTolerance = 4

-- PLACEHOLDER: hình dạng vòng: độ dày đĩa, số đoạn viền, độ dày và bề rộng viền phát sáng (stud)
ShopZoneConfig.DiscThickness = 0.1
ShopZoneConfig.DiscLift = 0.05
ShopZoneConfig.RingSegments = 48
ShopZoneConfig.RingThickness = 0.25
ShopZoneConfig.RingWidth = 0.9
ShopZoneConfig.RingSegmentOverlap = 0.08

ShopZoneConfig.RingColor = Color3.fromRGB(70, 255, 220)
ShopZoneConfig.DiscColor = Color3.fromRGB(90, 255, 190)
ShopZoneConfig.StudsColor = Color3.fromRGB(200, 255, 235)
-- PLACEHOLDER: độ trong suốt của đĩa khi nhấp nháy (min/max), chu kỳ nhấp nháy (giây), độ trong và kích thước ô studs
ShopZoneConfig.DiscTransparencyMin = 0.45
ShopZoneConfig.DiscTransparencyMax = 0.65
ShopZoneConfig.PulsePeriod = 1.2
ShopZoneConfig.StudsTransparency = 0.5
ShopZoneConfig.StudsPerTile = 1

return ShopZoneConfig
