#!/usr/bin/env bash

# Vacuit SDDM / blewh-glass Universal Installer
# Works seamlessly on any Linux distribution with SDDM & Qt6

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
THEME_NAME="blewh-glass"
SYSTEM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="$SDDM_CONF_DIR/theme.conf"

# Dynamically determine caller's home directory (Works with or without sudo, any username!)
CALLER_USER="${SUDO_USER:-$USER}"
CALLER_HOME="$(getent passwd "$CALLER_USER" 2>/dev/null | cut -d: -f6)"
CALLER_HOME="${CALLER_HOME:-$HOME}"
QYLOCK_THEMES_DIR="$CALLER_HOME/qylock/themes"

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
    echo "  |      Universal SDDM Theme Installer      |"
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

# 1. Dependency Check & Distro Detection
info "Checking system requirements..."

if ! command -v sddm &> /dev/null; then
    error "SDDM display manager is not installed."
    if command -v pacman &> /dev/null; then
        substep "Install on Arch: sudo pacman -S sddm"
    elif command -v dnf &> /dev/null; then
        substep "Install on Fedora: sudo dnf install sddm"
    elif command -v apt &> /dev/null; then
        substep "Install on Debian/Ubuntu: sudo apt install sddm"
    elif command -v zypper &> /dev/null; then
        substep "Install on openSUSE: sudo zypper install sddm"
    fi
    exit 1
fi
substep "SDDM found"

if ! command -v sddm-greeter-qt6 &> /dev/null; then
    substep "${C_YELLOW}Note: sddm-greeter-qt6 was not found in PATH; ensure Qt6 SDDM greeter is installed${C_RESET}"
else
    substep "Qt6 SDDM greeter found"
fi

# 2. Check Sudo Privileges
info "Checking permissions..."
if ! sudo -n true 2>/dev/null; then
    substep "${C_YELLOW}Root privileges required for system installation. You may be prompted for sudo.${C_RESET}"
fi

# 3. M3Shapes Plugin Installation (Ensures shapes work out of the box on any PC!)
if [ ! -d "/usr/lib/qt6/qml/M3Shapes" ]; then
    if [ -d "$SCRIPT_DIR/modules/M3Shapes" ]; then
        info "Installing bundled M3Shapes Qt6 plugin to system..."
        sudo mkdir -p "/usr/lib/qt6/qml/M3Shapes"
        sudo cp -r "$SCRIPT_DIR/modules/M3Shapes/"* "/usr/lib/qt6/qml/M3Shapes/"
        substep "Installed M3Shapes to /usr/lib/qt6/qml/M3Shapes"
    else
        substep "${C_YELLOW}Warning: /usr/lib/qt6/qml/M3Shapes not found. Geometric morphing requires M3Shapes.${C_RESET}"
    fi
else
    substep "M3Shapes Qt6 plugin found at /usr/lib/qt6/qml/M3Shapes"
fi

success "System environment verified"

# 4. Synchronize to local qylock (Only if qylock exists on this machine!)
if [ -d "$QYLOCK_THEMES_DIR" ]; then
    info "Found local qylock directory for user $CALLER_USER..."
    mkdir -p "$QYLOCK_THEMES_DIR/$THEME_NAME"
    cp -r "$SCRIPT_DIR/Main.qml" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    cp -r "$SCRIPT_DIR/theme.conf" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    cp -r "$SCRIPT_DIR/metadata.desktop" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    cp -r "$SCRIPT_DIR/bg.jpg" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    if [ -d "$SCRIPT_DIR/font" ]; then
        cp -r "$SCRIPT_DIR/font" "$QYLOCK_THEMES_DIR/$THEME_NAME/"
    fi
    substep "Synchronized to $QYLOCK_THEMES_DIR/$THEME_NAME"
fi

# 5. Install Theme to /usr/share/sddm/themes/
info "Installing theme to system themes directory..."

if [ ! -d "$SYSTEM_THEMES_DIR" ]; then
    substep "Creating $SYSTEM_THEMES_DIR..."
    sudo mkdir -p "$SYSTEM_THEMES_DIR"
fi

substep "Cleaning previous installation if present..."
sudo rm -rf "$SYSTEM_THEMES_DIR/$THEME_NAME"

substep "Copying theme files to $SYSTEM_THEMES_DIR/$THEME_NAME/..."
sudo mkdir -p "$SYSTEM_THEMES_DIR/$THEME_NAME"
sudo cp -r "$SCRIPT_DIR/Main.qml" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
sudo cp -r "$SCRIPT_DIR/theme.conf" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
sudo cp -r "$SCRIPT_DIR/metadata.desktop" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
sudo cp -r "$SCRIPT_DIR/bg.jpg" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
if [ -d "$SCRIPT_DIR/font" ]; then
    sudo cp -r "$SCRIPT_DIR/font" "$SYSTEM_THEMES_DIR/$THEME_NAME/"
fi

# 6. Configure SDDM active theme
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
success "Theme '$THEME_NAME' successfully installed and activated!"

# 7. Test mode option
echo -ne "${C_MAIN}${C_BOLD} Test theme in test-mode now? [y/N]: ${C_RESET}"
read -rp "" TEST_OPT
if [[ "$TEST_OPT" =~ ^[Yy]$ ]]; then
    info "Launching greeter test mode..."
    sddm-greeter-qt6 --test-mode --theme "$SYSTEM_THEMES_DIR/$THEME_NAME"
fi
