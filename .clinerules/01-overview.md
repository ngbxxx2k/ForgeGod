# 01 - Tổng quan dự án và nguyên tắc chung

## Dự án
- Game Roblox "forgeGod": rèn vũ khí, bán lấy tiền, mua quặng và buff để rèn vũ khí xịn hơn.
- Ngôn ngữ: **Luau**. Công cụ: **Rojo + VSCode**. File dùng đuôi `.luau`.
- Mọi đường dẫn dưới đây tính từ thư mục `src/`.
- **Không được viết Comment code**

## Ngôn ngữ
- **Tên biến, hàm, module, file, remote: tiếng Anh.** Không đặt tên tiếng Việt không dấu.
- Thông báo hiển thị cho người chơi: tiếng Anh, đặt trong `shared/Constants` (không viết cứng trong logic).

## 5 nguyên tắc vàng
1. **Server là nguồn sự thật.** Tiền, vật phẩm, vũ khí, kết quả rèn đều do server quyết định. Client chỉ gửi "ý định" và hiển thị.
2. **Mỗi file một trách nhiệm.** Nếu mô tả file cần chữ "và" thì tách file.
3. **Không số ma thuật.** Tỉ lệ, giá, thời gian, giới hạn đặt trong `shared/Config` hoặc `shared/Constants`, hoặc `serverStorage/LootTables` nếu là số nhạy cảm (xem file 02).
4. **Sửa nhỏ, đúng chỗ.** Không viết lại file không liên quan, không đổi tên hàng loạt khi không được yêu cầu.
5. **Không chắc thì hỏi.** Nếu yêu cầu mơ hồ hoặc cần quyết định thiết kế, hỏi người dùng trước khi viết code.
