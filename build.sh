#!/usr/bin/env bash
# NeoArch Linux - Build Script
set -euo pipefail

# ============================================
#  NeoArch Linux ISO Builder
#  An optimized Arch-based distribution
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"
ISO_NAME="neoarch-$(date +%Y.%m.%d)-x86_64.iso"

cleanup() {
    echo -e "\n${YELLOW}[!] Cleaning up...${NC}"
    if mountpoint -q "$WORK_DIR/airootfs" 2>/dev/null; then
        umount -R "$WORK_DIR/airootfs" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

banner() {
    clear
    echo -e "${PURPLE}"
    echo '██╗  ██╗███████╗ ██████╗  █████╗ ██████╗  ██████╗██╗  ██╗'
    echo '██║  ██║██╔════╝██╔═══██╗██╔══██╗██╔══██╗██╔════╝██║  ██║'
    echo '███████║█████╗  ██║   ██║███████║██████╔╝██║     ███████║'
    echo '██╔══██║██╔══╝  ██║   ██║██╔══██║██╔══██╗██║     ██╔══██║'
    echo '██║  ██║███████╗╚██████╔╝██║  ██║██║  ██║╚██████╗██║  ██║'
    echo '╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝'
    echo -e "${NC}"
    echo -e "${BOLD}${PURPLE}  Optimized Arch-based Distribution${NC}"
    echo -e "${CYAN}  Build: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

check_deps() {
    local deps=("archiso" "make" "git" "wget" "squashfs-tools" "xorriso" "dosfstools" "mtools" "python" "python-pillow")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! pacman -Qi "$dep" &>/dev/null; do
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[!] Missing dependencies: ${missing[*]}${NC}"
        echo -e "${YELLOW}[!] Installing...${NC}"
        pacman -S --needed --noconfirm "${missing[@]}"
    fi
}

prepare() {
    echo -e "${CYAN}[*] Preparing build environment...${NC}"

    mkdir -p "$WORK_DIR" "$OUT_DIR"

    # Generate GRUB theme assets
    generate_theme_assets

    # Copy configuration files
    cp -r "$SCRIPT_DIR/configs/archiso"/* "$WORK_DIR/"

    # Copy packages
    mkdir -p "$WORK_DIR/packages"
    cat "$SCRIPT_DIR/packages/base.x86_64" "$SCRIPT_DIR/packages/desktop.x86_64" \
        "$SCRIPT_DIR/packages/optimize.x86_64" > "$WORK_DIR/packages.x86_64"

    # Ensure calamares and its dependencies are in the package list
    echo "calamares" >> "$WORK_DIR/packages.x86_64"
    echo "calamares-config-neoarch" >> "$WORK_DIR/packages.x86_64"
    echo "yaml-cpp" >> "$WORK_DIR/packages.x86_64"

    # Copy Calamares config
    mkdir -p "$WORK_DIR/airootfs/etc/calamares"
    cp -r "$SCRIPT_DIR/configs/calamares"/* "$WORK_DIR/airootfs/etc/calamares/"
}

generate_theme_assets() {
    echo -e "${CYAN}[*] Generating theme assets...${NC}"

    local theme_dir="$WORK_DIR/airootfs/usr/share"

    # Generate a simple purple PNG for GRUB background
    generate_purple_image "$theme_dir/grub/themes/neoarch/background.png" 1920 1080
    generate_purple_image "$theme_dir/grub/themes/neoarch/logo.png" 256 128

    # Generate SDDM background
    generate_purple_image "$theme_dir/sddm/themes/neoarch/background.png" 1920 1080

    # Generate Plymouth background
    generate_purple_image "$theme_dir/plymouth/themes/neoarch/logo.png" 256 128

    # Generate wallpaper
    generate_purple_image "$theme_dir/wallpapers/neoarch-default.png" 3840 2160

    echo -e "${GREEN}[✓] Theme assets generated${NC}"
}

generate_purple_image() {
    local output="$1" width="$2" height="$3"
    local dir
    dir="$(dirname "$output")"
    mkdir -p "$dir"

    python3 -c "
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math

w, h = $width, $height
img = Image.new('RGB', (w, h), '#0F0520')
draw = ImageDraw.Draw(img)

# Gradient background - dark purple to deep violet
for y in range(h):
    ratio = y / h
    r = int(15 + ratio * 20)
    g = int(5 + ratio * 15)
    b = int(32 + ratio * 50)
    draw.line([(0, y), (w, y)], fill=(r, g, b))

# Subtle glow effect in center
cx, cy = w // 2, h // 2
for r in range(400, 0, -2):
    alpha = int(30 * (1 - r / 400))
    draw.ellipse(
        [(cx - r, cy - r), (cx + r, cy + r)],
        fill=(107, 33, 168, alpha) if 'alpha' in str(type(alpha)) else (107, 33, 168)
    )

# Diagonal light beams
for i in range(3):
    x_start = -200 + i * 300
    for j in range(0, w, 4):
        y_offset = int(math.sin(j * 0.005 + i) * 100)
        alpha = max(0, min(15, 15 - abs(j - w//2) // 100))
        if alpha > 0:
            draw.point([(j, cy + y_offset + i * 200)], fill=(200, 150, 255, alpha))
            draw.point([(j, cy - y_offset - i * 200)], fill=(200, 150, 255, max(0, alpha - 5)))

# Add subtle stars/dots
import random
random.seed(42)
for _ in range(200):
    x = random.randint(0, w)
    y = random.randint(0, h)
    size = random.randint(1, 3)
    brightness = random.randint(100, 255)
    draw.ellipse(
        [(x, y), (x + size, y + size)],
        fill=(brightness, brightness, brightness, 200)
    )

# Save with optimization
img.save(output, 'PNG', optimize=True)
print(f'Generated: {output} ({w}x{h})')
"
}

build() {
    echo -e "\n${CYAN}[*] Building NeoArch ISO...${NC}"
    echo -e "${YELLOW}[!] This will take a while...${NC}\n"

    cd "$WORK_DIR"

    # Run mkarchiso
    mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$WORK_DIR"

    echo -e "\n${GREEN}[✓] Build complete!${NC}"
    echo -e "${PURPLE}[✓] ISO: $OUT_DIR/$ISO_NAME${NC}"
}

main() {
    banner
    check_deps
    prepare
    build

    # Print ISO info
    if [[ -f "$OUT_DIR/neoarch-*.iso" ]]; then
        local iso
        iso=$(ls -1 "$OUT_DIR"/neoarch-*.iso 2>/dev/null | head -1)
        local size
        size=$(du -h "$iso" | cut -f1)
        echo -e "\n${BOLD}${GREEN}========================================${NC}"
        echo -e "${BOLD}${GREEN}  NeoArch ISO: $iso${NC}"
        echo -e "${BOLD}${GREEN}  Size: $size${NC}"
        echo -e "${BOLD}${GREEN}========================================${NC}"
    fi
}

main "$@"
