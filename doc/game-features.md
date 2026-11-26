# forgeGod: Danh sách chức năng

Tài liệu mô tả game **theo đúng code hiện tại** (nhánh `feat/forge-strike-animation`, cập nhật 2026-11-24).
Số liệu lấy từ `shared/Config`, `shared/Constants` và `serverStorage/LootTables`. Khi đổi số trong code, sửa lại bảng tương ứng ở đây.

Trạng thái: **Đã có** = chạy được trong game · **Một phần** = có nhưng còn thiếu · **Chưa làm** = mới là ý tưởng.

## 0. Vòng chơi chính

1. Mua quặng ở **Shop**.
2. Bỏ 5 quặng vào **lò nấu (OreCrucible)** để ra một **phôi** vũ khí ngẫu nhiên (độ hiếm, loại, kích thước).
3. Mang phôi lên **đe rèn (Anvil)**, đập búa để tăng giá trị và cấp. Càng đập cao càng dễ vỡ.
4. Đưa vũ khí vào **Loadout** để sinh tiền mỗi giây, hoặc **bán** lấy tiền.
5. Dùng tiền mua quặng tốt hơn và buff, rồi lặp lại.

## 1. Quy ước chung

| Khái niệm | Ý nghĩa |
| --- | --- |
| Độ hiếm | 6 bậc: Common, Uncommon, Rare, Epic, Legendary, Mythic |
| Phôi (Blank) | Vũ khí vừa nấu, chưa đập lần nào |
| Điểm rèn | 0 đến 10. Đập thành công lần thứ 11 thì về 0 và xoá lịch sử giá |
| Cấp vũ khí | Cộng/trừ theo từng lần đập. Tối đa theo độ hiếm (xem mục 5) |
| Giá trị (Value) | Giá hiện tại của vũ khí, đổi theo kết quả đập |
| Lịch sử giá | Giá trước mỗi lần lên điểm trong vòng hiện tại, dùng khi bị trừ điểm |
| Hình dạng | 5 giai đoạn, đổi ngẫu nhiên khi rèn (xem F4.5) |
| Kích thước (Scale) | Hệ số x1 đến x10, quyết định giá phôi và cân nặng |

## 2. Danh sách chức năng

### F1. Dữ liệu người chơi (Đã có)

- F1.1 Lưu bằng ProfileStore: tiền, quặng, buff, từng vũ khí, Loadout, sức chứa, thống kê. `SCHEMA_VERSION = 4`.
- F1.2 Có khoá phiên, lưu khi thoát, `Reconcile` tự bổ sung trường mới.
- F1.3 Người chơi mới có **100 coins**.
- F1.4 Kho chứa **50 vũ khí** (quặng và buff không tính chỗ).
- F1.5 Thống kê: tổng lần rèn, tổng lần vỡ, tổng tiền kiếm được, giá và cấp vũ khí cao nhất.

### F2. Shop (Đã có)

- F2.1 Bán 9 quặng và 8 vật phẩm (7 buff + đá tẩy mutation).
- F2.2 Mỗi mặt hàng có tồn kho giới hạn. **Restock mỗi 5 phút**, tính theo `os.time()` nên mọi server giống nhau, có đếm ngược và thông báo restock.
- F2.3 Mỗi lần restock, mỗi mặt hàng có tỉ lệ xuất hiện riêng (bảng mục 3). Bảng **Odds** trong shop hiển thị tỉ lệ này.
- F2.4 Server kiểm tra đủ tiền và còn hàng trước khi bán. Mỗi lần mua tối đa 99 món.

### F3. Lò nấu quặng / tạo phôi (Đã có)

- F3.1 Đứng gần lò và bấm **E** để mở. Mỗi công thức dùng **đúng 5 quặng** (cùng hoặc khác loại).
- F3.2 Tổng điểm 5 quặng (5 đến 50) quyết định bảng tỉ lệ độ hiếm (mục 4).
- F3.3 Bảng **Smelt Odds** hiện % ra từng độ hiếm (đã tính may mắn) khi chọn đủ 5 quặng mình có.
- F3.4 May mắn khi nấu (Alloy Flux Potion và bạn bè) đẩy tỉ lệ về phía độ hiếm cao.
- F3.5 Ngẫu nhiên loại vũ khí: **30 loại** = 6 độ hiếm × 5 họ (Sword, Axe, Spear, Dagger, Hammer). Tên đang là tên tạm.
- F3.6 Ngẫu nhiên kích thước x1 đến x10. Giá phôi = giá gốc độ hiếm × kích thước.
- F3.7 Lò có chu kỳ trạng thái và hiệu ứng (lửa, khói, âm thanh), đồng bộ mọi server.

### F4. Rèn vũ khí (Đã có)

- F4.1 Đứng gần đe và bấm **E**. Chọn vũ khí muốn rèn: không được nằm trong Loadout, không vỡ, không bị khoá.
- F4.2 Mỗi lần đập ra 1 trong 5 kết quả (mục 5). **Vòng quay** hiển thị % của lần đập kế tiếp.
- F4.3 Điểm rèn càng cao thì tỉ lệ vỡ càng cao. Vũ khí cấp 0 không thể vỡ.
- F4.4 **Vỡ**: vũ khí thành đồ hỏng, giá còn **50% giá phôi gốc**, chỉ dùng để bán.
- F4.5 **Đổi hình dạng** (sự kiện ngẫu nhiên): sau 3 lần đập hồi chiêu, mỗi lần đập có **15%** cơ hội. Đến lần thứ 10 chắc chắn xảy ra. Tối đa 5 dạng.
- F4.6 **Frenzy (đập liên tục)**: sự kiện ngẫu nhiên, cùng quy tắc 3 / 15% / 10 lần.
  - Kéo dài **4 giây**: chỉ tăng hoặc giảm giá, **không đổi cấp, không đổi điểm, không thể vỡ**.
  - Hết frenzy thì **khoá thao tác 1 giây**, để người chơi không đập lố làm mất vũ khí.
- F4.7 Vũ khí đạt cấp tối đa của độ hiếm thì không rèn tiếp được.
- F4.8 Animation đập búa góc nhìn thứ nhất, hiệu ứng tia lửa, hiệu ứng theo kết quả, màn hiện vũ khí khi có kết quả lớn.
- F4.9 Vỡ: vũ khí vỡ vụn thành mảnh bay ra rồi mờ dần, **3 giây** sau mới quay lại màn chọn vũ khí.

### F5. Mutation (Đã có)

- F5.1 Mỗi lần đập thường (không tính frenzy) có cơ hội ra mutation nếu vũ khí chưa có.
- F5.2 Mỗi vũ khí chỉ có **một** mutation. Mutation nhân cả giá bán lẫn tiền mỗi giây.
- F5.3 Ngoài thời tiết: **5%** mỗi lần đập, chọn mutation theo trọng số.
- F5.4 Trong thời tiết: **20%** mỗi lần đập, và chỉ ra mutation của thời tiết đó.
- F5.5 Đá tẩy mutation: **Một phần**. Đã bán trong shop nhưng **chưa dùng được** (server chưa xử lý).
- F5.6 Ra mutation khi rèn: tia sét đánh xuống vũ khí trên đe, màu theo độ hiếm mutation (Common trắng, Uncommon xanh lá, Rare xanh dương).

### F6. Thời tiết (Một phần)

- F6.1 **Cứ 30 phút** có một thời tiết ngẫu nhiên, kéo dài **5 phút**, đồng bộ mọi server.
- F6.2 7 loại thời tiết, mỗi loại gắn một mutation (mục 6).
- F6.3 Hiển thị ở bảng hiệu ứng trạng thái, có đếm ngược.
- F6.4 Hiệu ứng bầu trời, ánh sáng, hạt và âm thanh riêng cho từng thời tiết (client, `WeatherFx`): **đã có đủ 7 thời tiết** (thông số trong `WeatherFxConfig`).

### F7. Loadout và sinh tiền (Đã có)

- F7.1 **4 ô** Loadout lúc đầu (mỗi ô là một trụ trên plot). Vũ khí trong Loadout sinh tiền **mỗi giây**.
- F7.2 Tiền/giây = giá trị × hệ số mutation × `ValueRatio` (hiện là 1, giá trị tạm).
- F7.2b **Không có thu nhập offline**: chỉ cộng tiền khi người chơi đang ở trong game (`IncomeSystem`). Thoát game thì ngừng, vào lại không được cộng bù.
- F7.3 Nút **Equip Best** tự chọn các vũ khí sinh tiền cao nhất.
- F7.4 Vũ khí trong Loadout không thể bán hay rèn. Phải gỡ ra trước.
- F7.5 Nâng thêm ô Loadout ở bảng **Upgrade Plot**: từ 4 lên tối đa **10 ô**, trả bằng coins (giá tạm). Mua bằng Robux đã có code nhưng chưa tạo Developer Product.

### F8. Túi đồ, cầm vũ khí, bán (Đã có)

- F8.1 Túi đồ (Backpack) hiện vũ khí, quặng, buff, kèm độ hiếm, cấp, mutation, cân nặng.
- F8.2 Nút **Equip** trong túi để cầm vũ khí trên tay (chỉ để khoe, không lưu).
- F8.3 **Khoá vũ khí**: vũ khí bị khoá không bán được và không rèn được.
- F8.4 Bán từng vũ khí, **Sell All** (bỏ qua vũ khí khoá hoặc đang trong Loadout), có màn xác nhận.
- F8.5 Bán lại quặng và vật phẩm với **50% giá mua**.
- F8.6 Giá bán vũ khí = giá trị × hệ số mutation × buff bán (Merchant Potion). Vũ khí hỏng không được tính mutation.

### F9. Vật phẩm buff (Đã có)

- F9.1 **Buff theo thời gian**: dùng thêm thì cộng dồn thời gian. Khi thoát game, buff được tạm dừng và chạy tiếp lần sau.
- F9.2 **Buff dùng một lần** (Talisman): kích hoạt trước, tự dùng khi cần.
- F9.3 Buff khác loại cùng chạy được. Hiển thị ở bảng hiệu ứng trạng thái kèm thời gian còn lại.
- F9.4 Danh sách buff ở mục 7.

### F10. Bạn bè (Đã có)

- F10.1 Mỗi người bạn trong cùng server cho **+5% may mắn**, tối đa 4 người (**+20%**).
- F10.2 May mắn này tăng tỉ lệ kết quả tốt khi rèn và tăng tỉ lệ độ hiếm cao khi nấu.

### F11. Index / Bộ sưu tập (Một phần)

- F11.1 UI Index đã có: chia tab theo mutation, mỗi độ hiếm là một bộ sưu tập, có thanh tiến độ và phần thưởng quặng.
- F11.2 Chưa làm: đang dùng **dữ liệu giả**. Chưa lưu vũ khí đã mở khoá, chưa nhận được thưởng.

### F12. Bảng xếp hạng (Đã có)

- F12.1 Có `leaderstats` hiện tiền trong server.
- F12.2 4 bảng toàn game ở Hub (OrderedDataStore), top 100, cuộn được, làm mới mỗi 10 phút theo mốc `os.time()`: Top Money (tổng tiền kiếm được), Top Level (cấp vũ khí cao nhất), Top Weapon $/s ($/s cao nhất của một vũ khí), Top Donated (tổng Robux đã chi).

### F13. Nâng cấp đe rèn và búa rèn (Đã làm)

- Đe và búa mỗi món 7 bậc. Mỗi bậc cộng **may mắn khi rèn** (chỉ áp dụng lúc rèn). Có cả đe và búa Mithril thì được +150%.
- Mua bằng coins, **được mua vượt bậc** (trả giá của bậc mua), giống máy dò và xẻng. Mua bằng Robux đã có code, `ProductId` đang là 0.
- Mua xong thì đe trên plot và búa khi đập tự đổi sang **texture** của bậc mới. Bấm EQUIP ở bậc thấp hơn đã sở hữu để quay lại texture đó. May mắn luôn tính theo bậc cao nhất.
- Công thức trọng số Thành công / Xuất sắc khi rèn: × (1 + may mắn bạn bè + may mắn đe + may mắn búa) × Forge Luck Potion × pass x2 Luck.

| Bậc | Giá (mỗi món) | May mắn khi rèn (mỗi món) |
| --- | --- | --- |
| Copper | 0 | +0% |
| Silver | 25K | +5% |
| Gold | 2.5M | +10% |
| Platinum | 1B | +20% |
| Emerald | 2.5T | +35% |
| Dark Moonstone | 10Qa | +50% |
| Mithril | 1Qi | +75% |

Giá máy dò: 15K, 1.5M, 500M, 1T, 5Qa, 500Qa. Giá xẻng: 10K, 1M, 400M, 800B, 4Qa, 400Qa. Giá nâng plot (ô 5 đến 10): 100K, 25M, 5B, 5T, 10Qa, 5Qi.

### F14. Giao diện và âm thanh (Một phần)

- Đã có: HUD (tiền, nút mở các bảng), Shop, Lò nấu và Smelt Odds, Bàn rèn và vòng quay, chọn vũ khí, Backpack, Loadout, Index, bảng hiệu ứng trạng thái, thông báo (Toast), màn xác nhận.
- Đã có: âm thanh mở UI, đập búa, vòng quay.
- Chưa làm hoặc thiếu: âm thanh của lò (Sound ID đang để trống), âm thanh thời tiết, kiểm tra kỹ trên điện thoại.

### F15. Hướng dẫn người chơi mới (Đã có)

- 12 bước, làm lần lượt: tới bãi đào → đào 5 quặng mới → tới lò nấu (E) → chọn 5 quặng và Start → đóng lò → tới đe, chọn vũ khí → đập 1 lần → rời đe → mở Loadout → bấm EQUIP vũ khí vừa rèn → đóng Loadout → tới shop Upgrades, bấm lần lượt tab Anvil, Hammer, Shovel, Detector.
- Bảng hướng dẫn góc trên bên phải (dưới nút Item Shop): "TUTORIAL x/12", icon, tiêu đề, mô tả, thanh tiến độ. Chuyển sang trái khi mở lò nấu/Loadout, xuống giữa dưới khi mở bảng chọn vũ khí/Upgrades/đang ở đe. Xong thì hiện "TUTORIAL COMPLETE!" 6 giây.
- Mũi tên chevron trên mặt đất từ người chơi tới chỗ cần đến, bám theo cả khi dịch chuyển bằng nút HUD. Bàn tay chỉ vào nút cần bấm.
- Lưu tiến độ trong `Tutorial` (bước, số quặng đã đào, cờ hoàn thành). Thoát giữa chừng vào lại thì làm tiếp; bước chỉ có trong UI (đang mở lò, đang ở đe...) quay về bước gần nhất làm lại được.
- Trong lúc hướng dẫn: sau lần đập đầu tiên bị khoá đập cho tới khi rời đe; nút Equip Best bị khoá ở bước mở Loadout và trang bị.
- Người chơi cũ (đã từng rèn, chưa bắt đầu hướng dẫn) tự được tính là đã xong. Hoàn thành không có thưởng.

## 3. Shop: giá và tỉ lệ xuất hiện mỗi lần restock

### Quặng

| Quặng | Giá | Điểm | Tỉ lệ xuất hiện | Số lượng |
| --- | --- | --- | --- | --- |
| Copper | 20 | 1 | 100% | 35 đến 40 |
| Iron | 100 | 2 | 100% | 30 đến 40 |
| Silver | 300 | 3 | 90% | 25 đến 35 |
| Gold | 1,000 | 4 | 75% | 20 đến 30 |
| Platinum | 5,000 | 5 | 55% | 15 đến 25 |
| Emerald | 15,000 | 6 | 35% | 10 đến 20 |
| Dark Moonstone | 60,000 | 7 | 20% | 8 đến 15 |
| Mithril | 250,000 | 8 | 10% | 5 đến 10 |
| God's Core | 1,000,000 | 10 | 7% | 5 đến 8 |

- Quặng thường đủ nấu 5 đến 8 thanh mỗi lần restock (1 thanh = 5 quặng). Quặng hiếm nhất ra khoảng 1 lần mỗi 10 đến 15 lần restock. Kho shop dùng chung cả server.

### Vật phẩm

Tỉ lệ xuất hiện theo độ hiếm của vật phẩm: Common 90% (3 đến 5 cái), Uncommon 60% (2 đến 4), Rare 35% (1 đến 2), Epic 20% (1 đến 2), Legendary 10% (1), Mythic 7% (1).

## 4. Lò nấu: tỉ lệ độ hiếm theo tổng điểm

| Tổng điểm (5 quặng) | Common | Uncommon | Rare | Epic | Legendary | Mythic |
| --- | --- | --- | --- | --- | --- | --- |
| 5 đến 14 | 60% | 27% | 10% | 2.9% | 0.1% | 0% |
| 15 đến 24 | 35% | 32% | 25% | 6.5% | 1.3% | 0.2% |
| 25 đến 34 | 15% | 27% | 35% | 17% | 5% | 1% |
| 35 đến 44 | 4% | 15% | 36% | 30% | 12% | 3% |
| 45 đến 50 | 0% | 6% | 26% | 40% | 21% | 7% |

- **May mắn L** (tổng buff và bạn bè): trọng số độ hiếm thứ i (Common = 1) nhân với (1 + L)^(i − 1).

### Giá gốc phôi

| Độ hiếm | Giá gốc | Cấp tối đa |
| --- | --- | --- |
| Common | 500 | 30 |
| Uncommon | 1,200 | 40 |
| Rare | 2,500 | 50 |
| Epic | 20,000 | 60 |
| Legendary | 200,000 | 70 |
| Mythic | 1,200,000 | 100 |

### Kích thước phôi (giá trị tạm)

| Nhóm | Hệ số | Tỉ lệ |
| --- | --- | --- |
| Normal | x1 đến x2 | 70% |
| Large | x2 đến x4 | 20% |
| Huge | x4 đến x6 | 7% |
| Giant | x6 đến x8 | 2.5% |
| Colossal | x8 đến x10 | 0.5% |

Cân nặng = cân nặng gốc của họ vũ khí × hệ số (Dagger 1kg, Sword 3kg, Spear 4kg, Axe 5kg, Hammer 8kg). Hiện chỉ để hiển thị.

## 5. Rèn: kết quả mỗi lần đập

| Kết quả | Trọng số | Tác động giá | Điểm / cấp |
| --- | --- | --- | --- |
| Vỡ | (2 + 3 × điểm rèn) × độ khó | Thành đồ hỏng (50% giá phôi gốc) | Không đổi |
| Trừ điểm | 10 × độ khó | Về giá trước đó | −1 |
| Giữ nguyên | 25 | Giữ giá | 0 |
| Thành công | 40 | x1.5 | +1 |
| Xuất sắc | 15 | x2.5 (80%) hoặc x3.5 (20%) | +1 |

- Không có "Vỡ" khi vũ khí cấp 0. Không có "Trừ điểm" khi điểm rèn bằng 0.
- **Độ khó theo cấp vũ khí**: Lv 0 đến 9 là x0.25 (dễ). Từ Lv 10 tăng đều, Lv 20 là x0.62, Lv 30 là x1 (mức cũ), Lv 40 là x1.25, Lv 50 trở lên là x1.5 (tối đa).
- Tỉ lệ vỡ không buff (0 điểm / 9 điểm): Lv 5 khoảng **0.6% / 8%**, Lv 20 khoảng **1.5% / 17%**, Lv 30 khoảng **2.4% / 24%**, Lv 50+ khoảng **3.6% / 31%**.
- **Thành công và Xuất sắc** nhân trọng số với (1 + may mắn bạn bè + may mắn đe/búa) × Forge Luck Potion.
- **Talisman** biến một lần vỡ thành "Giữ nguyên".
- Trong **Frenzy**: không có Vỡ, giá vẫn đổi theo bảng, cấp và điểm không đổi.

## 6. Mutation và thời tiết

| Mutation | Hệ số tiền | Độ hiếm (trọng số) | Thời tiết gắn với | Độ hiếm thời tiết (trọng số) |
| --- | --- | --- | --- | --- |
| Aqua | x1.5 | Common (40) | Heavy Rain | Common (40) |
| Molten | x2 | Common (40) | Heatwave | Common (40) |
| Thunder | x3 | Uncommon (20) | Thunderstorm | Uncommon (20) |
| Aurora | x4 | Uncommon (20) | Aurora | Rare (10) |
| Radioactive | x4 | Rare (8) | Radiation | Rare (10) |
| Shadow | x5 | Rare (8) | Lunar Eclipse | Very Rare (4) |
| Plasma | x5 | Rare (8) | Plasma Storm | Very Rare (4) |

- May mắn bạn bè áp dụng cho rèn, nấu và đào quặng. May mắn đào = may mắn máy dò × (1 + may mắn bạn bè + Prospector Potion) × pass x2 Luck.
- Ngoài thời tiết: 1% mỗi lần đập (Mutation Catalyst x2).
- Trong thời tiết: 5% mỗi lần đập (Storm Potion x2).

## 7. Vật phẩm buff

| Vật phẩm | Loại | Thời gian | Độ hiếm | Giá | Tác dụng |
| --- | --- | --- | --- | --- | --- |
| Prospector Potion (id BlessingPotion) | Theo thời gian | 3 phút | Common | 5,000 | May mắn khi đào quặng +20% |
| Forge Luck Potion (id LuckPotion) | Theo thời gian | 3 phút | UnCommon | 10,000 | May mắn khi rèn +15% (trọng số Thành công x1.15) |
| Angel Heart | dùng ngay | | mythic | 2,500,000 | hồi sinh vũ khí đã vỡ về phôi level 0, xoá mutation |
| Mutation Catalyst | Theo thời gian | 3 phút | rare | 100,000 | Tỉ lệ mutation x2 |
| Alloy Flux Potion | Theo thời gian | 3 phút | epic | 1,000,000 | May mắn khi nấu +15% |
| Storm Potion | Theo thời gian | 5 phút | epic | 1,000,000 | Tỉ lệ mutation thời tiết x2 |
| Talisman | Dùng 1 lần | — | legendary | 10,000,000 | Chặn 1 lần vỡ |
| Mutation Eraser | Dùng ngay | — | epic | 2,500,000 | Xoá mutation, rèn tiếp có thể ra mutation mới |

- Angel Heart và Mutation Eraser dùng từ Backpack: mở bảng chọn vũ khí (nút **USE**). Angel Heart chỉ hiện vũ khí đã vỡ. Mutation Eraser chỉ hiện vũ khí có mutation, không nằm trong Loadout, không vỡ, không khoá.
- Talisman chặn vỡ: icon Talisman hiện to phía trên chữ "SAVED!" ngay trên đe.

## 8. Công thức giá

- Giá phôi = giá gốc độ hiếm × kích thước
- Giá sau mỗi lần đập thành công = giá hiện tại × hệ số kết quả
- Giá bán = giá trị × hệ số mutation × buff bán
- Tiền mỗi giây trong Loadout = giá trị × hệ số mutation × `ValueRatio` (1)
- Vũ khí hỏng = 50% giá phôi gốc, không tính mutation

## 9. Việc cần làm

Cập nhật 2026-11-24. Đánh dấu `[x]` khi xong. Cột "Cần chốt" là quyết định thiết kế phải có trước khi code.

### A. Gameplay còn thiếu

| # | Việc | Cần chốt |
| --- | --- | --- |
| [x] A1 | **Đá tẩy mutation**: Remote dùng đá với Id vũ khí, server kiểm tra sở hữu / khoá / Loadout, thêm hàm tẩy vào `DataActions`, nút dùng trong Backpack | Sau khi tẩy, rèn tiếp có ra lại mutation không |
| [ ] A2 | **Index lưu thật**: thêm trường vũ khí đã mở khoá vào `DataTemplate`, ghi khi nấu/rèn ra loại mới, Remote nhận thưởng, bỏ `IndexMockData` | Điều kiện mở khoá (loại + mutation?), phần thưởng |
| [x] A3 | **Nâng cấp đe/búa (F13), phía server**: trường cấp trong `DataTemplate`, hàm nâng trong `DataActions`, Remote, `ForgeService` đọc chỉ số khi tính trọng số, nối với UI đã có | Chỉ số từng track, số cấp, giá, cách cộng với buff, giới hạn trên |
| [ ] A4 | **Nâng sức chứa kho** (`Capacity.Items` = 50) | Giá, mỗi lần thêm bao nhiêu ô, có bán Robux không |
| [ ] A5 | Xoá `client/Controllers/BackpackMockData.luau` (không còn nơi nào dùng) | Người dùng đồng ý xoá |

### B. Model vũ khí

**Đã chốt phương án B: 5 họ × 5 dạng = 25 model.** Độ hiếm không có model riêng mà chỉ đổi màu/vật liệu (Common đến Mythic) trên cùng model.
Hiện chỉ có 2 model tạm (`Sword_level_1`, `Voidheart`) dùng chung cho mọi loại, và `blender/Weapons/Epic_ObsidianSword` chưa đưa vào game.

| # | Việc |
| --- | --- |
| [ ] B1 | Chốt phong cách từng họ (Sword, Axe, Spear, Dagger, Hammer) và sự khác biệt giữa 5 dạng (dạng sau to hơn, chi tiết hơn) |
| [ ] B2 | Chốt bảng màu/vật liệu theo 6 độ hiếm và cách áp màu lúc chạy (đổi màu part theo tên) |
| [ ] B3 | Làm 25 model trong Blender theo pipeline sẵn có (QA, export FBX, upload, sửa màu theo tên part) |
| [ ] B4 | Đưa `Epic_ObsidianSword` vào game (hoặc dùng làm một dạng của họ Sword) |
| [ ] B5 | Thay bảng `ForgeAnimationConfig.WeaponVisuals` và `ForgeStrikeConfig.TestWeaponModelStages` bằng mapping họ + dạng -> model, chỉnh `Length`/`Rotation` |
| [ ] B6 | Kiểm tra từng model ở: đe rèn, màn reveal, trên tay, trụ Loadout, ViewportFrame Backpack/Index |
| [ ] B7 | Model vũ khí vỡ (dùng chung theo họ) |
| [ ] B8 | Tên thật cho 30 loại vũ khí trong `shared/Constants/WeaponCatalog` (đang là tên tạm "Copper Sword"...) |

Tiến độ 25 model:

| Họ | Dạng 1 | Dạng 2 | Dạng 3 | Dạng 4 | Dạng 5 |
| --- | --- | --- | --- | --- | --- |
| Sword | [ ] | [ ] | [ ] | [ ] | [ ] |
| Axe | [ ] | [ ] | [ ] | [ ] | [ ] |
| Spear | [ ] | [ ] | [ ] | [ ] | [ ] |
| Dagger | [ ] | [ ] | [ ] | [ ] | [ ] |
| Hammer | [ ] | [ ] | [ ] | [ ] | [ ] |

### C. Model và hình ảnh khác

| # | Việc |
| --- | --- |
| [ ] C1 | Model đe/búa theo cấp nâng (F13), nếu nâng cấp có đổi ngoại hình |
| [ ] C2 | Kiểm tra đủ model cho 9 loại quặng trong Shop |
| [ ] C3 | Thay màu tạm của quặng trong `ItemVisuals` bằng icon/ảnh thật |

### D. Âm thanh

| # | Việc |
| --- | --- |
| [ ] D1 | 5 âm lò nấu đang trống trong `OreCrucibleConfig`: IdleLoop, ActiveLoop, MaxLoop, ActiveStart, MaxBurst |
| [ ] D2 | 4 âm rèn đang mượn tạm trong `ForgeAnimationConfig`: tiếng nổ khi vỡ, tick vòng quay, tiếng "chốt", tiếng "vào kho" |

### E. Robux

| # | Việc |
| --- | --- |
| [ ] E1 | Tạo Developer Product cho 6 bậc nâng plot, điền `ProductId` trong `PlotUpgradeConfig` (đang là 0) |
| [ ] E2 | Chốt món nào bán bằng Robux: buff, đá tẩy, nâng đe/búa, nâng kho |

### F. Cân bằng số liệu (đang là PLACEHOLDER)

| # | Việc |
| --- | --- |
| [ ] F1 | `LoadoutConfig.ValueRatio` (tiền/giây) |
| [ ] F2 | Tỉ lệ kích thước phôi (`WeaponScaleTable`) |
| [ ] F3 | Toàn bộ `ShopRestockTable` và giá buff trong `ShopConfig` |
| [ ] F4 | Giá nâng plot (`PlotUpgradeConfig`) |
| [ ] F5 | Ngưỡng `RateLimiter`, số vũ khí tối đa mỗi lần Sell All (`SellConfig`) |

### G. Hoàn thiện và phát hành

| # | Việc |
| --- | --- |
| [ ] G1 | Commit các thay đổi đang treo (bỏ `.blend1`, `_tmp_*.mp4`) |
| [x] G2 | Cập nhật tài liệu: Loadout nâng được qua plot, F13 đã có UI |
| [ ] G3 | Test điện thoại/tablet bằng Device Simulator |
| [ ] G4 | Test nhiều người chơi: Friend Boost, xem người khác rèn, Leaderboard |
| [ ] G5 | Rà bảo mật Remote, kiểm tra `USE_MOCK_IN_STUDIO` trước khi publish |

### Thứ tự đề xuất

1. G1 commit.
2. A1 đá tẩy mutation.
3. B1, B2 chốt hướng model, rồi làm dần B3 đến B6 xen kẽ với code.
4. A2 Index.
5. A3 nâng đe/búa, A4 nâng kho.
6. D, E, F, rồi G3 đến G5.
