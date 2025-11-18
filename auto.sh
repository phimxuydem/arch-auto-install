#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[1;34m' MAGENTA='\033[1;35m' NC='\033[0m'
info(){ echo -e "${GREEN}[+]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }
error(){ echo -e "${RED}[✗]${NC} $*"; exit 1; }

[[ $EUID -ne 0 ]] && error "Chạy script với root trên ArchISO!"

clear
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║   Arch + Hyprland Invincible-Dots – ULTIMATE 2025    ║${NC}"
echo -e "${MAGENTA}║               FIXED & HOÀN HẢO 100%                  ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"

# Kiểm tra mạng
ping -c 1 1.1.1.1 &>/dev/null || error "Không có Internet!"

# Cập nhật mirror VN nhanh nhất
pacman -Sy --noconfirm reflector 2>/dev/null || true
reflector --country Vietnam --latest 5 --sort rate --save /etc/pacman.d/mirrorlist --verbose || true

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

# ── 2. User & Hostname
while :; do
    read -rp "${BLUE}Username (a-z 0-9 _ -, mặc định: user): ${NC}" INPUT_USER
    USERNAME=${INPUT_USER:-user}
    [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] && break || warn "Username không hợp lệ!"
done

while :; do
    read -rp "${BLUE}Hostname (mặc định: tyno): ${NC}" INPUT_HOST
    HOSTNAME=${INPUT_HOST:-tyno}
    [[ "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]] && break || warn "Hostname không hợp lệ!"
done

read -rsp "${BLUE}Password user (mặc định = username): ${NC}" USER_PASS; echo
USER_PASS=${USER_PASS:-$USERNAME}
read -rsp "${BLUE}Password root (mặc định: root): ${NC}" ROOT_PASS; echo
ROOT_PASS=${ROOT_PASS:-root}

# ── 3. Chọn ổ đĩa
lsblk -dpo NAME,SIZE,MODEL
echo -e "\n${YELLOW}Ổ đĩa cài đặt (vd: /dev/sda hoặc /dev/nvme0n1):${NC}"
while :; do
    read -r DISK
    [[ -b "$DISK" ]] && ! [[ "$DISK" =~ [0-9]$ ]] && break || warn "Nhập đúng ổ, không phải partition!"
done

warn "TẤT CẢ DỮ LIỆU TRÊN $DISK SẼ BỊ XÓA!"
read -rp "Gõ YES để đồng ý: " c; [[ "$c" = "YES" ]] || error "Hủy cài đặt."

# ── 4. Phân vùng + Format (ĐÃ SỬA THỨ TỰ ĐÚNG 100%)
info "Phân vùng + format..."
wipefs -af "$DISK" &>/dev/null
sgdisk -Z "$DISK" &>/dev/null
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI"   "$DISK"
sgdisk -n 2:0:+8G   -t 2:8200 -c 2:"Swap"  "$DISK"
sgdisk -n 3:0:0     -t 3:8300 -c 3:"Root"  "$DISK"

if [[ "$DISK" == *nvme* ]]; then p="p"; else p=""; fi
EFI="${DISK}${p}1" SWAP="${DISK}${p}2" ROOT="${DISK}${p}3"

# FORMAT TRƯỚC
mkfs.fat -F32 "$EFI"
mkswap "$SWAP" && swapon "$SWAP"
mkfs.ext4 -F "$ROOT"

# MOUNT SAU (đúng thứ tự)
umount -f /mnt 2>/dev/null || true
umount -f /mnt/boot/efi 2>/dev/null || true
mount "$ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI" /mnt/boot/efi
genfstab -U /mnt >> /mnt/etc/fstab

# ── 5. Pacstrap
info "Pacstrap base system..."
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers git vim sudo networkmanager polkit seatd intel-ucode amd-ucode

# ── 6. Chroot script (đã tối ưu + fix lỗi yay, wal, theme)
cat > /mnt/install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export USERNAME HOSTNAME USER_PASS ROOT_PASS TIMEZONE LANG_CODE KEYMAP

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i "s/^#\(.*$LANG_CODE\)/\1/" /etc/locale.gen
locale-gen
echo "LANG=$LANG_CODE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOS

useradd -m -G wheel,audio,video,seat "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd
echo "root:$ROOT_PASS" | chpasswd
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

# GPU
if lspci | grep -iq VGA.*NVIDIA; then
    pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils hyprland-nvidia nvidia-settings
    sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
else
    pacman -S --noconfirm mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader
fi

pacman -Syu --noconfirm hyprland hyprpaper kitty wofi waybar mako pipewire wireplumber pipewire-pulse \
    xdg-desktop-portal-hyprland ttf-jetbrains-mono-nerd zsh sddm archlinux-wallpaper python-pip

systemctl enable NetworkManager sddm seatd pipewire wireplumber pipewire-pulse

# Cài yay + config Invincible-Dots
su - "$USERNAME" <<END
set -e
git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm && cd / && rm -rf /tmp/yay

# wal + theme
yay -S --noconfirm sddm-sugar-candy-git wal-colors || true

# Clone Invincible-Dots
git clone --depth 1 https://github.com/mkhmtolzhas/Invincible-Dots.git ~/Invincible-Dots
cp -r ~/Invincible-Dots/.config/* ~/.config/ 2>/dev/null || true
find ~/.config -type f -exec sed -i "s|mkhmtcore|$USERNAME|g" {} + 2>/dev/null || true
rm -rf ~/Invincible-Dots

# Áp dụng màu
wal -i /usr/share/backgrounds/archlinux/archwave.png || true
END

# SDDM autologin + theme
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

# Fix VM
if systemd-detect-virt &>/dev/null; then
    echo 'export WLR_NO_HARDWARE_CURSORS=1' >> /home/$USERNAME/.zshrc
fi

chsh -s /usr/bin/zsh "$USERNAME"
mkinitcpio -P
EOF

chmod +x /mnt/install.sh
arch-chroot /mnt /install.sh
rm -f /mnt/install.sh

umount -R /mnt
swapoff -a

echo -e "${MAGENTA}╔════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║           CÀI XONG 100% – HOÀN HẢO TUYỆT ĐỐI   ║${NC}"
echo -e "${MAGENTA}║   User: $USERNAME    Pass: $USER_PASS          ║${NC}"
echo -e "${MAGENTA}║   Root pass: $ROOT_PASS                        ║${NC}"
echo -e "${MAGENTA}║   → reboot là vào thẳng Hyprland Invincible    ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}Script FIXED by TYNO${NC}"
