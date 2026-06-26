# NeoArch Linux Makefile
# Convenience targets for building the distribution

.PHONY: all iso clean check-deps install-deps theme-assets help

all: iso

iso: check-deps theme-assets
	@echo "Building NeoArch ISO..."
	@./build.sh

help:
	@echo "NeoArch Linux Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build the ISO (default)"
	@echo "  iso          - Build the ISO"
	@echo "  install-deps - Install build dependencies"
	@echo "  theme-assets - Generate theme images"
	@echo "  clean        - Remove build artifacts"
	@echo "  help         - Show this help"

check-deps:
	@echo "Checking dependencies..."
	@command -v mkarchiso >/dev/null 2>&1 || { echo "ERROR: archiso not installed. Run: make install-deps"; exit 1; }
	@echo "All dependencies found."

install-deps:
	@echo "Installing build dependencies..."
	@sudo pacman -S --needed --noconfirm archiso make git wget squashfs-tools xorriso dosfstools mtools python python-pillow

theme-assets:
	@echo "Generating theme assets..."
	@python3 scripts/generate-theme-assets.py
	@echo "Theme assets generated."

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf work out
	@echo "Clean complete."

distclean: clean
	@echo "Removing all generated files..."
	@rm -rf output
	@echo "Done."
