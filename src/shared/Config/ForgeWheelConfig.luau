--!strict

local ForgeWheelConfig = {}

ForgeWheelConfig.MinFullTurns = 2
ForgeWheelConfig.NeedleRestAngle = 90
ForgeWheelConfig.NeedleIdleAngle = 0
ForgeWheelConfig.TargetEdgeMargin = 0.2

-- PLACEHOLDER: số vòng/nhịp lúc kim quay tự do trong khi chờ server trả kết quả
ForgeWheelConfig.FreeSpinTurnsPerBeat = 3
ForgeWheelConfig.MinLandingTime = 0.08
ForgeWheelConfig.HaltTime = 0.3
ForgeWheelConfig.ResultTimeout = 3
ForgeWheelConfig.NextChancesDelay = 0.35

ForgeWheelConfig.ChanceMorphTime = 0.25
ForgeWheelConfig.SettleTime = 0.25
ForgeWheelConfig.MinLabelChance = 4
ForgeWheelConfig.LabelRadius = 0.435
ForgeWheelConfig.DividerRadius = 0.435
ForgeWheelConfig.DividerLength = 0.135
ForgeWheelConfig.DividerThickness = 2
ForgeWheelConfig.DividerColor = Color3.fromRGB(24, 18, 14)
ForgeWheelConfig.TickMinInterval = 0.04
ForgeWheelConfig.TickSoundName = "ForgeWheelTick"

return ForgeWheelConfig
