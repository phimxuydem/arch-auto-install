#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[1;34m' MAGENTA='\033[1;35m' NC='\033[0m'
info(){ echo -e "${GREEN}[+]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }
error(){ echo -e "${RED}[✗]$NC $*"; exit 1; }

[[ $EUID -ne 0 ]] && error "Chạy script với root trên ArchISO!"

clear
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║   Arch + Hyprland Invincible-Dots – ULTIMATE 2025    ║${NC}"
echo -e "${MAGENTA}║               Tinh tế • An toàn • Zero lỗi           ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"

# ── 1. Ngôn ngữ & Múi giờ
echo -e "\n${YELLOW}Ngôn ngữ: 1) English  2) 日本語${NC}"
read -rp " → (mặc định 1): " l; l=${l:-1}
case $l in 2) LANG_CODE="ja_JP.UTF-8"; KEYMAP="jp106";; *) LANG_CODE="en_US.UTF-8"; KEYMAP="us";; esac

echo -e "\n${YELLOW}Múi giờ: 1) Việt Nam  2) Hàn Quốc  3) Anh${NC}"
read -rp " → (mặc định 1): " t; t=${t:-1}
case $t in 2) TIMEZONE="Asia/Seoul";; 3) TIMEZONE="Europe/London";; *) TIMEZONE="Asia/Ho_Chi_Minh";; esac

# ── 2. Username & Hostname (có validate)
while :; do
    read -rp "${BLUE}Username (mặc định: user): ${NC}" INPUT_USER
    USERNAME=${INPUT_USER:-user}
    [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { warn "Username không hợp lệ!"; continue; }
    break
done

while :; do
    read -rp "${BLUE}Hostname (mặc định: tyno): ${NC}" INPUT_HOST
    HOSTNAME=${INPUT_HOST:-tyno}
    [[ "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]] || { warn "Hostname không hợp lệ!"; continue; }
    break
done

# ── 3. Password (mặc định = username)
read -rsp "${BLUE}Password cho $USERNAME (mặc định: $USERNAME): ${NC}" USER_PASS
echo; USER_PASS=${USER_PASS:-$USERNAME}

read -rsp "${BLUE}Password cho root (mặc định: root): ${NC}" ROOT_PASS
echo; ROOT_PASS=${ROOT_PASS:-root}

# ── 4. Ổ đĩa – siêu an toàn (check đã mount chưa)
lsblk -dpo NAME,SIZE,MODEL,FSTYPE,UUID
echo -e "\n${YELLOW}Ổ đĩa cài đặt (vd: /dev/sda):${NC}"
while :; do
    read -r DISK
    [[ -b "$DISK" ]] && break || warn "Ổ đĩa không tồn tại, nhập lại!"
done

# Check xem có partition nào của $DISK đã được mount chưa → cảnh báo lần cuối
if mount | grep -q "$DISK"; then
    warn "ĐÃ PHÁT HIỆN partition của $DISK đang được mount!"
    read -rp "Gõ chính xác \"FORMAT $DISK\" để tiếp tục: " confirm
    [[ "$confirm" == "FORMAT $DISK" ]] || error "Hủy cài đặt để bảo vệ dữ liệu."
fi

warn "TẤT CẢ DỮ LIỆU TRÊN $DISK SẼ BỊ XÓA NGAY BÂY GIỜ!"
read -rp "Gõ YES để đồng ý: " c; [[ "$c" = "YES" ]] || error "Đã hủy."

# ── 5. Phân vùng + mount
info "Đang phân vùng và format..."
wipefs -af "$DISK" &>/dev/null
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart primary fat32 1MiB 512MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary ext4 512MiB 100%
[[ $DISK =~ nvme ]] && EFI="${DISK}p1" ROOT="${DISK}p2" || EFI="${DISK}1" ROOT="${DISK}2"
mkfs.fat -F32 "$EFI" &>/dev/null
mkfs.ext4 -F "$ROOT" &>/dev/null
mount "$ROOT" /mnt
mkdir -p /mnt/boot && mount "$EFI" /mnt/boot

# ── 6. Base system
pacstrap /mnt base base-devel linux linux-firmware linux-headers git vim sudo networkmanager polkit seatd
genfstab -U /mnt >> /mnt/etc/fstab

# ── 7. CHROOT SCRIPT ULTIMATE
cat > /mnt/chroot.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail

USERNAME="$USERNAME"
HOSTNAME="$HOSTNAME"
USER_PASS="$USER_PASS"
ROOT_PASS="$ROOT_PASS"

# Timezone & Locale
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i "/^#$LANG_CODE/s/^#//" /etc/locale.gen
locale-gen
echo "LANG=$LANG_CODE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname
echo "\$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   \$HOSTNAME.localdomain \$HOSTNAME
HOSTS

# User + password
useradd -m -G wheel,audio,video,seat "\$USERNAME"
echo "\$USERNAME:\$USER_PASS" | chpasswd
echo "root:\$ROOT_PASS" | chpasswd
echo "\$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/\$USERNAME
chmod 440 /etc/sudoers.d/\$USERNAME

# Microcode + GPU
grep -iq "GenuineIntel" /proc/cpuinfo && pacman -S --noconfirm intel-ucode || pacman -S --noconfirm amd-ucode
lspci | grep -iq nvidia && pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils nvidia-settings || \
    pacman -S --noconfirm mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader xf86-video-amdgpu

# Packages
pacman -Syu --noconfirm --needed hyprland hyprpaper kitty wofi waybar mako pipewire wireplumber pipewire-pulse \
    xdg-desktop-portal-hyprland ttf-jetbrains-mono-nerd zsh sddm archlinux-wallpaper python-pip seatd

systemctl enable NetworkManager sddm seatd

# Yay + Pywal
su - \$USERNAME <<'YAY'
  git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm && cd .. && rm -rf yay
  yay -S --noconfirm python-pywal16 || pip install --user pywal wal-colors
YAY

# Dotfiles
su - \$USERNAME <<'DOTS'
  cd ~
  git clone --depth 1 https://github.com/mkhmtolzhas/Invincible-Dots.git
  [[ -d Invincible-Dots/.config ]] && cp -a Invincible-Dots/.config/* ~/.config/
  find ~/.config -type f -name "*.css" -exec sed -i "s|mkhmtcore|\$USERNAME|g" {} + 2>/dev/null || true
  rm -rf Invincible-Dots
  wal -i /usr/share/backgrounds/archlinux/archwave.png || true
DOTS

# SDDM autologin + theme đẹp
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<SDDM
[Autologin]
User=\$USERNAME
Session=hyprland.desktop

[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_DISABLE_WINDOWDECORATIONS=1

[Theme]
Current=breeze
SDDM

# VM & NVIDIA env → .zshrc
[[ \$(systemd-detect-virt) =~ ^(vmware|qemu|virtualbox|oracle)\$ ]] && cat >> /home/\$USERNAME/.zshrc <<ENV
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER_ALLOW_SOFTWARE=1
ENV

lspci | grep -iq nvidia && cat >> /home/\$USERNAME/.zshrc <<NVIDIA
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
NVIDIA

chsh -s /usr/bin/zsh \$USERNAME
mkinitcpio -P
EOF

# Inject biến (dùng ký tự đặc biệt để tránh xung đột $)
sed -i "s|\$27USERNAME27|$USERNAME|g; s|\$27HOSTNAME27|$HOSTNAME|g; s|\$27USER_PASS27|$USER_PASS|g; s|\$27ROOT_PASS27|$ROOT_PASS|g; s|\$27TIMEZONE27|$TIMEZONE|g; s|\$27LANG_CODE27|$LANG_CODE|g; s|\$27KEYMAP27|$KEYMAP|g" /mnt/chroot.sh

# Thay $27... thành $ thật sự
sed -i "s|\$27|\\\$|g" /mnt/chroot.sh

chmod +x /mnt/chroot.sh
arch-chroot /mnt /chroot.sh
rm -f /mnt/chroot.sh
umount -R /mnt

echo -e "${MAGENTA}╔════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║               HOÀN HẢO TUYỆT ĐỐI               ║${NC}"
echo -e "${MAGENTA}║   User     : $USERNAME${NC}     Pass: $USER_PASS"
echo -e "${MAGENTA}║   Root pass: $ROOT_PASS                       ${NC}"
echo -e "${MAGENTA}║   Hostname : $HOSTNAME                        ${NC}"
echo -e "${MAGENTA}║                                                ║${NC}"
echo -e "${MAGENTA}║   → reboot là vào thẳng Hyprland Invincible    ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}Script by TYNO – 2025 Ultimate Edition ✨${NC}"
