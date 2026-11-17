--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedConfig = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local BuffConfig = require(sharedConfig:WaitForChild("BuffConfig"))

local DataTemplate = {}

-- Tăng số này khi đổi cấu trúc dữ liệu, rồi thêm hàm migrate trong DataService
DataTemplate.SCHEMA_VERSION = 4

DataTemplate.Limits = {
	DefaultItemSlots = 50, -- kho vật phẩm (tổng số lượng quặng + thuốc + vũ khí)
	MaxEquipped = 3, -- vũ khí treo lưng
	MaxWeaponLevel = 50, -- cấp vũ khí tối đa
	MaxForgePoints = 10, -- điểm rèn tối đa (đạt 10 thì reset về 0)
	LevelsPerShape = 10, -- mỗi 10 cấp đổi hình dạng
	MaxShapeStage = 5, -- hiện có 5 dạng
}

DataTemplate.Rarities = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

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

	-- Đá tẩy mutation
	MutationEraser = { Kind = "Instant" },
} :: { [string]: { Kind: string, Duration: number? } }

-- Vật phẩm buff: thêm hoặc sửa trong shared/Config/BuffConfig
for _, buff in BuffConfig.Buffs do
	DataTemplate.Items[buff.Id] = { Kind = buff.Kind, Duration = buff.Duration }
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

	-- Vũ khí treo lưng: mảng weaponId
	Equipped = {} :: { string },

	-- Sức chứa hiện tại
	Capacity = {
		Items = DataTemplate.Limits.DefaultItemSlots,
	},

	Stats = {
		TotalForges = 0,
		TotalBroken = 0,
		TotalCoinsEarned = 0,
		HighestWeaponValue = 0,
		HighestWeaponLevel = 0,
	},
}

--[[
	WeaponData mẫu cấu trúc khi được tạo trong Weapons:
	{
		Id          : string   -- mã định danh duy nhất
		Rarity      : string   -- Common..Mythic
		Tier        : number   -- 1..5 (bậc độ hiếm)
		WeaponType  : string   -- mã loại vũ khí trong WeaponCatalog (CommonSword...)
		State       : string   -- Blank | Forged | Broken
		Level       : number   -- 0..50
		ForgePoints : number   -- 0..10
		Mutation    : string?  -- nil hoặc tên mutation
		BaseValue   : number   -- giá trị phôi gốc
		Value       : number   -- giá bán hiện tại
		Recipe      : { [string]: number } -- quặng đã dùng: [oreId] = số lượng
		ValueHistory: { number }? -- giá trước mỗi bậc trong vòng rèn hiện tại
		IsLocked    : boolean? -- true nếu người chơi khoá: không bán, không rèn
		CreatedAt   : number   -- epoch
	}
]]

return DataTemplate