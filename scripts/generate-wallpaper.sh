#!/usr/bin/env bash
# NeoArch Wallpaper Generator
# Generates purple gradient wallpapers at various resolutions
set -euo pipefail

OUTPUT_DIR="${1:-./output/wallpapers}"
mkdir -p "$OUTPUT_DIR"

RESOLUTIONS=(
    "3840x2160:4K"
    "2560x1440:1440p"
    "2560x1080:Ultrawide"
    "1920x1080:1080p"
    "1600x900:900p"
    "1366x768:768p"
    "1280x720:720p"
)

generate_wallpaper() {
    local res="$1" label="$2" output="$3"

    IFS='x' read -r width height <<< "$res"

    python3 << EOF
from PIL import Image, ImageDraw, ImageFilter
import math, random

w, h = $width, $height
img = Image.new('RGB', (w, h))
draw = ImageDraw.Draw(img)

# Deep purple gradient background
for y in range(h):
    ratio = y / h
    r = int(10 + ratio * 25)
    g = int(3 + ratio * 18)
    b = int(30 + ratio * 55)
    draw.line([(0, y), (w, y)], fill=(r, g, b))

# Radial glow
cx, cy = w // 2, h // 2
for r in range(min(w, h) // 2, 0, -3):
    intensity = max(0, int(60 * (1 - r / (min(w, h) // 2))))
    c = (88 + intensity, 28 + intensity, 135 + intensity)
    draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)], outline=c, width=2)

# Nebula-like streaks
for _ in range(40):
    x = random.randint(0, w)
    y = random.randint(0, h)
    length = random.randint(50, 300)
    angle = random.uniform(0, math.pi * 2)
    thickness = random.randint(1, 4)
    alpha = random.randint(10, 40)
    colors = [(88, 28, 135, alpha), (124, 58, 237, alpha), (168, 85, 247, alpha), (192, 132, 252, alpha)]
    color = random.choice(colors)
    dx, dy = math.cos(angle) * length, math.sin(angle) * length
    draw.line([(x, y), (x + dx, y + dy)], fill=color[:3], width=thickness)

# Stars
for _ in range(300):
    x = random.randint(0, w)
    y = random.randint(0, h)
    size = random.randint(1, 3)
    b = random.randint(120, 255)
    draw.ellipse([(x, y), (x + size, y + size)], fill=(b, b, b))

img = img.filter(ImageFilter.GaussianBlur(radius=1))
img.save('$output', 'PNG', optimize=True)
print(f'Generated: $output ({res}) - $label')
EOF
}

echo "Generating NeoArch wallpapers..."
for entry in "${RESOLUTIONS[@]}"; do
    IFS=':' read -r res label <<< "$entry"
    output="$OUTPUT_DIR/neoarch-${label}.png"
    generate_wallpaper "$res" "$label" "$output"
done

echo "Done! Wallpapers saved to $OUTPUT_DIR"
