--!strict

local StationConfig = {}

StationConfig.FurnaceModelName = "OreCrucible"
StationConfig.ForgeModelName = "Fantasy_Anvil"

StationConfig.PromptKeyCode = Enum.KeyCode.E
-- PLACEHOLDER: khoảng cách và thời gian giữ phím để mở lò/bàn rèn
StationConfig.MaxActivationDistance = 10
StationConfig.HoldDuration = 0
-- PLACEHOLDER: khoảng cách server cho phép thêm để bù độ trễ mạng
StationConfig.ServerRangeTolerance = 4

return StationConfig
