#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# COLOR
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[1;34m' MAGENTA='\033[0;35m' NC='\033[0m'
info(){ echo -e "${GREEN}[+]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }
error(){ echo -e "${RED}[✗]${NC} $*"; exit 1; }

# ---- trap cleanup
cleanup() {
    # try to unmount /mnt if left mounted
    umount -R /mnt 2>/dev/null || true
    swapoff -a 2>/dev/null || true
}
trap cleanup EXIT

[[ $EUID -ne 0 ]] && error "Chạy script với root trên ArchISO! (Run as root)"

clear
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║   Arch + Hyprland Invincible-Dots – IMPROVED 2025     ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"

# quick internet check
ping -c 1 1.1.1.1 &>/dev/null || error "Không có Internet! (No Internet)"

# attempt to install reflector if missing
if ! command -v reflector &>/dev/null; then
    info "Cố gắng cài reflector tạm thời..."
    pacman -Sy --noconfirm reflector || warn "Không thể cài reflector — bỏ qua."
fi

# update mirrorlist if reflector available
if command -v reflector &>/dev/null; then
    info "Chọn mirror (Vietnam ưu tiên)..."
    reflector --country Vietnam --latest 5 --sort rate --save /etc/pacman.d/mirrorlist --verbose || warn "reflector thất bại."
fi

# ---------- helper: read with default
read_default(){
    local prompt="$1" default="$2" var
    read -rp "$prompt" var
    echo "${var:-$default}"
}

# ---------- 1. Language & timezone (simple menu)
echo -e "\n${YELLOW}Ngôn ngữ: 1) English  2) Tiếng Việt  3) 日本語${NC}"
read -rp " → (mặc định 2): " lang_choice; lang_choice=${lang_choice:-2}
case $lang_choice in
  3) LANG_CODE="ja_JP.UTF-8"; KEYMAP="jp106" ;;
  1) LANG_CODE="en_US.UTF-8"; KEYMAP="us" ;;
  *) LANG_CODE="vi_VN.UTF-8"; KEYMAP="us" ;;
esac

echo -e "\n${YELLOW}Múi giờ: 1) Việt Nam  2) Hàn Quốc  3) Anh${NC}"
read -rp " → (mặc định 1): " tz_choice; tz_choice=${tz_choice:-1}
case $tz_choice in 2) TIMEZONE="Asia/Seoul";; 3) TIMEZONE="Europe/London";; *) TIMEZONE="Asia/Ho_Chi_Minh";; esac

# ---------- 2. Username & Hostname (validate)
while :; do
    read -rp "${BLUE}Username (a-z 0-9 _ -, mặc định: user): ${NC}" INPUT_USER
    USERNAME=${INPUT_USER:-user}
    if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then break; else warn "Username chỉ được a-z, 0-9, _, - và không bắt đầu bằng số!"; fi
done

while :; do
    read -rp "${BLUE}Hostname (mặc định: tyno): ${NC}" INPUT_HOST
    HOSTNAME=${INPUT_HOST:-tyno}
    if [[ "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]]; then break; else warn "Hostname không hợp lệ!"; fi
done

read -rsp "${BLUE}Password cho $USERNAME (mặc định = username): ${NC}" USER_PASS; echo
USER_PASS=${USER_PASS:-$USERNAME}
read -rsp "${BLUE}Password root (mặc định: root): ${NC}" ROOT_PASS; echo
ROOT_PASS=${ROOT_PASS:-root}

# ---------- 3. Show available disks and ask for disk (must be existing block device, not partition)
echo -e "\n${YELLOW}Danh sách ổ vật lý hiện có:${NC}"
lsblk -dpo NAME,SIZE,MODEL

while :; do
    echo -e "\n${YELLOW}Ổ đĩa cài đặt (vd: /dev/sda hoặc /dev/nvme0n1) — KHÔNG nhập partition như /dev/sda1:${NC}"
    read -r DISK
    # Trim whitespace
    DISK="${DISK%% }"; DISK="${DISK## }"
    # must be in /dev/* and a block device
    if [[ -z "$DISK" ]]; then warn "Không được để trống!"; continue; fi
    if [[ ! "$DISK" =~ ^/dev/[a-zA-Z0-9]+ ]]; then warn "Đường dẫn ổ không hợp lệ!"; continue; fi
    if [[ ! -b "$DISK" ]]; then warn "Ổ $DISK không tồn tại!"; continue; fi
    # ensure not a partition (ends with digit or pN for nvme)
    # treat nvme devices: /dev/nvme0n1 is ok (ends with digit but whole-disk name)
    # We detect partitions by checking lsblk -dnpo NAME for parent device
    parent=$(lsblk -no PKNAME "$DISK" 2>/dev/null || true)
    if [[ -n "$parent" ]]; then
        # if PKNAME exists, user provided a partition like sda1 -> reject
        warn "Bạn đã nhập partition. Vui lòng nhập TÊN Ổ (ví dụ /dev/sda hoặc /dev/nvme0n1), không nhập partition!"
        continue
    fi
    break
done

# If disk is mounted -> auto-unmount & warn
info "Unmount & cleanup partitions liên quan tới $DISK trước khi thao tác..."
# Try to unmount everything under /mnt then any partitions of DISK
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true

# list partitions for disk and unmount individually
mapfile -t parts < <(lsblk -lnpo NAME "${DISK}" | tail -n +2 || true)
for p in "${parts[@]:-}"; do
    umount "$p" 2>/dev/null || true
done
sleep 1

# double-check mounts
if mount | grep -q "^${DISK}"; then
    warn "Vẫn có mount trên thiết bị $DISK. Hãy kiểm tra thủ công."
    mount | grep "$DISK" || true
    read -rp "Muốn tiếp tục và ép xoá tất cả partition trên $DISK? Gõ EXACT: FORMAT $DISK : " confirm_force
    [[ "$confirm_force" == "FORMAT $DISK" ]] || error "Hủy cài đặt."
fi

warn "TẤT CẢ DỮ LIỆU TRÊN $DISK SẼ BỊ XÓA!"
read -rp "Gõ YES để đồng ý: " c; [[ "$c" = "YES" ]] || error "Hủy."

# ---------- 4. Partition + Swap 8GB (safe)
info "Đang phân vùng EFI 512M + Swap 8G + Root còn lại..."
# ensure disk is clean
wipefs -af "$DISK" 2>/dev/null || warn "wipefs gặp lỗi nhưng tiếp tục..."
sgdisk -Z "$DISK" 2>/dev/null || true

# create partitions: EFI 512M, Swap 8G, rest root
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI"   "$DISK"
sgdisk -n 2:0:+8G   -t 2:8200 -c 2:"Swap"  "$DISK"
sgdisk -n 3:0:0     -t 3:8300 -c 3:"Root"  "$DISK"

# handle nvme naming
if [[ "$DISK" == *nvme* ]]; then p="p"; else p=""; fi
EFI="${DISK}${p}1" SWAP="${DISK}${p}2" ROOT="${DISK}${p}3"

# wait for kernel to refresh partitions
sleep 1
partprobe "$DISK" || true
sleep 1

info "Format EFI, Swap, Root..."
# unmount any residual or mounted partitions (defensive)
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true
for pt in "$EFI" "$SWAP" "$ROOT"; do umount "$pt" 2>/dev/null || true; done

# Format
mkfs.fat -F32 "$EFI"
mkswap "$SWAP" && swapon "$SWAP"
mkfs.ext4 -F "$ROOT"

# mount root & efi
mount "$ROOT" /mnt
# ensure /mnt/etc exists before genfstab later
mkdir -p /mnt/etc
mount --mkdir "$EFI" /mnt/boot/efi

# generate fstab (now /mnt/etc exists)
genfstab -U /mnt > /mnt/etc/fstab || warn "genfstab gặp vấn đề — nhưng tiếp tục."

# ---------- 5. Pacstrap
info "Pacstrap base system..."
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers git vim sudo networkmanager polkit seatd intel-ucode amd-ucode || warn "pacstrap gặp lỗi, kiểm tra logs"

# ---------- 6. Prepare chroot script (improved)
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
locale-gen || true
echo "LANG=$LANG_CODE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOS

# Create user & sudoers
useradd -m -G wheel,audio,video,seat "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd
echo "root:$ROOT_PASS" | chpasswd
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/00-install
chmod 440 /etc/sudoers.d/00-install

# GPU detection + VM detection
IS_VM=$(systemd-detect-virt 2>/dev/null || echo none)
IS_VM=${IS_VM:-none}

if [[ $IS_VM == "none" ]] && lspci | grep -iq 'VGA.*NVIDIA'; then
    pacman -S --noconfirm --needed nvidia nvidia-utils lib32-nvidia-utils hyprland-nvidia nvidia-settings || true
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

EOF

chmod +x /mnt/install.sh

# Run chroot script with environment
arch-chroot /mnt env \
    USERNAME="$USERNAME" HOSTNAME="$HOSTNAME" \
    USER_PASS="$USER_PASS" ROOT_PASS="$ROOT_PASS" \
    TIMEZONE="$TIMEZONE" LANG_CODE="$LANG_CODE" KEYMAP="$KEYMAP" \
    /install.sh || warn "arch-chroot hoặc install.sh có lỗi — kiểm tra đầu ra."

# cleanup
rm -f /mnt/install.sh
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true

echo -e "${MAGENTA}╔════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║           CÀI XONG 100% – IMPROVED SCRIPT      ║${NC}"
echo -e "${MAGENTA}║   User : $USERNAME     Pass: $USER_PASS        ${NC}"
echo -e "${MAGENTA}║   Root : $ROOT_PASS                              ${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}Script by TYNO – IMPROVED 2025 ${NC}"
