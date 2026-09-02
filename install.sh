#!/usr/bin/env bash

# Vacuit SDDM / blewh-glass Installer
# Professional installer script based on qylock SDDM setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
THEME_NAME="blewh-glass"
SYSTEM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="$SDDM_CONF_DIR/theme.conf"
QYLOCK_THEMES_DIR="/home/retro/qylock/themes"

# Reset colors on exit
trap 'echo -ne "\033[0m"' EXIT

# Terminal Palette
C_MAIN='\033[38;2;202;169;224m'
C_ACCENT='\033[38;2;145;177;240m'
C_DIM='\033[38;2;129;122;150m'
C_GREEN='\033[38;2;166;209;137m'
C_YELLOW='\033[38;2;229;200;144m'
C_RED='\033[38;2;231;130;132m'
C_BOLD='\033[1m'
C_RESET='\033[0m'

header() {
    clear
    echo -e "${C_MAIN}${C_BOLD}"
    echo "  +------------------------------------------+"
    echo "  |            VACUIT SDDM THEME             |"
    echo "  |        Blewh Glassmorphic Installer      |"
    echo "  +------------------------------------------+"
    echo -e "${C_RESET}"
}

info() {
    echo -e "${C_MAIN}${C_BOLD} [*] $1${C_RESET}"
}

substep() {
    echo -e "${C_DIM}     > ${C_RESET}$1"
}

success() {
    echo -e "${C_GREEN}${C_BOLD} [v] $1${C_RESET}\n"
}

error() {
    echo -e "${C_RED}${C_BOLD} [x] $1${C_RESET}\n"
}

header

# 1. Dependency Check
info "Verifying dependencies..."

if ! command -v sddm &> /dev/null; then
    error "SDDM is not installed. Install it with: pacman -S sddm"
    exit 1
fi
substep "SDDM found"

if ! command -v sddm-greeter-qt6 &> /dev/null; then
    substep "${C_YELLOW}Note: sddm-greeter-qt6 was not found in PATH; ensure Qt6 SDDM greeter is installed${C_RESET}"
else
    substep "Qt6 greeter found"
fi

if [ ! -d "/usr/lib/qt6/qml/M3Shapes" ]; then
    substep "${C_YELLOW}Warning: /usr/lib/qt6/qml/M3Shapes not detected in Qt6 QML plugins${C_RESET}"
else
    substep "M3Shapes Qt6 plugin found"
fi

success "Dependencies verified"

# 2. Check Sudo Privileges
info "Checking permissions..."
if ! sudo -n true 2>/dev/null; then
    substep "${C_YELLOW}sudo password may be required to copy files to /usr/share/sddm/themes/${C_RESET}"
fi

# 3. Synchronize to local qylock if available
if [ -d "$QYLOCK_THEMES_DIR" ]; then
    info "Synchronizing theme with qylock themes folder..."
    mkdir -p "$QYLOCK_THEMES_DIR/$THEME_NAME"
    cp -r "$SCRIPT_DIR/Main.qml" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    cp -r "$SCRIPT_DIR/theme.conf" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    cp -r "$SCRIPT_DIR/metadata.desktop" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    cp -r "$SCRIPT_DIR/bg.jpg" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    if [ -d "$SCRIPT_DIR/font" ]; then
        cp -r "$SCRIPT_DIR/font" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    fi
    substep "Synced to $QYLOCK_THEMES_DIR/$THEME_NAME"
fi

# 4. Install theme into system
info "Installing theme to system directory..."

if [ ! -d "$SYSTEM_THEMES_DIR" ]; then
    substep "Creating $SYSTEM_THEMES_DIR..."
    sudo mkdir -p "$SYSTEM_THEMES_DIR"
fi

substep "Removing previous installation if present..."
sudo rm -rf "$SYSTEM_THEMES_DIR/$THEME_NAME"

substep "Copying theme to $SYSTEM_THEMES_DIR/$THEME_NAME/..."
sudo mkdir -p "$SYSTEM_THEMES_DIR/$THEME_NAME"
sudo cp -r "$SCRIPT_DIR/Main.qml" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
sudo cp -r "$SCRIPT_DIR/theme.conf" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
sudo cp -r "$SCRIPT_DIR/metadata.desktop" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
sudo cp -r "$SCRIPT_DIR/bg.jpg" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
if [ -d "$SCRIPT_DIR/font" ]; then
    sudo cp -r "$SCRIPT_DIR/font" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
fi

# 5. Configure SDDM active theme
info "Updating SDDM configuration..."
if [ ! -d "$SDDM_CONF_DIR" ]; then
    sudo mkdir -p "$SDDM_CONF_DIR"
fi

if [ ! -f "$SDDM_CONF" ]; then
    echo -e "[Theme]\nCurrent=$THEME_NAME" | sudo tee "$SDDM_CONF" > /dev/null
else
    if grep -q "^Current=" "$SDDM_CONF"; then
        sudo sed -i "s|^Current=.*|Current=$THEME_NAME|" "$SDDM_CONF"
    else
        if grep -q "^\[Theme\]" "$SDDM_CONF"; then
            sudo sed -i "/^\[Theme\]/a Current=$THEME_NAME" "$SDDM_CONF"
        else
            echo -e "\n[Theme]\nCurrent=$THEME_NAME" | sudo tee -a "$SDDM_CONF" > /dev/null
        fi
    fi
fi

substep "Configured $SDDM_CONF with Current=$THEME_NAME"
success "Theme '$THEME_NAME' is now installed and active!"

# 6. Test mode option
echo -ne "${C_MAIN}${C_BOLD} Test theme in test-mode now? [y/N]: ${C_RESET}"
read -rp "" TEST_OPT
if [[ "$TEST_OPT" =~ ^[Yy]$ ]]; then
    info "Launching greeter test mode..."
    sddm-greeter-qt6 --test-mode --theme "$SYSTEM_THEMES_DIR/$THEME_NAME"
fi
