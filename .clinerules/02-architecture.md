# 02 - Kiến trúc và trách nhiệm từng thư mục

Kiểu tổ chức: **module thuần + Init()**, không dùng framework ngoài.
Mỗi Service/Controller/System là một ModuleScript, có hàm `Init()`. Chỉ `Bootstrap` mới gọi `Init()`.

## Server (`server/`)

| Thư mục | Chứa gì | Không được chứa |
|---|---|---|
| `Data/` | Lưu trữ: `DataTemplate`, `DataService`, `DataActions`, `LeaderboardService`, `ProfileStore` | Logic gameplay |
| `Services/` | Nghiệp vụ gameplay có API rõ ràng: `ForgeService`, `ShopService`, `InventoryService`... Xử lý yêu cầu từ client | Vòng lặp nền, truy cập DataStore trực tiếp |
| `Systems/` | Logic chạy nền theo thời gian cho cả server: thời tiết, restock shop, sự kiện | Xử lý yêu cầu từng người chơi |
| `Security/` | Kiểm tra hợp lệ, giới hạn tần suất (rate limit), chống exploit | Logic gameplay |
| `Internal/` | Hàm hỗ trợ chỉ server dùng, không hợp để vào `shared/Utils` | Logic nghiệp vụ |
| `Bootstrap.server.luau` | Script duy nhất khởi động server | Logic gameplay |

## Client (`client/`)

| Thư mục | Chứa gì |
|---|---|
| `Controllers/` | Logic client theo tính năng (`ShopController`, `ForgeController`...), có `Init()` |
| `Input/` | Bắt phím, chuột, cảm ứng; chuyển thành hành động |
| `UI/Screens/` | Màn hình lớn (Shop, Kho đồ, Bảng xếp hạng) |
| `UI/Components/` | Thành phần UI dùng lại (nút, ô vật phẩm, thanh tiến trình) |
| `Effects/` | Hiệu ứng hình ảnh/âm thanh phía client |
| `Bootstrap.client.luau` | Script duy nhất khởi động client |

## Dùng chung và tài nguyên

| Thư mục | Chứa gì |
|---|---|
| `shared/Config/` | Số liệu cân bằng game mà **client cũng cần biết** (giá hiển thị, giới hạn kho, tên hiển thị) |
| `shared/Constants/` | Hằng số, enum, tên vật phẩm, thông báo hiển thị |
| `shared/Network/` | Định nghĩa tên RemoteEvent/RemoteFunction, **một nơi duy nhất** |
| `shared/Types/` | `export type` dùng chung |
| `shared/Utils/` | Hàm thuần dùng cả hai phía (không phụ thuộc Service) |
| `serverStorage/LootTables/` | Tỉ lệ rơi, tỉ lệ vỡ, tỉ lệ mutation: **số nhạy cảm, không để client thấy** |
| `serverStorage/Templates/` | Mẫu object để clone (vũ khí, hiệu ứng) |
| `serverStorage/Models/` | Model chỉ server dùng |
| `assets/` | Animation, Effect, Model, Sound dùng chung |

## Hướng phụ thuộc (bắt buộc)

```
shared  <-  server
shared  <-  client
Systems -> Services -> Data -> ProfileStore
Security được Services gọi; Security không gọi Services
```

- `client` và `server` **không bao giờ** require nhau.
- `Data` không được require `Services` hay `Systems` (tránh vòng tròn phụ thuộc).
- Không require vòng tròn giữa hai module. Nếu cần, tách phần chung ra module thứ ba.
- Không đoán đường dẫn require. Xem `default.project.json` để biết thư mục nào map vào đâu.

## Khởi động (Bootstrap)

```lua
-- Bootstrap.server.luau: chỉ require và Init theo thứ tự, không có logic khác
local DataService = require(script.Parent.Data.DataService)
local LeaderboardService = require(script.Parent.Data.LeaderboardService)
-- ...

DataService.Init()
LeaderboardService.Init()
-- Thứ tự: Data -> Security -> Services -> Systems
```

- Thứ tự `Init()`: Data, rồi Security, rồi Services, rồi Systems.
- Thêm module mới thì thêm đúng một dòng require và một dòng `Init()` vào Bootstrap tương ứng.
- Không tạo thêm Script khác để khởi động riêng.

## Quy tắc tạo file/thư mục mới
- Đặt file vào thư mục đúng trách nhiệm ở bảng trên.
- **Không tạo thư mục mới ở cấp `src/` hoặc cấp con** khi chưa hỏi người dùng.
- Nếu không biết đặt file ở đâu, hỏi.
