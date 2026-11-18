# OreCrucible – Đưa vào Roblox (Bước 13 → 17)

Tất cả file nằm trong `blender/OreCrucible/`:

| Thư mục | File |
|---|---|
| `Models/` | `OreCrucible_Model.fbx` (mesh + rig, texture nhúng sẵn), 4 texture `T_OreCrucible_*.png` |
| `Animations/` | `OreCrucible_Idle.fbx`, `OreCrucible_Active.fbx`, `OreCrucible_Max.fbx` |
| `VFX_Textures/` | 9 texture hiệu ứng (đã upload, ID nằm sẵn trong config) |
| `SFX/` | 5 file `.ogg` + `generate_sfx.py` (công thức tạo âm) + `raw/*.wav` |
| `Preview/` | Video `*_VFX_SFX.mp4` (có tiếng), ảnh so sánh concept |
| `Icon/` | `OreCrucible_Icon.png` (đã upload: `rbxassetid://128457679985428`) |

---

## Bước 13 – Import model và dựng cấu trúc

1. Studio → tab **Home** → **Import 3D** → chọn `Models/OreCrucible_Model.fbx`.
2. Trong cửa sổ 3D Importer:
   - **Rig General → Rig Type**: `Custom` (không phải R15).
   - **File Dimensions → Scale Unit**: `Stud` (file đã xuất 1 đơn vị = 1 stud). Kiểm tra kích thước hiện ra khoảng **7.8 × 3.6 × 7.7 studs**. Nếu ra 100 lần to/nhỏ thì đổi Scale Unit cho đúng.
   - **Geometry → Anchored**: bật.
   - **Insert Location**: vị trí bạn muốn đặt nồi.
   - Bấm **Import**.
3. Kiểm tra trong Explorer có đủ Bone (`Root`, `Lava`, `VFX_*`) bên trong MeshPart.
4. Đổi tên Model gốc thành `OreCrucible`.
5. Mở **View → Command Bar**, chọn Model `OreCrucible` trong Explorer, rồi dán đoạn sau và Enter. Đoạn này tự làm phần cấu hình: Anchored, CanCollide, Neon, SurfaceAppearance, AnimationController, Tag.

```lua
local m = game:GetService("Selection"):Get()[1]
assert(m and m:IsA("Model"), "Hay chon Model OreCrucible truoc")
local glow = { Lava_Glow = "E8600C", Rune_Glow = "B8701A", Vent_Glow = "B03A0C" }
for _, p in m:GetDescendants() do
	if p:IsA("BasePart") then
		p.Anchored = true
		p.CanCollide = p.Name == "Crucible"
		p.CastShadow = p.Name == "Crucible"
		if glow[p.Name] then
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromHex(glow[p.Name])
		end
	end
end
local body = m:FindFirstChild("Crucible", true)
local sa = body:FindFirstChildWhichIsA("SurfaceAppearance") or Instance.new("SurfaceAppearance")
sa.ColorMap = "rbxassetid://105707820141450"
sa.NormalMap = "rbxassetid://111947881787911"
sa.RoughnessMap = "rbxassetid://109315329716509"
sa.MetalnessMap = "rbxassetid://87111297477456"
sa.Parent = body
m.PrimaryPart = body
local ac = m:FindFirstChildWhichIsA("AnimationController") or Instance.new("AnimationController")
ac.Parent = m
if not ac:FindFirstChildWhichIsA("Animator") then Instance.new("Animator").Parent = ac end
game:GetService("CollectionService"):AddTag(m, "OreCrucible")
print("OreCrucible setup xong")
```

### Cây Explorer hoàn chỉnh

```
Workspace
└─ OreCrucible (Model, PrimaryPart = Crucible, Tag "OreCrucible")
   ├─ Crucible (MeshPart, Anchored, CanCollide)
   │  ├─ SurfaceAppearance (Color/Normal/Roughness/Metalness)
   │  └─ Root (Bone)
   │     ├─ Lava (Bone)
   │     │  └─ VFX_Lava (Bone)
   │     ├─ VFX_Top (Bone)
   │     ├─ VFX_Grate (Bone)
   │     ├─ VFX_BackVent (Bone)
   │     └─ VFX_Base (Bone)
   ├─ Lava_Glow (MeshPart, Neon, CanCollide = false)
   ├─ Rune_Glow (MeshPart, Neon, CanCollide = false)
   ├─ Vent_Glow (MeshPart, Neon, CanCollide = false)
   └─ AnimationController
      └─ Animator
```

Ghi chú: 3D Importer có thể đặt Bone dưới MeshPart khác hoặc thêm một Part gốc tên `ItemRig`. Không sao: script tìm theo tên trong toàn bộ Model. Lúc chạy game, script tạo thêm một Folder `OreCrucibleRuntime` (hạt, đèn, vết nứt nền, vòng lửa). Folder này tự xoá khi model bị xoá.

---

### Đã chỉnh trực tiếp trong Studio (2026-11-19)

- 3D Importer **bỏ mất 5 bone `VFX_*`** (vì không gắn với mesh nào). Đã dựng lại từ `InitialPoses/*_Original`, đúng vị trí gốc.
- Model đổi tên thành `OreCrucible`, có tag `OreCrucible`, `PrimaryPart = RootPart`. Mọi part đều Anchored. Chỉ `Crucible` có va chạm (Hull). Các phần `_Glow` là Neon.
- Dời nồi tới **(−22, 0, −19)**: trước đó nồi lơ lửng 2.2 studs và chồng lên lò và đe. Mặt trước (song sắt, rune W) quay về phía điểm spawn.
- `SurfaceAppearance.Color` = (150, 140, 150) để đá tối như concept dưới ánh sáng hồng của map.
- Màu Neon, đèn và `LightEmission` của hạt đã chỉnh cho hợp trời sáng (giá trị nằm trong config).
- Animation chưa publish: script **trong Studio** tự lấy 3 KeyframeSequence trong `ReplicatedStorage.OreCrucibleKeyframes` để xem thử. Ngoài game thật, đoạn này không chạy. Sau khi publish và điền ID vào config, xoá folder `OreCrucibleKeyframes` đi.
- Animation đã publish: Idle `117359623468463`, Active `83981730592817`, Max `82994463595831` (đã điền vào config, đã xoá folder `OreCrucibleKeyframes`). `84072870759884` là bản Max trùng lặp, không dùng.
- **Nhớ lưu place** (Ctrl+S / File → Save to Roblox) để giữ các chỉnh sửa trên.

## Bước 14 – Import animation

1. Chọn Model `OreCrucible` → tab **Avatar** → **Animation Editor**.
2. Bảng Animation Editor → nút **…** → **Import → From FBX Animation** → chọn `Animations/OreCrucible_Idle.fbx`.
3. Bật nút **Loop** (biểu tượng vòng tròn mũi tên).
4. **… → Publish to Roblox** → đặt tên `OreCrucible_Idle` → Submit → copy **Animation ID**.
5. Làm lại với `OreCrucible_Active.fbx` và `OreCrucible_Max.fbx` (cả hai đều bật Loop).
6. Dán 3 ID vào `src/shared/Config/OreCrucibleConfig.luau`:

```lua
OreCrucibleConfig.AnimationIds = {
	Idle = "rbxassetid://ID_IDLE",
	Active = "rbxassetid://ID_ACTIVE",
	Max = "rbxassetid://ID_MAX",
}
```

**Quan trọng:** animation phải được publish bởi **cùng chủ sở hữu với game** (tài khoản `baobt1345`, hoặc cùng group nếu game thuộc group). Khác chủ thì animation không chạy. ID phải có tiền tố `rbxassetid://`, chỉ ghi số thì sẽ không tải được.

---

## Bước 15 – Upload âm thanh (ảnh đã upload sẵn)

**Ảnh:** đã upload xong 14 ảnh lên tài khoản `baobt1345`, ID đã điền sẵn trong config:

| Ảnh | Asset ID |
|---|---|
| T_VFX_Ember | rbxassetid://105087483312654 |
| T_VFX_Spark | rbxassetid://135622153420206 |
| T_VFX_Droplet | rbxassetid://137027728844221 |
| T_VFX_Bubble | rbxassetid://85075524619434 |
| T_VFX_Smoke_4x4 | rbxassetid://92861015773380 |
| T_VFX_Fire_4x4 | rbxassetid://113735401677355 |
| T_VFX_Trail | rbxassetid://127170178415103 |
| T_VFX_LavaVeins | rbxassetid://117046629968845 |
| T_FloorCracks | rbxassetid://130112349730731 |
| OreCrucible_Icon | rbxassetid://128457679985428 |
| T_OreCrucible_Color | rbxassetid://105707820141450 |
| T_OreCrucible_Normal | rbxassetid://111947881787911 |
| T_OreCrucible_Roughness | rbxassetid://109315329716509 |
| T_OreCrucible_Metalness | rbxassetid://87111297477456 |

**Âm thanh (bạn tự upload):**
1. Studio → **View → Asset Manager** → **Bulk Import** (hoặc Creator Hub → Development Items → Audio → Upload).
2. Chọn 5 file trong `SFX/`: `SFX_Idle_Loop.ogg`, `SFX_Active_Start.ogg`, `SFX_Active_Loop.ogg`, `SFX_Max_Burst.ogg`, `SFX_Max_Loop.ogg`.
3. Chờ Roblox kiểm duyệt. Âm thanh có thể mất vài phút đến vài giờ mới dùng được. Upload bằng cùng tài khoản với game để game có quyền dùng.
4. Chuột phải từng file → **Copy Asset ID** → dán vào `OreCrucibleConfig.Sounds`, trường `Id`:

```lua
{ Key = "IdleLoop", Id = "rbxassetid://...", ... },
```

Khi ID còn trống, script vẫn chạy bình thường (chỉ không có tiếng) và in một cảnh báo duy nhất trong Output.

---

## Bước 16 – Script (đã viết và nối vào Bootstrap)

| File (Rojo) | Loại | Vị trí trong Studio | Vai trò |
|---|---|---|---|
| `src/shared/Config/OreCrucibleConfig.luau` | ModuleScript | ReplicatedStorage.Shared.Config | **Bảng cấu hình duy nhất**: ID, thời gian chu kỳ, fadeTime, số hạt, màu, đèn, âm lượng, khoảng cách nghe/tắt |
| `src/server/Systems/OreCrucibleSystem.luau` | ModuleScript | ServerScriptService.Server.Systems | Server tính trạng thái theo đồng hồ thật `os.time()`: Idle 20 s → Active 8 s → Max 4 s → lặp. Đặt Attribute `ItemState` lên mọi Model có tag. Mọi server cùng nhịp. |
| `src/client/Effects/OreCrucibleFx.luau` | ModuleScript | StarterPlayerScripts.Client.Effects | Gắn vào mọi Model có tag `OreCrucible`, nghe `ItemState`, gọi 3 phần bên dưới cùng lúc (SetState), tắt hiệu ứng khi camera ở xa hơn 160 studs |
| `src/client/Effects/OreCrucibleRig.luau` | ModuleScript | (như trên) | Tìm part/bone, load 3 animation track **một lần**, đổi trạng thái bằng fadeTime (Idle 2.5 s, Active 1.2 s, Max 0.6 s) |
| `src/client/Effects/OreCrucibleEmitters.luau` | ModuleScript | (như trên) | 10 ParticleEmitter liên tục + 4 emitter bùng nổ (Emit một lần khi vào Max), 2 PointLight nhấp nháy, màu Neon đổi mượt, vết nứt nền (Decal), 2 vòng lửa xoáy (Trail) |
| `src/client/Effects/OreCrucibleSounds.luau` | ModuleScript | (như trên) | 3 âm lặp chạy song song, chuyển qua lại bằng nội suy âm lượng (không cắt ngang); 2 âm một lần phát khi vào Active và Max. Sound đặt tại điểm VFX nên có hướng và nhỏ dần theo khoảng cách (10 → 80 studs) |

`Bootstrap.server.luau` và `Bootstrap.client.luau` đã có thêm dòng `require` và `Init()`.

**Cách hoạt động để người chơi khác cũng thấy và nghe:** server chỉ đặt Attribute `ItemState`; Attribute tự đồng bộ tới mọi client. Mỗi client tự chạy animation, VFX và SFX cho trạng thái đó. Không cần RemoteEvent, vì không có input nào từ người chơi.

**Ghi chú về comment:** quy tắc dự án (`.clinerules/01-overview.md`) cấm viết comment trong code, nên phần giải thích nằm ở bảng trên thay vì chú thích trong file.

**Đã kiểm tra trong Studio** (bằng model thử, sau đó đã xoá):
- 8 file biên dịch không lỗi.
- Chu kỳ đúng: 32 s gồm 20 Idle / 8 Active / 4 Max.
- Ở Max: 10 emitter bật đúng số hạt, đèn 4.8 / 23.7, vết nứt hiện, lava đổi màu.
- Gỡ tag → dọn sạch 100% đối tượng runtime; gắn lại → tạo lại đủ.

**Hiệu năng:**
- Tổng số hạt ở Max khoảng 200 hạt sống cùng lúc. Có thể giảm Rate trong config.
- Ngoài 160 studs: tắt hết hạt, đèn, âm lặp và animation.
- Mọi Instance runtime có `Archivable = false`; mọi kết nối được ngắt khi model bị xoá hoặc gỡ tag.

---

## Bước 17 – Kiểm tra

### Các bước test
1. **Play**: đứng gần nồi, xem 3 trạng thái tự đổi. Thử nhanh bằng cách tạm sửa `Cycle` trong config thành 5/5/5 giây.
2. **Idle**: lava thấp trong lòng nồi, sủi bọt, khói xám mảnh, ít tàn lửa, rune vàng tối.
3. **Active**: lava dâng, lửa cam, giọt lava bắn, khói ánh cam, vết nứt nền hiện mờ, rune sáng.
4. **Max**: lava trào sát miệng, cột lửa lớn, 2 vòng lửa xoáy, nổ bùng một lần khi vừa vào, vết nứt sáng rõ.
5. So với video `Preview/*_VFX_SFX.mp4`.
6. Đổi trạng thái phải mượt: lava dâng hạ từ từ, màu và đèn chuyển dần, âm lặp chuyển dần. Âm lặp không được có tiếng "tách" ở điểm nối.
7. **Test → Clients and Servers → 2 Players**: cả hai người thấy cùng trạng thái cùng lúc, nghe tiếng có hướng. Đi xa thì tiếng nhỏ dần; quá 160 studs thì hiệu ứng tắt.
8. Output không có lỗi đỏ. Cảnh báo "ids are empty" chỉ xuất hiện khi chưa điền ID.

### Bảng lỗi thường gặp

| Hiện tượng | Nguyên nhân / cách sửa |
|---|---|
| Nồi rơi xuyên sàn / bay lung tung | Chưa Anchored. Chạy lại đoạn lệnh Command Bar ở Bước 13. |
| To/nhỏ sai tỉ lệ (100 lần) | Sai Scale Unit khi import. Import lại với `Stud`. |
| Import mất bone | Rig Type phải là `Custom`; đảm bảo import đúng file `OreCrucible_Model.fbx` (không phải file animation). |
| Bộ phận bị méo khi chạy animation | Không xảy ra với file này (mỗi đỉnh 1 bone, trọng số 1.0). Nếu thấy, import lại model. |
| Animation không chạy | ID trống, thiếu `rbxassetid://`, chưa publish, khác chủ sở hữu, thiếu Animator, tên bone bị đổi. |
| Animation giật khi lặp | Quên bật Loop khi publish. Script cũng ép `Looped = true`. |
| Lava không dâng/hạ | Animation chưa có ID; hoặc bone `Lava` không còn là cha của `VFX_Lava`. |
| Bộ phận xoay sai tâm | Không áp dụng: chỉ bone `Lava` chuyển động, tâm (0, 2.7, 0). |
| VFX không hiện | Model thiếu tag `OreCrucible`; sai tên part/bone; camera xa hơn 160 studs; ảnh còn chờ kiểm duyệt. |
| Flipbook hiện cả lưới 4×4 | `FlipbookLayout` phải là `Grid4x4` (đã đặt trong config). Đừng đổi texture sang ảnh không phải lưới. |
| VFX lệch chỗ | Bone bị di chuyển trong Studio; đừng kéo bone bằng tay. |
| Âm thanh không nghe | ID trống, âm chưa duyệt, upload bằng tài khoản khác, Volume = 0, đứng xa hơn 80 studs. |
| Âm lệch thời gian | Âm một lần phát đúng lúc server đổi Attribute. Độ trễ mạng khoảng 0.1–0.3 s là bình thường. |
| Icon không hiện | Đây là vật trang trí, không có hotbar. Icon dùng cho UI/Index nếu cần: `rbxassetid://128457679985428`. |
| Người chơi khác không thấy | Script client không chạy (kiểm tra Bootstrap); model phải nằm trong Workspace. |

---

## Bảng 1 – Bộ phận chuyển động (bản cuối)

| Bone / Mesh | Tâm (so với Root) | Trục | Kiểu | Idle | Active | Max | Tốc độ |
|---|---|---|---|---|---|---|---|
| `Lava` / `Lava_Glow` | (0, 2.7, 0) | Trượt dọc + nghiêng nhẹ | Mực lava | mức 2.45 ±0.02, nghiêng 0.6° | mức 2.60 ±0.035, nghiêng 1° | mức 2.74 ±0.03, nghiêng 0.5°, rung | 4 s / 2 s / 1 s mỗi vòng |
| `Root` / phần còn lại | (0, 0, 0) | — | Đứng yên | — | — | — | — |

## Bảng 2 – Điểm VFX (bản cuối)

| Điểm | Gắn vào | Vị trí (Blender, so với Root) | Hiệu ứng | Texture | Idle / Active / Max |
|---|---|---|---|---|---|
| `VFX_Lava` | bone `Lava` (đi theo mực lava) | (0, 0, 2.7) | Bubbles, LavaVeins, Embers, Sparks, Droplets, Flames, FlamePillar, Smoke, đèn LavaLight, nổ Burst | Bubble, LavaVeins, Ember, Spark, Droplet, Fire 4×4, Smoke 4×4 | Rate: bọt 6/14/24, vân 1.2/2/3, tàn 5/18/40, tia 0/6/14, giọt 0/7/16, lửa 0/14/34, cột lửa 0/0/26, khói 3/6/11. Đèn 1.6/3/5, Range 14/18/24 |
| `VFX_Top` | `Root` | (0, 0, 3.4) | 2 vòng lửa xoáy (Trail), âm Max | Trail | Chỉ bật ở Max; bán kính 4.2 / 4.9, tốc độ 2.8 / −2.2 rad/s |
| `VFX_Grate` | `Root` | (0, −2.62, 1.1) | GrateFlames, GrateLight | Fire 4×4 | Rate 3/9/16, đèn 0.6/1.2/2 |
| `VFX_BackVent` | `Root` | (0, 2.7, 0.72) | VentEmbers | Ember | Rate 1/4/8 |
| `VFX_Base` | `Root` | (0, 0, 0.03) | Vết nứt nền (Decal 13×13) | FloorCracks | Transparency 1 / 0.5 / 0.1 |

Màu Neon: Lava `#E8600C` / `#FB8210` / `#FFA02A`; Rune `#B8701A` / `#FDD32B` / `#FFF08A`; Vent `#B03A0C` / `#F25A0A` / `#FF8A2A`.

## Bảng 3 – Âm thanh (bản cuối)

| File | Lặp | Điểm phát | Độ dài | Đỉnh | Volume Roblox |
|---|---|---|---|---|---|
| SFX_Idle_Loop.ogg | Có | VFX_Lava | 4.000 s | −1.0 dBFS | 0.35 |
| SFX_Active_Start.ogg | Không | VFX_Lava | 1.200 s | −1.0 dBFS | 0.6 |
| SFX_Active_Loop.ogg | Có | VFX_Lava | 4.000 s | −1.0 dBFS | 0.55 |
| SFX_Max_Burst.ogg | Không | VFX_Top | 2.500 s | −0.9 dBFS | 0.9 |
| SFX_Max_Loop.ogg | Có | VFX_Top | 4.000 s | −1.1 dBFS | 0.8 |

Nguồn: tự tạo bằng Python (`SFX/generate_sfx.py`), không dùng âm có bản quyền. Định dạng mono, 44.1 kHz, Vorbis 128 kbps, không bị rè. Điểm nối vòng lặp nhỏ hơn bước trung bình giữa hai mẫu, nên không có tiếng "tách".

## Thiết lập xuất FBX (để làm lại)

- **Scene Unit Scale = 0.01** khi xuất (1 đơn vị Blender = 1 stud), Apply Unit = bật, Scale = 1.0, Apply Scalings = FBX Units Scale None.
- Forward = **−Z**, Up = **Y**. Add Leaf Bones = **tắt**. Primary Bone Axis = Y, Secondary = X.
- **Model:** Selected Objects (ItemRig + 4 mesh), Armature ở tư thế Rest, mesh được chia tam giác lúc xuất, Path Mode = Copy + Embed Textures, không Bake Animation.
- **Animation:** chỉ ItemRig, Bake Animation = bật, All Bones, không NLA, không All Actions, Simplify = 0, Step = 1. Trước khi xuất, thêm key tư thế gốc ở frame 1000 và đặt frame hiện tại = 1000, để FBX ghi tư thế gốc đúng.

File Blender cuối: `OreCrucible_v10_export.blend` (các bản v00 → v09 giữ lại để quay về).
