--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedConfig = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local BuffConfig = require(sharedConfig:WaitForChild("BuffConfig"))
local LoadoutConfig = require(sharedConfig:WaitForChild("LoadoutConfig"))
local TutorialConfig = require(sharedConfig:WaitForChild("TutorialConfig"))
local WeaponItemConfig = require(sharedConfig:WaitForChild("WeaponItemConfig"))

local DataTemplate = {}

-- Tăng số này khi đổi cấu trúc dữ liệu, rồi thêm hàm migrate trong DataService
DataTemplate.SCHEMA_VERSION = 8

DataTemplate.Limits = {
	DefaultItemSlots = 50, -- kho vật phẩm (chỉ đếm vũ khí, quặng và buff không tính)
	DefaultLoadoutSlots = LoadoutConfig.DefaultSlots, -- số ô Loadout (vũ khí sinh tiền mỗi giây)
	MaxWeaponLevel = 100, -- cấp tối đa tuyệt đối (theo độ hiếm: ForgeConfig)
	MaxForgePoints = 10, -- điểm rèn tối đa (chỉ reset về 0 khi vượt quá mức này)
	LevelsPerShape = 10, -- mỗi 10 cấp đổi hình dạng
	MinShapeStage = 1, -- dạng ban đầu của vũ khí
	MaxShapeStage = 5, -- hiện có 5 dạng
	MaxProcessedPurchases = 50, -- số mã giao dịch Robux gần nhất giữ lại để chống cộng trùng
	MaxCoins = 1e300, -- trần tiền và tổng tiền kiếm được, tránh tràn số thành inf (DataStore không lưu được inf)
}

DataTemplate.Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

DataTemplate.WeaponStates = {
	Blank = "Blank", -- phôi chưa rèn
	Forged = "Forged", -- vũ khí đã rèn
	Broken = "Broken", -- vũ khí hỏng: chỉ để bán, không đeo được
}

DataTemplate.ItemKinds = {
	Ore = "Ore", -- quặng
	OneUse = "OneUse", -- buff dùng 1 lần, cộng dồn số lần
	Timed = "Timed", -- buff theo thời gian, cộng dồn thời gian
	Instant = "Instant", -- dùng ngay lên vũ khí
}

DataTemplate.Items = {
	-- Quặng
	Copper = { Kind = "Ore" },
	Iron = { Kind = "Ore" },
	Silver = { Kind = "Ore" },
	Gold = { Kind = "Ore" },
	Platinum = { Kind = "Ore" },
	Emerald = { Kind = "Ore" },
	DarkMoonstone = { Kind = "Ore" },
	Mithril = { Kind = "Ore" },
	GodsCore = { Kind = "Ore" },
} :: { [string]: { Kind: string, Duration: number? } }

-- Vật phẩm buff: thêm hoặc sửa trong shared/Config/BuffConfig
for _, buff in BuffConfig.Buffs do
	DataTemplate.Items[buff.Id] = { Kind = buff.Kind, Duration = buff.Duration }
end

-- Vật phẩm dùng ngay lên vũ khí (đá tẩy mutation, hồi sinh): shared/Config/WeaponItemConfig
for _, item in WeaponItemConfig.Items do
	DataTemplate.Items[item.Id] = { Kind = "Instant" }
end

-- Dữ liệu mặc định của người chơi mới.
DataTemplate.Default = {
	SchemaVersion = DataTemplate.SCHEMA_VERSION,

	Coins = 100, -- Tiền khởi đầu để mua quặng đầu tiên

	-- Kho vật phẩm: [itemId] = số lượng (quặng + thuốc)
	Items = {} :: { [string]: number },

	-- Từng vũ khí/phôi: [weaponId] = WeaponData
	Weapons = {} :: { [string]: any },

	-- Buff theo thời gian đang chạy: [itemId] = thời điểm hết hạn (epoch, giây)
	ActiveBuffs = {} :: { [string]: number },

	-- Buff theo thời gian tạm dừng khi thoát game: [itemId] = số giây còn lại
	PausedBuffs = {} :: { [string]: number },

	-- Buff dùng 1 lần đã kích hoạt nhưng chưa bị consume: [itemId] = số lần còn lại
	ArmedBuffs = {} :: { [string]: number },

	-- Vũ khí trong Loadout (sinh tiền mỗi giây): mảng weaponId
	Equipped = {} :: { string },

	-- Sức chứa hiện tại
	Capacity = {
		Items = DataTemplate.Limits.DefaultItemSlots,
		Loadout = DataTemplate.Limits.DefaultLoadoutSlots, -- = số trụ của plot, nâng qua bảng Upgrade Plot
	},

	-- Bậc dụng cụ đào đang trang bị (1..7, phải nằm trong OwnedDigTiers): quyết định chỉ số khi đào
	DigTools = {
		Detector = 1,
		Shovel = 1,
	},

	-- Các bậc máy dò / xẻng đã sở hữu: mảng chỉ số bậc (1..7), luôn có bậc 1; mua bậc nào mở khoá bậc đó
	OwnedDigTiers = {
		Detector = { 1 },
		Shovel = { 1 },
	},

	-- Các bậc đe / búa đã sở hữu: mảng chỉ số bậc (1..7), luôn có bậc 1; mua bậc nào mở khoá bậc đó.
	-- Bậc có may mắn cao nhất trong mảng quyết định may mắn khi rèn
	OwnedForgeTiers = {
		Anvil = { 1 },
		Hammer = { 1 },
	},

	-- Bậc texture đe / búa đang dùng (<= bậc sở hữu): chỉ đổi hình, không đổi may mắn
	ForgeSkins = {
		Anvil = 1,
		Hammer = 1,
	},

	-- Bộ sưu tập Index: [IndexKey "Mutation|WeaponType|ShapeStage"] = true khi từng sở hữu
	Index = {} :: { [string]: boolean },

	-- Quà Index đã nhận: ["Tab|Rarity"] = true khi đã bấm CLAIM bộ sưu tập đủ của bậc đó trong tab đó
	IndexRewards = {} :: { [string]: boolean },

	-- Vòng quay may mắn: số lượt đã có (mua/trúng) và thời điểm dùng lượt free gần nhất (epoch, giây)
	Spin = {
		Tokens = 0,
		LastFreeAt = 0,
	},

	-- Pass được người khác tặng (mua qua Developer Product tặng quà): [passId] = true, tác dụng như Game Pass
	GiftedPasses = {} :: { [string]: boolean },

	-- Mã giao dịch Robux (PurchaseId) đã cộng quà, mới nhất ở cuối, tối đa MaxProcessedPurchases
	ProcessedPurchases = {} :: { string },

	-- Hướng dẫn người chơi mới: bước đang làm (Id trong TutorialConfig.Steps), số quặng đã đào trong bước
	-- DigOres, và cờ đã hoàn thành (true thì không hướng dẫn nữa)
	Tutorial = {
		StepId = TutorialConfig.FirstStepId,
		DigCount = 0,
		IsComplete = false,
	},

	Stats = {
		TotalForges = 0,
		TotalBroken = 0,
		TotalCoinsEarned = 0,
		HighestWeaponValue = 0,
		HighestWeaponLevel = 0,
		HighestWeaponIncome = 0, -- $/s cao nhất của một vũ khí từng sở hữu (bảng xếp hạng)
		TotalRobuxSpent = 0, -- tổng Robux đã chi trong game (bảng xếp hạng Donated)
	},
}

--[[
	WeaponData mẫu cấu trúc khi được tạo trong Weapons:
	{
		Id          : string   -- mã định danh duy nhất
		Rarity      : string   -- Common..Mythic
		Tier        : number   -- 1..6 (bậc độ hiếm)
		WeaponType  : string   -- mã loại vũ khí trong WeaponCatalog (CommonSword...)
		State       : string   -- Blank | Forged | Broken
		Level       : number   -- 0..50
		ForgePoints : number   -- 0..10
		ShapeStage  : number?  -- dạng hiện tại 1..MaxShapeStage (nil = 1)
		ShapeStrikes: number?  -- số lượt đập kể từ lần đổi hình gần nhất (nil = 0)
		FrenzyStrikes: number? -- số lượt đập thường kể từ lần frenzy gần nhất (nil = 0)
		Mutation    : string?  -- nil hoặc tên mutation
		Scale       : number?  -- hệ số kích thước 1..10 (nil = 1); cân nặng suy ra từ Scale
		BaseValue   : number   -- giá trị phôi gốc (đã nhân hệ số kích thước)
		Value       : number   -- giá bán hiện tại
		Recipe      : { [string]: number } -- quặng đã dùng: [oreId] = số lượng
		ValueHistory: { number }? -- giá trước mỗi bậc trong vòng rèn hiện tại
		IsLocked    : boolean? -- true nếu người chơi khoá: không bán, không rèn
		CreatedAt   : number   -- epoch
	}
]]

return DataTemplate