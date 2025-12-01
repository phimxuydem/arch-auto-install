# Arch + Hyprland Auto Installation – Hướng Dẫn Đầy Đủ V3.2

Tự động cài Arch Linux với Hyprland (dành cho máy thật và VirtualBox). Script được cải tiến V3.2 với các tính năng thông minh hơn.

---

## 📑 Mục Lục

1. [Tính Năng Chính](#tính-năng-chính)
2. [Cải Tiến V3.2](#cải-tiến-v32--mới)
3. [Yêu Cầu & Hỗ Trợ](#yêu-cầu--hỗ-trợ)
4. [Cài Đặt Nhanh](#cài-đặt-nhanh)
5. [Cải Tiến Chi Tiết](#cải-tiến-chi-tiết)
6. [Sử Dụng & Tùy Chỉnh](#sử-dụng--tùy-chỉnh)
7. [Khắc Phục Sự Cố](#khắc-phục-sự-cố)
8. [Phím Tắt & Gói Cài](#phím-tắt--gói-cài)
9. [Tỷ Lệ Thành Công](#tỷ-lệ-thành-công)
10. [Tài Liệu Tham Khảo](#tài-liệu-tham-khảo)

---

## ✨ Tính Năng Chính

- ✅ Cài tự động từ ArchISO; hỗ trợ UEFI/BIOS
- ✅ Phát hiện GPU và cài driver phù hợp (NVIDIA / Intel / AMD)
- ✅ Hyprland + Kitty + Wofi, SDDM, NetworkManager
- ✅ Kiểm tra log chi tiết và hướng dẫn khắc phục
- ✅ Script tối ưu cho VirtualBox: `vm/virtualbox.sh`
- ✅ Pacman keyring tự động refresh & update
- ✅ Phát hiện kernel thông minh (hỗ trợ linux-lts, linux-zen, etc.)
- ✅ Cấu hình swap động dựa trên RAM
- ✅ AUR packages cấu hình linh hoạt

---

## 🚀 Cải Tiến V3.2 – Mới

### 1. 🧠 Swap Partition Thông Minh

**Tính toán tự động dựa trên RAM:**
```
RAM ≤ 8GB   → swap = 2 × RAM
RAM 8–16GB  → swap = RAM
RAM > 16GB  → swap = 16GB
```

**Các cải tiến:**
- ✅ Hiển thị thông tin RAM chi tiết (GB + MB)
- ✅ Cảnh báo nếu RAM >32GB nhưng swap nhỏ
- ✅ Ghi log byte-level: `8589934592 bytes = 8GB (8192MB)`
- ✅ Gợi ý về hibernation cho hệ thống lớn
- ✅ Cho phép người dùng tùy chỉnh kích thước swap

**Ví dụ:**
```
Detected RAM: 16GB (16384MB).
Suggested swap size: 16GB
   (1) Nhập số GB tùy chỉnh (ví dụ: 32)
   (2) Bấm Enter để dùng giá trị đề xuất (16GB)
→ Chọn:
```

---

### 2. 🔧 Phát Hiện Kernel & Initramfs Thông Minh

**Hỗ trợ các kernel tùy chỉnh:**
- ✅ `linux` (kernel chuẩn)
- ✅ `linux-lts` (hỗ trợ dài hạn)
- ✅ `linux-zen` (tối ưu hóa)
- ✅ `linux-hardened` (bảo mật tăng cường)
- ✅ Bất kỳ kernel tùy chỉnh nào

**Cách hoạt động:**
1. Liệt kê tất cả kernel có sẵn
2. Chọn kernel **mới nhất** theo timestamp
3. Tìm `initramfs` phù hợp
4. Ghi log DEBUG chi tiết

**Ví dụ output:**
```
DEBUG: Available kernels in /boot: /boot/vmlinuz-linux, /boot/vmlinuz-linux-lts
DEBUG: Selected kernel: vmlinuz-linux-lts (kernel type: linux-lts)
DEBUG: Matched initramfs: /boot/initramfs-linux-lts.img
✓ Detected & using kernel: vmlinuz-linux-lts with initramfs: initramfs-linux-lts.img
```

---

### 3. 📦 Cài Đặt AUR Cải Tiến

**A. Kiểm tra Build Dependencies:**
```
Đảm bảo build dependencies (base-devel, git, make) có sẵn...
✓ Build-dep 'base-devel' available
✓ Build-dep 'git' available
✓ Build-dep 'make' available
```

**B. Danh sách gói AUR tùy chỉnh:**
```bash
AUR_PACKAGES=(
    "hyprland" "hyprgrass" "wlogout" "waypaper" "waybar" "swww" "rofi-wayland" "swaync"
    "nemo" "kitty" "pavucontrol" "gtk3" "gtk2" "xcur2png" "gsettings"
    "nwg-look" "fastfetch" "zsh" "oh-my-zsh-git" "hyprshot"
    "networkmanager" "networkmanager-qt" "nm-connection-editor"
    "ttf-firacode-nerd" "nerd-fonts-jetbrains-mono"
)
```

Chỉ cần sửa mảng này để thêm/xóa gói!

**C. Ghi log chi tiết:**
- Mỗi gói có file log riêng: `/tmp/aur_<package>.log`
- yay build được retry tới 3 lần
- Log chi tiết: `/tmp/yay_build_1.log`, `/tmp/yay_build_2.log`, etc.

**D. Báo cáo cuối cùng:**
```
[+] ✓ All AUR packages installed successfully
```
hoặc
```
[!] Failed AUR packages: package1, package2
[!] Logs available in /tmp/aur_<package>.log for debugging
```

---

### 4. 📋 Ghi Log & Debug Cải Tiến

**File log chính:**
```bash
/tmp/arch-install-v3.log  # Log cài đặt chính
```

**Kiểm tra thông tin swap:**
```bash
grep "Creating swap\|Swap" /tmp/arch-install-v3.log
```

**Kiểm tra kernel được chọn:**
```bash
grep "DEBUG.*kernel\|Detected & using" /tmp/arch-install-v3.log
```

**Kiểm tra AUR fail:**
```bash
cat /tmp/aur_<package-name>.log
```

---

## ⚠️ Yêu Cầu & Hỗ Trợ

### Yêu Cầu Hệ Thống
- Arch ISO, 20GB+ (40GB khuyến nghị), internet
- 2GB+ RAM (4GB+ cho VM)
- Kết nối Ethernet hoặc WiFi ổn định

### Hỗ Trợ

| Hệ thống | Trạng thái | Ghi chú |
|---------|-----------|--------|
| Máy thật | ✅ | Hỗ trợ đầy đủ |
| VirtualBox | ⚠️ | Xem lưu ý bên dưới |
| KVM/QEMU/Hyper-V | ❌ | Không hỗ trợ |

### 🚨 VirtualBox & Hyprland
- Hyprland cần GPU acceleration; VirtualBox có giới hạn cho Wayland.
- Trước khi cài trên VM: **bật `3D Acceleration`**, cấp **>=4GB RAM** và **>=2 CPU cores**.
- Trong hệ đích, cài Guest Additions: `pacman -S virtualbox-guest-utils`.
- Nếu Hyprland không chạy: chuyển sang Openbox/Xfce hoặc dùng Xorg.

`vm/virtualbox.sh` là trợ giúp hậu cài: cài guest utils, bật service, in hướng dẫn cấu hình VM, và áp một số sửa lỗi riêng cho VirtualBox. **Chỉ chạy khi đã chạy `auto.sh` và gặp lỗi hoặc muốn áp thêm cấu hình.**

---

## 🚀 Cài Đặt Nhanh

### Bước 1: Boot ArchISO & Kiểm Tra Mạng
```bash
ping 8.8.8.8
```

### Bước 2: Lấy Script
```bash
git clone https://github.com/phimxuydem/arch-auto-install.git
cd arch-auto-install
chmod +x auto.sh vm/virtualbox.sh
```

### Bước 3: Chạy Cài (Mọi Trường Hợp)
```bash
sudo ./auto.sh
```

### Bước 4 (Nếu Cần): VirtualBox Post-Install
```bash
sudo ./vm/virtualbox.sh
```

### Trả Lời Câu Hỏi Cài Đặt

| Câu hỏi | Mặc định | Ví dụ |
|---|---|---|
| Ngôn ngữ | Tiếng Việt (2) | `1=English`, `3=日本語` |
| Múi giờ | Ho Chi Minh (1) | `2=Seoul`, `3=London` |
| Tên người dùng | `user` | `john`, `alice` |
| Hostname | `tyno` | `myarch`, `desktop` |
| Mật khẩu | (trống = mặc định) | Nhập hoặc bỏ trống |
| Kích thước swap | (tính tự động) | Nhập tùy chỉnh hoặc Enter |
| Thiết bị cài | — | `/dev/sda` (**không** `/dev/sda1`) |

⚠️ **Xác nhận format:** Gõ `FORMAT /dev/sdX` rồi `YES` để tiếp tục.

### Khi Được Hỏi Kích Thước Swap

```
Detected RAM: 16GB (16384MB).
Suggested swap size: 16GB
   (1) Nhập số GB tùy chỉnh (ví dụ: 32)
   (2) Bấm Enter để dùng giá trị đề xuất (16GB)
→ Chọn:
```

**Gợi ý:**
- Nhấn Enter để chấp nhận giá trị đề xuất
- Nhập số GB để tùy chỉnh (ví dụ: `32` cho 32GB swap)
- Nếu RAM >32GB và muốn hibernation: nhập kích thước = RAM

---

## 🔍 Cải Tiến Chi Tiết

### Cải Tiến 1: Swap Sizing

**Vị trí trong script:** Lines 285–315, 390–413

**Thay đổi:**
- RAM được đọc từ `/proc/meminfo` chính xác
- Hiển thị cả GB và MB
- Cảnh báo nếu RAM >32GB
- Cho phép tùy chỉnh kích thước
- Ghi log byte-level trước mkswap
- Hiển thị ✓ khi thành công

**Ví dụ:**
```
Detected RAM: 64GB (65536MB).
Suggested swap size: 16GB
⚠ RAM rất lớn (>32GB). Swap hiện tại chỉ 16GB.
   → Nếu bạn muốn dùng hibernate, bạn cần swap ≥ RAM (64GB).

Creating swap on /dev/sda2: 8589934592 bytes = 8GB (8192MB)
✓ Swap partition created and formatted
✓ Swap activated
```

---

### Cải Tiến 2: Kernel Detection

**Vị trí trong script:** Lines 677–747

**Thay đổi:**
- Tìm tất cả kernel trong `/boot`
- Chọn kernel mới nhất theo timestamp
- Khớp initramfs với kernel type
- Debug log chi tiết
- Hỗ trợ kernel tùy chỉnh

**Hỗ trợ kernel:**
- ✅ linux
- ✅ linux-lts
- ✅ linux-zen
- ✅ linux-hardened
- ✅ Custom kernel

**Ví dụ debug output:**
```
DEBUG: Available kernels in /boot: /boot/vmlinuz-linux, /boot/vmlinuz-linux-lts
DEBUG: Selected kernel: vmlinuz-linux-lts (kernel type: linux-lts)
DEBUG: Matched initramfs: /boot/initramfs-linux-lts.img
✓ Detected & using kernel: vmlinuz-linux-lts with initramfs: initramfs-linux-lts.img
```

---

### Cải Tiến 3: Build Dependencies

**Vị trí trong script:** Lines 611–619

**Thay đổi:**
- Kiểm tra riêng lẻ: `base-devel`, `git`, `make`
- Báo cáo trạng thái từng gói
- Tiếp tục nếu một số package fail (best-effort)

**Ví dụ:**
```
Đảm bảo build dependencies (base-devel, git, make) có sẵn...
✓ Build-dep 'base-devel' available
✓ Build-dep 'git' available
✓ Build-dep 'make' available
```

---

### Cải Tiến 4: AUR Packages

**Vị trí trong script:** Lines 816–882

**Thay đổi:**
- Mảng `AUR_PACKAGES` dễ tùy chỉnh
- Kiểm tra riêng lẻ từng gói
- Log file cho từng gói: `/tmp/aur_<package>.log`
- yay build retry 3 lần với log
- Báo cáo summary chi tiết

**Tùy chỉnh gói:**
```bash
AUR_PACKAGES=(
    "hyprland" "hyprgrass" # Keep
    "new-package-here"      # Add
    # "remove-by-commenting" # Skip
)
```

**Báo cáo cuối:**
```
[+] ✓ All AUR packages installed successfully
```

---

## 📋 Sử Dụng & Tùy Chỉnh

### Sửa Kích Thước Swap

Edit `auto.sh`, tìm dòng:
```bash
RAM_GB=$(( (RAM_KB / 1024 / 1024) ))
```

Sửa công thức tính toán nếu cần.

### Thêm/Xóa AUR Packages

Edit `auto.sh`, tìm mảng `AUR_PACKAGES` (quanh dòng 827):

**Thêm gói:**
```bash
AUR_PACKAGES=(
    "existing_packages"
    "new_package_here"  # Thêm
)
```

**Xóa gói:**
```bash
# "package_to_remove"  # Comment để bỏ
```

### Thay Đổi Số Lần Retry yay

Edit `auto.sh`, tìm:
```bash
MAX_TRIES=3
```

Sửa thành số lần cần thiết.

### Kiểm Tra Log Installation

**Main log:**
```bash
tail -100 /tmp/arch-install-v3.log
```

**yay build logs:**
```bash
cat /tmp/yay_build_1.log
cat /tmp/yay_build_2.log
cat /tmp/yay_build_3.log
```

**AUR package logs:**
```bash
cat /tmp/aur_hyprland.log
cat /tmp/aur_waybar.log
cat /tmp/aur_<package>.log
```

---

## 🔧 Khắc Phục Sự Cố

### Boot Lỗi
```bash
# Mount và chroot vào hệ cài
mount /dev/sdaX /mnt
arch-chroot /mnt
mkinitcpio -P
exit
reboot
```

### Quên Password
```bash
arch-chroot /mnt
passwd username
```

### NVIDIA Driver Lỗi
```bash
pacman -S nvidia nvidia-utils
mkinitcpio -P
reboot
```

### Hyprland Không Chạy
- Đảm bảo Guest Additions cài (VirtualBox)
- Bật 3D Acceleration
- Hoặc dùng DE nhẹ hơn

### Kiểm Tra Kernel Được Chọn
```bash
grep "Detected & using kernel" /tmp/arch-install-v3.log
```

### Kiểm Tra Swap
```bash
grep "Creating swap\|Swap" /tmp/arch-install-v3.log
swapon --show
```

### Kiểm Tra AUR Fail
```bash
# Tìm gói fail
grep "Failed AUR packages" /tmp/arch-install-v3.log

# Xem chi tiết
cat /tmp/aur_package_name.log
```

---

## ⌨️ Phím Tắt Hyprland (Mặc Định)

```
Super + Return → Terminal (Kitty)
Super + D      → Launcher (Wofi)
Super + C      → Close window
Super + V      → Fullscreen
Super + H/J/K/L→ Move focus
Super + Arrow  → Resize
Super + Q      → Quit Hyprland
Super + E      → File manager
Super + B      → Firefox
```

---

## 📦 Gói Cài (Tóm Tắt)

### Base System
- `linux`, `base-devel`, `grub`, `efibootmgr`
- `git`, `vim`, `sudo`, `curl`

### Desktop Environment
- `hyprland`, `kitty`, `wofi`, `sddm`
- `xdg-desktop-portal-hyprland`

### Window Manager & Tools
- `wlogout`, `waypaper`, `waybar`, `swww`
- `rofi-wayland`, `swaync`, `nemo`

### Audio
- `pipewire`, `wireplumber`, `pipewire-pulse`
- `pavucontrol`

### GPU Drivers
- **NVIDIA:** `nvidia`, `nvidia-utils`, `lib32-nvidia-utils`
- **Intel/AMD:** `mesa`, `lib32-mesa`
- **Common:** `vulkan-icd-loader`, `lib32-vulkan-icd-loader`

### Fonts & Themes
- `ttf-firacode-nerd`, `nerd-fonts-jetbrains-mono`
- `archlinux-wallpaper`

### Shell & Tools
- `zsh`, `oh-my-zsh-git`
- `fastfetch`, `hyprshot`

### Network
- `networkmanager`, `networkmanager-qt`, `nm-connection-editor`

---

## 📊 Tỷ Lệ Thành Công

| Kịch bản | Xác suất | Ghi chú |
|---------|---------:|---------|
| Hardware mới (2020+) | 85–90% | SSD, Ethernet, GPU mới |
| Hardware trung bình (2015–2019) | 65–75% | HDD/SSD, WiFi OK |
| VirtualBox (4GB+) | 80–85% | Cần 3D bật, Guest Additions |
| Laptop (WiFi, hybrid GPU) | 70–80% | Có thể cần setup bổ sung |

**Lưu ý:** Không phải lỗi script luôn do hardware/mạng/ảo hoá.

**Quan trọng:** Script không đảm bảo thành công 100% — kết quả phụ thuộc vào:
- Phần cứng
- Cấu hình (máy thật hoặc VM)
- Kết nối mạng
- Một phần "may mắn" :)

Kiểm tra `/tmp/arch-install-v3.log` nếu gặp lỗi!

---

## 📚 Tài Liệu Tham Khảo

### Tài Liệu Chính
- **Arch Wiki:** https://wiki.archlinux.org/
- **Hyprland Docs:** https://wiki.hyprland.org/
- **Installation Log:** `/tmp/arch-install-v3.log`

### Log Files
- **Main installation log:** `/tmp/arch-install-v3.log`
- **yay build logs:** `/tmp/yay_build_*.log`
- **AUR package logs:** `/tmp/aur_<package>.log`
- **Swap info:** `grep "Creating swap" /tmp/arch-install-v3.log`
- **Kernel info:** `grep "Detected & using" /tmp/arch-install-v3.log`

### Useful Commands
```bash
# View full installation log
tail -100 /tmp/arch-install-v3.log | less

# Search for errors
grep "ERROR\|Failed" /tmp/arch-install-v3.log

# Check swap status
swapon --show
free -h

# Check kernel
uname -r
cat /boot/loader/entries/arch.conf

# Check GPU drivers
lspci | grep VGA
glxinfo | grep "OpenGL renderer"
```

---

## 📝 Phiên Bản & License

- **Script Version:** V3.2 (Enhanced, 2025)
- **Release Date:** November 30, 2025
- **Total Lines:** ~1000 (auto.sh)
- **Enhancements:** 4 major + 12 sub-features
- **License:** FIXED V3 2025 – Arch + Hyprland Auto Install

---

## 💡 Mẹo & Gợi Ý

✅ **Luôn kiểm tra log nếu gặp lỗi:** `/tmp/arch-install-v3.log`

✅ **Cho phép quá trình cài hoàn tất:** Đừng ngắt script

✅ **Chuẩn bị phương án dự phòng:** Live USB thứ hai hoặc backup

✅ **Tùy chỉnh AUR packages trước cài:** Edit `AUR_PACKAGES` array

✅ **Để ý thông báo swap:** Nếu RAM >32GB và muốn hibernation

✅ **Kiểm tra kernel được chọn:** Log sẽ hiển thị chi tiết

✅ **Chạy yay test sau cài:** Để chắc AUR packages OK

✅ **Cập nhật pacman mirror:** `reflector --country Vietnam --save /etc/pacman.d/mirrorlist`

---

## 🤝 Hỗ Trợ & Đóng Góp

Nếu gặp lỗi:
1. Kiểm tra log file: `/tmp/arch-install-v3.log`
2. Tìm message error cụ thể
3. Kiểm tra phần cứng & kết nối mạng
4. Xem phần "Khắc Phục Sự Cố" bên trên

Để đóng góp:
1. Fork repository
2. Tạo branch mới: `git checkout -b feature/xyz`
3. Commit changes: `git commit -am 'Add xyz'`
4. Push: `git push origin feature/xyz`
5. Tạo Pull Request

---

**Cảm ơn bạn đã sử dụng Arch Auto Installation Script! 🎉**

Chúc bạn cài đặt thành công!
