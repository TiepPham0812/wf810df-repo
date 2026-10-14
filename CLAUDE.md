# Quy tắc dự án wf810df-repo (kho kmod)

## Vai trò
- **Kho gói kmod** cho FPT AX3000CV2 (WF-810DF) chạy firmware `TiepPham0812/wf810df-fw`. **Không build firmware** ở đây (chủ repo nói rõ 14/10/2026: firmware đã có ở wf810df-fw).
- Nguồn kmod duy nhất: `kmods-wf810df.tar.gz` trong Releases của wf810df-fw. Không biên dịch lại kmod: kmod phải đúng kernel của firmware đã nạp.

## Cơ chế (đã chạy thử 14/10/2026)
- `scripts/build-repo.sh`: Releases mới → cũ; thư mục `kmods/<kver>-<vermagic>/` (đổi `~` thành `-`), lấy từ tên `kernel-*.apk`; mỗi kernel lấy bản build mới nhất; lập lại `packages.adb` bằng `apk mkndx --sign`; cuốn chiếu theo `MAX_MB` (900, chủ repo chọn).
- Ký lại chỉ mục là đủ: ImmortalWrt không ký từng gói `.apk` (`apk mkpkg` không có `--sign`, chỉ `mkndx` ký). Mỗi bản build của wf810df-fw tự sinh khoá riêng (chưa đặt `APK_SIGN_KEY`), nên kho này phải dùng khoá cố định `REPO_SIGN_KEY`.
- apk-tools phải đúng bản ImmortalWrt đang dùng (`APK_TOOLS_REF` = commit trong `package/system/apk/Makefile`, hiện 3.0.5). Lên bản ImmortalWrt mới thì kiểm tra lại commit này.
- `router/setup.sh`: đọc `V:` của `P:kernel` trong `/lib/apk/db/installed`; chỉ gỡ dòng kho chứa `github.io/wf810df-fw/` hoặc `github.io/wf810df-repo/`, giữ dòng khác; thêm khoá vào `/etc/sysupgrade.conf`; kernel không có trong kho thì báo lỗi, không sửa gì. Biến `R=` chỉ để thử nghiệm.
- Bước 6 của workflow (giả lập router chỉ tin khoá kho, cài thử `kmod-wireguard` + `kmod-dsa-yt921x`) **không được nới lỏng hay xoá**.

## Quy tắc
- Không commit khoá riêng. Không ký bằng khoá tạm khi thiếu secret: workflow phải dừng.
- Không đổi cấu trúc đường dẫn `kmods/<dir>/packages.adb`, `kmods.txt`, `wf810df-repo.pem`, `setup.sh` khi chưa sửa đồng thời `router/setup.sh` (router đang dùng).
- Không push thẳng vào nhánh chính, không tự merge PR.
- Trả lời, mô tả Issue/PR bằng tiếng Việt.
