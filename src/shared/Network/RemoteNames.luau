--!strict
--[[
	RemoteNames
	Trách nhiệm: định nghĩa tên RemoteEvent dùng cho shop ở MỘT nơi duy nhất.
	Không viết chuỗi tên Remote rải rác trong code.
]]

local RemoteNames = {
	-- Client -> Server: (itemId: string, amount: number)
	RequestBuy = "RequestBuy",

	-- Server -> Client: (ok: boolean, reason: string?)
	NotifyBuyResult = "NotifyBuyResult",

	-- Server -> Client: trạng thái shop (tồn kho, giá, mốc restock)
	NotifyShopState = "NotifyShopState",

	-- Client -> Server: (ores: { [oreId] = amount }) tạo phôi (F3)
	RequestSmelt = "RequestSmelt",

	-- Server -> Client: (ok: boolean, reason: string?, weapon: table?)
	NotifySmeltResult = "NotifySmeltResult",

	RequestSmeltOdds = "RequestSmeltOdds",

	NotifySmeltOdds = "NotifySmeltOdds",

	-- Client -> Server: (weaponId: string) đập búa một lần vào vũ khí đã chọn (F4)
	RequestForge = "RequestForge",

	-- Server -> Client: (ok: boolean, reason: string?, result: table?)
	NotifyForgeResult = "NotifyForgeResult",

	-- Client -> Server: (weaponId: string) hỏi tỉ lệ lần đập kế tiếp của vũ khí đã chọn
	RequestForgePreview = "RequestForgePreview",

	-- Server -> Client: (ok: boolean, reason: string?, preview: table?)
	NotifyForgePreview = "NotifyForgePreview",

	-- Client -> Server: (weaponId: string?) vào bàn rèn với vũ khí này, nil khi rời bàn rèn
	RequestForgeStance = "RequestForgeStance",

	-- Server -> Client khác: (userId: number, strike: table) kết quả một lần đập để phát hiệu ứng cho người xem
	NotifyForgeStrike = "NotifyForgeStrike",

	-- Client -> Server: (weaponId: string) trang bị vũ khí
	RequestEquip = "RequestEquip",

	-- Client -> Server: (weaponId: string) gỡ vũ khí
	RequestUnequip = "RequestUnequip",

	-- Server -> Client: (ok: boolean, reason: string?)
	NotifyEquipResult = "NotifyEquipResult",

	-- Client -> Server: () trang bị các vũ khí sinh tiền nhiều nhất vào Loadout
	RequestEquipBest = "RequestEquipBest",

	-- Client -> Server: (weaponId: string) cầm/bỏ cầm vũ khí trên tay
	RequestHoldWeapon = "RequestHoldWeapon",

	-- Server -> Client: (ok: boolean, reason: string?)
	NotifyHoldResult = "NotifyHoldResult",

	-- Client -> Server: (weaponId: string) bán vũ khí, server tự tính giá (F7)
	RequestSellWeapon = "RequestSellWeapon",

	RequestSellItem = "RequestSellItem",

	-- Client -> Server: (weaponIds: { string }) bán các vũ khí đã xác nhận, trừ đang đeo/đã khoá
	RequestSellAllWeapons = "RequestSellAllWeapons",

	-- Server -> Client: (ok: boolean, reason: string?, coins: number?)
	NotifySellResult = "NotifySellResult",

	-- Client -> Server: (weaponId: string, isLocked: boolean) khoá/mở khoá vũ khí
	RequestSetWeaponLock = "RequestSetWeaponLock",

	-- Server -> Client: (ok: boolean, reason: string?)
	NotifyWeaponLockResult = "NotifyWeaponLockResult",

	-- Client -> Server: (itemId: string) dùng một vật phẩm buff
	RequestUseItem = "RequestUseItem",

	-- Server -> Client: (ok: boolean, reason: string?, itemId: string?)
	NotifyUseItemResult = "NotifyUseItemResult",

	-- Client -> Server: (itemId: string, weaponId: string) dùng vật phẩm lên vũ khí (hồi sinh, tẩy mutation)
	RequestUseWeaponItem = "RequestUseWeaponItem",

	-- Server -> Client: (ok: boolean, reason: string?, itemId: string?)
	NotifyUseWeaponItemResult = "NotifyUseWeaponItemResult",

	-- Client -> Server: (currency: "Coins" | "Robux") nâng plot thêm 1 trụ
	RequestPlotUpgrade = "RequestPlotUpgrade",

	-- Server -> Client: (ok: boolean, reason: string?)
	NotifyPlotUpgradeResult = "NotifyPlotUpgradeResult",

	-- Client -> Server: () đào tại vị trí đầu dò hiện tại
	RequestDig = "RequestDig",

	-- Server -> Client: (strength: number, isOnSpot: boolean) 0 = không tín hiệu, 0..1 = quặng ngoài vòng, 1 = quặng trong vòng
	NotifyDigSignal = "NotifyDigSignal",

	-- Server -> Client: (markers: { { Position: Vector3, Rarity: string } }) điểm quặng trong vòng dò
	NotifyDigMarkers = "NotifyDigMarkers",

	-- Server -> Client: (spot: Vector3, duration: number) bắt đầu đào
	NotifyDigStarted = "NotifyDigStarted",

	-- Server -> Client: (ok: boolean, reason: string?, oreId: string?)
	NotifyDigResult = "NotifyDigResult",

	-- Client -> Server: (toolId: string, tierIndex: number, currency: "Coins" | "Robux") mua bậc máy dò / xẻng (được nhảy bậc)
	RequestBuyDigTool = "RequestBuyDigTool",

	-- Server -> Client: (ok: boolean, reason: string?, toolId: string?, tierIndex: number?)
	NotifyBuyDigToolResult = "NotifyBuyDigToolResult",

	-- Client -> Server: (trackId: "Anvil" | "Hammer", tierIndex: number, currency: "Coins" | "Robux") mua bậc đe / búa (được nhảy bậc)
	RequestBuyForgeTool = "RequestBuyForgeTool",

	-- Server -> Client: (ok: boolean, reason: string?, trackId: string?, tierIndex: number?, isSkinChange: boolean?)
	NotifyForgeToolResult = "NotifyForgeToolResult",

	-- Client -> Server: (trackId: string, tierIndex: number) chọn texture đe / búa trong các bậc đã sở hữu
	RequestSetForgeSkin = "RequestSetForgeSkin",

	-- Client -> Server: (toolId: "Detector" | "Shovel", tierIndex: number) trang bị bậc máy dò / xẻng đã sở hữu
	RequestEquipDigTool = "RequestEquipDigTool",

	-- Client -> Server: () mở cửa sổ mua Robux mở rộng kho vũ khí
	RequestBuyStorage = "RequestBuyStorage",

	-- Server -> Client: (ok: boolean, reason: string?)
	NotifyBuyStorageResult = "NotifyBuyStorageResult",

	-- Client -> Server: (kind: "Pass" | "CoinPack" | "OrePack", id: string) mở cửa sổ mua Robux ở Shop nạp
	RequestPremiumPurchase = "RequestPremiumPurchase",

	-- Server -> Client: (ok: boolean, reason: string?, kind: string?, id: string?)
	NotifyPremiumPurchaseResult = "NotifyPremiumPurchaseResult",

	-- Client -> Server: (kind: "Item" | "Restock", itemId: string?) mua vật phẩm Item Shop hoặc restock bằng Robux
	RequestShopRobuxPurchase = "RequestShopRobuxPurchase",

	-- Server -> Client: (ok: boolean, reason: string?, kind: string?, itemId: string?)
	NotifyShopRobuxResult = "NotifyShopRobuxResult",

	-- Client -> Server: (kind: "Pass" | "CoinPack", id: string, recipientUserId: number) mua quà tặng người chơi khác
	RequestGiftPurchase = "RequestGiftPurchase",

	-- Server -> Client (người tặng): (ok: boolean, reason: string?, recipientName: string?, isFallback: boolean?)
	NotifyGiftResult = "NotifyGiftResult",

	-- Server -> Client (người nhận): (kind: string, id: string, senderName: string)
	NotifyGiftReceived = "NotifyGiftReceived",

	-- Client -> Server: () quay vòng may mắn (dùng lượt free trước, rồi lượt đã có)
	RequestSpin = "RequestSpin",

	-- Server -> Client: (ok: boolean, reason: string?, rewardId: string?)
	NotifySpinResult = "NotifySpinResult",

	-- Client -> Server: () mở cửa sổ mua 1 lượt quay bằng Robux
	RequestBuySpin = "RequestBuySpin",

	-- Server -> Client: (ok: boolean, reason: string?)
	NotifyBuySpinResult = "NotifyBuySpinResult",

	-- Client -> Server: (tabId: string, rarity: string) nhận quà bộ sưu tập Index đã đủ
	RequestClaimIndexReward = "RequestClaimIndexReward",

	-- Server -> Client: (ok: boolean, reason: string?, tabId: string?, rarity: string?)
	NotifyClaimIndexRewardResult = "NotifyClaimIndexRewardResult",

	-- Client -> Server: (stepId: string) báo đã xong bước hướng dẫn chỉ client thấy được (mở/đóng UI, tới nơi)
	RequestTutorialAdvance = "RequestTutorialAdvance",

	-- Server -> Client: (state: PlayerState) tiền, kho đồ, vũ khí của chính người chơi
	NotifyPlayerState = "NotifyPlayerState",

	-- Server -> Client: (payload: { Cycle: number, Boards: { [boardId]: { entry } } }) top bảng xếp hạng
	NotifyLeaderboards = "NotifyLeaderboards",
}

return RemoteNames
