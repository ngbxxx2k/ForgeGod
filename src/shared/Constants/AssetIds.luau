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
	-- Tab "Weapon" của Backpack; cũng là ảnh vũ khí mẫu trong BackpackMockData và IndexMockData
	TabWeapon = asset(83946172746491),
	-- Tab "Ore" của Backpack và danh mục Ore trong Shop
	TabOre = asset(83336810328534),
	-- Tab "Buff" của Backpack và danh mục Item trong Shop
	TabBuff = asset(122050066941039),
	-- Icon vật phẩm buff (dùng chung Shop, Backpack, thanh buff)
	BlessingPotion = asset(100313368188317),
	LuckPotion = asset(122050066941039),
	MerchantPotion = asset(92194121586622),
	MutationCatalyst = asset(117694636364132),
	MutationEraser = asset(85748149860580),
	-- Icon nồi nấu quặng (hiện ở bảng/prompt của OreCrucible)
	OreCrucible = asset(84035766699621),
	-- Icon ngôi nhà: hiện trên plot của chính người chơi thay cho avatar
	Home = asset(104508028871785),
}

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
		asset(9120016241),
		asset(9120016037),
		asset(9120016256),
	},
	-- Tiếng nổ plasma, chọn ngẫu nhiên mỗi lần sét plasma
	PlasmaZap = {
		asset(9116274415),
		asset(9116274992),
	},
}

return AssetIds
