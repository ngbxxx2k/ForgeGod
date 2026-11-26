--!strict

local ForgeUpgradeZoneConfig = {}

ForgeUpgradeZoneConfig.FolderName = "ForgeUpgradeZone"
ForgeUpgradeZoneConfig.RingName = "ForgeUpgradeRing"

-- Quầy shop nâng cấp ở Hub (thay cho Ore Shop cũ), vòng đặt trước quầy giống vòng Item Shop
ForgeUpgradeZoneConfig.StallPath = { "Map", "Hub", "UpgradeShopStall" }

-- Neon tím bị bloom đẩy sang hồng nên dùng sắc tím ngả xanh
ForgeUpgradeZoneConfig.RingColor = Color3.fromRGB(75, 25, 200)
ForgeUpgradeZoneConfig.DiscColor = Color3.fromRGB(130, 80, 240)
ForgeUpgradeZoneConfig.StudsColor = Color3.fromRGB(230, 200, 255)

-- PLACEHOLDER: độ cao tối đa của HumanoidRootPart so với mặt vòng vẫn tính là đứng trong vòng (stud)
ForgeUpgradeZoneConfig.MaxHeight = 10

return ForgeUpgradeZoneConfig
