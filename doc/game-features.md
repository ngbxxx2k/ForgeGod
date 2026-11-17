# Game Rèn Vũ Khí: Danh sách chức năng

## 0. Quy ước chung

| **Khái niệm** | **Ý nghĩa**                                                    |
| ------------- | -------------------------------------------------------------- |
| Điểm rèn      | 0 đến 10 trong một vòng. Đạt 10 thì đổi hình dạng, reset về 0. |
| Cấp vũ khí    | Tổng cấp tích lũy qua các vòng, tối đa **50** (5 vòng x 10).   |
| Giá hiện tại  | Giá vũ khí đang có, thay đổi theo kết quả đập.                 |
| Lịch sử giá   | Danh sách giá từng bậc, dùng để "trừ về giá trước một bậc".    |
| Độ hiếm       | Common, Rare, Epic, Legendary, Mythic.                         |

## 1. Danh sách chức năng

### F1. Dữ liệu người chơi (nền tảng)

- F1.1 Lưu tiền, kho quặng vật phẩm vũ khí, vũ khí đang treo.
- F1.2 Tải và lưu an toàn (retry, lưu khi thoát, lưu định kỳ).
- F1.3 Khóa phiên để chống ghi đè khi người chơi đổi server.

### F2. Shop

- F2.1 Bán 9 quặng: đồng, sắt, bạc, vàng, Platinum, Emerald, Dark Moonstone, Mithril, God's Core.
- F2.2 Bán vật phẩm buff (xem F8).
- F2.3 Mỗi mặt hàng có số lượng tồn kho giới hạn.
- F2.4 Restock mỗi 5 phút, hiển thị đếm ngược , đồng bộ shop tất cả các server đều giống nhau.
- F2.5 Quặng hiếm có tỉ lệ xuất hiện thấp hơn trong mỗi lần restock.
- F2.6 Kiểm tra đủ tiền và còn hàng ở server trước khi bán.

### F3. Tạo phôi (nấu quặng)

- F3.1 Chọn quặng vào lò, mỗi quặng có điểm riêng.
- F3.2 Tổng điểm và cách phối quyết định bảng tỉ lệ ra vũ khí (độ hiếm và loại vũ khí).
- F3.3 nấu quặng, kết quả quyết định giá phôi nằm ở đâu trong khoảng dao động (xem mục 3).
- F3.4 Buff "may mắn khi tạo phôi" dịch bảng tỉ lệ về phía độ hiếm cao hơn.
- F3.5 Có 25 loại vũ khí: 5 độ hiếm x 5 loại mỗi độ hiếm.

### F4. Rèn vũ khí

- F4.1 Mỗi lần đập búa ra 1 trong 6 kết quả (xem mục 4).
- F4.2 Vỡ: mất vũ khí và nhận vũ khí hỏng (F4.6).
- F4.3 Điểm rèn càng cao, tỉ lệ vỡ hỏng càng cao các tỉ lệ khác giảm .
- F4.4 Đạt điểm rèn 10: vũ khí đổi hình dạng (to hơn, đẹp hơn), điểm về 0, tỉ lệ vỡ về ban đầu, bật chế độ **đập liên tục trong 2 giây tăng tiền nhưng không tăng điểm hay cấp vũ khí chỉ tăng tiền trong trạng thái này vũ khí không thể bị vỡ khi hết trạng thái tạm dừng thao tác không cho người đập lố gây mất vũ khí khi không kiểm soát lần đập**.
- F4.5 Cấp vũ khí cộng hoặc trừ theo kết quả từng lần đập, tối đa 50 (có thể cập nhật cấp cao hơn khi update).
- F4.6 Vũ khí hỏng: bán được với **50%** giá gốc.
- F4.7 Hình dạng vũ khí có 5 giai đoạn, mỗi 10 điểm đổi một lần.

### F5. Mutation

- F5.1 Mỗi lần đập có tỉ lệ thấp ra mutation 5% .
- F5.2 Mỗi vũ khí chỉ có **một** mutation. Chưa ra thì các lần đập sau vẫn có cơ hội.
- F5.3 Mỗi mutation có hệ số tiền riêng (x1, x3, x5...).
- F5.4 Tỉ lệ mutation tăng theo thời tiết (F6) và thuốc (F8).
- F5.5 Đá tẩy mutation xóa mutation, vũ khí có thể ra mutation lại.

### F6. Sự kiện thời tiết

- F6.1 Cứ 30 phút, server xuất hiện một sự kiện ngẫu nhiên, kéo dài 5 phút ,đồng bộ tất cả các server đều giống nhau.
- F6.2 Loại: Bão, Plasma, Mưa sao băng, God's Blessing, Đêm trăng đen (còn mở rộng).
- F6.3 Thông báo toàn server khi bắt đầu và kết thúc, có đếm ngược.
- F6.4 Thời tiết có 20% mutation và có bảng mutation riêng.
- F6.5 Hiệu ứng thị giác (trời, ánh sáng, âm thanh).

### F7. Bán vũ khí

- F7.1 Chọn vũ khí trong kho để bán, server tính giá cuối.
- F7.2 Coin Potion tăng tiền khi bán.
- F7.3 Xác nhận trước khi bán vũ khí giá cao hoặc đang treo.

### F8. Vật phẩm buff

| **Vật phẩm**        | **Tác dụng**                           |
| ------------------- | -------------------------------------- |
| Thuốc may mắn phôi  | Tăng tỉ lệ ra độ hiếm cao khi tạo phôi |
| Thuốc Thợ Rèn       | Giảm tỉ lệ vỡ khi rèn                  |
| Coin Potion         | Tăng tiền khi bán                      |
| Đá tẩy mutation     | Xóa mutation hiện tại                  |
| Thuốc tăng đột biến | Tăng tỉ lệ mutation                    |

- F8.1 Thuốc có thời gian hiệu lực, không cộng dồn cùng loại, khác loại thì được, có thể dùng nhiều loại buff khác nhau.
- F8.2 Hiển thị buff gốc phải bên dưới đang chạy và thời gian còn lại.

### F9. Khoe vũ khí

- F9.1 Treo tối đa **3** vũ khí sau lưng nhân vật, mọi người chơi nhìn thấy.
- F9.2 Hai bảng xếp hạng toàn game ở tất cả server: top người chơi sở hữu vũ khí **giá cao nhất**, top người chơi sở hữu vũ khí **cấp rèn cao nhất**.
- F9.3 Cập nhật bảng định kỳ để tiết kiệm request.

### F10. Giao diện, âm thanh

- F10.1 UI shop, lò nấu, bàn rèn, túi đồ, bảng xếp hạng.
- F10.2 UI hợp cả điện thoại và máy tính.
- F10.3 Âm thanh đập búa, vỡ, thăng cấp, thông báo thời tiết.

## 2. Công thức mẫu

### Giá quặng và điểm quặng

| **Quặng**      | **Giá** | **Điểm** |
| -------------- | ------- | -------- |
| Đồng           | 20      | 1        |
| Sắt            | 100     | 2        |
| Bạc            | 300     | 3        |
| Vàng           | 1000    | 4        |
| Platinum       | 5000    | 5        |
| Emerald        | 15000   | 6        |
| Dark Moonstone | 60000   | 7        |
| Mithril        | 250000  | 8        |
| God's Core     | 1000000 | 10       |

### Giá gốc vũ khí theo độ hiếm

| **Độ hiếm** | **Giá gốc** |
| ----------- | ----------- |
| Common      | 500         |
| Rare        | 2500        |
| Epic        | 20000       |
| Legendary   | 200000      |
| Mythic      | 1200000     |

## 3. Tạo phôi: bảng tỉ lệ mẫu

Công thức tạm: dùng 5 **loại quặng (có thể khác hoặc cùng loại)**, tổng điểm S quyết định bảng:

| **Tổng điểm (5 Quặng)** | **Common (Giá 500)** | **Rare (Giá 1000)** | **Epic (Giá 5000)** | **Legendary (Giá 50K)** | **Mythic (Giá 120K)** |
| ----------------------- | -------------------- | ------------------- | ------------------- | ----------------------- | --------------------- |
| **5 đến 14 điểm**       | 95%                  | 5%                  | 0%                  | 0%                      | 0%                    |
| **15 đến 24 điểm**      | 70%                  | 28%                 | 2%                  | 0%                      | 0%                    |
| **25 đến 34 điểm**      | 40%                  | 45%                 | 12%                 | 2.5%                    | 0.5%                  |
| **35 đến 44 điểm**      | 15%                  | 50%                 | 25%                 | 8%                      | 2%                    |
| **45 đến 50 điểm**      | 0%                   | 40%                 | 40%                 | 15%                     | 5%                    |

- Giá phôi = giá gốc x hệ số , hệ số trong khoảng 1 **đến 2 ngẫu nhiên**.
- Buff may mắn: cộng thêm tỉ lệ vào độ hiếm cao, lấy từ độ hiếm thấp nhất.

## 4. Rèn: kết quả mỗi lần đập

| **Kết quả** | **Trọng số** | **Tác động giá**      | **Điểm rèn** |
| ----------- | ------------ | --------------------- | ------------ |
| Vỡ          | 2 + 3p       | mất vũ khí            | reset        |
| Trừ điểm    | 10           | về giá bậc trước      | \-1          |
| Giữ nguyên  | 25           | giữ giá               | 0            |
| Thàng công  | 40           | x1.5                  | +1           |
| Xuất sắc    | 15           | x2.5 hoặc x3.5 random | +1           |

- Tỉ lệ vỡ thực tế (khi không có buff): p=0 khoảng 2%, p=9 khoảng 22%.
- Thuốc Thợ Rèn nhân trọng số "Vỡ" với hệ số nhỏ hơn 1 (ví dụ x0.5).
- Điểm rèn nhảy quá 10 thì chỉ tính đến 10, phần dư xử lý theo cách bạn chọn (xem mục 7).
- Cấp vũ khí cộng hoặc trừ theo đúng số điểm của kết quả đó.

### Giá cuối khi bán

giá cuối = giá hiện tại x hệ số mutation x (1 + buff Coin Potion)

## 5. Mutation

| **Mutation** | **Hệ số tiền** | **Gắn với thời tiết** |
| ------------ | -------------- | --------------------- |
| Thường       | x1             | mặc định              |
| lightning    | x3             | Bão                   |
| Plasma       | x5             | Plasma                |
| Sao băng     | x5             | Mưa sao băng          |
| Thần phúc    | x10            | God's Blessing        |
| Nguyệt hắc   | x7             | Đêm trăng đen         |

- Tỉ lệ nền mỗi lần đập: 5**%**.
- Thời tiết tỉ lệ 20% mutation .
- Thuốc tăng đột biến giúp nhân đôi tỉ lệ đột biến.

