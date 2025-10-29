# ghep-mp4-ffmpeg-nhanh

Script PowerShell `__merge_parts.ps1` giúp ghép nhiều file MP4 bằng ffmpeg theo lô (batch) để tránh concat quá nhiều file trong một lần.

## Yêu cầu

- Windows PowerShell
- ffmpeg có trong PATH (có thể kiểm tra bằng `ffmpeg -version`)

## Cách dùng

1. Đặt các file `*.mp4` cần ghép vào cùng thư mục chứa `__merge_parts.ps1`.
2. Mở PowerShell trong thư mục đó.
3. Chạy script (ví dụ ghép mỗi 6 file thành một phần):

```powershell
.\__merge_parts.ps1 -BATCH 6
```

Tham số `-BATCH` là số file sẽ ghép thành một phần trước khi tạo file phần (`__parts\part_1.mp4`, `part_2.mp4`, ...).

Script sẽ:

- Tạo thư mục `__parts` để lưu file phần và danh sách `list_part_*.txt`.
- Tạo file `part_N.mp4` bằng concat copy (`-c copy`). Nếu thất bại, script sẽ thử re-encode bằng `h264_nvenc` nếu máy có NVENC, còn không thì dùng `libx264`.
- Sau khi tạo các `part_*.mp4`, script sẽ ghép các phần này thành `output.mp4` ở thư mục gốc.

## Tùy chọn & gợi ý

- Nếu bạn muốn force re-encode (không dùng `-c copy`), chỉnh script để thay đổi lệnh ffmpeg.
- Đảm bảo tên file không chứa ký tự đặc biệt gây lỗi khi ghi vào file danh sách.

## Vấn đề thường gặp

- Lỗi `ffmpeg` không tìm thấy: cài ffmpeg và thêm vào PATH.
- Nếu concat-copy thất bại do codec/timebase mismatch, script tự fallback sang re-encode.

## Cách đẩy lên GitHub

Nếu bạn muốn đẩy repo này lên GitHub (đã có repo sẵn):

```powershell
git init
git remote add origin https://github.com/hungzero168/ghep-mp4-ffmpeg-nhanh.git
git add .
git commit -m "Add README and merge script"
git branch -M main
git push -u origin main
```

Thay `main` bằng `master` nếu repo sử dụng `master`.

---

Nếu bạn muốn, tôi có thể giúp tạo commit và push trực tiếp từ workspace này. Hãy xác nhận để tôi tiếp tục.
