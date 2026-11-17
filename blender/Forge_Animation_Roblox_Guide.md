# Forge Animation: thời gian, vị trí và hướng dẫn dựng VFX trong Roblox

File nguồn: `blender/Weapon_Forging_Animation.blend` (30 FPS, 1 Blender unit = 1 stud).
FBX: `blender/export/NormalForge.fbx`, `blender/export/FinalForge.fbx`.

## 1. Thời gian và frame va chạm

Thời gian Roblox = (frame Blender - 1) / 30.

| Animation | Độ dài | Sự kiện (marker) | Frame Blender | Thời gian Roblox |
|---|---|---|---|---|
| NormalForge (loop) | 37 frame | Impact | 22 | **0.700 s** |
| NormalForge | | Kết thúc / lặp | 37 | 1.200 s |
| FinalForge | 85 frame | ChargeStart | 24 | 0.767 s |
| FinalForge | | Release (bắt đầu vung) | 44 | 1.433 s |
| FinalForge | | **Impact** | 50 | **1.633 s** |
| FinalForge | | HoldEnd (bắt đầu hồi) | 70 | 2.300 s |
| FinalForge | | Kết thúc | 85 | 2.800 s |

- Frame đầu và cuối của cả hai animation là cùng một tư thế "sẵn sàng", nên Normal lặp liên tục được và Final nối tiếp Normal không giật.
- Sau khi import vào Animation Editor, thêm **Animation Event** cùng tên (`Impact`, `ChargeStart`, `Release`) tại các mốc trên, rồi bắt bằng `AnimationTrack:GetMarkerReachedSignal("Impact")`.
- Đặt `AnimationPriority = Action` để đè animation cầm Tool mặc định.

## 2. Bố cục (toạ độ Roblox, tương đối với Anvil)

Đe và kiếm trong Blender đã scale ×2. **Trong Studio hiện vẫn là kích thước cũ**, nên phải scale ×2 tương ứng thì animation mới khớp:

- `Fantasy_Anvil.Size` = (4.156, 2.741, 2.184)
- `sword_level_1.Sword.Size` = (0.787, 2.4, 0.16)

| Đối tượng | CFrame / vị trí so với `Anvil.CFrame` |
|---|---|
| Sword (nằm ngang, mũi về phía sừng đe, mặt local -Z hướng lên) | `CFrame.fromMatrix(Vector3.new(-0.58, 1.4532, 0), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0))` |
| `ImpactAttachment` (đặt trên **Anvil**, vì kiếm thay theo cấp) | `Position = (-0.38, 1.49, 0)`, trục Y hướng lên |
| HumanoidRootPart của người chơi khi rèn | `Anvil.CFrame * CFrame.new(-1.35, 1.822, 2.5)` (mặt nhìn về -Z của đe) |
| Búa (Tool, Handle = mesh búa) | `Tool.Grip = CFrame.new(0, -0.55, 0) * CFrame.Angles(0, math.rad(90), 0)` |
| `HammerHeadAttachment` (trong Handle búa) | `Position = (0, 0.72, 0)` |

Điểm va chạm nằm đúng trên mặt lưỡi kiếm. Khi rèn, nên khoá người chơi tại vị trí HRP ở trên (chỉ đặt X/Z và hướng; độ cao để Humanoid tự xử lý), vì animation được căn theo vị trí này.

## 3. Góc nhìn thứ nhất

- Animation được kiểm tra qua camera mô phỏng Roblox first-person: cao 1.5 stud trên HRP, FOV dọc 70°, nhìn xuống 33° và lệch phải 27° về điểm va chạm (`CAM_FirstPerson` trong file .blend).
- Roblox tự ẩn thân nhân vật ở góc thứ nhất; búa (Tool) vẫn hiện. Animation được thiết kế cho trường hợp này: đầu búa luôn trong khung hình khi đập thường; búa không bao giờ đến gần camera dưới 1.1 stud (không xuyên camera).
- FinalForge: lúc tụ lực, đầu búa ở trên cao, ngoài khung hình (chỉ thấy cán ở góc phải). Cảm giác tụ lực ở góc thứ nhất đến từ kiếm nóng đỏ, đốm lửa bốc lên và ánh sáng quanh đe tăng dần. Nếu muốn người chơi thấy cả đầu búa phát sáng, có thể ngẩng camera lên vài độ trong khoảng 0.767 s → 1.433 s.
- Khuyến nghị: khoá hướng camera nhìn vào `ImpactAttachment` trong lúc chạy animation, và rung camera nhẹ (Final mạnh hơn Normal) tại `Impact`.

## 4. VFX: Blender → Roblox

Các hiệu ứng trong Blender (particle, mesh phát sáng, keyframe) chỉ để xem trước. Trong Roblox, dựng lại bằng ParticleEmitter, PointLight, Highlight và TweenService như dưới đây. Mọi emitter để `Enabled = false` và gọi `:Emit(n)` khi nhận marker.

### NormalForge, kích hoạt tại `Impact` (0.700 s)

| Lớp | Roblox | Thông số gợi ý |
|---|---|---|
| Tia lửa | ParticleEmitter trên ImpactAttachment | Emit(45), Lifetime 0.2–0.45, Speed 2–7, SpreadAngle (70,70), Acceleration (0,-6,0), Drag 1, Size 0.06, Orientation VelocityParallel, LightEmission 1, Color cam (255,115,15) → vàng |
| Hạt lửa nhỏ | ParticleEmitter | Emit(14), Lifetime 0.4–0.9, Speed 0.5–3, Acceleration (0,-10,0), Size 0.08, Color (255,70,8) |
| Chớp kim loại | ParticleEmitter (texture flare) | Emit(1), Lifetime 0.1, Size 0.5 → 0, LightEmission 1, Color (255,200,115) |
| Sóng nhỏ | ParticleEmitter (texture vòng), Orientation VelocityPerpendicular, Speed 0.01 | Emit(1), Lifetime 0.15, Size 0.3 → 1.4, Transparency 0 → 1 |
| Đèn chớp | PointLight trên ImpactAttachment | Range 8, Color (255,140,50), Brightness 0 → 3 → 0 trong 0.2 s (Tween) |
| Rung kiếm | Tween CFrame kiếm | lệch -0.012 / +0.008 / -0.005 / 0 stud trong ~0.15 s |

### FinalForge

Tụ lực, từ `ChargeStart` (0.767 s) đến `Impact` (1.633 s):

| Lớp | Roblox | Thông số gợi ý |
|---|---|---|
| Kiếm nóng dần | `Highlight` trên kiếm | FillColor (255,80,10), FillTransparency 1 → 0.55 (tween 0.87 s), OutlineTransparency 1 |
| Đốm lửa bốc từ lưỡi | ParticleEmitter, Shape Box phủ lưỡi kiếm | Rate 70, Lifetime 0.5, Speed 0.3–1.1 (lên), Acceleration (0,0.5,0), Size 0.05 |
| Hạt lửa hút vào đầu búa | ParticleEmitter trên HammerHeadAttachment, Shape Sphere, ShapeInOut Inward, ShapeStyle Surface | Rate 90, Lifetime 0.3, Speed 1.6, Size 0.05 (tắt tại Impact) |
| Đầu búa phát sáng | PointLight trên HammerHeadAttachment | Brightness 0 → 2, Range 6 |
| Ánh sáng quanh đe tăng | PointLight trên ImpactAttachment | Brightness 0 → 1.5, Range 12 |
| Vệt búa khi vung | Trail giữa 2 attachment trên đầu búa | Bật 1.433 → 1.70 s, Lifetime 0.15, màu cam |

Va chạm, tại `Impact` (1.633 s). Các lớp khác nhau về hành vi, không chỉ to hơn bản Normal:

| Lớp | Roblox | Thông số gợi ý |
|---|---|---|
| Nổ tia lửa (nhanh, rộng) | ParticleEmitter | Emit(180), Lifetime 0.25–0.6, Speed 3.5–11.5, SpreadAngle (85,85), Acceleration (0,-4,0), Drag 3, Orientation VelocityParallel |
| Tia lửa vòng cung (bay lâu) | ParticleEmitter | Emit 70 rải trong 0.13 s, Lifetime 0.7–1.3, Speed 2.4–5.6, Acceleration (0,-10,0), Color vàng (255,160,30) |
| Mảnh vụn phát sáng | ParticleEmitter | Emit(24), Lifetime 0.8–1.4, Speed 1–5.4, Acceleration (0,-14,0), Size 0.1, RotSpeed ±180 |
| Chớp lớn | ParticleEmitter flare | Emit(1), Lifetime 0.15, Size 0.7 → 0 (nhỏ hơn đầu búa để không che điểm chạm) |
| Sóng xung kích 1 | Vòng phẳng (particle hoặc part + Tween) | 0.5 → 5.6 stud trong 0.25 s, Transparency 0 → 1 |
| Sóng xung kích 2 (trễ 0.07 s) | như trên | 0.3 → 3.6 stud trong 0.27 s, màu vàng nhạt |
| Xung năng lượng dọc lưỡi | 2 part Neon nhỏ, Tween từ điểm chạm tới mũi và tới chuôi | 0.2 s, rồi Transparency → 1 |
| Kiếm sáng bùng rồi dịu | Highlight | FillTransparency 0.55 → 0.25 (tại Impact) → 0.75 (trạng thái hoàn thành) trong 1.2 s |
| Đèn bùng | PointLight ImpactAttachment | Brightness 6, Range 14, giảm về 0.3 trong 1.2 s |
| Rung kiếm + đe | Tween CFrame | kiếm: 0.035 → 0 trong 0.33 s; đe: 0.014 → 0 trong 0.2 s |
| Camera (góc thứ nhất) | Client | FOV +6 trong 0.15 s, rung 0.2 s |

## 5. Import animation vào Roblox

1. Animation Editor → chọn rig R15 → `...` → **Import → From FBX Animation** → chọn `NormalForge.fbx` (tương tự `FinalForge.fbx`).
2. NormalForge: bật Looping. FinalForge: tắt Looping. Priority: Action.
3. Thêm Animation Event theo bảng mục 1, rồi Publish để lấy AnimationId.
4. Để xuất lại sau khi sửa: trong file .blend chạy text `export_fbx.py` (tự đặt Unit Scale 0.01 khi xuất để 1 unit = 1 stud).

## 6. Giới hạn

- Không có model thợ rèn trong dự án, nên nhân vật là **rig R15 chuẩn của Roblox** (mesh thân lấy trực tiếp từ Studio). Đầu là hình trụ bo tạm, vì mesh đầu mặc định không đọc được. Animation áp dụng cho avatar R15 của người chơi.
- Animation căn cho tỉ lệ R15 mặc định. Avatar có scale khác nhiều (BodyHeightScale…) sẽ lệch điểm va chạm vài phần mười stud.
- Animation chỉ chứa xoay bone và dịch chuyển nhẹ LowerTorso; HumanoidRootPart đứng yên.
