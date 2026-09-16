#!/usr/bin/env bash

# Vacuit SDDM / blewh-glass
# Wallpaper & Dynamic Material Theme Engine
# Supports static images (.jpg, .png, .webp) and live wallpapers (.mp4, .webm)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
THEME_NAME="blewh-glass"
SYSTEM_THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"

CALLER_USER="${SUDO_USER:-$USER}"
CALLER_HOME="$(getent passwd "$CALLER_USER" 2>/dev/null | cut -d: -f6)"
CALLER_HOME="${CALLER_HOME:-$HOME}"
QYLOCK_THEME_DIR="$CALLER_HOME/qylock/themes/$THEME_NAME"

# Reset terminal colors
trap 'echo -ne "\033[0m"' EXIT

C_MAIN='\033[38;2;202;169;224m'
C_ACCENT='\033[38;2;145;177;240m'
C_DIM='\033[38;2;129;122;150m'
C_GREEN='\033[38;2;166;209;137m'
C_YELLOW='\033[38;2;229;200;144m'
C_RED='\033[38;2;231;130;132m'
C_BOLD='\033[1m'
C_RESET='\033[0m'

header() {
    echo -e "${C_MAIN}${C_BOLD}"
    echo "  +------------------------------------------+"
    echo "  |       SDDM WALLPAPER & THEME ENGINE      |"
    echo "  |   Static & MP4 Live Wallpaper Changer    |"
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
    echo -e "${C_GREEN}${C_BOLD} [v] $1${C_RESET}"
}

error() {
    echo -e "${C_RED}${C_BOLD} [x] $1${C_RESET}"
}

header

INPUT_FILE="$1"

# Interactive picker if no file passed
if [ -z "$INPUT_FILE" ]; then
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        if command -v zenity &> /dev/null; then
            substep "Opening file picker..."
            INPUT_FILE="$(zenity --file-selection --title="Select SDDM Wallpaper or MP4 Video" \
                --file-filter="All Supported Media | *.jpg *.jpeg *.png *.webp *.mp4 *.webm *.mkv *.mov" \
                --file-filter="Images (*.jpg, *.png, *.webp) | *.jpg *.jpeg *.png *.webp" \
                --file-filter="Videos (*.mp4, *.webm, *.mkv) | *.mp4 *.webm *.mkv *.mov" 2>/dev/null || true)"
        fi
    fi
fi

if [ -z "$INPUT_FILE" ]; then
    echo -e "${C_ACCENT}Enter path to wallpaper (Image or .mp4 video):${C_RESET} "
    read -e -r INPUT_FILE
fi

# Expand tilde and trim quotes
INPUT_FILE="${INPUT_FILE/#\~/$HOME}"
INPUT_FILE="${INPUT_FILE%\"}"
INPUT_FILE="${INPUT_FILE#\"}"
INPUT_FILE="${INPUT_FILE%\'}"
INPUT_FILE="${INPUT_FILE#\'}"

if [ ! -f "$INPUT_FILE" ]; then
    error "File not found: $INPUT_FILE"
    exit 1
fi

EXT="${INPUT_FILE##*.}"
EXT_LOWER="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"

info "Processing media: $(basename "$INPUT_FILE")..."

IS_VIDEO=false
case "$EXT_LOWER" in
    mp4|webm|mkv|mov|avi|m4v)
        IS_VIDEO=true
        ;;
    jpg|jpeg|png|webp|bmp|gif)
        IS_VIDEO=false
        ;;
    *)
        # Check MIME type fallback
        MIME="$(file --mime-type -b "$INPUT_FILE" 2>/dev/null || true)"
        if [[ "$MIME" =~ video/ ]]; then
            IS_VIDEO=true
        elif [[ "$MIME" =~ image/ ]]; then
            IS_VIDEO=false
        else
            error "Unsupported file type: $EXT_LOWER ($MIME)"
            exit 1
        fi
        ;;
esac

if [ "$IS_VIDEO" = true ]; then
    substep "Detected live video wallpaper ($EXT_LOWER)"
    
    if ! command -v ffmpeg &> /dev/null; then
        error "ffmpeg is required for live video wallpapers to extract poster frames."
        exit 1
    fi

    # Copy video into theme
    substep "Copying video to theme as bg.mp4..."
    cp -f "$INPUT_FILE" "$SCRIPT_DIR/bg.mp4"
    
    # Extract high-res poster frame at 1s (or 0.1s if very short)
    substep "Extracting high-resolution poster frame for scene blur and color analysis..."
    if ! ffmpeg -y -ss 00:00:01 -i "$INPUT_FILE" -vframes 1 -q:v 2 "$SCRIPT_DIR/bg.jpg" &> /dev/null; then
        ffmpeg -y -ss 00:00:00.1 -i "$INPUT_FILE" -vframes 1 -q:v 2 "$SCRIPT_DIR/bg.jpg" &> /dev/null
    fi

    THEME_TYPE="video"
    BG_CONF="bg.mp4"
else
    substep "Detected static image wallpaper ($EXT_LOWER)"
    
    if command -v magick &> /dev/null; then
        magick "$INPUT_FILE" -quality 95 "$SCRIPT_DIR/bg.jpg"
    else
        cp -f "$INPUT_FILE" "$SCRIPT_DIR/bg.jpg"
    fi

    # Remove video if transitioning to static image
    rm -f "$SCRIPT_DIR/bg.mp4"

    THEME_TYPE="image"
    BG_CONF="bg.jpg"
fi

# Extract Material Design 3 / Frosted Glass colors
info "Extracting harmonious dynamic color palette from wallpaper..."
eval "$("$SCRIPT_DIR/scripts/extract-palette.py" "$SCRIPT_DIR/bg.jpg")"

substep "Dynamic Accent Color:  ${C_ACCENT}$ACCENT_COLOR${C_RESET}"
substep "Glass Tint Tone:       ${C_ACCENT}$CARD_TINT${C_RESET}"
substep "Glass Border Glow:     ${C_ACCENT}$BORDER_COLOR${C_RESET}"

# Update theme.conf
cat > "$SCRIPT_DIR/theme.conf" << EOF
[General]
background=$BG_CONF
type=$THEME_TYPE
font=JetBrainsMono Nerd Font
color=#ffffff
fontSize=14
accentColor=$ACCENT_COLOR
cardTint=$CARD_TINT
borderColor=$BORDER_COLOR
highlightGlow=$HIGHLIGHT_GLOW
cardOpacity=0.75
EOF

substep "Updated $SCRIPT_DIR/theme.conf"
success "Theme workspace updated successfully!"

# Synchronize to user qylock if present
if [ -d "$QYLOCK_THEME_DIR" ]; then
    info "Synchronizing with local qylock theme..."
    cp -f "$SCRIPT_DIR/bg.jpg" "$QYLOCK_THEME_DIR/"
    cp -f "$SCRIPT_DIR/theme.conf" "$QYLOCK_THEME_DIR/"
    [ -f "$SCRIPT_DIR/variants.json" ] && cp -f "$SCRIPT_DIR/variants.json" "$QYLOCK_THEME_DIR/"
    [ -f "$SCRIPT_DIR/variants.js" ] && cp -f "$SCRIPT_DIR/variants.js" "$QYLOCK_THEME_DIR/"
    if [ "$IS_VIDEO" = true ]; then
        cp -f "$SCRIPT_DIR/bg.mp4" "$QYLOCK_THEME_DIR/"
    else
        rm -f "$QYLOCK_THEME_DIR/bg.mp4"
    fi
    substep "Updated $QYLOCK_THEME_DIR"
fi

# Synchronize to system SDDM directory if already installed
if [ -d "$SYSTEM_THEME_DIR" ]; then
    if [ -t 0 ]; then
        echo ""
        info "Detected system installation at $SYSTEM_THEME_DIR"
        read -r -p " Apply new wallpaper to system SDDM now? [y/N]: " SYNC_SYS
        if [[ "$SYNC_SYS" =~ ^[Yy]$ ]]; then
            substep "Updating system SDDM theme files..."
            sudo cp -f "$SCRIPT_DIR/bg.jpg" "$SYSTEM_THEME_DIR/"
            sudo cp -f "$SCRIPT_DIR/theme.conf" "$SYSTEM_THEME_DIR/"
            [ -f "$SCRIPT_DIR/variants.json" ] && sudo cp -f "$SCRIPT_DIR/variants.json" "$SYSTEM_THEME_DIR/"
            [ -f "$SCRIPT_DIR/variants.js" ] && sudo cp -f "$SCRIPT_DIR/variants.js" "$SYSTEM_THEME_DIR/"
            if [ "$IS_VIDEO" = true ]; then
                sudo cp -f "$SCRIPT_DIR/bg.mp4" "$SYSTEM_THEME_DIR/"
            else
                sudo rm -f "$SYSTEM_THEME_DIR/bg.mp4"
            fi
            success "System SDDM wallpaper updated!"
        fi
    fi
fi

echo ""
success "All done! Run 'sddm-greeter-qt6 --test-mode --theme $SCRIPT_DIR' to preview."
