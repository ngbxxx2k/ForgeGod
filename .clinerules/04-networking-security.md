# 04 - Mạng (Remote) và bảo mật

## Nguyên tắc
Client **không đáng tin**. Mọi thứ client gửi lên đều có thể bị giả mạo.

## Quy tắc Remote
- Tên Remote khai báo **một nơi duy nhất**: `shared/Network`. Không viết chuỗi tên Remote rải rác.
- Remote do client gọi chỉ truyền **ý định và ID** (ví dụ `RequestForge(weaponId)`), **không** truyền kết quả hay số tiền (`"tôi được 500 coins"`).
- Server **kiểm tra mọi tham số** của Remote trước khi dùng:
  - đúng kiểu (`typeof`), không phải `NaN`/`inf`, nằm trong khoảng cho phép;
  - chuỗi ID phải tồn tại trong registry hoặc trong dữ liệu của chính người chơi đó;
  - người chơi thực sự sở hữu vũ khí/vật phẩm đó.
- Mỗi Remote có **rate limit** (giới hạn tần suất) qua module trong `server/Security`.
- Server gửi cho client chỉ phần dữ liệu client cần hiển thị. Không gửi tỉ lệ rơi, tỉ lệ vỡ, seed ngẫu nhiên.
- Dùng `RemoteEvent` khi không cần trả lời. Hạn chế `RemoteFunction` từ server gọi client (client có thể treo script).

## Quy tắc ngẫu nhiên và kinh tế
- Mọi phép random liên quan đến phần thưởng (rèn, mutation, rơi phôi) chạy **trên server**.
- Dùng `Random.new()` một lần cho mỗi module, không gọi `math.randomseed` nhiều lần.
- Mọi thay đổi tiền/vật phẩm đi qua `DataActions` (xem file 05). Không sửa tiền trực tiếp trong Service.
- Chặn lỗi "nhân đôi" (duplicate): thao tác trừ cái này và cộng cái kia phải kiểm tra điều kiện **trước**, rồi mới thay đổi, và không có chỗ `task.wait()` xen giữa hai bước.

## Xử lý người chơi rời game giữa chừng
- Sau mỗi thao tác bất đồng bộ (`task.wait`, `InvokeServer`, minigame), kiểm tra lại `player.Parent` và dữ liệu còn tải (`DataService.IsLoaded`).
- Trạng thái tạm (minigame đang chơi, đang đập búa) lưu trong bộ nhớ server theo người chơi, **xoá khi `PlayerRemoving`**.

## Đồng bộ trạng thái toàn server (shop restock, thời tiết)
- Không lưu vào DataStore. Tính từ đồng hồ thật `os.time()` chia theo mốc (5 phút, 30 phút), dùng số mốc làm seed. Mọi server cho cùng kết quả.
- Logic này đặt trong `server/Systems`, giá trị chu kỳ đặt trong `shared/Config`.
