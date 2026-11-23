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

	-- Client -> Server: (currency: "Coins" | "Robux") nâng plot thêm 1 trụ
	RequestPlotUpgrade = "RequestPlotUpgrade",

	-- Server -> Client: (ok: boolean, reason: string?)
	NotifyPlotUpgradeResult = "NotifyPlotUpgradeResult",

	-- Server -> Client: (state: PlayerState) tiền, kho đồ, vũ khí của chính người chơi
	NotifyPlayerState = "NotifyPlayerState",

	-- Server -> Client: (payload: { Cycle: number, Boards: { [boardId]: { entry } } }) top bảng xếp hạng
	NotifyLeaderboards = "NotifyLeaderboards",
}

return RemoteNames
