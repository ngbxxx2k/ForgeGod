# 03 - Phong cách code

## Định dạng
- Thụt lề bằng **tab**. Một dòng không quá ~100 ký tự.
- Dòng đầu mọi file mới: `--!strict`. Nếu file gặp lỗi type không sửa được hợp lý, hạ xuống `--!nonstrict` kèm comment giải thích lý do.
- Khai báo kiểu cho tham số và giá trị trả về của hàm public.
- Mỗi file kết thúc bằng `return`, một dòng trống ở cuối.

## Đặt tên (tiếng Anh)

| Đối tượng | Kiểu | Ví dụ |
|---|---|---|
| File/module, type | PascalCase | `ForgeService`, `WeaponData` |
| Hàm public (có trong bảng module) | PascalCase | `ForgeService.TryForge` |
| Hàm local, biến local, tham số | camelCase | `local function rollMutation()` |
| Hằng số | UPPER_SNAKE_CASE | `MAX_EQUIPPED` |
| Biến boolean | tiền tố `is`/`has`/`can` | `isEquipped`, `canForge` |
| RemoteEvent | PascalCase, động từ | `RequestForge`, `NotifyCoinsChanged` |

- Tên phải nói rõ ý nghĩa. Không viết tắt khó hiểu (`wpn`, `tmp`, `val`). Cho phép: `id`, `i`, `dt`.
- File đặt tên đúng chữ hoa/thường của module (ví dụ `DataTemplate.luau`, **không** `Datatemplate.luau`). Lệch hoa/thường gây lỗi khi chạy trên Linux/CI và khi dùng git.

## Cấu trúc một module

```lua
--!strict
--[[
	ShopService
	Trách nhiệm: xử lý mua quặng và vật phẩm, quản lý tồn kho shop.
]]

local Players = game:GetService("Players")

local DataActions = require(script.Parent.Parent.Data.DataActions)

local MAX_BUY_PER_REQUEST = 99

local ShopService = {}

local isInitialized = false

-- Hàm local (private) đặt phía trên
local function canBuy(player: Player, itemId: string, amount: number): boolean
	-- ...
	return true
end

-- Hàm public
function ShopService.Buy(player: Player, itemId: string, amount: number): (boolean, string?)
	if not canBuy(player, itemId, amount) then
		return false, "InvalidRequest"
	end
	-- ...
	return true
end

function ShopService.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	-- kết nối Remote, tạo vòng lặp...
end

return ShopService
```

Thứ tự trong file: `--!strict` -> mô tả -> `GetService` -> `require` -> hằng số -> bảng module -> state local -> hàm local -> hàm public -> `Init` -> `return`.

## Viết hàm
- Một hàm làm một việc. Mục tiêu **≤ 40 dòng**, **≤ 3 cấp lồng nhau**.
- Dùng **early return** (kiểm tra lỗi trước, thoát sớm) thay vì `if` lồng sâu.
- Hàm có thể thất bại trả về `(ok: boolean, reason: string?)`. `reason` là mã ngắn (`"NotEnoughCoins"`), không phải câu văn.
- Không viết hàm "làm tất cả" nhận nhiều cờ boolean. Tách thành hàm riêng.

## Comment (tiếng Việt)
- Giải thích **vì sao**, không lặp lại **cái gì** mà code đã nói rõ.
- Đầu mỗi module: tên + trách nhiệm một hai dòng.
- Hàm public phức tạp: ghi ngắn tham số, kết quả, lỗi có thể xảy ra.
- Không để code cũ bị comment lại. Xoá hẳn (đã có git).
- `TODO:` phải kèm mô tả cụ thể, không để `TODO` trơ trọi.

## Cấm
- `wait()`, `spawn()`, `delay()` cũ. Dùng `task.wait`, `task.spawn`, `task.delay`.
- `:connect(` viết thường. Dùng `:Connect(`.
- Biến global, `_G`, `shared`. Chỉ dùng `local`.
- `while true do` không có `task.wait()` hoặc điều kiện thoát.
- Truyền thuộc tính Parent trong `Instance.new("X", parent)`. Gán `Parent` **sau cùng**.
- Để rò rỉ kết nối: kết nối gắn vào đối tượng có vòng đời (người chơi, UI) phải `Disconnect` khi đối tượng bị huỷ.
- Số hoặc chuỗi "ma thuật" lặp lại trong code (đưa vào Config/Constants).

## Xử lý lỗi và log
- Bọc `pcall` cho mọi thao tác có thể lỗi từ bên ngoài: DataStore, MemoryStore, HttpService, `MarketplaceService`.
- Không nuốt lỗi im lặng. Dùng `warn` với tiền tố module: `warn("[ShopService] Mua thất bại:", reason)`.
- Không dùng `print` để debug còn sót lại trong code hoàn thiện.
