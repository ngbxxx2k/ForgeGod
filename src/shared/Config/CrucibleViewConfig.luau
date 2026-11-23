--!strict

local CrucibleViewConfig = {}

-- PLACEHOLDER: vị trí đứng trước nồi (tính từ tâm nồi về phía cửa lò) và độ cao mắt so với mặt đất
CrucibleViewConfig.StandDistance = 5.2
CrucibleViewConfig.EyeHeight = 4.6
CrucibleViewConfig.LookOffset = Vector3.new(0, -0.3, 0)
CrucibleViewConfig.ScreenYaw = 0
CrucibleViewConfig.FieldOfView = 70
CrucibleViewConfig.CameraTweenTime = 0.35
CrucibleViewConfig.RenderStepName = "CrucibleStanceView"

CrucibleViewConfig.OreFolderName = "Ores"
CrucibleViewConfig.DropModelName = "OreDrop"
-- PLACEHOLDER: kích thước, độ cao rơi, độ sâu chìm và thời gian rơi của quặng thả vào nồi
CrucibleViewConfig.OreScale = 0.55
CrucibleViewConfig.DropHeight = 6
CrucibleViewConfig.SinkDepth = 1.5
CrucibleViewConfig.DropDuration = 0.65
CrucibleViewConfig.DropSpinSpeed = 4

return CrucibleViewConfig
