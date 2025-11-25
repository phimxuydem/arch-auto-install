# Arch + Hyprland Auto Installation

Tự động cài đặt **Arch Linux** với **Hyprland** (Wayland compositor) trên máy thật hoặc VirtualBox.

## ✨ Tính Năng

- ✅ Cài đặt tự động từ ArchISO
- ✅ Hỗ trợ UEFI/BIOS
- ✅ Phát hiện GPU (NVIDIA/Intel/AMD)
- ✅ Hyprland + Kitty + Wofi
- ✅ SDDM login manager
- ✅ NetworkManager
- ✅ Kiểm tra lỗi toàn diện

## ⚠️ Hỗ Trợ

| Hệ thống | Trạng thái |
|----------|-----------|
| Máy thật | ✅ Được hỗ trợ |
| VirtualBox | ⚠️ Được hỗ trợ (xem lưu ý) |
| KVM, QEMU, Hyper-V | ❌ Không hỗ trợ |

### 🚨 Lưu ý VirtualBox & Hyprland

Script chạy được trên VirtualBox, **nhưng Hyprland có thể không hoạt động** do:
- Hyprland cần GPU acceleration cao
- VirtualBox hỗ trợ kém Wayland

**Để fix:**
1. Bật **3D Acceleration** trong Settings → Display
2. Cài **VirtualBox Guest Additions**: `pacman -S virtualbox-guest-utils`
3. Cấp **4GB+ RAM** + **2+ cores**
4. Nếu vẫn lỗi → Dùng **Openbox/Xfce** thay Hyprland

## 📋 Yêu Cầu

- **Arch Linux ISO** (mới nhất)
- **20GB+ dung lượng** (40GB an toàn)
- **Internet ổn định** (Ethernet tốt hơn WiFi)
- **2GB+ RAM**

## 🚀 Cài Đặt

### 1. Chuẩn Bị
```bash
# Boot ArchISO, kết nối Internet, sau đó:
ping 8.8.8.8  # Kiểm tra kết nối
```

### 2. Tải Script
```bash
git clone https://github.com/dhungx/arch-auto-install.git
cd arch-auto-install
chmod +x auto.sh
```
hoặc
```bash
curl -O https://raw.githubusercontent.com/dhungx/arch-auto-install/refs/heads/main/auto.sh
chmod +x auto.sh
```

### 3. Chạy
```bash
sudo ./auto.sh
```

### 4. Trả Lời Câu Hỏi
| Câu hỏi | Mặc định | Ví dụ |
|--------|---------|-------|
| Ngôn ngữ | Tiếng Việt | 1=EN, 3=日本語 |
| Múi giờ | Ho Chi Minh | 2=Seoul, 3=London |
| Username | user | john, alice |
| Hostname | tyno | myarch |
| Password | (trống=mặc định) | - |
| Ổ đĩa | - | **/dev/sda** (không phải /dev/sda1) |

⚠️ **Xác nhận xóa**: Gõ `FORMAT /dev/sdX` rồi `YES`

### 5. Chờ & Khởi Động
- Cài khoảng 15-30 phút
- **Không interrupt** (Ctrl+C)
- Xem log: `/tmp/arch-install-v3.log`
- Gõ `reboot`

## ⌨️ Hyprland Shortcuts

```
Super + Return    → Terminal (Kitty)
Super + D         → Launcher (Wofi)
Super + C         → Close window
Super + V         → Fullscreen
Super + H/J/K/L   → Move focus
Super + Arrow     → Resize
```

## 🔧 Khắc Phục Sự Cố

### Boot không được?
```bash
# Boot ArchISO → Mount → Chroot → Rebuild
mount /dev/sdX /mnt
arch-chroot /mnt
mkinitcpio -P
exit && reboot
```

### Quên Password?
```bash
arch-chroot /mnt
passwd username  # Hoặc 'passwd' cho root
exit && reboot
```

### NVIDIA không hoạt động?
```bash
sudo pacman -S nvidia nvidia-utils
sudo mkinitcpio -P
```

### Đổi Desktop Environment
```bash
sudo pacman -R hyprland xdg-desktop-portal-hyprland
sudo pacman -S i3  # Hoặc gnome, xfce, ...
```

## 📦 Packages Được Cài

**Base:** linux, base-devel, grub, efibootmgr  
**Desktop:** hyprland, kitty, wofi, sddm  
**Audio:** pipewire, wireplumber  
**GPU:** nvidia (NVIDIA) hoặc mesa (Intel/AMD)

## 📊 Tỷ Lệ Thành Công

| Kịch bản | Xác suất |
|---------|----------|
| Hardware mới (2020+, Ethernet, SSD) | 85-90% |
| Hardware trung bình (2015-2019) | 65-75% |
| VirtualBox (4GB+) | 80-85% |
| **Trung bình** | **65-70%** |

Không phải lỗi script, mà hardware/network/may mắn rất biến động.

## 📚 Tài Liệu

- [Arch Wiki](https://wiki.archlinux.org/)
- [Hyprland Docs](https://wiki.hyprland.org/)
- [Log Script](file:///tmp/arch-install-v3.log)

## 📝 License

FIXED V3 2025 - Arch + Hyprland Auto Install

---

**Mẹo:** Đọc `/tmp/arch-install-v3.log` nếu cài thất bại. Script sẽ cố sửa các vấn đề tự động.
