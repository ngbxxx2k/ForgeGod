--!strict

local PlotConfig = {}

PlotConfig.PlotsFolderName = "Plots"
PlotConfig.PlotNamePrefix = "Plot"
PlotConfig.PedestalsFolderName = "Pedestals"
PlotConfig.PedestalNamePrefix = "Pedestal"
PlotConfig.AnchorName = "WeaponAnchor"
PlotConfig.DisplayModelName = "DisplayWeapon"
PlotConfig.StationsFolderName = "Stations"

-- PLACEHOLDER: vị trí nồi nấu và đe so với tâm sàn plot (trục +Z hướng về tâm map, Y -0.2 là mặt đất vì sàn plot trong suốt)
PlotConfig.CrucibleOffset = CFrame.new(0, -0.2, 0) * CFrame.Angles(0, math.pi, 0)
PlotConfig.AnvilOffset = CFrame.new(9, -0.2, 0)

PlotConfig.LabelName = "DisplayLabel"
-- PLACEHOLDER: kích thước nhãn (stud), khoảng cách từ đỉnh vũ khí lên nhãn (stud), tầm nhìn tối đa (stud)
PlotConfig.LabelSize = Vector2.new(4.4, 2.4)
PlotConfig.LabelGap = 0.4
PlotConfig.LabelMaxDistance = 90
PlotConfig.LabelFont = Enum.Font.FredokaOne
PlotConfig.LabelTextColor = Color3.fromRGB(255, 255, 255)
PlotConfig.LabelIncomeColor = Color3.fromRGB(70, 230, 60)
PlotConfig.LabelStrokeColor = Color3.fromRGB(20, 20, 20)
PlotConfig.LabelStrokeThickness = 3
PlotConfig.LabelRowHeights = { Rarity = 0.34, Name = 0.33, Income = 0.33 }

PlotConfig.BadgeName = "PlotOwnerBadge"
PlotConfig.BadgeAnchorName = "PlotBadgeAnchor"
-- PLACEHOLDER: độ cao bảng chủ plot so với tâm sàn (stud), kích thước ảnh tròn và chữ tên (pixel, cố định ở mọi khoảng cách)
PlotConfig.BadgeHeight = 28
PlotConfig.BadgeIconSize = 96
PlotConfig.BadgeNameHeight = 30
PlotConfig.BadgeNameWidth = 220
PlotConfig.BadgeIconBackground = Color3.fromRGB(225, 232, 240)
PlotConfig.BadgeOutlineColor = Color3.fromRGB(20, 20, 20)
PlotConfig.BadgeOutlineThickness = 4
PlotConfig.BadgeThumbnailFormat = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"

PlotConfig.FencePath = { "Map", "Fences", "PlotFences" }
PlotConfig.FenceSuffix = "Fence"
PlotConfig.FencePostNames = { "Post", "PostCap" }
PlotConfig.FenceRailNames = { "RailTop", "RailBottom" }

-- PLACEHOLDER: điểm hồi sinh so với tâm sàn plot: ngoài cổng rào (rào r=26.5), cao 3 stud (HumanoidRootPart), mặt nhìn vào plot
PlotConfig.SpawnOffset = CFrame.new(0, 3, 32)
-- PLACEHOLDER: thời gian chờ tối đa (giây) để nhân vật có HumanoidRootPart trước khi dời về plot
PlotConfig.SpawnRootWaitTime = 5

PlotConfig.UpgradeSignName = "PlotUpgradeSign"
-- PLACEHOLDER: vị trí bảng nâng cấp so với tâm sàn plot: ngoài rào, bên phải cổng khi nhìn từ tâm map ra, mặt bảng nhìn về tâm map
PlotConfig.UpgradeSignOffset = CFrame.new(9, -0.2, 30) * CFrame.Angles(0, math.pi, 0)
-- PLACEHOLDER: kích thước bảng và cột (stud), tổng cao = cao hàng rào 4.4; độ phân giải chữ (pixel mỗi stud, giữ canvas ~350x225)
PlotConfig.UpgradeBoardSize = Vector3.new(4.2, 2.7, 0.3)
PlotConfig.UpgradePostSize = Vector3.new(0.6, 1.7, 0.4)
PlotConfig.UpgradePixelsPerStud = 84
PlotConfig.UpgradeBoardColor = Color3.fromRGB(30, 40, 78)
PlotConfig.UpgradePostColor = Color3.fromRGB(22, 30, 60)
PlotConfig.UpgradeLevelColor = Color3.fromRGB(120, 240, 80)
PlotConfig.UpgradeCoinButtonColor = Color3.fromRGB(225, 40, 40)
PlotConfig.UpgradeRobuxButtonColor = Color3.fromRGB(55, 190, 70)

-- PLACEHOLDER: biên độ (stud) và chu kỳ (giây) nhấp nhô, độ lệch pha giữa các trụ (giây)
PlotConfig.BobAmplitude = 0.25
PlotConfig.BobPeriod = 3
PlotConfig.BobPhaseStep = 0.6

return PlotConfig
