# NeoArch Linux

An optimized, purple-themed Arch-based distribution for x86_64.

## Features

- **Performance Optimized**: Linux-zen kernel, `-O3` + LTO, BBR, ZRAM, early OOM, IRQ balance, BTRFS with ZSTD compression
- **Purple Theme**: Complete KDE Plasma dark purple theme (GRUB, SDDM, Plymouth, GTK, Qt, Konsole)
- **GUI Installer**: Calamares with netinstall (choose desktop, drivers, software)
- **BTRFS + Snapper**: Automatic snapshots, rollback support
- **Gaming Ready**: gamemode, mangohud, PipeWire, Vulkan
- **Rolling Release**: Always latest Arch packages

## System Requirements

- x86_64 CPU
- 4GB RAM (8GB+ recommended)
- 30GB storage (64GB+ recommended)
- UEFI or BIOS boot

## Quick Start (Download)

Releases are built automatically via GitHub Actions. Download from the [Releases](https://github.com/yourusername/neoarch/releases) page.

## Build From Source

### On Arch Linux (or Arch-based)

```bash
# Install build dependencies
sudo pacman -S archiso make git

# Clone and build
git clone https://github.com/yourusername/neoarch
cd neoarch
make iso
# or: ./build.sh
```

ISO will be in `out/neoarch-YYYY.MM.DD-x86_64.iso`

### On Other Distros (via Docker)

```bash
docker run --rm -it -v $(pwd):/build archlinux:base bash -c "
  pacman -Sy --noconfirm archiso make git &&
  cd /build/neoarch &&
  ./build.sh
"
```

### GitHub Actions (Automatic)

Push to main branch or run workflow manually - ISO builds on Ubuntu runners with Arch ISO build environment.

## Project Structure

```
neoarch/
├── build.sh              # Main build script
├── Makefile              # make iso, make clean, etc.
├── packages/             # Package lists
│   ├── base.x86_64
│   ├── desktop.x86_64
│   └── optimize.x86_64
├── configs/
│   ├── archiso/          # archiso profile
│   └── calamares/        # GUI installer config
└── scripts/              # Theme asset generators
```

## Customization

- **Packages**: Edit `packages/*.x86_64`
- **Theme**: Modify `configs/archiso/airootfs/usr/share/`
- **Installer**: Edit `configs/calamares/modules/*.conf`
- **Kernel params**: `configs/archiso/grub/grub.cfg` and `isolinux/isolinux.cfg`
- **System optimizations**: `configs/archiso/airootfs/etc/sysctl.d/99-neoarch.conf`

## Default Credentials (Live ISO)

- User: `root` (no password)
- Run installer: `calamares` (desktop shortcut available)

## License

MIT License - Based on Arch Linux

---

Built with ❤️ using archiso and Calamares