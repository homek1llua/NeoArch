#!/usr/bin/env bash
# NeoArch Theme Assets Generator
# Generates all purple theme images for the distribution
set -euo pipefail

OUTPUT_DIR="${1:-./output/theme}"
mkdir -p "$OUTPUT_DIR"/{grub,sddm,plymouth,wallpapers,icons}

# Generate GRUB background
python3 << 'PYEOF'
from PIL import Image, ImageDraw, ImageFilter
import math, random

w, h = 1920, 1080
img = Image.new('RGB', (w, h))
draw = ImageDraw.Draw(img)

for y in range(h):
    ratio = y / h
    r = int(15 + ratio * 20)
    g = int(5 + ratio * 15)
    b = int(32 + ratio * 50)
    draw.line([(0, y), (w, y)], fill=(r, g, b))

cx, cy = w // 2, h // 2
for r in range(400, 0, -2):
    alpha = int(30 * (1 - r / 400))
    draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)],
                 outline=(107 + alpha, 33 + alpha//3, 168 + alpha//2), width=1)

for i in range(3):
    x_start = -200 + i * 300
    for j in range(0, w, 3):
        y_offset = int(math.sin(j * 0.005 + i) * 150)
        a = max(0, min(20, 20 - abs(j - w//2) // 80))
        if a > 0:
            draw.point((j, cy + y_offset + i * 200), fill=(200, 150, 255))
            draw.point((j, cy - y_offset - i * 200), fill=(200, 150, 255))

random.seed(42)
for _ in range(150):
    x = random.randint(0, w)
    y = random.randint(0, h)
    s = random.randint(1, 3)
    b = random.randint(100, 255)
    draw.ellipse([(x, y), (x + s, y + s)], fill=(b, b, b, 200))

img.save('output/theme/grub/background.png', 'PNG', optimize=True)
print('GRUB background generated')

# Generate logo
img2 = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
draw2 = ImageDraw.Draw(img2)

# N letter
n_points = [(60, 40), (60, 216), (196, 40), (196, 216)]
draw2.polygon([(60, 40), (60, 216), (80, 216), (80, 60)], fill=(168, 85, 247))
draw2.polygon([(80, 60), (180, 200), (180, 40)], fill=(124, 58, 237))
draw2.polygon([(176, 40), (176, 216), (196, 216), (196, 40)], fill=(168, 85, 247))

# Glow
for r in range(20, 0, -2):
    x0 = 50 - r
    y0 = 30 - r
    x1 = 206 + r
    y1 = 226 + r
    a = int(15 * (1 - r / 20))
    draw2.rectangle([x0, y0, x1, y1], outline=(168, 85, 247, a))

img2.save('output/theme/grub/logo.png', 'PNG', optimize=True)
print('GRUB logo generated')

# Generate SDDM background
import shutil
shutil.copy('output/theme/grub/background.png', 'output/theme/sddm/background.png')
print('SDDM background generated (copied from GRUB)')

# Generate Plymouth logo
shutil.copy('output/theme/grub/logo.png', 'output/theme/plymouth/logo.png')
print('Plymouth logo generated (copied from GRUB)')
PYEOF

# Generate default wallpaper
python3 << 'PYEOF'
from PIL import Image, ImageDraw, ImageFilter
import math, random

w, h = 3840, 2160
img = Image.new('RGB', (w, h))
draw = ImageDraw.Draw(img)

for y in range(h):
    ratio = y / h
    r = int(10 + ratio * 25)
    g = int(3 + ratio * 18)
    b = int(30 + ratio * 55)
    draw.line([(0, y), (w, y)], fill=(r, g, b))

cx, cy = w // 2, h // 2
for r in range(min(w, h) // 2, 0, -5):
    intensity = max(0, int(60 * (1 - r / (min(w, h) // 2))))
    draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)],
                 outline=(88 + intensity, 28 + intensity, 135 + intensity), width=2)

random.seed(42)
for _ in range(500):
    x = random.randint(0, w)
    y = random.randint(0, h)
    s = random.randint(1, 4)
    b = random.randint(100, 255)
    draw.ellipse([(x, y), (x + s, y + s)], fill=(b, b, b))

img = img.filter(ImageFilter.GaussianBlur(radius=1))
img.save('output/theme/wallpapers/neoarch-default.png', 'PNG', optimize=True)
print('Default wallpaper generated (4K)')
PYEOF

echo "All theme assets generated in $OUTPUT_DIR"
