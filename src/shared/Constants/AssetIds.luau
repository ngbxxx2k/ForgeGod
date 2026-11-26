--!strict

local PREFIX = "rbxassetid://"

local function asset(id: number): string
	return PREFIX .. tostring(id)
end

local AssetIds = {}

-- Icon giao diện (ImageLabel/ImageButton). Muốn đổi ảnh: upload ảnh mới, thay số trong asset(...)
AssetIds.Icons = {
	-- Icon ổ khóa: mục chưa mở khóa (Index, vũ khí bị khóa)
	Locked = asset(116170804854928),
	-- Icon ổ khóa mở: mục đã mở khóa
	Unlocked = asset(137807970911103),
	-- Tab "Weapon" của Backpack; cũng là ảnh vũ khí mẫu trong BackpackMockData
	TabWeapon = asset(83946172746491),
	-- Tab "Ore" của Backpack và danh mục Ore trong Shop
	TabOre = asset(83336810328534),
	-- Tab "Buff" của Backpack và danh mục Item trong Shop
	TabBuff = asset(122050066941039),
	-- Icon vật phẩm buff (dùng chung Shop, Backpack, thanh buff)
	BlessingPotion = asset(100313368188317),
	LuckPotion = asset(122050066941039),
	MutationCatalyst = asset(117694636364132),
	MutationEraser = asset(85748149860580),
	Talisman = asset(137887222437114),
	AngelHeart = asset(74287936778624),
	AlloyFluxPotion = asset(113388677230192),
	StormPotion = asset(71642826688601),
	-- Icon nồi nấu quặng (hiện ở bảng/prompt của OreCrucible)
	OreCrucible = asset(84035766699621),
	-- Icon ngôi nhà: hiện trên plot của chính người chơi thay cho avatar
	Home = asset(104508028871785),
	-- Icon mũi tên tím: nút Upgrades trên HUD (thay nút Ore Shop cũ)
	UpgradeShop = asset(134494624970689),
	-- Icon xẻng: bảng nổi phía trên bãi cát dò quặng ở Hub
	DigSite = asset(99042413700948),
	-- Icon đồng tiền (HUD CoinsDisplay): gói tiền trong Shop nạp, pass x2 Money, ô tiền của vòng quay
	Coin = asset(122325887881962),
	-- Icon nút Shop trên HUD và tiêu đề Shop nạp
	PremiumShop = asset(104483798665649),
	-- Icon nút Spin trên HUD (thay Daily), tiêu đề vòng quay, ô +1 Spin
	SpinWheel = asset(88471574444989),
	-- PLACEHOLDER: icon hộp quà (nút Gift trong Shop nạp, tiêu đề Gift Player); để "" thì hiện emoji 🎁
	Gift = "",
	-- Icon Robux cạnh giá (ảnh có sẵn của Roblox)
	Robux = "rbxasset://textures/ui/common/robux.png",
}

-- Icon từng loại mutation (nguồn SVG/PNG ở blender/Icons/Mutations); icon thời tiết trên thanh trạng thái dùng icon mutation của thời tiết đó
AssetIds.Mutations = {
	Molten = asset(94352777842157),
	Aqua = asset(115331808563539),
	Thunder = asset(128877372640375),
	Aurora = asset(105744258940949),
	Radioactive = asset(108130193265926),
	Shadow = asset(97652349632861),
	Plasma = asset(99258059855144),
} :: { [string]: string }

-- Texture dùng cho hiệu ứng và nền UI
AssetIds.Textures = {
	-- Hoa văn chấm studs phủ lên HUD (StudsPattern)
	Studs = asset(6927295847),
	-- Ô caro + chấm studs của mặt đất, phủ lên đĩa vòng tròn shop (ShopZoneRing)
	GroundStuds = asset(127973933055248),
	-- Dải cầu vồng dán lên vũ khí khi Frenzy (ForgeFrenzyFx), bản ngang
	FrenzyBandHorizontal = asset(127769054059579),
	-- Dải cầu vồng dán lên vũ khí khi Frenzy, bản dọc
	FrenzyBandVertical = asset(119192023066187),
}

-- Hướng dẫn người chơi mới (nguồn SVG ở blender/Icons/Tutorial/make.js)
AssetIds.Tutorial = {
	-- Mũi tên chevron chỉ đường dưới đất (texture của Beam, ảnh mũi nhọn hướng lên)
	Chevron = asset(123603137254546),
	-- Bàn tay chỉ vào nút cần bấm
	Hand = asset(127910171298093),
	-- Dấu tick xanh khi hoàn thành hướng dẫn
	Check = asset(103499708896615),
}

-- Mọi thứ của nồi nấu quặng OreCrucible
AssetIds.OreCrucible = {
	-- Animation theo trạng thái nồi (ID của animation đã publish từ Blender)
	Animations = {
		-- Trạng thái chờ
		Idle = asset(131635666369358),
		-- Trạng thái đang nấu
		Active = asset(112225746301732),
		-- Trạng thái đầy/tối đa
		Max = asset(82410527096972),
	},
	-- Bộ texture PBR của thân nồi (SurfaceAppearance)
	SurfaceMaps = {
		-- Màu nền
		ColorMap = asset(80822439114862),
		-- Độ nổi bề mặt
		NormalMap = asset(125715622521299),
		-- Độ nhám
		RoughnessMap = asset(128672398612948),
		-- Độ kim loại
		MetalnessMap = asset(86737336686091),
	},
	-- Texture cho hạt (ParticleEmitter) và hiệu ứng lòng nồi
	Particles = {
		-- Tàn lửa
		Ember = asset(127621519375653),
		-- Tia lửa bắn ra
		Spark = asset(77331934147232),
		-- Giọt kim loại nóng chảy
		Droplet = asset(140703959410794),
		-- Bong bóng trên mặt dung nham
		Bubble = asset(123982128171892),
		-- Khói
		Smoke = asset(94679649458968),
		-- Ngọn lửa
		Fire = asset(123496354055482),
		-- Vệt đuôi (Trail)
		Trail = asset(127034540395197),
		-- Đường gân dung nham trên mặt lava
		LavaVeins = asset(116441582617631),
		-- Vết nứt phát sáng dưới sàn quanh nồi
		FloorCracks = asset(107434069996136),
	},
}

AssetIds.Ores = {
	BaseModel = asset(85207022749948),
	DarkMoonstoneModel = asset(70514917149728),
	MithrilModel = asset(134900378441258),
	GodsCoreModel = asset(130905576282102),
	Icons = {
		Copper = asset(132527332552444),
		Iron = asset(134746757900808),
		Silver = asset(119359807363991),
		Gold = asset(108421017307120),
		Platinum = asset(117608380513509),
		Emerald = asset(140013879678679),
		DarkMoonstone = asset(110153512947817),
		Mithril = asset(83963392826556),
		GodsCore = asset(93536895109713),
	},
}

AssetIds.DigTools = {
	MetalDetectorModel = asset(70994051491113),
	ShovelModel = asset(108821739656146),
}

-- Âm thanh của bãi đào quặng
AssetIds.DigSounds = {
	-- Tiếng xẻng đào, phát một lần suốt lượt đào
	Scoop = asset(111542693009881),
	-- Tiếng nhặt được quặng khi popup quặng hiện ra
	OreFound = asset(110080249267849),
	-- Tiếng máy dò kim loại, lặp khi có tín hiệu
	DetectorLoop = asset(117020699480793),
}

-- Âm thanh và texture của hiệu ứng thời tiết (WeatherFx)
AssetIds.Weather = {
	-- Tiếng mưa lặp nền
	RainLoop = asset(9112854469),
	-- Tiếng mưa to bắn tung toé (HeavyRain)
	HeavyRainLoop = asset(9112876474),
	-- Tiếng lửa cháy âm ỉ (Heatwave)
	HeatFireLoop = asset(9112887827),
	-- Nhạc nền huyền ảo (Aurora)
	AuroraLoop = asset(9113948291),
	-- Máy đo phóng xạ kêu lách tách (Radiation)
	GeigerLoop = asset(17541330396),
	-- Tiếng ù u ám (Radiation, LunarEclipse)
	EerieLoop = asset(9112775414),
	-- Gió rít ma quái (LunarEclipse)
	GhostWindLoop = asset(9114574159),
	-- Gió plasma vù vù (PlasmaStorm)
	PlasmaWindLoop = asset(9125742262),
	-- Tiếng điện rè (PlasmaStorm)
	ElectricHumLoop = asset(9112889325),
	-- Texture vệt mưa (ảnh dọc trắng mờ dần 2 đầu)
	RainStreak = asset(75740657807834),
	-- Texture dải sáng mờ 2 mép, phủ lên tia sét (WeatherBolt)
	BoltGlow = asset(86460555918100),
	-- Vệt sáng nằm ngang, dùng cho hạt bay theo hướng chuyển động (tia plasma)
	PlasmaStreak = asset(98595886783024),
	-- Đốm sáng tròn mềm: tàn lửa, đốm cực quang, bụi phóng xạ, tia nước
	SoftDot = asset(131293999139327),
	-- Đám khói mềm: sương bò sát đất, hơi nóng
	SmokeBlob = asset(73967202470594),
	-- Dải cực quang có tia dọc (WeatherAurora)
	AuroraCurtain = asset(74613724410058),
	-- Viền tối quanh màn hình (WeatherVignette)
	Vignette = asset(129370407444162),
	-- Mặt trăng đỏ máu (LunarEclipse)
	BloodMoon = asset(76814410333688),
	-- Các tiếng sấm, chọn ngẫu nhiên mỗi lần sét
	Thunder = {
		asset(85024183902564),
	},
	-- Tiếng sấm khi nấu quặng (reveal) và khi rèn ra mutation
	ForgeThunder = {
		asset(85024183902564),
	},
	-- Tiếng nổ plasma, chọn ngẫu nhiên mỗi lần sét plasma
	PlasmaZap = {
		asset(9116274415),
		asset(9116274992),
	},
}

AssetIds.ForgeUpgradeTextures = {
	Anvil = {
		Default = asset(129994269657982),
		Silver = asset(114846749886068),
		Gold = asset(94051511793819),
		Platinum = asset(121370023236992),
		Emerald = asset(70701419553010),
		DarkMoonstone = asset(123965059556990),
		Mithril = asset(97955729014350),
	},
	Hammer = {
		Default = asset(96109438688114),
		Silver = asset(137759292981200),
		Gold = asset(83293152848192),
		Platinum = asset(111462999518806),
		Emerald = asset(114361393320988),
		DarkMoonstone = asset(75127232027178),
		Mithril = asset(138777134766431),
	},
} :: { [string]: { [string]: string } }

AssetIds.Music = {
	asset(114640467716097),
	asset(78783089033746),
	asset(131814178857335),
}

return AssetIds
