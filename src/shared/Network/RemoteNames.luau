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

	-- Client -> Server: (weaponId: string) đập búa một lần vào vũ khí đã chọn (F4)
	RequestForge = "RequestForge",

	-- Server -> Client: (ok: boolean, reason: string?, result: table?)
	NotifyForgeResult = "NotifyForgeResult",

	-- Client -> Server: () hỏi tỉ lệ lần đập kế tiếp của vũ khí đang trang bị
	RequestForgePreview = "RequestForgePreview",

	-- Server -> Client: (ok: boolean, reason: string?, preview: table?)
	NotifyForgePreview = "NotifyForgePreview",

	-- Client -> Server: (weaponId: string) trang bị vũ khí
	RequestEquip = "RequestEquip",

	-- Client -> Server: (weaponId: string) gỡ vũ khí
	RequestUnequip = "RequestUnequip",

	-- Server -> Client: (ok: boolean, reason: string?)
	NotifyEquipResult = "NotifyEquipResult",

	-- Client -> Server: (weaponId: string) bán vũ khí, server tự tính giá (F7)
	RequestSellWeapon = "RequestSellWeapon",

	RequestSellItem = "RequestSellItem",

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

	-- Server -> Client: (state: PlayerState) tiền, kho đồ, vũ khí của chính người chơi
	NotifyPlayerState = "NotifyPlayerState",
}

return RemoteNames
