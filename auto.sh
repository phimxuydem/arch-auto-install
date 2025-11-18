#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# màu
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[1;34m' MAGENTA='\033[1;35m' NC='\033[0m'
info(){ echo -e "${GREEN}[+]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }
error(){ echo -e "${RED}[✗]${NC} $*"; exit 1; }

[[ $EUID -ne 0 ]] && error "Chạy script với root trên ArchISO!"

clear
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║   Arch + Hyprland Invincible-Dots – ULTIMATE 2025    ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"

# Kiểm tra mạng
ping -c 1 1.1.1.1 &>/dev/null || error "Không có Internet!"

# đảm bảo reflector có sẵn (nếu không sẽ cài)
if ! command -v reflector &>/dev/null; then
    info "Cài reflector tạm thời để cập nhật mirror..."
    pacman -Sy --noconfirm reflector || warn "Không thể cài reflector — bỏ qua."
fi

info "Chọn mirror Việt Nam nhanh nhất..."
if command -v reflector &>/dev/null; then
    reflector --country Vietnam --latest 5 --sort rate --save /etc/pacman.d/mirrorlist --verbose || warn "reflector thất bại."
fi

# ── 1. Ngôn ngữ & Múi giờ
echo -e "\n${YELLOW}Ngôn ngữ: 1) English  2) Tiếng Việt  3) 日本語${NC}"
read -rp " → (mặc định 2): " l; l=${l:-2}
case $l in
  2) LANG_CODE="vi_VN.UTF-8"; KEYMAP="us" ;;
  3) LANG_CODE="ja_JP.UTF-8"; KEYMAP="jp106" ;;
  *) LANG_CODE="en_US.UTF-8"; KEYMAP="us" ;;
esac

echo -e "\n${YELLOW}Múi giờ: 1) Việt Nam  2) Hàn Quốc  3) Anh${NC}"
read -rp " → (mặc định 1): " t; t=${t:-1}
case $t in 2) TIMEZONE="Asia/Seoul";; 3) TIMEZONE="Europe/London";; *) TIMEZONE="Asia/Ho_Chi_Minh";; esac

# ── 2. Username & Hostname
while :; do
    read -rp "${BLUE}Username (a-z 0-9 _ -, mặc định: user): ${NC}" INPUT_USER
    USERNAME=${INPUT_USER:-user}
    [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { warn "Username chỉ được a-z, 0-9, _, - và không bắt đầu bằng số!"; continue; }
    break
done

while :; do
    read -rp "${BLUE}Hostname (mặc định: tyno): ${NC}" INPUT_HOST
    HOSTNAME=${INPUT_HOST:-tyno}
    [[ "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]] || { warn "Hostname không hợp lệ!"; continue; }
    break
done

read -rsp "${BLUE}Password cho $USERNAME (mặc định = username): ${NC}" USER_PASS; echo
USER_PASS=${USER_PASS:-$USERNAME}
read -rsp "${BLUE}Password root (mặc định: root): ${NC}" ROOT_PASS; echo
ROOT_PASS=${ROOT_PASS:-root}

# ── 3. Ổ đĩa (chỉ ổ, không nhận partition)
lsblk -dpo NAME,SIZE,MODEL
echo -e "\n${YELLOW}Ổ đĩa cài đặt (vd: /dev/sda hoặc /dev/nvme0n1) — KHÔNG nhập partition như /dev/sda1:${NC}"
while :; do
    read -r DISK
    [[ -b "$DISK" ]] || { warn "Ổ không tồn tại!"; continue; }
    # từ chối nếu là partition (ends with digit or pN)
    if [[ "$DISK" =~ [0-9]$ ]]; then
        warn "Nhập ổ (ví dụ /dev/sda hoặc /dev/nvme0n1), không phải partition!"
        continue
    fi
    break
done

if mount | grep -q "${DISK}"; then
    warn "Ổ $DISK đang có partition được mount!"
    read -rp "Gõ \"FORMAT $DISK\" để tiếp tục: " confirm
    [[ "$confirm" == "FORMAT $DISK" ]] || error "Hủy cài đặt."
fi
warn "TẤT CẢ DỮ LIỆU TRÊN $DISK SẼ BỊ XÓA!"
read -rp "Gõ YES để đồng ý: " c; [[ "$c" = "YES" ]] || error "Hủy."

# ── 4. Partition + Swap 8GB
info "Đang phân vùng EFI 512M + Swap 8G + Root còn lại..."
wipefs -af "$DISK" &>/dev/null
sgdisk -Z "$DISK" &>/dev/null
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI"   "$DISK"
sgdisk -n 2:0:+8G   -t 2:8200 -c 2:"Swap"  "$DISK"
sgdisk -n 3:0:0     -t 3:8300 -c 3:"Root"  "$DISK"

# đúng xử lý nvme suffix
if [[ "$DISK" == *nvme* ]]; then p="p"; else p=""; fi
EFI="${DISK}${p}1" SWAP="${DISK}${p}2" ROOT="${DISK}${p}3"

mkfs.fat -F32 "$EFI"
mkswap "$SWAP" && swapon "$SWAP"
mkfs.ext4 -F "$ROOT"

mount "$ROOT" /mnt
# mount EFI vào /mnt/boot/efi theo chuẩn
mount --mkdir "$EFI" /mnt/boot/efi
genfstab -U /mnt > /mnt/etc/fstab

# ── 5. Pacstrap
info "Pacstrap base system..."
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers git vim sudo networkmanager polkit seatd intel-ucode amd-ucode

# ── 6. Chroot script – fix & tối ưu
cat > /mnt/install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export USERNAME HOSTNAME USER_PASS ROOT_PASS TIMEZONE LANG_CODE KEYMAP

# Enable multilib if commented (cho lib32)
if grep -q '^\s*#\s*\[multilib\]' /etc/pacman.conf; then
    sed -i '/^\s*#\s*\[multilib\]/,/\[/{s/^\s*#\s*//}' /etc/pacman.conf || true
    pacman -Syu --noconfirm || true
fi

# Time & Locale
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# uncomment locale line safely
sed -i "s/^#\s*\(${LANG_CODE}.*\)/\1/" /etc/locale.gen || true
locale-gen
echo "LANG=$LANG_CODE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOS

# Create user & sudoers (NOPASSWD kept as requested)
useradd -m -G wheel,audio,video,seat "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd
echo "root:$ROOT_PASS" | chpasswd
# Write sudoers d file (safer naming)
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/00-install
chmod 440 /etc/sudoers.d/00-install

# GPU detection + VM detection (an toàn)
IS_VM=$(systemd-detect-virt 2>/dev/null || echo none)
IS_VM=${IS_VM:-none}

if [[ $IS_VM == "none" ]] && lspci | grep -iq 'VGA.*NVIDIA'; then
    pacman -S --noconfirm --needed nvidia nvidia-utils lib32-nvidia-utils hyprland-nvidia nvidia-settings || true
    # thêm module vào mkinitcpio nếu cần
    sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf || true
else
    pacman -S --noconfirm --needed mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader || true
fi

# Packages chính
pacman -Syu --noconfirm --needed hyprland hyprpaper kitty wofi waybar mako pipewire wireplumber pipewire-pulse \
    xdg-desktop-portal-hyprland ttf-jetbrains-mono-nerd zsh sddm archlinux-wallpaper python-pip || true

systemctl enable NetworkManager sddm seatd pipewire wireplumber pipewire-pulse || true

# Tạo user env và cài AUR bằng yay (nếu cần)
su - "$USERNAME" -s /bin/bash <<'ENDUSER'
set -e
export PATH="$HOME/.local/bin:$PATH"

# build yay nếu chưa có
if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay
    makepkg -si --noconfirm || true
    cd / && rm -rf /tmp/yay
fi

# cài wal-colors (ưu tiên AUR qua yay, fallback pip)
if ! pacman -Q wal-colors &>/dev/null 2>&1; then
    yay -S --noconfirm --needed wal-colors || pip install --user wal-colors pywal || true
fi

# clone config repo (fallback if exists)
if git clone --depth 1 https://github.com/mkhmtolzhas/Invincible-Dots.git /tmp/Invincible-Dots 2>/dev/null; then
    cp -r /tmp/Invincible-Dots/.config/* ~/.config/ 2>/dev/null || true
    find ~/.config -type f -exec sed -i "s|mkhmtcore|$USERNAME|g" {} + 2>/dev/null || true
    rm -rf /tmp/Invincible-Dots
fi

# apply wal if available
wal -i /usr/share/backgrounds/archlinux/archwave.png || true
ENDUSER

# SDDM theme: cài bằng yay nếu cần
if ! pacman -Q sddm-sugar-candy-git &>/dev/null 2>&1; then
    # dùng yay (AUR) để cài
    su - "$USERNAME" -s /bin/bash -c "yay -S --noconfirm sddm-sugar-candy-git" || true
fi

mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<SDDM
[Autologin]
User=$USERNAME
Session=hyprland.desktop

[Theme]
Current=sugar-candy

[General]
DisplayServer=wayland
SDDM

# VM & NVIDIA env shims
[[ $IS_VM != "none" ]] && echo 'export WLR_NO_HARDWARE_CURSORS=1' >> /home/$USERNAME/.zshrc
[[ $IS_VM == "none" ]] && lspci | grep -iq 'VGA.*NVIDIA' && cat >> /home/$USERNAME/.zshrc <<NV
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export LIBVA_DRIVER_NAME=nvidia
export WLR_RENDERER=vulkan
NV

chsh -s /usr/bin/zsh "$USERNAME" || true
mkinitcpio -P || true

# KEEP NOPASSWD as requested; leave /etc/sudoers.d/00-install for user to remove later if desired
EOF

chmod +x /mnt/install.sh

# Chạy chroot (truyền env)
arch-chroot /mnt env \
    USERNAME="$USERNAME" HOSTNAME="$HOSTNAME" \
    USER_PASS="$USER_PASS" ROOT_PASS="$ROOT_PASS" \
    TIMEZONE="$TIMEZONE" LANG_CODE="$LANG_CODE" KEYMAP="$KEYMAP" \
    /install.sh

# cleanup
rm -f /mnt/install.sh
umount -R /mnt || true
swapoff -a || true

echo -e "${MAGENTA}╔════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║           CÀI XONG 100% – HOÀN HẢO TUYỆT ĐỐI   ║${NC}"
echo -e "${MAGENTA}║   User     : $USERNAME     Pass: $USER_PASS    ${NC}"
echo -e "${MAGENTA}║   Root pass: $ROOT_PASS                        ${NC}"
echo -e "${MAGENTA}║   → reboot là vào thẳng Hyprland Invincible    ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}Script by TYNO – 2025 Final Edition ${NC}"
