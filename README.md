# ToolVN

Bộ gõ tiếng Việt trên macOS (Input Method), dùng **Telex** và **VNI**, tương tự VNKey nhưng bạn tự build và cài trên máy cá nhân.

## Yêu cầu

- macOS 14 trở lên
- Xcode Command Line Tools (Swift)

```bash
xcode-select --install
```

## Lệnh Make

Chạy trong thư mục dự án:

```bash
cd /path/to/ToolVN
make help
```

| Lệnh | Mô tả |
|------|--------|
| `make build` | Biên dịch Input Method → `build/ToolVN.app` |
| `make install` | Build (nếu cần) và copy vào `~/Library/Input Methods/ToolVN.app`, đăng ký lại với hệ thống |
| `make reinstall` | Xóa bản cũ trong Input Methods, rồi `make install` |
| `make test` | Toàn bộ test (65 Telex + 23 VNI extended) |
| `make test-golden` | Chỉ bộ golden (47 + 18) |
| `make verify` | Smoke test nhanh vài từ Telex (`toolvn-verify`) |
| `make clean` | Xóa thư mục `build/` và `.build/` |

### Quy trình gợi ý

```bash
make test          # kiểm tra engine trước
make install       # cài bộ gõ
```

Sau khi cài lần đầu:

1. **Đăng xuất và đăng nhập lại** (hoặc khởi động lại máy) nếu chưa thấy icon / chế độ Telex–VNI.
2. **Cài đặt hệ thống → Bàn phím → Nguồn nhập → Thêm → ToolVN**.
3. Menu **Input** (biểu tượng bàn phím): chọn **ToolVN**, rồi **Telex** hoặc **VNI** (mục con).
4. ToolVN **không mở cửa sổ** khi double-click — đó là Input Method chạy nền.

Đổi Telex/VNI: menu Input → ToolVN → Telex hoặc VNI (hoặc `./Scripts/configure.sh telex|vni` rồi `./Scripts/reload-im.sh`).

Nếu macOS chặn app chưa ký:

```bash
xattr -cr ~/Library/Input\ Methods/ToolVN.app
```

## Test chi tiết (Swift)

```bash
swift run toolvn-test              # engine + VNI + gõ từng phím + regression
swift run toolvn-test --strict     # chỉ golden engine
swift run toolvn-test --typing     # chỉ mô phỏng gõ / corpus
swift run toolvn-test --matrix     # ma trận 6×5 thanh, mũ×thanh, đoạn văn, chuỗi tích lũy
swift run toolvn-test --long       # 20 đoạn Telex dài (~1860 ký tự gõ)
swift run toolvn-test -c perkeystroke_long
swift run toolvn-test -c perkeystroke_corpus
swift run toolvn-test -c matrix_plain
swift run toolvn-test --vni --strict
./Scripts/run-tests.sh
```

Case trong `Sources/ToolVNTestFixtures/`: **`PerKeystrokeTypingEngine`** (chuẩn gõ từng phím), `PerKeystrokeTypingRunner`, `TelexLongPassages`, `TelexTestMatrix`, `TelexCorpus`. Test engine batch (`TelexEngine.transform`) tách riêng; test gõ IME luôn **một bước / một phím**.

## Cấu hình bộ gõ

```bash
./Scripts/configure.sh telex    # Telex (mặc định)
./Scripts/configure.sh vni      # VNI
./Scripts/configure.sh on       # bật IME
./Scripts/configure.sh off      # tắt (gõ ASCII trong IME)
./Scripts/configure.sh status
```

Đổi nguồn nhập hoặc khởi động lại IME để áp dụng.

## Gõ Telex (tóm tắt)

| Gõ | Kết quả |
|-----|---------|
| `aa` `aw` `ee` `oo` `ow` `uw` `dd` | â ă ê ô ơ ư đ |
| `s` `f` `r` `x` `j` | sắc huyền hỏi ngã nặng |
| `z` | bỏ dấu thanh (trong từ đang gõ) |

Ví dụ: `vieetj` → việt, `khoongf` → khồng (không).

## Cấu trúc dự án

| Thư mục | Nội dung |
|---------|----------|
| `Sources/ToolVNCore/` | Engine Telex / VNI |
| `InputMethod/` | Input Method macOS (IMK) |
| `Sources/ToolVNTestFixtures/` | Bộ test |
| `Scripts/` | `build-im.sh`, `install.sh`, `configure.sh`, `run-tests.sh` |
| `build/ToolVN.app` | App sau `make build` |

## Script tương đương Make

| Make | Script |
|------|--------|
| `make build` | `./Scripts/build-im.sh` |
| `make install` | `./Scripts/install.sh` (tự build nếu chưa có `.app`) |
