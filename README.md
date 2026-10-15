# wf810df-repo – Kho kmod cho  (WF-810DF)

Kho gói để router **đang chạy firmware [wf810df-fw](https://github.com/TiepPham0812/wf810df-fw)** cài và cập nhật kmod qua **LuCI** hoặc **SSH** (`apk add`). Repo này **không build firmware**. Firmware nạp máy lấy ở `wf810df-fw`.

Trang kho: https://tieppham0812.github.io/wf810df-repo/

## Vì sao cần kho riêng

Firmware `wf810df-fw` dùng kernel tự build, nên kmod trong kho chính hãng ImmortalWrt không cài được: sai vermagic, `apk` báo lỗi. Kmod đúng kernel nằm trong file `kmods-wf810df.tar.gz` ở Releases của `wf810df-fw`, nhưng có hai trở ngại:

- Mỗi bản build tự ký bằng một khoá riêng, nên router chỉ tin chỉ mục kmod của đúng bản build nó đang chạy.
- Trang Pages của `wf810df-fw` chỉ giữ bản build mới nhất.

Repo này gom kmod của mọi bản build, **ký lại chỉ mục bằng một khoá cố định**, xếp theo kernel, rồi đăng lên GitHub Pages. Router tin khoá này một lần là dùng được mãi.

## Thiết lập trên router (một lần)

SSH vào router rồi chạy:

```sh
wget -qO- https://tieppham0812.github.io/wf810df-repo/setup.sh | sh
```

Script này làm các việc sau:

1. Đọc phiên bản kernel đang chạy (ví dụ `6.12.103~38a2e620…`) và kiểm tra kho có kmod cho kernel đó.
2. Cài khoá công khai `/etc/apk/keys/wf810df-repo.pem` và thêm khoá vào `/etc/sysupgrade.conf` để giữ qua nâng cấp.
3. Thay dòng kho kmod cũ của `wf810df-fw` trong `/etc/apk/repositories.d/customfeeds.list` bằng thư mục đúng kernel. Các dòng khác giữ nguyên.
4. Chạy `apk update`.

Sau đó cài gói như bình thường:
- **LuCI:** Hệ thống → Phần mềm.
- **SSH:** `apk add kmod-<tên>`.

Gói không phải kmod vẫn lấy từ kho chính hãng ImmortalWrt.

**Sau mỗi lần nâng cấp firmware, chạy lại lệnh trên.** Kernel mới nằm ở thư mục khác; nếu giữ dòng kho cũ thì `apk` sẽ từ chối cài vì không khớp kernel.

## Cách kho được cập nhật

Workflow **Cap nhat kho kmod WF810DF** chạy 3 giờ một lần, chạy khi bấm tay, và chạy khi sửa script:

1. Đọc Releases của `wf810df-fw`. Nếu không có gì mới so với trang đang chạy thì dừng ngay.
2. Duyệt các bản build từ mới đến cũ. Mỗi kernel (phiên bản + vermagic) chỉ lấy bản build mới nhất.
3. Lập lại `packages.adb` cho từng kernel, ký bằng secret `REPO_SIGN_KEY`. Các gói `.apk` của ImmortalWrt không mang chữ ký riêng, chỉ chỉ mục được ký.
4. **Cuốn chiếu:** khi tổng dung lượng chạm 900 MB (`MAX_MB`) thì bỏ các kernel cũ nhất. Kmod của chúng vẫn còn trong Releases của `wf810df-fw`.
5. Trước khi đăng, giả lập một router chỉ tin khoá của kho và cài thử `kmod-wireguard`, `kmod-dsa-yt921x` cho từng kernel.

apk-tools được dựng đúng bản ImmortalWrt 25.12 đang dùng (3.0.5).

## Thiết lập một lần cho repo

1. **Settings → Pages → Build and deployment → Source: GitHub Actions.**
2. **Tạo khoá ký**, rồi dán vào **Settings → Secrets and variables → Actions → New repository secret**, đặt tên `REPO_SIGN_KEY`. Tạo khoá bằng một trong hai cách:
   - Trên router (SSH): `apk add openssl-util && openssl ecparam -name prime256v1 -genkey -noout`, rồi copy toàn bộ khối `-----BEGIN EC PRIVATE KEY----- … -----END EC PRIVATE KEY-----`.
   - Trên Windows có Git Bash: chạy cùng lệnh `openssl ecparam …`.

   Không commit khoá này vào repo. Nếu đổi khoá, mọi router phải chạy lại `setup.sh`.
3. **Actions → Cap nhat kho kmod WF810DF → Run workflow.**

## Giới hạn

- Kho chỉ có kmod của những kernel đã build ở `wf810df-fw`. Muốn **đổi cấu hình kernel** (bật hoặc tắt tính năng trong kernel) thì phải build firmware mới ở `wf810df-fw` và nạp lại. `apk` không thay được kernel đang chạy.
- Các bản build có cùng vermagic dùng chung kmod của bản mới nhất. Đây là cách OpenWrt và ImmortalWrt vẫn xác định tính tương thích của kmod.
