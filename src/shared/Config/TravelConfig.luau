--!strict

local TravelConfig = {}

-- PLACEHOLDER: điểm đứng trước cổng plot so với pivot plot (+Z hướng về tâm map, Y -0.2 là mặt đất, cổng ở r=26.5)
TravelConfig.HomeStandOffset = CFrame.new(0, -0.2, 32)
-- PLACEHOLDER: khoảng cách đứng ngoài mép vòng shop khi dịch chuyển tới shop (stud)
TravelConfig.ShopStandGap = 4
-- PLACEHOLDER: camera sau dịch chuyển: khoảng cách phía sau và độ cao so với nhân vật (stud)
TravelConfig.CameraBackDistance = 14
TravelConfig.CameraHeight = 6

return TravelConfig
