# Arch + Hyprland Auto Installation

Tự động cài Arch Linux với Hyprland (dành cho máy thật và VirtualBox). Có `auto.sh` (chung). `vm/virtualbox.sh` là script hỗ trợ chạy SAU khi `auto.sh` hoàn tất — chỉ dùng nếu cài trên VirtualBox và gặp vấn đề!

## ✨ Tính năng
- Cài tự động từ ArchISO; hỗ trợ UEFI/BIOS
- Phát hiện GPU và cài driver phù hợp (NVIDIA / Intel / AMD)
- Hyprland + Kitty + Wofi, SDDM, NetworkManager
- Kiểm tra log và khắc phục cơ bản
- Script tối ưu cho VirtualBox: `vm/virtualbox.sh`

## ⚠️ Hỗ trợ

| Hệ thống | Trạng thái |
|---------|-----------|
| Máy thật | ✅ |
| VirtualBox | ⚠️ (xem lưu ý) |
| KVM/QEMU/Hyper-V | ❌ |

### 🚨 VirtualBox & Hyprland
- Hyprland cần GPU acceleration; VirtualBox có giới hạn cho Wayland.
- Trước khi cài trên VM: bật `3D Acceleration`, cấp >=4GB RAM và >=2 CPU cores.
- Trong hệ đích, cài Guest Additions: `pacman -S virtualbox-guest-utils`.
- Nếu Hyprland không chạy: chuyển sang Openbox/Xfce hoặc dùng Xorg.

`vm/virtualbox.sh` là trợ giúp hậu cài: cài guest utils (tuỳ hệ), bật service, in hướng dẫn cấu hình VM, và áp một số sửa lỗi/khuyến nghị riêng cho VirtualBox. Chạy nó chỉ khi đã chạy `auto.sh` và gặp lỗi hoặc khi muốn áp cấu hình VM bổ sung. Nó không thay thế `auto.sh` và không đảm bảo Hyprland chạy 100% trên mọi VM.

## 📋 Yêu cầu
- Arch ISO, 20GB+ (40GB khuyến nghị), internet, 2GB+ RAM (4GB+ cho VM)

## 🚀 Cài đặt nhanh
1. Boot ArchISO và kiểm tra mạng: `ping 8.8.8.8`.
2. Lấy script:
```bash
git clone https://github.com/dhungx/arch-auto-install.git
cd arch-auto-install
chmod +x auto.sh vm/virtualbox.sh
```
3) Chạy cài (mọi trường hợp):
```bash
sudo ./auto.sh
```
4) Nếu cài trên VirtualBox và gặp lỗi liên quan tới Wayland/Hyprland hoặc muốn áp thêm cấu hình Guest Additions, chạy (sau khi `auto.sh` hoàn tất):
```bash
sudo ./vm/virtualbox.sh
```

Trong quá trình cài bạn sẽ trả lời một số câu hỏi cơ bản. Ví dụ:

| Câu hỏi | Mặc định | Ví dụ |
|---|---|---|
| Ngôn ngữ | Tiếng Việt | `1=EN` |
| Múi giờ | Ho Chi Minh | `2=Seoul` |
| Tên người dùng | `user` | `john` |
| Hostname | `tyno` | `myarch` |
| Mật khẩu | (trống = mặc định) | — |
| Thiết bị cài | — | `/dev/sda` (không phải `/dev/sda1`) |

⚠️ Xác nhận format: gõ `FORMAT /dev/sdX` rồi `YES` để tiếp tục.

## 🔧 Khắc phục nhanh
- Boot lỗi: mount, `arch-chroot /mnt` → `mkinitcpio -P` → reboot
- Quên password: `arch-chroot /mnt` → `passwd username`
- NVIDIA lỗi: `pacman -S nvidia nvidia-utils` → `mkinitcpio -P`
- Hyprland trên VM: đảm bảo Guest Additions, 3D bật, hoặc dùng DE nhẹ

Log cài: `/tmp/arch-install-v3.log`

## ⌨️ Phím tắt Hyprland (mặc định)
```
Super + Return → Terminal (Kitty)
Super + D      → Launcher (Wofi)
Super + C      → Close window
Super + V      → Fullscreen
Super + H/J/K/L→ Move focus
Super + Arrow  → Resize
```

## 📦 Gói cài (tóm tắt)
- Base: `linux`, `base-devel`, `grub`, `efibootmgr`
- Desktop: `hyprland`, `kitty`, `wofi`, `sddm`
- Audio: `pipewire`, `wireplumber`
- GPU: `nvidia` hoặc `mesa`

## 📊 Tỷ lệ thành công (tham khảo)
| Kịch bản | Xác suất |
|---------|---------:|
| Hardware mới (2020+, Ethernet, SSD) | 85–90% |
| Hardware trung bình (2015–2019) | 65–75% |
| VirtualBox (4GB+) | 80–85% |

Không phải lỗi script luôn do hardware/mạng/ảo hoá.

Lưu ý quan trọng: script không đảm bảo thành công 100% — kết quả phụ thuộc phần cứng, cấu hình (máy thật hoặc VM), kết nối mạng và một phần "may mắn":)) Hãy kiểm tra `/tmp/arch-install-v3.log` nếu gặp lỗi và chuẩn bị phương án dự phòng.

## 📚 Tài liệu
- Arch Wiki: https://wiki.archlinux.org/
- Hyprland Docs: https://wiki.hyprland.org/
- Log: `file:///tmp/arch-install-v3.log`

## 📝 License
FIXED V3 2025 — Arch + Hyprland Auto Install

---

**Mẹo:** kiểm tra `/tmp/arch-install-v3.log` nếu cài thất bại
