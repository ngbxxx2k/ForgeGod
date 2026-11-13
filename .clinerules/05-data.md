# 05 - Dữ liệu người chơi (DataStore / ProfileStore)

## Cách truy cập
- Lấy dữ liệu bằng `DataService.GetData(player)` (nil nếu chưa tải xong hoặc đã thoát). **Luôn kiểm tra nil.**
- **Chỉ `DataActions` được sửa trực tiếp `data`.** Service/System/Controller gọi hàm của `DataActions`, không viết `data.Coins += ...` ngoài `Data/`.
- Cần hành động chưa có trong `DataActions` thì **thêm hàm vào `DataActions`**, kèm kiểm tra hợp lệ, không viết tắt trong Service.

## Thêm hoặc đổi trường dữ liệu
1. Thêm trường vào `DataTemplate.Default` (kèm comment tiếng Việt về ý nghĩa).
2. Nếu đổi cấu trúc trường cũ (đổi tên, đổi kiểu): tăng `SCHEMA_VERSION` và viết bước `migrate` trong `DataService`.
3. Chỉ **thêm** trường mới thì `Reconcile` tự bổ sung, không cần migrate.
4. **Không xoá hoặc đổi tên trường đang dùng** mà không có migrate, vì sẽ mất dữ liệu người chơi.

## Quy tắc dữ liệu lưu được
- Chỉ lưu kiểu đơn giản: `number`, `string`, `boolean`, và `table` chứa các kiểu đó.
- **Không** lưu `Instance`, `Vector3`, `Color3`, hàm. Muốn lưu thì chuyển thành số/chuỗi/bảng.
- Key của bảng dạng từ điển là **chuỗi**. Không trộn khoá chuỗi và khoá số trong cùng một bảng. Mảng không được có lỗ hổng.
- Số tiền, cấp, số lượng lưu số nguyên (`math.floor`).
- Không lưu dữ liệu suy ra được (ví dụ hình dạng vũ khí suy ra từ `Level`). Không lưu trạng thái tạm (minigame, UI).
- Không lưu trạng thái chung toàn server (restock, thời tiết). Xem file 04.

## Kho đồ
- Kho dùng chung: số chỗ đã dùng = tổng số lượng trong `Items` + số vũ khí trong `Weapons`. So với `Capacity.Items`.
- Vũ khí lưu **từng món** trong `Weapons` (mỗi món có Id riêng). Không gộp vũ khí vào dạng `[itemId] = số lượng`.
- Vũ khí đang đeo (`Equipped`) không được bán, rèn, xoá. Gỡ xuống trước.
- Mutation chỉ ghi một lần cho mỗi vũ khí (trừ khi dùng đá tẩy).

## Bảng xếp hạng
- Chỉ gửi điểm qua `LeaderboardService.Submit`. Không gọi OrderedDataStore từ chỗ khác.
- Không gọi DataStore trực tiếp ngoài thư mục `Data/`.

## Test
- Trong Studio mặc định dùng dữ liệu giả (`USE_MOCK_IN_STUDIO = true`). Không đổi giá trị này khi commit.
- Đổi `STORE_NAME` (ví dụ `PlayerData_v2`) nếu muốn bắt đầu lại dữ liệu sạch khi thử nghiệm.
