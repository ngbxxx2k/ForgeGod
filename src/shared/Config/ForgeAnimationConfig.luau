--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetIds = require(ReplicatedStorage.Shared.Constants.AssetIds)
local ForgeRevealTypes = require(ReplicatedStorage.Shared.Types.ForgeRevealTypes)
local WeaponCatalog = require(ReplicatedStorage.Shared.Constants.WeaponCatalog)

type WeaponVisual = ForgeRevealTypes.WeaponVisual
type SoundSpec = ForgeRevealTypes.SoundSpec

local SWORD_MODEL = "Sword_level_1"
local WEAPON_LENGTH = 4.8

local ForgeAnimationConfig = {}

-- Font dùng cho toàn bộ chữ trong cutscene nấu quặng
ForgeAnimationConfig.CutsceneFont = Font.new("rbxasset://fonts/families/FredokaOne.json")

-- Thư mục tìm model vũ khí: ReplicatedStorage.Assets.Models
ForgeAnimationConfig.AssetsFolderName = "Assets"
ForgeAnimationConfig.ModelsFolderName = "Models"
ForgeAnimationConfig.WeaponInstanceName = "ForgeRevealWeapon"

-- Chờ kết quả server tối đa bao nhiêu giây, quá thì huỷ cutscene
ForgeAnimationConfig.ResultTimeout = 6

ForgeAnimationConfig.DefaultVisual = { ModelName = SWORD_MODEL, Length = WEAPON_LENGTH } :: WeaponVisual

ForgeAnimationConfig.WeaponVisuals = {} :: { [string]: WeaponVisual }

for id in WeaponCatalog.ById do
	ForgeAnimationConfig.WeaponVisuals[id] = { ModelName = SWORD_MODEL, WeaponTypeId = id, Length = WEAPON_LENGTH }
end

-- Camera điện ảnh
ForgeAnimationConfig.Camera = {
	RenderStepName = "ForgeRevealCamera",
	-- Zoom vào nồi: thời gian, góc nhìn, khoảng cách tới nham thạch, độ cao camera so với nham thạch
	IntroDuration = 0.9,
	IntroFieldOfView = 55,
	IntroDistance = 6.5,
	IntroHeight = 2.2,
	IntroLookLift = 0.5,
	-- Khung hình vũ khí: camera lùi xa theo chiều dài vũ khí (stud lùi mỗi stud chiều dài)
	WeaponFieldOfView = 50,
	WeaponMinDistance = 11,
	WeaponDistancePerStud = 2.2,
	WeaponHeight = -0.6,
	-- Trả camera về góc nhìn nồi khi kết thúc
	ReturnDuration = 0.6,
	EasingStyle = Enum.EasingStyle.Quart,
	-- Trong lúc sét roll: camera lùi dần ra xa (nhân khoảng cách) cho kịch tính
	RollPullback = 1.15,
	-- Rung camera: độ mạnh mỗi cú sét thường / cú sét cuối, độ lệch tối đa (stud, độ), tốc độ tắt dần
	ShakeStrike = 0.3,
	ShakeFinal = 1,
	ShakePosition = 0.35,
	ShakeRotation = 1.6,
	ShakeDecay = 7,
	ShakeFrequency = 26,
	-- FOV punch tắt dần nhanh cỡ nào
	FovPunchDecay = 6,
}

-- Thứ tự cấp bậc từ thấp tới cao (thêm cấp mới thì thêm vào đây và vào Rarities)
ForgeAnimationConfig.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

-- Mỗi cấp: tên hiển thị, màu flash/sét, số cú sét (mỗi cú sét = một bậc trong vòng roll)
ForgeAnimationConfig.Rarities = {
	Common = { DisplayName = "COMMON", Color = Color3.fromRGB(225, 228, 235), StrikeCount = 5 },
	Uncommon = { DisplayName = "UNCOMMON", Color = Color3.fromRGB(70, 200, 90), StrikeCount = 5 },
	Rare = { DisplayName = "RARE", Color = Color3.fromRGB(60, 140, 255), StrikeCount = 6 },
	Epic = { DisplayName = "EPIC", Color = Color3.fromRGB(175, 75, 255), StrikeCount = 6 },
	Legendary = { DisplayName = "LEGENDARY", Color = Color3.fromRGB(255, 200, 40), StrikeCount = 7 },
	Mythic = { DisplayName = "MYTHIC", Color = Color3.fromRGB(255, 45, 45), StrikeCount = 8 },
} :: { [string]: { DisplayName: string, Color: Color3, StrikeCount: number } }

-- Nhịp sét bám theo tiếng sấm: cú sét kế tiếp chỉ đánh khi tiếng sấm trước đã phát hết
-- ThunderLength: độ dài file tiếng sấm (giây, ở tốc độ 1), StrikeGap: nghỉ thêm giữa 2 cú
-- FinalHold: giữ bao lâu sau cú cuối (phải >= tiếng sấm cuối để không bị cắt)
ForgeAnimationConfig.RarityRoll = {
	ThunderLength = 1.57,
	StrikeGap = 0.1,
	FinalHold = 2.3,
}

-- Tia sét (Beam zigzag)
ForgeAnimationConfig.Lightning = {
	-- Điểm bắt đầu: cao hơn đỉnh vũ khí bao nhiêu stud, lệch ngang ngẫu nhiên tối đa
	SkyHeight = 30,
	SkySpread = 8,
	-- Số đoạn zigzag và độ lệch tối đa mỗi đoạn (stud)
	Segments = 9,
	Jitter = 1.6,
	CoreWidth = 0.3,
	GlowWidth = 1.4,
	GlowTransparency = 0.55,
	CoreWhiteness = 0.65,
	Lifetime = 0.3,
	-- Tia sét xuyên qua vũ khí: đi tiếp xuống dưới đáy vũ khí bao nhiêu stud, số đoạn và độ lệch khi xuyên
	ExitDepth = 2.5,
	PassSegments = 4,
	PassJitter = 0.35,
	-- Cú sét cuối: nhiều tia cùng lúc, to hơn, lâu hơn
	FinalBoltCount = 3,
	FinalWidthMultiplier = 2.2,
	FinalLifetime = 0.7,
	-- Đèn loé tại điểm sét đánh
	ImpactLightRange = 18,
	ImpactLightBrightness = 8,
	-- Mỗi cú sét phát tiếng sấm, chọn ngẫu nhiên trong danh sách
	ThunderSoundIds = AssetIds.Weather.ForgeThunder,
	ThunderVolume = 1,
	-- Cú sét cuối: to hơn, trầm hơn
	FinalThunderVolume = 2.5,
	FinalPlaybackSpeed = 0.75,
	-- Pitch giảm dần theo từng cú sét: tiếng sấm trầm và dài dần, nhịp roll chậm dần lại
	PitchStart = 1.25,
	PitchEnd = 0.9,
}

-- Vũ khí rung khi bị sét đánh: độ mạnh cú thường / cú cuối, độ lệch tối đa (stud, độ),
-- tốc độ tắt dần và tần số rung
ForgeAnimationConfig.WeaponShake = {
	Strike = 1,
	Final = 2.2,
	Position = 0.18,
	Rotation = 7,
	Decay = 8,
	Frequency = 24,
}

-- Flash toàn màn hình và hiệu ứng ánh sáng
ForgeAnimationConfig.ScreenFlash = {
	DisplayOrder = 50,
	-- Độ trong suốt lúc loé (0 = che kín màn hình) và thời gian mờ dần
	StrikeTransparency = 0.6,
	StrikeFadeTime = 0.25,
	FinalTransparency = 0.1,
	FinalFadeTime = 0.9,
	-- Làm tối cảnh trong lúc roll cho sét nổi bật
	DimBrightness = -0.12,
	DimSaturation = -0.35,
	DimTweenTime = 0.6,
	-- Độ sáng loé thêm mỗi cú sét
	StrikeBrightnessKick = 0.08,
	-- Cả cảnh ngả sang màu cấp bậc bao nhiêu khi loé (0 = không, 1 = toàn màu)
	TintStrength = 0.25,
	FinalBrightnessKick = 0.3,
	-- Cú sét cuối: nhoè (Blur) và bloom rồi tắt dần
	FinalBlurSize = 18,
	FinalBloomIntensity = 1.5,
	FinalEffectFadeTime = 0.7,
}

-- Chữ tên cấp bậc phía trên vũ khí (không khung)
ForgeAnimationConfig.RarityLabel = {
	-- Khoảng cách từ đầu vũ khí tới đáy chữ (stud); kích thước vùng chữ tính bằng pixel
	Gap = 0.8,
	WidthPixels = 320,
	HeightPixels = 56,
	StrokeColor = Color3.new(0, 0, 0),
	StrokeThickness = 3,
	-- Lúc roll: chữ nghiêng qua lại (độ, số lần/giây) và rung (pixel)
	TiltAngle = 7,
	TiltFrequency = 1.6,
	ShakePixels = 2.5,
	-- Mỗi cú sét chữ nảy lên rồi về kích thước thường
	PopScale = 1.35,
	PopTime = 0.15,
	-- Cú cuối: phóng to rồi khoá lại ở kích thước lớn hơn
	FinalPopScale = 2,
	FinalScale = 1.3,
	FinalPopTime = 0.45,
}

-- Lửa bùng và tiếng nổ khi bắt đầu
ForgeAnimationConfig.Flare = {
	Lift = 1,
	Color = Color3.fromRGB(255, 140, 50),
	Brightness = 12,
	Range = 20,
	RiseTime = 0.15,
	FadeTime = 1.8,
	-- PLACEHOLDER: tạm dùng âm ForgeBreak, thay ID tiếng nổ thật sau
	Sound = { SoundId = "rbxassetid://9114592102", Volume = 0.9, PlaybackSpeed = 0.7 } :: SoundSpec,
}

-- Vũ khí trồi lên từ giữa nồi
ForgeAnimationConfig.Rise = {
	-- PLACEHOLDER: chờ bao lâu sau khi có kết quả rồi mới trồi lên
	StartDelay = 0.35,
	Duration = 2.4,
	EasingStyle = Enum.EasingStyle.Quint,
	-- Khoảng cách từ mặt nham thạch tới đáy (chuôi) vũ khí khi lơ lửng
	HoverGap = 4,
	-- Tốc độ xoay (radian/giây): nhanh lúc trồi lên, chậm khi lơ lửng
	SpinSpeedStart = 14,
	SpinSpeedHover = 1.2,
	-- Lơ lửng nhấp nhô: biên độ (stud) và tần số (lần/giây)
	BobAmplitude = 0.25,
	BobFrequency = 0.6,
}

-- Bóng đen (silhouette) che màu thật của vũ khí
ForgeAnimationConfig.Silhouette = {
	FillColor = Color3.new(0, 0, 0),
	OutlineColor = Color3.fromRGB(170, 140, 255),
	OutlineTransparency = 0.55,
	-- Khói đen quanh vũ khí: số điểm phát dọc thân, kích thước khói theo chiều dài vũ khí
	SmokePoints = 3,
	SmokeTexture = "rbxasset://textures/particles/smoke_main.dds",
	SmokeColor = Color3.fromRGB(20, 14, 30),
	SmokeRate = 6,
	SmokeLifetime = NumberRange.new(1, 1.6),
	SmokeSpeed = NumberRange.new(0.3, 0.8),
	SmokeSizePerStud = 0.35,
	SmokeTransparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	}),
	SmokeRotSpeed = NumberRange.new(-40, 40),
}

-- Giai đoạn C: đổi hình dạng và kích thước (mỗi lần đổi có flash trắng), chậm dần rồi chốt
ForgeAnimationConfig.ShapeRoll = {
	-- Số lần đổi hình (lần cuối là kết quả thật) và thời gian từ lần đổi đầu tới lần chốt
	SwapCount = 9,
	FirstInterval = 0.16,
	Duration = 3.8,
	-- Hình dạng đổi ngẫu nhiên, kích thước to dần từ x1 tới đúng kích thước server roll
	-- GrowthEasing: kiểu to dần (Linear = đều, Quad/Cubic = chậm lúc đầu, nhanh về cuối)
	GrowthEasing = Enum.EasingStyle.Quad,
	-- Lần đổi hình đầu tiên nhỏ bằng bao nhiêu phần kích thước (để vũ khí nhỏ cũng thấy to dần)
	GrowthStartRatio = 0.4,
	FlashColor = Color3.new(1, 1, 1),
	Shake = 0.25,
	CameraMoveTime = 0.3,
	-- PLACEHOLDER: tạm dùng âm ForgeWheelTick, thay ID thật sau
	Sound = { SoundId = "rbxassetid://9126016225", Volume = 0.8, PlaybackSpeed = 1 } :: SoundSpec,
	PitchStart = 0.9,
	PitchEnd = 1.5,
	-- Bao nhiêu lần đổi hình cuối (trước lần chốt) thì màn hình nháy đen thay vì loé trắng
	BlackFlickerSteps = 3,
}

-- Ánh sáng lấp lánh bay ra từ vũ khí trong lúc roll kích thước
ForgeAnimationConfig.ShapeSparkles = {
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 220, 120)),
	Rate = 35,
	Lifetime = NumberRange.new(0.6, 1.1),
	Speed = NumberRange.new(3, 7),
	Drag = 2,
	-- Kích thước hạt theo chiều dài vũ khí (stud mỗi stud chiều dài), tối thiểu
	SizePerStud = 0.09,
	MinSize = 0.25,
	-- Mỗi lần đổi hình bắn thêm bấy nhiêu hạt
	BurstCount = 18,
	LightEmission = 1,
	ZOffset = 2,
}

-- Màn hình chuyển cảnh lúc chốt kết quả: nháy đen -> đen hẳn -> vòng tròn trắng nở từ tâm -> mờ dần
ForgeAnimationConfig.Blackout = {
	DisplayOrder = 55,
	FlickerTransparency = 0.15,
	FlickerFadeTime = 0.18,
	FadeToBlackTime = 0.25,
	BlackHoldTime = 0.45,
	WhiteColor = Color3.new(1, 1, 1),
	WhiteExpandTime = 0.5,
	WhiteHoldTime = 0.12,
	WhiteFadeTime = 0.8,
	-- Đường kính vòng trắng cuối cùng = đường chéo màn hình x hệ số này
	WhiteOverscan = 1.15,
}

-- Hiệu ứng nổ kiểu mở quà trên màn hình (tia sáng toả ra từ tâm)
ForgeAnimationConfig.ScreenBurst = {
	DisplayOrder = 54,
	RayCount = 16,
	-- Chiều dài tia (tỉ lệ cạnh ngắn màn hình), độ dày (pixel)
	RayLengthScale = 0.9,
	RayThickness = 10,
	Time = 0.7,
	-- Ngôi sao lấp lánh bay ra
	StarCount = 24,
	StarSize = 22,
	StarTravelScale = 0.55,
	StarImage = "rbxasset://textures/particles/sparkles_main.dds",
}

-- Thẻ thông tin vũ khí ở giữa màn hình ngay sau khi lộ màu
ForgeAnimationConfig.InfoCard = {
	DisplayOrder = 56,
	WidthPixels = 560,
	RowHeightPixels = 34,
	TitleHeightMultiplier = 1.8,
	RowGap = 10,
	StrokeColor = Color3.new(0, 0, 0),
	StrokeThickness = 3,
	-- Phóng to bật vào, giữ, rồi phóng to + mờ đi
	PopStartScale = 0.3,
	PopTime = 0.35,
	HoldTime = 2.2,
	HideScale = 1.25,
	HideTime = 0.3,
}

-- Hiệu ứng chốt kết quả: càng hiếm càng lớn (nhân với Magnitude của cấp)
ForgeAnimationConfig.Impact = {
	Magnitude = { Common = 1, Uncommon = 1.1, Rare = 1.2, Epic = 1.5, Legendary = 1.9, Mythic = 2.4 } :: { [string]: number },
	-- Vòng shockwave lan ra mặt phẳng ngang: bán kính = (RingRadius + chiều dài vũ khí x RingRadiusPerStud) x Magnitude
	RingRadius = 10,
	RingRadiusPerStud = 0.6,
	RingThickness = 0.15,
	RingTransparency = 0.15,
	RingTime = 0.7,
	-- Quả cầu năng lượng nở ra quanh vũ khí
	BubbleRadius = 6,
	BubbleTime = 0.5,
	-- Cột sáng bắn lên trời
	PillarHeight = 160,
	PillarWidth = 2.5,
	PillarRiseTime = 0.12,
	PillarHoldTime = 0.5,
	PillarFadeTime = 0.9,
	PillarTransparency = 0.25,
	-- Particle bung ra
	BurstCount = 40,
	BurstTexture = "rbxasset://textures/particles/sparkles_main.dds",
	BurstSpeed = NumberRange.new(18, 40),
	BurstLifetime = NumberRange.new(0.6, 1.2),
	BurstSize = 0.8,
	BurstDrag = 3,
	-- Đèn loé
	LightBrightness = 10,
	LightRange = 30,
	LightFadeTime = 0.9,
	-- Camera giật FOV và rung
	FovPunch = 8,
	Shake = 1.2,
	-- Thời gian chờ sau khi nổ trước khi sang outro
	SettleTime = 0.7,
	-- PLACEHOLDER: tạm dùng âm ForgeGreatSuccess, thay ID tiếng "chốt" nặng sau
	Sound = { SoundId = "rbxassetid://71491555548135", Volume = 1, PlaybackSpeed = 0.85 } :: SoundSpec,
}

-- Vỏ đen vỡ ra khi chốt
ForgeAnimationConfig.Shatter = {
	ShardCount = 16,
	-- Kích thước mảnh và quãng bay tính theo chiều dài vũ khí
	ShardSizePerStud = 0.12,
	ShardTravelPerStud = 0.9,
	ShardLifetime = 0.8,
	ShardColor = Color3.new(0, 0, 0),
	-- Bóng đen mờ đi để lộ màu thật
	RevealTime = 0.25,
}

-- Giai đoạn D: outro
ForgeAnimationConfig.Outro = {
	-- Tự đóng sau bao lâu nếu người chơi không bấm (giây)
	AutoCloseTime = 6,
	-- Vũ khí thu nhỏ và bay vào nút Kho đồ trên HUD
	HudGuiName = "HudGui",
	InventoryButtonName = "InventoryButton",
	FlyTime = 0.7,
	FlyEndScale = 0.05,
	-- Điểm đích nằm trước camera bao nhiêu stud (theo hướng nút Kho đồ)
	FlyDepth = 6,
	FlyEasingStyle = Enum.EasingStyle.Quad,
	-- PLACEHOLDER: tạm dùng âm UiOpen, thay ID tiếng "vào kho" sau
	FlySound = { SoundId = "rbxassetid://102089708414322", Volume = 0.7, PlaybackSpeed = 1 } :: SoundSpec,
}

-- Hào quang màu cấp bậc quanh vũ khí sau khi lộ màu
ForgeAnimationConfig.Aura = {
	Points = 3,
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Rate = 10,
	Lifetime = NumberRange.new(0.8, 1.4),
	Speed = NumberRange.new(0.5, 1.5),
	SizePerStud = 0.12,
	LightEmission = 1,
	-- Viền sáng quanh vũ khí
	OutlineTransparency = 0.35,
	LightBrightness = 3,
	LightRange = 14,
}

-- Bảng kết quả phía trên vũ khí: Cấp bậc -> Tên -> Cân nặng -> Giá (từ trên xuống)
ForgeAnimationConfig.ResultLabel = {
	-- Khoảng cách từ đầu vũ khí tới đáy bảng (stud); kích thước bảng tính bằng pixel (không đổi theo khoảng cách)
	Gap = 0.8,
	WidthPixels = 420,
	RowHeightPixels = 34,
	StrokeColor = Color3.new(0, 0, 0),
	StrokeThickness = 3,
	-- Dòng đầu (cấp bậc) to hơn các dòng khác
	TitleHeightMultiplier = 1.4,
	-- Mỗi dòng hiện cách nhau bao lâu, tween trong bao lâu, trượt lên từ dưới bao nhiêu (tỉ lệ chiều cao dòng)
	RowDelay = 0.25,
	RowTweenTime = 0.35,
	SlideOffset = 0.6,
	FadeOutTime = 0.2,
	-- Camera chừa chỗ phía trên cho bảng: nhìn cao hơn tâm vũ khí (tỉ lệ chiều dài vũ khí) và lùi xa thêm
	CameraMoveTime = 0.6,
	FocusLift = 0.35,
	Pullback = 1.3,
}

-- Nút Back ở giữa cạnh dưới màn hình (bấm nút hoặc bấm bất kỳ đâu để đóng)
ForgeAnimationConfig.BackButton = {
	DisplayOrder = 60,
	Size = UDim2.fromOffset(180, 56),
	BottomMargin = 40,
	Color = Color3.fromRGB(235, 70, 70),
	TextColor = Color3.new(1, 1, 1),
	StrokeColor = Color3.new(0, 0, 0),
	StrokeThickness = 3,
	CornerRadius = UDim.new(0, 12),
	TextPadding = 12,
}

return ForgeAnimationConfig
