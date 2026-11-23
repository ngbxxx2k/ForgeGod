--!strict

local ForgeUpgradeZoneConfig = {}

ForgeUpgradeZoneConfig.FolderName = "ForgeUpgradeZone"
ForgeUpgradeZoneConfig.RingName = "ForgeUpgradeRing"

-- Trục cục bộ của mesh đe hướng về mũi nhọn (đo bằng raycast: đe thon dần về phía +X)
ForgeUpgradeZoneConfig.HornAxis = Vector3.xAxis
-- PLACEHOLDER: khoảng cách mong muốn từ tâm đe tới tâm vòng theo hướng mũi đe (stud), trước khi bắt vào góc ô cỏ
ForgeUpgradeZoneConfig.Distance = 6
-- PLACEHOLDER: lệch thêm về phía người chơi đứng rèn (+Z cục bộ của đe, xem ForgeStrikeConfig.StandOffset) để chọn góc ô ổn định (stud)
ForgeUpgradeZoneConfig.SideAxis = Vector3.zAxis
ForgeUpgradeZoneConfig.SideOffset = 1
-- Kích thước một ô caro của cỏ (Ground Texture StudsPerTile = 8 chứa 2x2 ô); tâm vòng bắt vào giao điểm 4 ô, đường kính vòng = 1 ô
ForgeUpgradeZoneConfig.GridSize = 4
ForgeUpgradeZoneConfig.GridOrigin = Vector2.zero
ForgeUpgradeZoneConfig.Radius = ForgeUpgradeZoneConfig.GridSize / 2
-- PLACEHOLDER: bề rộng viền phát sáng (stud), giữ tỉ lệ viền/bán kính gần với vòng shop
ForgeUpgradeZoneConfig.RingWidth = 0.3
-- Neon tím bị bloom đẩy sang hồng nên dùng sắc tím ngả xanh
ForgeUpgradeZoneConfig.RingColor = Color3.fromRGB(75, 25, 200)
ForgeUpgradeZoneConfig.DiscColor = Color3.fromRGB(130, 80, 240)
ForgeUpgradeZoneConfig.StudsColor = Color3.fromRGB(230, 200, 255)

ForgeUpgradeZoneConfig.LabelName = "ForgeUpgradeLabel"
-- PLACEHOLDER: độ cao chữ so với mặt đất (ngang đầu nhân vật R15), kích thước chữ (stud), tầm nhìn tối đa (stud)
ForgeUpgradeZoneConfig.LabelHeight = 5
ForgeUpgradeZoneConfig.LabelSize = Vector2.new(5, 1.25)
ForgeUpgradeZoneConfig.LabelMaxDistance = 80
ForgeUpgradeZoneConfig.LabelFont = Enum.Font.FredokaOne
ForgeUpgradeZoneConfig.LabelTextColor = Color3.fromRGB(255, 150, 30)
ForgeUpgradeZoneConfig.LabelStrokeColor = Color3.fromRGB(20, 20, 20)
ForgeUpgradeZoneConfig.LabelStrokeThickness = 3
-- PLACEHOLDER: khoảng cách ngang tối thiểu từ tâm đe tới tâm vòng để vòng không đè lên đe (stud)
ForgeUpgradeZoneConfig.MinAnvilClearance = 4.5
-- Số góc ô lân cận (mỗi phía) được xét khi chọn góc gần điểm mong muốn nhất
ForgeUpgradeZoneConfig.SnapSearchRange = 1
-- PLACEHOLDER: độ cao tối đa của HumanoidRootPart so với mặt vòng vẫn tính là đứng trong vòng (stud)
ForgeUpgradeZoneConfig.MaxHeight = 10

return ForgeUpgradeZoneConfig
