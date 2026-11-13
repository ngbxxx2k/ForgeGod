# 06 - Quy trình làm việc của AI

## Trước khi viết code
1. **Đọc file liên quan trước**: module sắp sửa, module nó gọi, và `DataTemplate`/`DataActions` nếu đụng dữ liệu.
2. Kiểm tra đã có hàm/module làm việc tương tự chưa. **Dùng lại, không viết trùng.**
3. Xác định file sẽ nằm ở thư mục nào theo file 02. Nếu không rõ thì hỏi.
4. Yêu cầu mơ hồ hoặc thiếu số liệu thiết kế (tỉ lệ, giá, thời gian): **hỏi người dùng**, không tự bịa. Nếu bắt buộc dùng giá trị tạm, ghi rõ `-- PLACEHOLDER:` và báo trong tóm tắt.

## Khi viết code
- Làm **một tính năng mỗi lần**. Không tiện tay "dọn dẹp" các file không liên quan.
- Thay đổi nhỏ nhất đủ để hoàn thành. Không viết lại cả file nếu chỉ cần sửa một hàm.
- Không thêm thư viện hoặc package mới khi chưa hỏi.
- Không sửa file cấu hình Rojo (`default.project.json`), `aftman.toml`, `wally.toml`, `.gitignore` khi chưa được yêu cầu.
- Không xoá code của người dùng. Nếu cần bỏ, giải thích lý do trong tóm tắt.
- Đặt đúng đuôi `.luau` và đúng tên (PascalCase cho module).

## Sau khi viết code, tự kiểm tra
- [ ] Đúng thư mục và đúng hướng phụ thuộc (file 02)?
- [ ] Có `--!strict` và kiểu cho hàm public (file 03)?
- [ ] Không còn số ma thuật, không `wait()`/`spawn()` cũ?
- [ ] Mọi dữ liệu từ client đã được kiểm tra trên server (file 04)?
- [ ] Mọi thay đổi dữ liệu đi qua `DataActions` (file 05)?
- [ ] Đã thêm `Init()` vào Bootstrap nếu là module mới?
- [ ] Comment tiếng Việt, tên tiếng Anh?

## Báo cáo kết quả (ngắn gọn, tiếng Việt)
Cuối mỗi tác vụ ghi:
1. **File đã tạo/sửa** (danh sách đường dẫn).
2. **Giá trị tạm (PLACEHOLDER)** hoặc giả định đã dùng.
3. **Cách test nhanh** trong Studio (1 đến 3 bước).
4. **Việc còn lại** (nếu có).

## Git
- Commit message tiếng Việt hoặc tiếng Anh nhất quán trong cả dự án: `<loại>: <mô tả ngắn>`, ví dụ `feat: thêm ShopService`, `fix: chặn bán vũ khí đang đeo`.
- Không commit file thử nghiệm, dữ liệu cá nhân hay token.
