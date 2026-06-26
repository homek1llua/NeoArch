#!/usr/bin/env bash
# NeoArch live environment customization
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${PURPLE}[NeoArch]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

log "${CYAN}██╗  ██╗███████╗ ██████╗  █████╗ ██████╗  ██████╗██╗  ██╗${NC}"
log "${CYAN}██║  ██║██╔════╝██╔═══██╗██╔══██╗██╔══██╗██╔════╝██║  ██║${NC}"
log "${CYAN}███████║█████╗  ██║   ██║███████║██████╔╝██║     ███████║${NC}"
log "${CYAN}██╔══██║██╔══╝  ██║   ██║██╔══██║██╔══██╗██║     ██╔══██║${NC}"
log "${CYAN}██║  ██║███████╗╚██████╔╝██║  ██║██║  ██║╚██████╗██║  ██║${NC}"
log "${CYAN}╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝${NC}"
log ""

# Configure pacman
log "Configuring pacman..."
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf
sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
echo "Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
success "pacman configured"

# Set up ZSH as default
log "Setting up ZSH..."
chsh -s /usr/bin/zsh root
cp /usr/share/zsh/manjaro-zsh-config /root/.zshrc 2>/dev/null || true
success "ZSH configured"

# Theme configurations
log "Applying NeoArch themes..."
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/neoarch.conf << 'SDDM'
[Theme]
Current=neoarch
Font=DejaVu Sans,12
ThemeDir=/usr/share/sddm/themes
CursorTheme=breeze_cursors
SDDM

# Configure GRUB
log "Configuring GRUB..."
cat >> /etc/default/grub << 'GRUB'
GRUB_THEME="/usr/share/grub/themes/neoarch/theme.txt"
GRUB_BACKGROUND="/usr/share/grub/themes/neoarch/background.png"
GRUB_GFXMODE=1920x1080x32,auto
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 udev.log_priority=3 nowatchdog nvme_load=YES"
GRUB_DISABLE_OS_PROBER=false
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=menu
GRUB_COLOR_NORMAL="cyan/black"
GRUB_COLOR_HIGHLIGHT="white/black"
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_SAVEDEFAULT=true
GRUB_DISABLE_SUBMENU=y
GRUB_DISABLE_RECOVERY=true
GRUB_ENABLE_CRYPTODISK=y
GRUB_DISTRIBUTOR="NeoArch"
GRUB_TERMINAL_OUTPUT=gfxterm
GRUB_VIDEO_BACKEND=auto
GRUB_FONT="/boot/grub/fonts/unicode.pf2"
GRUB_INIT_TUNE="480 440 4 440 4 440 4 349 3 523 1 440 4 349 3 523 1 440 4 659 4 440 4 349 3 523 1 294 4 349 3 523 1 440 4 349 3 523 1"
GRUB

success "GRUB configured"

# Configure Plymouth
log "Configuring Plymouth..."
sed -i 's/HideDelay=.*/HideDelay=0/' /etc/plymouth/plymouthd.conf 2>/dev/null || true
plymouth-set-default-theme -R neoarch 2>/dev/null || true
success "Plymouth configured"

# System optimizations
log "Applying system optimizations..."

# ZRAM configuration
cat > /etc/systemd/zram-generator.conf << 'ZRAM'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
ZRAM
success "ZRAM configured"

# IRQ balance
systemctl enable irqbalance 2>/dev/null || true
success "IRQ balance enabled"

# fstrim timer
systemctl enable fstrim.timer 2>/dev/null || true
success "Periodic TRIM enabled"

# Configure early OOM
cat > /etc/earlyoom.conf << 'EARLYOOM'
EARLYOOM_ARGS="-m 5,10 -s 5,10 -r 0 --prefer '(^|/)(firefox|chromium|code|Xorg|plasma.*|kwin.*)$' --avoid '(^|/)root$'"
EARLYOOM
success "early OOM configured"

# Configure tuned
cat > /etc/tuned/neoarch-vm.conf << 'TUNED'
[main]
include=balanced
[sysctl]
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=5
vm.dirty_background_ratio=3
kernel.sched_autogroup_enabled=0
TUNED
success "tuned profile configured"

# Create Calamares desktop launcher
log "Creating Calamares desktop entry..."
mkdir -p /usr/share/applications
cat > /usr/share/applications/calamares.desktop << 'CALAMARES'
[Desktop Entry]
Type=Application
Name=Install NeoArch
Comment=Install NeoArch Linux on your computer
Exec=calamares
Icon=calamares
Terminal=false
Categories=System;Settings;
StartupNotify=true
CALAMARES

# Create desktop shortcut for installer
mkdir -p /root/Desktop
cp /usr/share/applications/calamares.desktop /root/Desktop/
chmod +x /root/Desktop/calamares.desktop

success "Installer shortcut created"

# Ensure network
systemctl enable NetworkManager 2>/dev/null || true
systemctl start NetworkManager 2>/dev/null || true

log ""
log "${GREEN}========================================${NC}"
log "${GREEN}  NeoArch customization complete!${NC}"
log "${GREEN}  Launch installer: calamares${NC}"
log "${GREEN}========================================${NC}"
