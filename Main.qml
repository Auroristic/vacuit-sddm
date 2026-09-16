import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtCore
import QtMultimedia
import SddmComponents 2.0
import M3Shapes
import "./variants.js" as ThemeVariants

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#030408"
    readonly property real s: height / 768

    // ──────────────────────────────────────────
    // Persistent Theme Settings (Auto-saves blur, colors & all tweaks to disk!)
    // ──────────────────────────────────────────
    Settings {
        id: persistentSettings
        category: "BlewhGlassSDDM"
        property alias colorScheme: root.colorScheme
        property alias schemeVariant: root.schemeVariant
        property alias schemeFlavour: root.schemeFlavour
        property alias clockBorderEnabled: root.clockBorderEnabled
        property alias cardBorderEnabled: root.cardBorderEnabled
        property alias boxStyle: root.boxStyle
        property alias avatarVisible: root.avatarVisible
        property alias currentM3Shape: root.currentM3Shape
        property alias avatarShape: root.avatarShape
        property alias avatarOrientation: root.avatarOrientation
        property alias avatarScale: root.avatarScale
        property alias unlockAnimStyle: root.unlockAnimStyle
        property alias is12Hour: root.is12Hour
        property alias showLavaBlobs: root.showLavaBlobs
        property alias clockStyle: root.clockStyle
        property alias clockGridPos: root.clockGridPos
        property alias clockScale: root.clockScale
        property alias clockCardEnabled: root.clockCardEnabled
        property alias clockCardOpacity: root.clockCardOpacity
        property alias loginGridPos: root.loginGridPos
        property alias loginScale: root.loginScale
        property alias loginCardEnabled: root.loginCardEnabled
        property alias loginCardOpacity: root.loginCardOpacity
        property alias glassBlurEnabled: root.glassBlurEnabled
        property alias glassBlurRadius: root.glassBlurRadius
        property alias loginStyle: root.loginStyle
        property alias uiFontFamily: root.uiFontFamily
        property alias avatarStyle: root.avatarStyle
        property alias avatarTintMode: root.avatarTintMode
        property alias avatarTintIntensity: root.avatarTintIntensity
    }

    // Wayland mouse cursor fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }

    // SDDM State & Environment
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    
    // UI States
    property bool isUnlocked: false
    property bool isLoggingIn: false
    property bool isKeyboardOpen: false
    property bool userListOpen: false
    property bool sessionMenuOpen: false
    property bool powerMenuOpen: false
    property bool settingsOpen: false
    property bool shapeMenuOpen: false
    property bool paletteMenuOpen: false
    property bool boxMenuOpen: false
    property bool clockStyleMenuOpen: false
    property bool clockPosMenuOpen: false
    property bool loginPosMenuOpen: false
    property bool avatarOrientMenuOpen: false
    property bool avatarStyleMenuOpen: false
    property bool avatarTintMenuOpen: false
    property bool loginStyleMenuOpen: false
    property bool fontMenuOpen: false
    property string loginStyle: "Modern Glass" // "Modern Glass", "Pixel Retro", "Cyber Terminal", "Editorial Minimal"
    property string uiFontFamily: "Google Sans" // "Google Sans", "Pixelify Sans", "Orbitron", "Share Tech Mono", "Oxanium", "Cinzel", "NDot Matrix", "Itim", "JetBrains Mono"
    property string avatarStyle: "Minimal Outline" // "Minimal Outline", "Neon Glow", "Double Ring", "Glass Badge", "Cyber Brackets"
    property string avatarTintMode: "None" // "None", "Subtle Glow", "Duo-tone", "Monochrome"
    property real avatarTintIntensity: 0.35
    property alias settingsCurrentTab: morphingSettingsContainer.currentTab
    property bool unlockAnimMenuOpen: false
    property string unlockAnimStyle: "Kinetic Slide" // "Kinetic Slide", "Morph Dissolve", "Directional Sweep"
    property bool capsLock: false
    property bool is12Hour: true
    property bool showLavaBlobs: true
    property real uiOpacity: 0

    // Smooth Delayed Text Reveal for Power Pill (Prevents squashed text while expanding!)
    property real powerContentOpacity: 0
    property real powerContentXOffset: 16 * s

    onPowerMenuOpenChanged: {
        if (powerMenuOpen) {
            powerOpenAnim.restart()
        } else {
            powerCloseAnim.restart()
        }
    }

    SequentialAnimation {
        id: powerOpenAnim
        NumberAnimation { target: root; property: "powerContentOpacity"; to: 0; duration: 0 }
        NumberAnimation { target: root; property: "powerContentXOffset"; to: 16 * s; duration: 0 }
        PauseAnimation { duration: 180 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "powerContentOpacity"; to: 1; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "powerContentXOffset"; to: 0; duration: 240; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        id: powerCloseAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "powerContentOpacity"; to: 0; duration: 100 }
            NumberAnimation { target: root; property: "powerContentXOffset"; to: 12 * s; duration: 100 }
        }
    }

    // Wallpaper & Background Configuration (from theme.conf)
    readonly property string bgType: (typeof config !== "undefined" && config.type) ? config.type : "image"
    readonly property string bgFile: (typeof config !== "undefined" && config.background) ? config.background : (bgType === "video" ? "bg.mp4" : "bg.jpg")
    readonly property color dynamicAccentColor: (typeof config !== "undefined" && config.accentColor) ? config.accentColor : "#dc4b4e"
    readonly property color dynamicCardTint: (typeof config !== "undefined" && config.cardTint) ? config.cardTint : "#190e0f"
    readonly property color dynamicBorderColor: (typeof config !== "undefined" && config.borderColor) ? config.borderColor : "#dc4b4e"
    readonly property color dynamicHighlightGlow: (typeof config !== "undefined" && config.highlightGlow) ? config.highlightGlow : Qt.alpha(dynamicAccentColor, 0.38)

    // Material 3 / Caelestia Dynamic Scheme Variants & Flavours
    property string schemeVariant: "Vibrant" // "Tonal Spot", "Vibrant", "Expressive", "Fidelity", "Fruit Salad", "Rainbow", "Neutral", "Monochrome"
    property string schemeFlavour: "Default" // "Default", "Hard"
    property bool variantMenuOpen: false

    // Outline / Border Controls
    property bool clockBorderEnabled: false // Default off: clean borderless frosted clock card!
    property bool cardBorderEnabled: false  // Default off: clean borderless frosted panels/menus!

    // HSL & Palette Math for Material 3 Scheme Variants across ALL Themes
    function rgbToHsl(r, g, b) {
        var max = Math.max(r, g, b), min = Math.min(r, g, b)
        var h = 0, s = 0, l = (max + min) / 2
        if (max !== min) {
            var d = max - min
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
            if (max === r) {
                h = (g - b) / d + (g < b ? 6 : 0)
            } else if (max === g) {
                h = (b - r) / d + 2
            } else {
                h = (r - g) / d + 4
            }
            h /= 6
        }
        return { h: h, s: s, l: l }
    }

    function hueToRgb(p, q, t) {
        if (t < 0) t += 1
        if (t > 1) t -= 1
        if (t < 1/6) return p + (q - p) * 6 * t
        if (t < 1/2) return q
        if (t < 2/3) return p + (q - p) * (2/3 - t) * 6
        return p
    }

    function hslToRgb(h, s, l) {
        var r, g, b
        if (s === 0) {
            r = g = b = l
        } else {
            var q = l < 0.5 ? l * (1 + s) : l + s - l * s
            var p = 2 * l - q
            r = hueToRgb(p, q, h + 1/3)
            g = hueToRgb(p, q, h)
            b = hueToRgb(p, q, h - 1/3)
        }
        return { r: r, g: g, b: b }
    }

    // Customizable Appearance Properties with Real M3Shapes!
    property int currentM3Shape: MaterialShape.Cookie9Sided
    property string avatarShape: "Cookie 9-Sided" 
    property string boxShape: "Rounded"
    property string colorScheme: "Dynamic"

    readonly property var passwordM3Shapes: [
        MaterialShape.Cookie9Sided,
        MaterialShape.Triangle,
        MaterialShape.ClamShell,
        MaterialShape.Sunny,
        MaterialShape.Cookie4Sided,
        MaterialShape.Heart,
        MaterialShape.Diamond,
        MaterialShape.VerySunny,
        MaterialShape.Cookie7Sided
    ]

    // ──────────────────────────────────────────
    // 9-Grid Positioning Engine & Kinetic Physics
    // ──────────────────────────────────────────
    readonly property var gridPositionNames: [
        "Top Left",    "Top Center",    "Top Right",
        "Middle Left", "Middle Center", "Middle Right",
        "Bottom Left", "Bottom Center", "Bottom Right"
    ]

    function getGridX(posIndex, itemW, marginX) {
        var col = posIndex % 3
        if (col === 0) return marginX
        if (col === 1) return (root.width - itemW) / 2
        return root.width - itemW - marginX
    }

    function getGridY(posIndex, itemH, marginY, bottomReserved) {
        var row = Math.floor(posIndex / 3)
        if (row === 0) return marginY
        if (row === 1) return (root.height - itemH) / 2
        return root.height - itemH - bottomReserved
    }

    // ──────────────────────────────────────────
    // Clock Customization Properties
    // ──────────────────────────────────────────
    property string clockStyle: "Caelestia Split" // "Caelestia Split", "Classic Minimal", "Two-Tier Stacked", "Compact Capsule", "Cyber HUD", "Editorial Typographic", "Neo-Digital Capsule", "Pixel Retro"
    property int clockGridPos: 2 // Default: 2 (Top Right)
    property real clockScale: 1.0 // 0.6 to 2.2
    property bool clockCardEnabled: false
    property real clockCardOpacity: 0.35 // 0.15 to 0.85

    // Dynamic Clock Strings (Auto-updated by updateClock())
    property string clockHours: "00"
    property string clockMinutes: "00"
    property string clockAmPm: "AM"
    property string clockMonthName: "SEPTEMBER"
    property string clockDayNum: "03"
    property string clockWeekday: "Thursday"
    property string clockFullDate: ""
    property string clockYear: "2026"

    // ──────────────────────────────────────────
    // Login Container Customization Properties
    // ──────────────────────────────────────────
    property int loginGridPos: 5 // Default: 5 (Middle Right)
    property real loginScale: 1.0 // 0.7 to 1.6
    property real avatarScale: 1.0 // 0.6 to 1.4
    property bool glassBlurEnabled: true
    property int glassBlurRadius: 48 // 16 to 80

    // ──────────────────────────────────────────
    // Shared Frosted Glass Backdrop Component
    // ──────────────────────────────────────────
    component FrostedGlassCard: Item {
        id: glassBackdrop
        anchors.fill: parent
        z: -1

        property real radius: parent && parent.radius !== undefined ? parent.radius : 16 * s
        property color tintColor: root.glassBg
        property color borderColor: root.glassBorder
        property real borderWidth: 1.2 * s
        property bool isClockCard: false
        property bool showBorder: isClockCard ? root.clockBorderEnabled : root.cardBorderEnabled

        readonly property real screenX: {
            var p = glassBackdrop;
            var _d = 0;
            while (p && p !== root) {
                _d += p.x + p.y + p.width + p.height + p.scale;
                p = p.parent;
            }
            return glassBackdrop.mapToItem(root, 0, 0).x;
        }

        readonly property real screenY: {
            var p = glassBackdrop;
            var _d = 0;
            while (p && p !== root) {
                _d += p.x + p.y + p.width + p.height + p.scale;
                p = p.parent;
            }
            return glassBackdrop.mapToItem(root, 0, 0).y;
        }

        readonly property real screenW: {
            var p = glassBackdrop;
            var _d = 0;
            while (p && p !== root) {
                _d += p.x + p.y + p.width + p.height + p.scale;
                p = p.parent;
            }
            return Math.abs(glassBackdrop.mapToItem(root, glassBackdrop.width, 0).x - glassBackdrop.mapToItem(root, 0, 0).x);
        }

        readonly property real screenH: {
            var p = glassBackdrop;
            var _d = 0;
            while (p && p !== root) {
                _d += p.x + p.y + p.width + p.height + p.scale;
                p = p.parent;
            }
            return Math.abs(glassBackdrop.mapToItem(root, 0, glassBackdrop.height).y - glassBackdrop.mapToItem(root, 0, 0).y);
        }

        layer.enabled: root.glassBlurEnabled
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: glassBackdrop.width
                height: glassBackdrop.height
                radius: glassBackdrop.radius
            }
        }

        ShaderEffectSource {
            anchors.fill: parent
            sourceItem: fullGlassBlur
            visible: root.glassBlurEnabled
            live: true
            recursive: false
            sourceRect: Qt.rect(
                glassBackdrop.screenX,
                glassBackdrop.screenY,
                glassBackdrop.screenW,
                glassBackdrop.screenH
            )
        }

        Rectangle {
            anchors.fill: parent
            radius: glassBackdrop.radius
            color: glassBackdrop.tintColor
            border.color: glassBackdrop.showBorder ? glassBackdrop.borderColor : "transparent"
            border.width: glassBackdrop.showBorder ? glassBackdrop.borderWidth : 0
        }
    }
    property bool loginCardEnabled: false
    property real loginCardOpacity: 0.40 // 0.15 to 0.85
    property bool avatarVisible: true
    property string avatarOrientation: "Right" // "Right", "Left", "Top Center", "Top Left", "Top Right", "Bottom Center", "Bottom Left", "Bottom Right", "Center"
    property string boxStyle: "Glass Pill" // "Glass Pill", "Minimal Underline", "Split Badge", "Sharp M3 Card"

    function getAvatarGridPos() {
        switch (root.avatarOrientation) {
            case "Top Left": return 0;
            case "Top Center": return 1;
            case "Top Right": return 2;
            case "Left": return 3;
            case "Center": return 4;
            case "Right": return 5;
            case "Bottom Left": return 6;
            case "Bottom Center": return 7;
            case "Bottom Right": return 8;
            default: return 5;
        }
    }

    function setAvatarGridPos(idx) {
        var map = [
            "Top Left", "Top Center", "Top Right",
            "Left", "Center", "Right",
            "Bottom Left", "Bottom Center", "Bottom Right"
        ];
        if (idx >= 0 && idx < map.length) {
            root.avatarOrientation = map[idx];
        }
    }

    function getBoxRadius(h) {
        if (boxStyle === "Glass Pill" || boxStyle === "Split Badge") return h / 2
        if (boxStyle === "Sharp M3 Card") return 6 * s
        if (boxStyle === "Minimal Underline") return 4 * s
        return 14 * s
    }

    // ──────────────────────────────────────────
    // Real SDDM Models for Users & Sessions (Zero Mock Data!)
    // ──────────────────────────────────────────
    function getSystemUser() {
        if (typeof userModel !== "undefined") {
            if (userModel.lastUser && userModel.lastUser !== "") return userModel.lastUser
            var count = typeof userModel.rowCount === "function" ? userModel.rowCount() : (userModel.count || 0)
            if (count > 0) {
                var first = userModel.data(userModel.index(0, 0), Qt.UserRole + 1)
                if (first && first !== "") return first
            }
        }
        return "retro"
    }

    function getUserAvatar(uLogin, sddmIcon) {
        var login = uLogin || root.getSystemUser()
        // If SDDM provides a user-specific avatar, use it (filter out generic silhouette fallbacks)
        if (sddmIcon && sddmIcon !== "" && sddmIcon.indexOf("/faces/.face.icon") === -1 && sddmIcon.indexOf("default.face.icon") === -1) {
            return sddmIcon
        }
        if (login && login !== "") {
            return "file:///home/" + login + "/.face"
        }
        return ""
    }

    property int currentUserIdx: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    readonly property var activeUser: {
        var uName = ""
        var uRealName = ""
        var uIcon = ""

        if (typeof userModel !== "undefined") {
            var count = typeof userModel.rowCount === "function" ? userModel.rowCount() : (userModel.count || 0)
            if (count > 0 && root.currentUserIdx >= 0 && root.currentUserIdx < count) {
                var idx = userModel.index(root.currentUserIdx, 0)
                uName = userModel.data(idx, Qt.UserRole + 1) || ""
                uRealName = userModel.data(idx, Qt.UserRole + 2) || uName
                uIcon = userModel.data(idx, Qt.UserRole + 4) || ""
            }
        }

        if (uName === "") {
            if (userHelper.currentItem && userHelper.currentItem.uLogin !== "") {
                uName = userHelper.currentItem.uLogin
                uRealName = userHelper.currentItem.uName
                uIcon = userHelper.currentItem.uIcon
            } else {
                uName = root.getSystemUser()
                uRealName = uName
                uIcon = root.getUserAvatar(uName, "")
            }
        }

        return {
            name: uName,
            realName: uRealName,
            icon: uIcon
        }
    }

    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.currentUserIdx
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item {
            property string uLogin: (typeof model !== "undefined" && model.name) ? model.name : root.getSystemUser()
            property string uName: (typeof model !== "undefined" && (model.realName || model.name)) ? (model.realName || model.name) : uLogin
            property string uIcon: root.getUserAvatar(uLogin, (typeof model !== "undefined" && model.icon) ? model.icon : "")
        }
    }

    property int currentSessionIdx: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    readonly property var activeSession: {
        var sName = (sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "Hyprland"
        return {
            name: sName,
            icon: getSessionIcon(sName)
        }
    }

    function getSessionIcon(sName) {
        if (!sName) return "󰣇"
        var lower = sName.toLowerCase()
        if (lower.indexOf("hyprland") !== -1) return "󰣇"
        if (lower.indexOf("plasma") !== -1 || lower.indexOf("kde") !== -1) return ""
        if (lower.indexOf("gnome") !== -1) return ""
        if (lower.indexOf("sway") !== -1) return "󰍹"
        if (lower.indexOf("wayfire") !== -1) return "󰕰"
        if (lower.indexOf("niri") !== -1) return "󱂬"
        if (lower.indexOf("river") !== -1) return "󰐊"
        return "󰣇"
    }

    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.currentSessionIdx
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item {
            property string sName: (typeof model !== "undefined" && model.name) ? model.name : "Hyprland"
        }
    }

    // ──────────────────────────────────────────
    // Dynamic Themed Colors & Themed Glass Materials
    // ──────────────────────────────────────────
    readonly property var currentSchemeBase: {
        if (colorScheme === "Catppuccin Mocha")      return { hex: "#c2c1ff", bg: "#131317", outline: "#918f9a" }
        if (colorScheme === "Catppuccin Macchiato")  return { hex: "#bac3ff", bg: "#131317", outline: "#90909a" }
        if (colorScheme === "Catppuccin Frappe")     return { hex: "#b7c4ff", bg: "#131317", outline: "#8f909a" }
        if (colorScheme === "Catppuccin Latte")      return { hex: "#3e7b9f", bg: "#f8f9fc", outline: "#6e757c" }
        if (colorScheme === "Nord")                  return { hex: "#88c0d0", bg: "#2e3440", outline: "#616e88" }
        if (colorScheme === "Tokyo Night")           return { hex: "#7aa2f7", bg: "#1a1b26", outline: "#565f89" }
        if (colorScheme === "Rose Pine Main")        return { hex: "#c9bfff", bg: "#141317", outline: "#938f9a" }
        if (colorScheme === "Rose Pine Moon")        return { hex: "#c6bfff", bg: "#141317", outline: "#928f9a" }
        if (colorScheme === "Dracula")               return { hex: "#bd93f9", bg: "#282a36", outline: "#6272a4" }
        if (colorScheme === "Gruvbox")               return { hex: "#81d3e0", bg: "#101415", outline: "#889394" }
        if (colorScheme === "Everforest")            return { hex: "#7fbbb3", bg: "#252b2e", outline: "#859289" }
        if (colorScheme === "OneDark")               return { hex: "#a8c8ff", bg: "#121317", outline: "#8d919a" }
        if (colorScheme === "Dark Green")            return { hex: "#24bd5c", bg: "#1e1e24", outline: "#979797" }
        if (colorScheme === "Astra")                 return { hex: "#5db5f5", bg: "#05131e", outline: "#65788a" }
        if (colorScheme === "Caelestia")             return { hex: "#9bd0cc", bg: "#0a0f0f", outline: "#6d7876" }
        if (colorScheme === "Nothing Red")           return { hex: "#ff3b30", bg: "#16090a", outline: "#802020" }
        if (colorScheme === "Sakura Pink")           return { hex: "#ff7b90", bg: "#1f1014", outline: "#9e5f6e" }
        if (colorScheme === "Cyber Cyan")            return { hex: "#00f0ff", bg: "#06151a", outline: "#008899" }
        if (colorScheme === "Editorial Gold")        return { hex: "#e2b774", bg: "#191610", outline: "#8c7247" }
        return { hex: dynamicAccentColor, bg: dynamicCardTint, outline: dynamicBorderColor }
    }

    function resolveVariant(type) {
        var vKey = schemeVariant.toLowerCase().replace(/ /g, "")
        var isHard = schemeFlavour === "Hard"

        if (colorScheme === "Dynamic") {
            var fKey = isHard ? "hard" : "default"
            if (typeof ThemeVariants !== "undefined" && ThemeVariants.variants && ThemeVariants.variants[vKey] && ThemeVariants.variants[vKey][fKey]) {
                var cVal = ThemeVariants.variants[vKey][fKey][type]
                if (cVal) {
                    if (type === "surface") return isHard ? Qt.rgba(0.015, 0.015, 0.02, 0.88) : Qt.alpha(Qt.color(cVal), 0.62)
                    if (type === "outline") return isHard ? Qt.alpha(Qt.color(cVal), 0.65) : Qt.alpha(Qt.color(cVal), 0.40)
                    return cVal
                }
            }
            if (type === "primary") return dynamicAccentColor
            if (type === "surface") return isHard ? Qt.rgba(0.015, 0.015, 0.02, 0.88) : Qt.alpha(dynamicCardTint, 0.62)
            if (type === "outline") return isHard ? Qt.alpha(dynamicAccentColor, 0.60) : dynamicBorderColor
            return dynamicHighlightGlow
        }

        var baseHex = currentSchemeBase.hex
        var baseBgRgba = currentSchemeBase.bg
        var c = Qt.color(baseHex)
        var hsl = rgbToHsl(c.r, c.g, c.b)
        var vH = hsl.h
        var vS = hsl.s
        var vL = hsl.l

        if (vKey === "tonalspot") {
            vS = Math.max(0.18, vS * 0.55)
            vL = Math.min(0.80, Math.max(0.60, vL * 1.05))
        } else if (vKey === "vibrant") {
            vS = Math.min(1.0, Math.max(0.85, vS * 1.35))
            vL = Math.min(0.70, Math.max(0.58, vL))
        } else if (vKey === "expressive") {
            vH = (vH + 0.12) % 1.0
            vS = Math.min(1.0, vS * 1.15)
        } else if (vKey === "fidelity") {
            // retain exact base
        } else if (vKey === "fruitsalad") {
            vH = (vH + 0.25) % 1.0
            vS = Math.min(1.0, Math.max(0.75, vS * 1.25))
            vL = 0.65
        } else if (vKey === "rainbow") {
            vH = (vH + 0.40) % 1.0
            vS = 1.0
            vL = 0.68
        } else if (vKey === "neutral") {
            vS = Math.max(0.04, vS * 0.15)
            vL = 0.74
        } else if (vKey === "monochrome") {
            vS = 0.0
            vL = 0.82
        }

        var rgb = hslToRgb(vH, vS, vL)
        var primaryCol = Qt.rgba(rgb.r, rgb.g, rgb.b, 1.0)

        if (type === "primary") return primaryCol
        if (type === "glow") return Qt.alpha(primaryCol, 0.38)
        if (type === "outline") {
            if (isHard) return Qt.alpha(primaryCol, 0.70)
            if (vKey === "fidelity" && currentSchemeBase.outline) return Qt.alpha(Qt.color(currentSchemeBase.outline), 0.55)
            return Qt.alpha(primaryCol, 0.40)
        }
        if (type === "surface") {
            if (isHard) {
                return Qt.rgba(0.015, 0.015, 0.022, 0.88)
            }
            var sCol = Qt.color(baseBgRgba)
            return Qt.rgba(
                Math.min(1.0, sCol.r * 0.82 + rgb.r * 0.18),
                Math.min(1.0, sCol.g * 0.82 + rgb.g * 0.18),
                Math.min(1.0, sCol.b * 0.82 + rgb.b * 0.18),
                0.62
            )
        }
        return primaryCol
    }

    readonly property color accentColor: {
        var _c = colorScheme; var _v = schemeVariant; var _f = schemeFlavour; var _b = currentSchemeBase
        return resolveVariant("primary")
    }
    readonly property color highlightGlow: {
        var _c = colorScheme; var _v = schemeVariant; var _f = schemeFlavour; var _b = currentSchemeBase
        return resolveVariant("glow")
    }
    readonly property color glassBg: {
        var _c = colorScheme; var _v = schemeVariant; var _f = schemeFlavour; var _b = currentSchemeBase
        return resolveVariant("surface")
    }
    readonly property color glassBorder: {
        var _c = colorScheme; var _v = schemeVariant; var _f = schemeFlavour; var _b = currentSchemeBase
        return resolveVariant("outline")
    }

    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#c8d0de"
    readonly property color textMuted: "#7a8596"

    // Custom Font Loaders
    FontLoader {
        id: nerdFont
        source: "font/JetBrainsMonoNerdFont-Regular.ttf"
    }
    FontLoader {
        id: googleSansFont
        source: "font/GoogleSans-VariableFont_GRAD,opsz,wght.ttf"
    }
    FontLoader {
        id: orbitronFont
        source: "font/Orbitron.ttf"
    }
    FontLoader {
        id: shareTechFont
        source: "font/ShareTechMono.ttf"
    }
    FontLoader {
        id: oxaniumFont
        source: "font/Oxanium.ttf"
    }
    FontLoader {
        id: pixelFont
        source: "font/PixelifySans-Bold.ttf"
    }
    FontLoader {
        id: cinzelFont
        source: "font/Cinzel-Bold.ttf"
    }
    FontLoader {
        id: dotMatrixFont
        source: "font/NDot55.otf"
    }
    FontLoader {
        id: itimFont
        source: "font/Itim-Regular.ttf"
    }

    readonly property string monoFont: nerdFont.name !== "" ? nerdFont.name : "JetBrainsMono Nerd Font, monospace"
    readonly property string sansFont: {
        if (root.uiFontFamily === "Pixelify Sans") return pixelFont.name !== "" ? pixelFont.name : "Pixelify Sans, sans-serif"
        if (root.uiFontFamily === "Orbitron") return orbitronFont.name !== "" ? orbitronFont.name : "Orbitron, sans-serif"
        if (root.uiFontFamily === "Share Tech Mono") return shareTechFont.name !== "" ? shareTechFont.name : "Share Tech Mono, monospace"
        if (root.uiFontFamily === "Oxanium") return oxaniumFont.name !== "" ? oxaniumFont.name : "Oxanium, sans-serif"
        if (root.uiFontFamily === "Cinzel") return cinzelFont.name !== "" ? cinzelFont.name : "Cinzel, serif"
        if (root.uiFontFamily === "NDot Matrix") return dotMatrixFont.name !== "" ? dotMatrixFont.name : "NDot55, sans-serif"
        if (root.uiFontFamily === "Itim") return itimFont.name !== "" ? itimFont.name : "Itim, cursive"
        if (root.uiFontFamily === "JetBrains Mono") return nerdFont.name !== "" ? nerdFont.name : "JetBrainsMono Nerd Font, monospace"
        return googleSansFont.name !== "" ? googleSansFont.name : "Google Sans Flex, Google Sans, Inter, sans-serif"
    }
    readonly property string pixelFontFamily: pixelFont.name !== "" ? pixelFont.name : "Pixelify Sans, sans-serif"
    readonly property string cinzelFontFamily: cinzelFont.name !== "" ? cinzelFont.name : "Cinzel, serif"
    readonly property string dotMatrixFontFamily: dotMatrixFont.name !== "" ? dotMatrixFont.name : "NDot55, sans-serif"
    readonly property string itimFontFamily: itimFont.name !== "" ? itimFont.name : "Itim, cursive"
    readonly property string cyberDisplayFont: orbitronFont.name !== "" ? orbitronFont.name : "Orbitron, sans-serif"
    readonly property string cyberHudMono: shareTechFont.name !== "" ? shareTechFont.name : "Share Tech Mono, monospace"
    readonly property string techDisplayFont: oxaniumFont.name !== "" ? oxaniumFont.name : "Oxanium, sans-serif"

    // Startup Animation
    Component.onCompleted: {
        if (typeof Qt.inputMethod !== "undefined" && Qt.inputMethod) {
            Qt.inputMethod.hide()
        }
        introFadeAnim.start()
        updateClock()
    }

    // Suppress system Qt Virtual Keyboard overlay (prevents un-themed full-screen keyboard popup)
    Connections {
        target: Qt.inputMethod
        function onVisibleChanged() {
            if (Qt.inputMethod && Qt.inputMethod.visible) {
                Qt.inputMethod.hide()
            }
        }
    }

    NumberAnimation {
        id: introFadeAnim
        target: root
        property: "uiOpacity"
        from: 0
        to: 1
        duration: 1100
        easing.type: Easing.OutCubic
    }

    // Global Key Listener
    Item {
        id: globalKeyHandler
        anchors.fill: parent
        focus: !root.isUnlocked
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_CapsLock) {
                root.capsLock = !root.capsLock
            }
            if (!root.isUnlocked) {
                unlockScreen()
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                handleEscape()
                event.accepted = true
            }
        }
    }

    function unlockScreen() {
        root.isUnlocked = true
        root.settingsOpen = false
        root.powerMenuOpen = false
        root.isKeyboardOpen = false
        root.sessionMenuOpen = false
        root.userListOpen = false
        focusTimer.start()
    }

    function closeAllSettingsDrawers() {
        root.shapeMenuOpen = false
        root.paletteMenuOpen = false
        root.variantMenuOpen = false
        root.boxMenuOpen = false
        root.clockStyleMenuOpen = false
        root.clockPosMenuOpen = false
        root.loginPosMenuOpen = false
        root.loginStyleMenuOpen = false
        root.avatarOrientMenuOpen = false
        root.avatarStyleMenuOpen = false
        root.avatarTintMenuOpen = false
        root.unlockAnimMenuOpen = false
        root.fontMenuOpen = false
    }

    function applyPreset(name) {
        if (name === "Pixel Sakura") {
            root.clockStyle = "Pixel Retro"
            root.loginStyle = "Pixel Retro"
            root.uiFontFamily = "Pixelify Sans"
        } else if (name === "Cyber HUD") {
            root.clockStyle = "Cyber HUD"
            root.loginStyle = "Cyber Terminal"
            root.uiFontFamily = "Share Tech Mono"
        } else if (name === "Editorial Luxe") {
            root.clockStyle = "Editorial Typographic"
            root.loginStyle = "Editorial Minimal"
            root.uiFontFamily = "Cinzel"
        } else if (name === "Neo Digital") {
            root.clockStyle = "Neo-Digital Capsule"
            root.loginStyle = "Modern Glass"
            root.uiFontFamily = "Oxanium"
        } else if (name === "Spectrum") {
            root.clockStyle = "Caelestia Split"
            root.loginStyle = "Modern Glass"
            root.uiFontFamily = "Google Sans"
        }
    }

    Timer {
        id: settingsCloseCleanupTimer
        interval: 420
        repeat: false
        onTriggered: {
            if (!root.settingsOpen) {
                closeAllSettingsDrawers()
            }
        }
    }

    function getGridPosName(idx) {
        var names = [
            "Top Left",    "Top Center",    "Top Right",
            "Middle Left", "Middle Center", "Middle Right",
            "Bottom Left", "Bottom Center", "Bottom Right"
        ]
        return names[idx] !== undefined ? names[idx] : "Center"
    }

    function lockScreen() {
        root.isUnlocked = false
        root.userListOpen = false
        root.sessionMenuOpen = false
        root.isKeyboardOpen = false
        if (typeof Qt.inputMethod !== "undefined" && Qt.inputMethod) {
            Qt.inputMethod.hide()
        }
        root.powerMenuOpen = false
        root.settingsOpen = false
        closeAllSettingsDrawers()
        passwordInput.text = ""
        errorText.text = ""
        globalKeyHandler.forceActiveFocus()
    }

    function handleEscape() {
        if (root.shapeMenuOpen || root.paletteMenuOpen || root.boxMenuOpen ||
            root.clockStyleMenuOpen || root.clockPosMenuOpen || root.loginPosMenuOpen ||
            root.loginStyleMenuOpen || root.avatarOrientMenuOpen || root.avatarStyleMenuOpen ||
            root.avatarTintMenuOpen || root.unlockAnimMenuOpen || root.fontMenuOpen) {
            closeAllSettingsDrawers()
        } else if (root.userListOpen) {
            root.userListOpen = false
        } else if (root.sessionMenuOpen) {
            root.sessionMenuOpen = false
        } else if (root.settingsOpen) {
            root.settingsOpen = false
            settingsCloseCleanupTimer.restart()
            if (root.isUnlocked) passwordInput.forceActiveFocus()
        } else if (root.powerMenuOpen) {
            root.powerMenuOpen = false
            if (root.isUnlocked) passwordInput.forceActiveFocus()
        } else if (root.isKeyboardOpen) {
            root.isKeyboardOpen = false
            if (root.isUnlocked) passwordInput.forceActiveFocus()
        } else {
            lockScreen()
        }
    }

    Timer {
        id: focusTimer
        interval: 220
        running: false
        onTriggered: passwordInput.forceActiveFocus()
    }

    // ──────────────────────────────────────────
    // Accurate 12-Hour / 24-Hour Clock Formatting
    // ──────────────────────────────────────────
    function getFormattedTime() {
        var d = new Date()
        var hours = d.getHours()
        var minutes = d.getMinutes()
        var minsStr = (minutes < 10 ? "0" : "") + minutes
        if (root.is12Hour) {
            var h12 = hours % 12
            if (h12 === 0) h12 = 12
            var hStr = (h12 < 10 ? "0" : "") + h12
            return hStr + ":" + minsStr
        } else {
            var h24 = (hours < 10 ? "0" : "") + hours
            return h24 + ":" + minsStr
        }
    }

    function getFormattedAmPm() {
        var d = new Date()
        return d.getHours() >= 12 ? "PM" : "AM"
    }

    function updateClock() {
        var d = new Date()
        var hours = d.getHours()
        var minutes = d.getMinutes()
        var minsStr = (minutes < 10 ? "0" : "") + minutes
        if (root.is12Hour) {
            var h12 = hours % 12
            if (h12 === 0) h12 = 12
            root.clockHours = (h12 < 10 ? "0" : "") + h12
        } else {
            root.clockHours = (hours < 10 ? "0" : "") + hours
        }
        root.clockMinutes = minsStr
        root.clockAmPm = hours >= 12 ? "PM" : "AM"
        root.clockMonthName = Qt.formatDate(d, "MMMM").toUpperCase()
        root.clockDayNum = Qt.formatDate(d, "dd")
        root.clockWeekday = Qt.formatDate(d, "dddd")
        root.clockFullDate = Qt.formatDate(d, "dddd, MMMM d, yyyy").toUpperCase()
        root.clockYear = Qt.formatDate(d, "yyyy")
    }

    onIs12HourChanged: updateClock()

    // ──────────────────────────────────────────
    // Background & Live Real-Time Scene Blur
    // ──────────────────────────────────────────
    Item {
        id: bgSceneLayer
        anchors.fill: parent
        layer.enabled: true

        // Static Wallpaper Image
        Image {
            id: bgSharp
            anchors.fill: parent
            source: "bg.jpg"
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: root.width
            sourceSize.height: root.height
            smooth: true
            visible: root.bgType !== "video"
            opacity: root.isUnlocked ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }

        // Live Animated Video Wallpaper (QtMultimedia)
        MediaPlayer {
            id: bgMediaPlayer
            source: root.bgType === "video" ? Qt.resolvedUrl(root.bgFile || "bg.mp4") : ""
            loops: MediaPlayer.Infinite
            audioOutput: null
            videoOutput: bgVideoOutput
            Component.onCompleted: {
                if (root.bgType === "video") {
                    play()
                }
            }
        }

        VideoOutput {
            id: bgVideoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            visible: root.bgType === "video"
            opacity: root.isUnlocked ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }

        // Dedicated Blur Source Image (Poster frame bg.jpg: instant, zero GPU overhead)
        Image {
            id: bgBlurSource
            anchors.fill: parent
            source: "bg.jpg"
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: root.width
            sourceSize.height: root.height
            smooth: true
            visible: false
        }

        FastBlur {
            id: bgBlur
            anchors.fill: parent
            source: bgBlurSource
            radius: root.glassBlurRadius
            opacity: root.isUnlocked ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }

    // Ambient floating M3 geometric background shapes (Balanced Everywhere Layout)
    Item {
        id: ambientShapesContainer
        anchors.fill: parent
        visible: root.showLavaBlobs
        opacity: root.isUnlocked ? 0.65 : 0.38
        Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }

        Repeater {
            model: [
                // 1. Far Top-Left Corner (Outer Sky)
                { shape: MaterialShape.Triangle,     xRatio: 0.06, yRatio: 0.12, dx: 30, riseY: 130, sz: 105, alpha: 0.28, rotT: 38000, riseT: 20000, swayT: 13000 },

                // 2. Top-Center High Sky (Above Hair)
                { shape: MaterialShape.Diamond,      xRatio: 0.42, yRatio: 0.08, dx: -25, riseY: 110, sz: 90,  alpha: 0.26, rotT: 34000, riseT: 18000, swayT: 12000 },

                // 3. Top-Right Upper Sky (Above Moon)
                { shape: MaterialShape.Cookie9Sided, xRatio: 0.72, yRatio: 0.12, dx: -35, riseY: 140, sz: 120, alpha: 0.24, rotT: 44000, riseT: 24000, swayT: 16000 },

                // 4. Far-Right Upper Edge
                { shape: MaterialShape.Sunny,        xRatio: 0.91, yRatio: 0.32, dx: -30, riseY: 120, sz: 110, alpha: 0.25, rotT: 40000, riseT: 22000, swayT: 14000 },

                // 5. Mid-Left Outer Edge (Far Left Border)
                { shape: MaterialShape.Flower,       xRatio: 0.05, yRatio: 0.46, dx: 25,  riseY: 120, sz: 100, alpha: 0.26, rotT: 36000, riseT: 19000, swayT: 13000 },

                // 6. Mid-Right Ambient Space (Between User & Right Edge)
                { shape: MaterialShape.ClamShell,    xRatio: 0.68, yRatio: 0.58, dx: 35,  riseY: 130, sz: 115, alpha: 0.24, rotT: 42000, riseT: 23000, swayT: 15000 },

                // 7. Bottom-Left Corner (Under Arm)
                { shape: MaterialShape.Cookie4Sided, xRatio: 0.08, yRatio: 0.85, dx: 30,  riseY: 120, sz: 110, alpha: 0.26, rotT: 38000, riseT: 21000, swayT: 14000 },

                // 8. Bottom-Center Floor
                { shape: MaterialShape.Heart,        xRatio: 0.50, yRatio: 0.88, dx: -25, riseY: 100, sz: 95,  alpha: 0.28, rotT: 32000, riseT: 17000, swayT: 11000 },

                // 9. Far Bottom-Right Corner
                { shape: MaterialShape.VerySunny,    xRatio: 0.88, yRatio: 0.84, dx: -30, riseY: 130, sz: 115, alpha: 0.25, rotT: 42000, riseT: 22000, swayT: 15000 }
            ]

            delegate: Item {
                id: shapeWrapper
                readonly property real basePosX: modelData.xRatio * root.width
                readonly property real basePosY: modelData.yRatio * root.height
                readonly property real shapeSize: modelData.sz * s

                x: basePosX - shapeSize / 2
                y: basePosY - shapeSize / 2
                width: shapeSize
                height: shapeSize

                transformOrigin: Item.Center

                MaterialShape {
                    anchors.fill: parent
                    shape: modelData.shape
                    color: Qt.alpha(root.accentColor, modelData.alpha)
                    animationDuration: 1200
                }

                // Fluid Lava Lamp Motion: Gentle Vertical Drift
                SequentialAnimation {
                    loops: Animation.Infinite
                    running: root.showLavaBlobs
                    NumberAnimation {
                        target: shapeWrapper
                        property: "y"
                        to: shapeWrapper.basePosY - shapeWrapper.shapeSize / 2 - modelData.riseY * s
                        duration: modelData.riseT
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: shapeWrapper
                        property: "y"
                        to: shapeWrapper.basePosY - shapeWrapper.shapeSize / 2
                        duration: modelData.riseT
                        easing.type: Easing.InOutSine
                    }
                }

                // Gentle horizontal fluid sway
                SequentialAnimation {
                    loops: Animation.Infinite
                    running: root.showLavaBlobs
                    NumberAnimation {
                        target: shapeWrapper
                        property: "x"
                        to: shapeWrapper.basePosX - shapeWrapper.shapeSize / 2 + modelData.dx * s
                        duration: modelData.swayT
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: shapeWrapper
                        property: "x"
                        to: shapeWrapper.basePosX - shapeWrapper.shapeSize / 2 - modelData.dx * 0.5 * s
                        duration: modelData.swayT
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: shapeWrapper
                        property: "x"
                        to: shapeWrapper.basePosX - shapeWrapper.shapeSize / 2
                        duration: modelData.swayT
                        easing.type: Easing.InOutSine
                    }
                }

                // Continuous slow rotation
                NumberAnimation {
                    target: shapeWrapper
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: modelData.rotT
                    loops: Animation.Infinite
                    running: root.showLavaBlobs
                }

                // Subtle fluid breathing scale
                SequentialAnimation {
                    loops: Animation.Infinite
                    running: root.showLavaBlobs
                    NumberAnimation {
                        target: shapeWrapper
                        property: "scale"
                        to: 1.05
                        duration: modelData.riseT * 0.5
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: shapeWrapper
                        property: "scale"
                        to: 0.95
                        duration: modelData.riseT * 0.5
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    // Light Dark Tint
    Rectangle {
        anchors.fill: parent
        color: "#020306"
        opacity: root.isUnlocked ? 0.24 : 0.08
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    }

    // Soft Edge Vignette
    RadialGradient {
        anchors.fill: parent
        opacity: 0.55
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.7; color: "#15000000" }
            GradientStop { position: 1.0; color: "#b0010307" }
        }
    }
    }

    // Shared Gaussian Blur Source for Frosted Glass Cards (Live Screen Scene FBO)
    FastBlur {
        id: fullGlassBlur
        anchors.fill: parent
        source: bgSceneLayer
        radius: root.glassBlurRadius
        visible: false
    }

    // Background Click Handler
    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: {
            if (root.settingsOpen) {
                root.settingsOpen = false
                settingsCloseCleanupTimer.restart()
                return
            }
            if (root.userListOpen) { root.userListOpen = false; return }
            if (root.sessionMenuOpen) { root.sessionMenuOpen = false; return }
            if (root.powerMenuOpen) { root.powerMenuOpen = false; return }
            if (root.isKeyboardOpen) { root.isKeyboardOpen = false; return }

            if (!root.isUnlocked) {
                unlockScreen()
            } else {
                passwordInput.forceActiveFocus()
            }
        }
    }

    // ──────────────────────────────────────────
    // STATE 1: Lockscreen Intro Clock & Date (Right Side)
    // ──────────────────────────────────────────
    // ──────────────────────────────────────────
    // Clock Customization Container (9-Grid Kinetic Glide + 4 Styles + Card)
    // ──────────────────────────────────────────
    Item {
        id: clockContainer

        readonly property real cs: s * root.clockScale

        property real colonOpacity: 1.0
        SequentialAnimation on colonOpacity {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 0.35; duration: 750; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 750; easing.type: Easing.InOutSine }
        }

        readonly property real activeW: {
            if (root.clockStyle === "Caelestia Split") return styleCaelestiaSplit.implicitWidth
            if (root.clockStyle === "Classic Minimal") return styleClassicMinimal.implicitWidth
            if (root.clockStyle === "Two-Tier Stacked") return styleTwoTierStacked.implicitWidth
            if (root.clockStyle === "Compact Capsule") return styleCompactCapsule.width
            if (root.clockStyle === "Cyber HUD") return styleCyberHUD.implicitWidth
            if (root.clockStyle === "Editorial Typographic") return styleEditorialTypo.implicitWidth
            if (root.clockStyle === "Neo-Digital Capsule") return styleNeoDigital.width
            if (root.clockStyle === "Pixel Retro") return stylePixelRetro.implicitWidth
            return 300 * clockContainer.cs
        }

        readonly property real activeH: {
            if (root.clockStyle === "Caelestia Split") return styleCaelestiaSplit.implicitHeight
            if (root.clockStyle === "Classic Minimal") return styleClassicMinimal.implicitHeight
            if (root.clockStyle === "Two-Tier Stacked") return styleTwoTierStacked.implicitHeight
            if (root.clockStyle === "Compact Capsule") return styleCompactCapsule.height
            if (root.clockStyle === "Cyber HUD") return styleCyberHUD.implicitHeight
            if (root.clockStyle === "Editorial Typographic") return styleEditorialTypo.implicitHeight
            if (root.clockStyle === "Neo-Digital Capsule") return styleNeoDigital.height
            if (root.clockStyle === "Pixel Retro") return stylePixelRetro.implicitHeight
            return 80 * clockContainer.cs
        }

        width: Math.max(100 * s, activeW)
        height: Math.max(40 * s, activeH)

        x: {
            var baseX = root.getGridX(root.clockGridPos, width, 80 * s)
            if (root.isUnlocked && root.unlockAnimStyle === "Split Horizontal") return baseX - 140 * s
            return baseX
        }
        y: {
            var baseY = root.getGridY(root.clockGridPos, height, 60 * s, 100 * s)
            if (root.isUnlocked) {
                if (root.unlockAnimStyle === "Kinetic Slide") return baseY - 40 * s
                if (root.unlockAnimStyle === "Directional Sweep") return -height - 60 * s
                if (root.unlockAnimStyle === "Cyber Drop") return baseY + 70 * s
            }
            return baseY
        }
        scale: {
            if (root.isUnlocked) {
                if (root.unlockAnimStyle === "Morph Dissolve") return 0.85
                if (root.unlockAnimStyle === "Zoom Velocity") return 1.45
            }
            return 1.0
        }
        opacity: (!root.isUnlocked) ? root.uiOpacity : 0
        visible: opacity > 0
        z: 5

        Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        Behavior on y {
            NumberAnimation {
                duration: root.isUnlocked ? (root.unlockAnimStyle === "Directional Sweep" ? 350 : 380) : 450
                easing.type: root.isUnlocked ? (root.unlockAnimStyle === "Directional Sweep" ? Easing.InQuad : Easing.OutCubic) : Easing.OutCubic
            }
        }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: root.isUnlocked ? 350 : 400; easing.type: Easing.OutCubic } }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: root.updateClock()
        }

        // Toggleable Frosted Glass Background Card (Unscaled 1:1 on Screen!)
        FrostedGlassCard {
            id: clockGlassCard
            isClockCard: true
            anchors.fill: parent
            anchors.margins: -18 * clockContainer.cs
            radius: 24 * clockContainer.cs
            tintColor: Qt.alpha(root.glassBg, root.clockCardOpacity)
            borderColor: Qt.alpha(root.glassBorder, 0.40)
            borderWidth: 1.5 * s
            visible: root.clockCardEnabled
            opacity: root.clockCardEnabled ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        Item {
            id: clockScaler
            anchors.centerIn: parent
            width: clockContainer.activeW
            height: clockContainer.activeH

                // Style 1: Caelestia Split (Hours:Minutes | 3-Tier Date)
                Row {
                    id: styleCaelestiaSplit
                    opacity: root.clockStyle === "Caelestia Split" ? 1 : 0
                    scale: root.clockStyle === "Caelestia Split" ? 1.0 : 0.96
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    spacing: 16 * clockContainer.cs
                    anchors.centerIn: parent

                    // Left: Digital Hours:Minutes
                    Row {
                        spacing: 4 * clockContainer.cs
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.clockHours + ":" + root.clockMinutes
                            color: root.textPrimary
                            font.family: root.monoFont
                            font.pixelSize: 84 * clockContainer.cs
                            font.weight: Font.Bold
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: DropShadow { color: "#aa000000"; radius: Math.round(24 * root.clockScale); samples: 16 }
                        }

                        Text {
                            text: root.clockAmPm
                            color: root.accentColor
                            font.family: root.sansFont
                            font.pixelSize: 20 * clockContainer.cs
                            font.weight: Font.Bold
                            visible: root.is12Hour
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 14 * clockContainer.cs
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    // Vertical Separator Bar
                    Rectangle {
                        width: 2 * clockContainer.cs
                        height: 64 * clockContainer.cs
                        radius: 1 * clockContainer.cs
                        color: root.accentColor
                        opacity: 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    // Right: 3-Tier Date Block
                    Column {
                        spacing: 1 * clockContainer.cs
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.clockMonthName
                            color: root.textMuted
                            font.family: root.sansFont
                            font.pixelSize: 11 * clockContainer.cs
                            font.letterSpacing: 3 * clockContainer.cs
                            font.weight: Font.Bold
                        }

                        Text {
                            text: root.clockDayNum
                            color: root.textPrimary
                            font.family: root.sansFont
                            font.pixelSize: 34 * clockContainer.cs
                            font.weight: Font.Black
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: DropShadow { color: "#80000000"; radius: Math.round(10 * root.clockScale); samples: 10 }
                        }

                        Text {
                            text: root.clockWeekday
                            color: root.textSecondary
                            font.family: root.sansFont
                            font.pixelSize: 12 * clockContainer.cs
                            font.weight: Font.Medium
                        }
                    }
                }

                // Style 2: Classic Minimal (Horizontal Time with Date subtitle below)
                Column {
                    id: styleClassicMinimal
                    opacity: root.clockStyle === "Classic Minimal" ? 1 : 0
                    scale: root.clockStyle === "Classic Minimal" ? 1.0 : 0.96
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    spacing: 6 * clockContainer.cs
                    anchors.centerIn: parent

                    Row {
                        spacing: 10 * clockContainer.cs

                        Text {
                            text: root.clockHours + ":" + root.clockMinutes
                            color: root.textPrimary
                            font.family: root.monoFont
                            font.pixelSize: 96 * clockContainer.cs
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: DropShadow { color: "#aa000000"; radius: Math.round(24 * root.clockScale); samples: 16 }
                        }

                        Text {
                            text: root.clockAmPm
                            color: root.accentColor
                            font.family: root.sansFont
                            font.pixelSize: 20 * clockContainer.cs
                            font.weight: Font.Bold
                            visible: root.is12Hour
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 18 * clockContainer.cs
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    Row {
                        spacing: 10 * clockContainer.cs
                        Rectangle {
                            width: 7 * clockContainer.cs
                            height: 7 * clockContainer.cs
                            radius: 3.5 * clockContainer.cs
                            color: root.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                        Text {
                            text: root.clockFullDate
                            color: root.textSecondary
                            font.family: root.sansFont
                            font.pixelSize: 13 * clockContainer.cs
                            font.letterSpacing: 2 * clockContainer.cs
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: DropShadow { color: "#80000000"; radius: Math.round(10 * root.clockScale); samples: 10 }
                        }
                    }
                }

                // Style 3: Two-Tier Stacked (Hours stacked over Minutes)
                Row {
                    id: styleTwoTierStacked
                    opacity: root.clockStyle === "Two-Tier Stacked" ? 1 : 0
                    scale: root.clockStyle === "Two-Tier Stacked" ? 1.0 : 0.96
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    spacing: 16 * clockContainer.cs
                    anchors.centerIn: parent

                    Column {
                        spacing: -10 * clockContainer.cs
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.clockHours
                            color: root.textPrimary
                            font.family: root.monoFont
                            font.pixelSize: 68 * clockContainer.cs
                            font.weight: Font.ExtraBold
                            lineHeight: 0.9
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: DropShadow { color: "#aa000000"; radius: Math.round(20 * root.clockScale); samples: 16 }
                        }

                        Text {
                            text: root.clockMinutes
                            color: root.accentColor
                            font.family: root.monoFont
                            font.pixelSize: 68 * clockContainer.cs
                            font.weight: Font.ExtraBold
                            lineHeight: 0.9
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: DropShadow { color: "#aa000000"; radius: Math.round(20 * root.clockScale); samples: 16 }
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * clockContainer.cs

                        Rectangle {
                            height: 26 * clockContainer.cs
                            width: twoTierDateText.implicitWidth + 18 * clockContainer.cs
                            radius: 13 * clockContainer.cs
                            color: Qt.alpha(root.accentColor, 0.20)
                            border.color: Qt.alpha(root.accentColor, 0.40)
                            border.width: 1 * s

                            Text {
                                id: twoTierDateText
                                anchors.centerIn: parent
                                text: (root.clockWeekday.substring(0, 3) + ", " + root.clockMonthName.substring(0, 3) + " " + root.clockDayNum).toUpperCase()
                                color: "#ffffff"
                                font.family: root.sansFont
                                font.pixelSize: 11 * clockContainer.cs
                                font.weight: Font.Bold
                                font.letterSpacing: 1 * clockContainer.cs
                            }
                        }

                        Text {
                            text: root.clockAmPm
                            color: root.textSecondary
                            font.family: root.sansFont
                            font.pixelSize: 15 * clockContainer.cs
                            font.weight: Font.Bold
                            visible: root.is12Hour
                        }
                    }
                }

                // Style 4: Compact Capsule (Inline pill with time & date)
                Rectangle {
                    id: styleCompactCapsule
                    opacity: root.clockStyle === "Compact Capsule" ? 1 : 0
                    scale: root.clockStyle === "Compact Capsule" ? 1.0 : 0.96
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    height: 48 * clockContainer.cs
                    width: capsuleRow.implicitWidth + 36 * clockContainer.cs
                    radius: 24 * clockContainer.cs
                    anchors.centerIn: parent
                    color: "transparent"
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: DropShadow { color: "#50000000"; radius: Math.round(12 * root.clockScale); samples: 12 }

                    FrostedGlassCard {
                        radius: parent.radius
                        tintColor: root.glassBg
                        borderColor: root.glassBorder
                        borderWidth: 1.5 * s
                    }

                    Row {
                        id: capsuleRow
                        anchors.centerIn: parent
                        spacing: 12 * clockContainer.cs

                        Text {
                            text: root.clockHours + ":" + root.clockMinutes + (root.is12Hour ? (" " + root.clockAmPm) : "")
                            color: root.textPrimary
                            font.family: root.monoFont
                            font.pixelSize: 18 * clockContainer.cs
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 5 * clockContainer.cs
                            height: 5 * clockContainer.cs
                            radius: 2.5 * clockContainer.cs
                            color: root.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }

                        Text {
                            text: root.clockWeekday.substring(0, 3) + ", " + root.clockMonthName.substring(0, 3) + " " + root.clockDayNum
                            color: root.textSecondary
                            font.family: root.sansFont
                            font.pixelSize: 14 * clockContainer.cs
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Style 5: Cyber HUD (Futuristic Monospace Telemetry)
                Item {
                    id: styleCyberHUD
                    implicitWidth: cyberHUDCol.implicitWidth + 24 * clockContainer.cs
                    implicitHeight: cyberHUDCol.implicitHeight + 16 * clockContainer.cs
                    anchors.centerIn: parent
                    opacity: root.clockStyle === "Cyber HUD" ? 1 : 0
                    scale: root.clockStyle === "Cyber HUD" ? 1.0 : 0.96
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                    Column {
                        id: cyberHUDCol
                        anchors.centerIn: parent
                        spacing: 6 * clockContainer.cs

                        // Top Telemetry Header
                        Row {
                            spacing: 8 * clockContainer.cs
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                height: 18 * clockContainer.cs
                                width: cyberTagText.implicitWidth + 14 * clockContainer.cs
                                radius: 4 * clockContainer.cs
                                color: Qt.alpha(root.accentColor, 0.25)
                                border.color: Qt.alpha(root.accentColor, 0.6)
                                border.width: 1 * s

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4 * clockContainer.cs
                                    Rectangle {
                                        width: 4 * clockContainer.cs
                                        height: 4 * clockContainer.cs
                                        radius: 2 * clockContainer.cs
                                        color: root.accentColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        id: cyberTagText
                                        text: "SYS // SYNCED"
                                        color: root.accentColor
                                        font.family: root.dotMatrixFontFamily
                                        font.pixelSize: 8.5 * clockContainer.cs
                                        font.letterSpacing: 1.5 * clockContainer.cs
                                        font.weight: Font.Bold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Text {
                                text: "// " + root.clockYear + "." + Qt.formatDate(new Date(), "MM.dd")
                                color: root.textMuted
                                font.family: root.dotMatrixFontFamily
                                font.pixelSize: 10.5 * clockContainer.cs
                                font.letterSpacing: 1 * clockContainer.cs
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "[" + root.clockAmPm + "]"
                                color: root.accentColor
                                font.family: root.dotMatrixFontFamily
                                font.pixelSize: 10.5 * clockContainer.cs
                                font.weight: Font.Bold
                                visible: root.is12Hour
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Main Digits with Cyber HUD Brackets
                        Row {
                            spacing: 8 * clockContainer.cs
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "["
                                color: Qt.alpha(root.accentColor, 0.65)
                                font.family: root.cyberHudMono
                                font.pixelSize: 68 * clockContainer.cs
                                font.weight: Font.Light
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.clockHours
                                color: root.textPrimary
                                font.family: root.dotMatrixFontFamily
                                font.pixelSize: 72 * clockContainer.cs
                                font.weight: Font.Bold
                                layer.enabled: true
                                layer.smooth: true
                                layer.effect: DropShadow { color: "#aa000000"; radius: Math.round(20 * root.clockScale); samples: 16 }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: ":"
                                color: root.accentColor
                                font.family: root.dotMatrixFontFamily
                                font.pixelSize: 66 * clockContainer.cs
                                font.weight: Font.Bold
                                opacity: clockContainer.colonOpacity
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.clockMinutes
                                color: root.textPrimary
                                font.family: root.dotMatrixFontFamily
                                font.pixelSize: 72 * clockContainer.cs
                                font.weight: Font.Bold
                                layer.enabled: true
                                layer.smooth: true
                                layer.effect: DropShadow { color: "#aa000000"; radius: Math.round(20 * root.clockScale); samples: 16 }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "]"
                                color: Qt.alpha(root.accentColor, 0.65)
                                font.family: root.cyberHudMono
                                font.pixelSize: 68 * clockContainer.cs
                                font.weight: Font.Light
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Bottom Telemetry Gridline & Weekday
                        Row {
                            spacing: 10 * clockContainer.cs
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                width: 32 * clockContainer.cs
                                height: 1 * s
                                color: Qt.alpha(root.accentColor, 0.45)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.clockWeekday.toUpperCase() + " // " + root.clockMonthName.substring(0, 3) + " " + root.clockDayNum
                                color: root.textSecondary
                                font.family: root.dotMatrixFontFamily
                                font.pixelSize: 11 * clockContainer.cs
                                font.letterSpacing: 2.5 * clockContainer.cs
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 32 * clockContainer.cs
                                height: 1 * s
                                color: Qt.alpha(root.accentColor, 0.45)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // Style 6: Editorial Typographic (Wireframe Light Hours + Bold Accent Minutes)
                Item {
                    id: styleEditorialTypo
                    implicitWidth: editorialCol.implicitWidth + 24 * clockContainer.cs
                    implicitHeight: editorialCol.implicitHeight + 16 * clockContainer.cs
                    anchors.centerIn: parent
                    opacity: root.clockStyle === "Editorial Typographic" ? 1 : 0
                    scale: root.clockStyle === "Editorial Typographic" ? 1.0 : 0.96
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                    Column {
                        id: editorialCol
                        anchors.centerIn: parent
                        spacing: 4 * clockContainer.cs

                        Row {
                            spacing: 8 * clockContainer.cs
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: root.clockHours
                                color: root.textPrimary
                                font.family: root.sansFont
                                font.pixelSize: 92 * clockContainer.cs
                                font.weight: Font.ExtraLight
                                anchors.verticalCenter: parent.verticalCenter
                                layer.enabled: true
                                layer.smooth: true
                                layer.effect: DropShadow { color: "#80000000"; radius: Math.round(20 * root.clockScale); samples: 14 }
                            }

                            Rectangle {
                                width: 2 * clockContainer.cs
                                height: 60 * clockContainer.cs
                                radius: 1 * clockContainer.cs
                                color: root.accentColor
                                opacity: 0.65
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.clockMinutes
                                color: root.accentColor
                                font.family: root.sansFont
                                font.pixelSize: 92 * clockContainer.cs
                                font.weight: Font.Black
                                anchors.verticalCenter: parent.verticalCenter
                                layer.enabled: true
                                layer.smooth: true
                                layer.effect: DropShadow { color: "#aa000000"; radius: Math.round(24 * root.clockScale); samples: 16 }
                            }

                            Rectangle {
                                height: 22 * clockContainer.cs
                                width: editorialAmPmText.implicitWidth + 14 * clockContainer.cs
                                radius: 11 * clockContainer.cs
                                color: Qt.alpha(root.accentColor, 0.18)
                                border.color: Qt.alpha(root.accentColor, 0.45)
                                border.width: 1 * s
                                visible: root.is12Hour
                                anchors.top: parent.top
                                anchors.topMargin: 12 * clockContainer.cs

                                Text {
                                    id: editorialAmPmText
                                    anchors.centerIn: parent
                                    text: root.clockAmPm
                                    color: "#ffffff"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * clockContainer.cs
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.clockWeekday.toUpperCase() + "  ·  " + root.clockMonthName + " " + root.clockDayNum
                            color: root.textSecondary
                            font.family: root.sansFont
                            font.pixelSize: 12 * clockContainer.cs
                            font.letterSpacing: 3.5 * clockContainer.cs
                            font.weight: Font.Medium
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: DropShadow { color: "#70000000"; radius: Math.round(10 * root.clockScale); samples: 10 }
                        }
                    }
                }

                // Style 7: Neo-Digital Capsule (Cyber Glass Pill with LED Status Meters)
                Rectangle {
                    id: styleNeoDigital
                    implicitWidth: neoContentRow.implicitWidth + 36 * clockContainer.cs
                    implicitHeight: 58 * clockContainer.cs
                    width: implicitWidth
                    height: implicitHeight
                    radius: 18 * clockContainer.cs
                    anchors.centerIn: parent
                    color: "transparent"
                    opacity: root.clockStyle === "Neo-Digital Capsule" ? 1 : 0
                    scale: root.clockStyle === "Neo-Digital Capsule" ? 1.0 : 0.96
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: DropShadow { color: "#60000000"; radius: Math.round(16 * root.clockScale); samples: 14 }

                    FrostedGlassCard {
                        radius: parent.radius
                        tintColor: root.glassBg
                        borderColor: root.glassBorder
                        borderWidth: 1.5 * s
                    }

                    Row {
                        id: neoContentRow
                        anchors.centerIn: parent
                        spacing: 14 * clockContainer.cs

                        // LED Signal Bars
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3 * clockContainer.cs

                            Rectangle { width: 14 * clockContainer.cs; height: 3 * clockContainer.cs; radius: 1.5 * s; color: root.accentColor }
                            Rectangle { width: 14 * clockContainer.cs; height: 3 * clockContainer.cs; radius: 1.5 * s; color: root.accentColor; opacity: 0.75 }
                            Rectangle { width: 14 * clockContainer.cs; height: 3 * clockContainer.cs; radius: 1.5 * s; color: root.accentColor; opacity: 0.50 }
                            Rectangle { width: 14 * clockContainer.cs; height: 3 * clockContainer.cs; radius: 1.5 * s; color: root.accentColor; opacity: clockContainer.colonOpacity }
                        }

                        // Monospace Time
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * clockContainer.cs

                            Text {
                                text: root.clockHours
                                color: root.textPrimary
                                font.family: root.techDisplayFont
                                font.pixelSize: 34 * clockContainer.cs
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: ":"
                                color: root.accentColor
                                font.family: root.techDisplayFont
                                font.pixelSize: 32 * clockContainer.cs
                                font.weight: Font.Bold
                                opacity: clockContainer.colonOpacity
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.clockMinutes
                                color: root.textPrimary
                                font.family: root.techDisplayFont
                                font.pixelSize: 34 * clockContainer.cs
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Vertical Separator
                        Rectangle {
                            width: 1 * s
                            height: 28 * clockContainer.cs
                            color: Qt.rgba(1, 1, 1, 0.18)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // 2-Tier Date & AmPm
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * clockContainer.cs

                            Text {
                                text: root.clockWeekday.substring(0, 3).toUpperCase() + " " + root.clockDayNum
                                color: root.textPrimary
                                font.family: root.techDisplayFont
                                font.pixelSize: 12 * clockContainer.cs
                                font.weight: Font.Bold
                            }

                            Text {
                                text: root.clockMonthName.substring(0, 3).toUpperCase() + (root.is12Hour ? (" · " + root.clockAmPm) : "")
                                color: root.accentColor
                                font.family: root.techDisplayFont
                                font.pixelSize: 10 * clockContainer.cs
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                // Style 8: Pixel Retro (Authentic 8-Bit Pixel Art from pixel-sakura / pixel-coffee)
                Item {
                    id: stylePixelRetro
                    implicitWidth: pixelRetroCol.implicitWidth + 24 * clockContainer.cs
                    implicitHeight: pixelRetroCol.implicitHeight + 16 * clockContainer.cs
                    anchors.centerIn: parent
                    opacity: root.clockStyle === "Pixel Retro" ? 1 : 0
                    scale: root.clockStyle === "Pixel Retro" ? 1.0 : 0.96
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                    Column {
                        id: pixelRetroCol
                        anchors.centerIn: parent
                        spacing: 4 * clockContainer.cs

                        // Time Digits
                        Row {
                            spacing: 4 * clockContainer.cs
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: root.clockHours
                                color: root.textPrimary
                                font.family: root.pixelFontFamily
                                font.pixelSize: 74 * clockContainer.cs
                                font.bold: true
                                layer.enabled: true
                                layer.smooth: true
                                layer.effect: DropShadow { color: "#aa000000"; radius: Math.round(18 * root.clockScale); samples: 16 }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: ":"
                                color: root.accentColor
                                font.family: root.pixelFontFamily
                                font.pixelSize: 70 * clockContainer.cs
                                font.bold: true
                                opacity: clockContainer.colonOpacity
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.clockMinutes
                                color: root.textPrimary
                                font.family: root.pixelFontFamily
                                font.pixelSize: 74 * clockContainer.cs
                                font.bold: true
                                layer.enabled: true
                                layer.smooth: true
                                layer.effect: DropShadow { color: "#aa000000"; radius: Math.round(18 * root.clockScale); samples: 16 }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // 12-Hour Am/Pm Pill
                            Rectangle {
                                height: 20 * clockContainer.cs
                                width: pixelAmPmText.implicitWidth + 12 * clockContainer.cs
                                radius: 4 * clockContainer.cs
                                color: Qt.alpha(root.accentColor, 0.25)
                                border.color: root.accentColor
                                border.width: 1 * s
                                visible: root.is12Hour
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: pixelAmPmText
                                    anchors.centerIn: parent
                                    text: root.clockAmPm
                                    color: root.accentColor
                                    font.family: root.pixelFontFamily
                                    font.pixelSize: 10 * clockContainer.cs
                                    font.bold: true
                                }
                            }
                        }

                        // Pixel Date
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (root.clockWeekday + ", " + root.clockMonthName + " " + root.clockDayNum).toUpperCase()
                            color: root.accentColor
                            font.family: root.pixelFontFamily
                            font.pixelSize: 12 * clockContainer.cs
                            font.letterSpacing: 2 * clockContainer.cs
                            font.bold: true
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: DropShadow { color: "#80000000"; radius: Math.round(10 * root.clockScale); samples: 12 }
                        }

                        // Pixel Sakura Track Ruler (Line + 11 Ticks)
                        Item {
                            width: Math.max(140 * clockContainer.cs, pixelRetroCol.implicitWidth * 0.75)
                            height: 10 * clockContainer.cs
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                width: parent.width
                                height: 1.5 * s
                                color: Qt.alpha(root.accentColor, 0.45)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Row {
                                anchors.fill: parent
                                spacing: (parent.width - (11 * 2 * s)) / 10

                                Repeater {
                                    model: 11
                                    Rectangle {
                                        width: 2 * s
                                        height: 6 * s
                                        color: (index === 0 || index === 5 || index === 10) ? root.accentColor : Qt.alpha(root.accentColor, 0.55)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }
        }
    }

    // ──────────────────────────────────────────
    // Lockscreen Unlock Hint (Bottom Centered)
    // ──────────────────────────────────────────
    Item {
        id: lockscreenHintItem
        anchors.fill: parent
        opacity: (!root.isUnlocked) ? root.uiOpacity : 0
        visible: opacity > 0
        z: 6

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48 * s
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10 * s

            Text { text: "·"; color: root.accentColor; font.family: root.monoFont; font.pixelSize: 16 * s; opacity: 0.8; anchors.verticalCenter: parent.verticalCenter }
            Text {
                id: unlockHint
                text: "Click anywhere or press any key to unlock"
                color: root.textSecondary
                font.family: root.sansFont
                font.pixelSize: 13 * s
                font.letterSpacing: 1.5 * s
                anchors.verticalCenter: parent.verticalCenter
            }
            Text { text: "·"; color: root.accentColor; font.family: root.monoFont; font.pixelSize: 16 * s; opacity: 0.8; anchors.verticalCenter: parent.verticalCenter }

            SequentialAnimation {
                loops: Animation.Infinite
                running: !root.isUnlocked
                NumberAnimation { target: unlockHint; property: "opacity"; from: 0.85; to: 0.3; duration: 1300; easing.type: Easing.InOutQuad }
                NumberAnimation { target: unlockHint; property: "opacity"; from: 0.3; to: 0.85; duration: 1300; easing.type: Easing.InOutQuad }
            }
        }
    }

    // ──────────────────────────────────────────
    // STATE 2: Right-Aligned Login Panel (Kaneki Layout + Themed Glass Password Box)
    // ──────────────────────────────────────────
    // ──────────────────────────────────────────
    // STATE 2: Login Container (9-Grid Kinetic Engine, Avatar Orientations, Box Styles)
    // ──────────────────────────────────────────
    Item {
        id: loginPanelContainer
        objectName: "loginPanelContainer"
        x: {
            var baseX = root.getGridX(root.loginGridPos, width, 80 * s)
            if (!root.isUnlocked && root.unlockAnimStyle === "Split Horizontal") return baseX + 140 * s
            return baseX
        }
        y: {
            var baseY = root.getGridY(root.loginGridPos, height, 60 * s, 100 * s)
            if (root.isKeyboardOpen) {
                var maxAllowedY = root.height - 305 * s - height - 25 * s
                if (baseY > maxAllowedY) baseY = maxAllowedY
            }
            if (!root.isUnlocked) {
                if (root.unlockAnimStyle === "Kinetic Slide") return baseY + 45 * s
                if (root.unlockAnimStyle === "Directional Sweep") return root.height + 60 * s
                if (root.unlockAnimStyle === "Cyber Drop") return baseY - 120 * s
            }
            return baseY
        }
        scale: {
            if (!root.isUnlocked) {
                if (root.unlockAnimStyle === "Kinetic Slide") return 0.94
                if (root.unlockAnimStyle === "Morph Dissolve") return 0.88
                if (root.unlockAnimStyle === "Zoom Velocity") return 0.35
            }
            return 1.0
        }
        width: Math.max(280 * s, loginContentInner.width * root.loginScale)
        height: Math.max(90 * s, loginContentInner.height * root.loginScale)
        opacity: root.isUnlocked ? root.uiOpacity : 0
        visible: opacity > 0
        z: 10

        Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        Behavior on y {
            NumberAnimation {
                duration: root.isUnlocked ? (root.unlockAnimStyle === "Directional Sweep" ? 520 : (root.unlockAnimStyle === "Cyber Drop" ? 520 : 460)) : 350
                easing.type: root.isUnlocked ? (root.unlockAnimStyle === "Cyber Drop" ? Easing.OutBounce : Easing.OutBack) : Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.isUnlocked ? (root.unlockAnimStyle === "Zoom Velocity" ? 540 : 460) : 300
                easing.type: root.isUnlocked ? (root.unlockAnimStyle === "Zoom Velocity" ? Easing.OutBack : Easing.OutBack) : Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.isUnlocked ? 380 : 300
                easing.type: Easing.OutCubic
            }
        }

        // Toggleable Frosted Glass Background Card (Unscaled 1:1 on Screen!)
        FrostedGlassCard {
            id: loginGlassCard
            anchors.fill: parent
            anchors.margins: -18 * s * Math.min(1.2, root.loginScale)
            radius: 24 * s * Math.min(1.2, root.loginScale)
            tintColor: Qt.alpha(root.glassBg, root.loginCardOpacity)
            borderColor: Qt.alpha(root.glassBorder, 0.40)
            borderWidth: 1.5 * s
            visible: root.loginCardEnabled
            opacity: root.loginCardEnabled ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        Item {
            id: loginScaler
            anchors.centerIn: parent
            width: loginContentInner.width
            height: loginContentInner.height
            scale: root.loginScale
            transformOrigin: Item.Center

            Item {
                id: loginContentInner
                readonly property real pwBoxW: 280 * s
                readonly property real pwBoxH: 52 * s
                readonly property real avatarSize: Math.round(80 * s * root.avatarScale)
                readonly property bool isTop: root.avatarOrientation === "Top Center" || root.avatarOrientation === "Top Left" || root.avatarOrientation === "Top Right"
                readonly property bool isBottom: root.avatarOrientation === "Bottom Center" || root.avatarOrientation === "Bottom Left" || root.avatarOrientation === "Bottom Right"
                readonly property bool isHidden: !root.avatarVisible || root.avatarOrientation === "Hidden"

                width: {
                    if (isHidden) return pwBoxW
                    if (root.avatarOrientation === "Right" || root.avatarOrientation === "Left") {
                        return pwBoxW + 20 * s + avatarSize
                    }
                    if (root.avatarOrientation === "Top Left") {
                        return Math.max(pwBoxW, avatarSize + 14 * s + userDisplayNameRow.width)
                    }
                    return Math.max(pwBoxW, avatarSize)
                }

                height: {
                    if (isHidden) {
                        return userDisplayNameRow.height + 10 * s + pwBoxH
                    }
                    if (root.avatarOrientation === "Center") {
                        return userDisplayNameRow.height + 10 * s + avatarSize + 12 * s + pwBoxH
                    }
                    if (root.avatarOrientation === "Top Center") {
                        return avatarSize + 12 * s + userDisplayNameRow.height + 12 * s + pwBoxH
                    }
                    if (root.avatarOrientation === "Top Left" || root.avatarOrientation === "Top Right") {
                        return avatarSize + 14 * s + pwBoxH
                    }
                    if (isBottom) {
                        return userDisplayNameRow.height + 10 * s + pwBoxH + 14 * s + avatarSize
                    }
                    return Math.max(avatarSize, userDisplayNameRow.height + 10 * s + pwBoxH)
                }

                // Username display with Accent Dot
                Row {
                    id: userDisplayNameRow
                    spacing: 8 * s
                    x: {
                        if (root.avatarOrientation === "Center" || root.avatarOrientation === "Top Center" || root.avatarOrientation === "Bottom Center") return (loginContentInner.pwBoxW - width) / 2
                        if (root.avatarOrientation === "Top Left") return loginContentInner.avatarSize + 14 * s
                        if (root.avatarOrientation === "Top Right") return 0
                        if (root.avatarOrientation === "Left") return loginContentInner.avatarSize + 20 * s
                        return 0
                    }
                    y: {
                        if (root.avatarOrientation === "Top Center") return loginContentInner.avatarSize + 12 * s
                        if (root.avatarOrientation === "Top Left" || root.avatarOrientation === "Top Right") {
                            return (loginContentInner.avatarSize - height) / 2
                        }
                        return 0
                    }

                    Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: root.loginStyle === "Pixel Retro" ? 7 * s : 6 * s
                        height: width
                        radius: (root.loginStyle === "Pixel Retro" || root.loginStyle === "Cyber Terminal") ? 0 : (width / 2)
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    Text {
                        id: userDisplayName
                        text: {
                            if (root.loginStyle === "Pixel Retro") return root.activeUser.realName.toUpperCase()
                            if (root.loginStyle === "Cyber Terminal") return "// AUTH_ID :: [" + (root.activeUser.realName || root.activeUser.loginName).toUpperCase() + "]"
                            return root.activeUser.realName
                        }
                        color: root.textPrimary
                        font.family: {
                            if (root.loginStyle === "Pixel Retro") return root.pixelFontFamily
                            if (root.loginStyle === "Cyber Terminal") return root.cyberHudMono
                            if (root.loginStyle === "Editorial Minimal") return root.cinzelFontFamily
                            return root.sansFont
                        }
                        font.pixelSize: root.loginStyle === "Cyber Terminal" ? 13 * s : (root.loginStyle === "Pixel Retro" ? 17 * s : 16 * s)
                        font.weight: root.loginStyle === "Editorial Minimal" ? Font.Medium : Font.Bold
                        font.letterSpacing: root.loginStyle === "Pixel Retro" ? 3 * s : (root.loginStyle === "Editorial Minimal" ? 2 * s : 0.5 * s)
                    }
                }

                // ─── Themed Glass Password Box (4 Box Styles + Fixed Typing Pool) ───
                Rectangle {
                    id: passwordBoxRect
                    x: {
                        if (root.avatarOrientation === "Left") return loginContentInner.avatarSize + 20 * s
                        return 0
                    }
                    y: {
                        if (root.avatarOrientation === "Center") {
                            return userDisplayNameRow.height + 10 * s + loginContentInner.avatarSize + 12 * s
                        }
                        if (root.avatarOrientation === "Top Center") {
                            return userDisplayNameRow.y + userDisplayNameRow.height + 12 * s
                        }
                        if (root.avatarOrientation === "Top Left" || root.avatarOrientation === "Top Right") {
                            return loginContentInner.avatarSize + 14 * s
                        }
                        return userDisplayNameRow.height + 10 * s
                    }
                    width: loginContentInner.pwBoxW
                    height: loginContentInner.pwBoxH
                    radius: {
                        if (root.loginStyle === "Pixel Retro" || root.loginStyle === "Cyber Terminal") return 4 * s
                        if (root.loginStyle === "Editorial Minimal") return 2 * s
                        return root.getBoxRadius(height)
                    }
                    color: "transparent"

                    FrostedGlassCard {
                        radius: parent.radius
                        tintColor: {
                            if (root.loginStyle === "Editorial Minimal" || root.boxStyle === "Minimal Underline") return Qt.alpha(root.glassBg, 0.20)
                            if (root.loginStyle === "Pixel Retro") return Qt.alpha(root.glassBg, 0.50)
                            if (root.loginStyle === "Cyber Terminal") return Qt.alpha(root.glassBg, 0.35)
                            return root.boxStyle === "Minimal Underline" ? Qt.alpha(root.glassBg, 0.30) : (passwordInput.activeFocus ? Qt.alpha(root.accentColor, 0.28) : root.glassBg)
                        }
                        borderColor: {
                            if (root.loginStyle === "Editorial Minimal" || root.boxStyle === "Minimal Underline") return "transparent"
                            return passwordInput.activeFocus ? root.accentColor : root.glassBorder
                        }
                        borderWidth: (root.loginStyle === "Editorial Minimal" || root.boxStyle === "Minimal Underline") ? 0 : (root.loginStyle === "Pixel Retro" ? 2 * s : 1.5 * s)
                    }

                    property real pressBloom: 0.0

                    // Outer shadow handled without conflicting FBO layer
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: passwordInput.activeFocus ? root.highlightGlow : "transparent"
                        border.width: passwordInput.activeFocus ? 2 * s : 0
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 250 } }
                    Behavior on border.color { ColorAnimation { duration: 250 } }

                    NumberAnimation {
                        id: bloomAnim
                        target: passwordBoxRect
                        property: "pressBloom"
                        from: 0.55
                        to: 0.0
                        duration: 350
                        easing.type: Easing.OutQuad
                    }

                    // Inner Pill-Conforming Glow (Always strictly matched to parent.radius, ZERO rectangular scissor clipping!)
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(root.accentColor, 0.38)
                        opacity: passwordBoxRect.pressBloom
                        visible: opacity > 0
                    }

                    // Minimal Underline glowing bar
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: passwordInput.activeFocus ? 2.5 * s : 1.5 * s
                        radius: 1 * s
                        color: passwordInput.activeFocus ? root.accentColor : Qt.alpha(root.glassBorder, 0.65)
                        visible: root.loginStyle === "Editorial Minimal" || root.boxStyle === "Minimal Underline"
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    // Split Badge circular badge
                    Rectangle {
                        id: lockBadgeCircle
                        width: parent.height - 10 * s
                        height: width
                        radius: width / 2
                        anchors.left: parent.left
                        anchors.leftMargin: 5 * s
                        anchors.verticalCenter: parent.verticalCenter
                        color: passwordInput.activeFocus ? Qt.alpha(root.accentColor, 0.40) : Qt.alpha(root.accentColor, 0.15)
                        border.color: root.accentColor
                        border.width: 1.5 * s
                        visible: root.boxStyle === "Split Badge" && root.loginStyle === "Modern Glass"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // Lock Icon with Fixed Safe Bounds
                    Item {
                        id: lockIconContainer
                        width: root.boxStyle === "Split Badge" ? (parent.height - 10 * s) : (28 * s)
                        height: parent.height
                        anchors.left: parent.left
                        anchors.leftMargin: root.boxStyle === "Split Badge" ? 5 * s : 12 * s

                        Text {
                            id: lockIcon
                            anchors.centerIn: parent
                            text: {
                                if (root.loginStyle === "Cyber Terminal") return "[>"
                                return "󰌾"
                            }
                            font.family: root.loginStyle === "Cyber Terminal" ? root.cyberHudMono : root.monoFont
                            font.pixelSize: root.loginStyle === "Cyber Terminal" ? 13 * s : 16 * s
                            color: passwordInput.activeFocus ? root.accentColor : root.textMuted
                            scale: passwordInput.activeFocus ? 1.15 : 1.0

                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        }
                    }

                    // Dedicated Text Input Region (Starts strictly AFTER lockIconContainer)
                    Item {
                        anchors.left: lockIconContainer.right
                        anchors.leftMargin: 8 * s
                        anchors.right: submitArrow.left
                        anchors.rightMargin: 8 * s
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        visible: !root.isLoggingIn
                        clip: true

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Normal
                            color: "transparent"
                            font.family: root.sansFont
                            font.pixelSize: 14 * s
                            font.letterSpacing: 2 * s
                            cursorVisible: false
                            cursorDelegate: Item { visible: false }
                            focus: true
                            inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Escape) {
                                    handleEscape()
                                    event.accepted = true
                                }
                            }

                            onTextChanged: {
                                errorText.text = ""
                            }

                            onAccepted: doLogin()

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (root.loginStyle === "Pixel Retro") return "PASSWORD..."
                                    if (root.loginStyle === "Cyber Terminal") return "> AUTH_CODE..."
                                    if (root.loginStyle === "Editorial Minimal") return "Password..."
                                    return "Password..."
                                }
                                color: root.textMuted
                                font.family: {
                                    if (root.loginStyle === "Pixel Retro") return root.pixelFontFamily
                                    if (root.loginStyle === "Cyber Terminal") return root.cyberHudMono
                                    if (root.loginStyle === "Editorial Minimal") return root.cinzelFontFamily
                                    return root.sansFont
                                }
                                font.pixelSize: 13 * s
                                font.letterSpacing: root.loginStyle === "Pixel Retro" ? 2 * s : 0
                                visible: passwordInput.text.length === 0
                                opacity: 0.65
                            }

                            // Pre-allocated Fixed Pool of 24 Animated Dots with Android 14 / M3 Cooldown Morphing!
                            Row {
                                id: dotsContainer
                                anchors.centerIn: parent
                                spacing: 4 * s

                                Repeater {
                                    id: dotsRepeater
                                    model: 24

                                    Item {
                                        id: dotWrapper
                                        property bool isShown: index < passwordInput.text.length
                                        property var randomShape: root.passwordM3Shapes[Math.floor(Math.random() * root.passwordM3Shapes.length)]
                                        property bool isMorphedToCircle: false

                                        width: isShown ? 13 * s : 0
                                        height: 14 * s
                                        visible: width > 0

                                        Timer {
                                            id: morphTimer
                                            interval: 500 // 0.5-second cooldown per user preference!
                                            repeat: false
                                            onTriggered: {
                                                dotWrapper.isMorphedToCircle = true
                                            }
                                        }

                                        onIsShownChanged: {
                                            if (isShown) {
                                                isMorphedToCircle = false
                                                randomShape = root.passwordM3Shapes[Math.floor(Math.random() * root.passwordM3Shapes.length)]
                                                morphTimer.restart()
                                            } else {
                                                morphTimer.stop()
                                                isMorphedToCircle = false
                                            }
                                        }

                                        Behavior on width {
                                            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                                        }

                                        // Pixel Retro Dot
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 8 * s
                                            height: 8 * s
                                            color: "#ffffff"
                                            visible: root.loginStyle === "Pixel Retro" && dotWrapper.isShown
                                        }

                                        // Cyber Terminal Dot
                                        Text {
                                            anchors.centerIn: parent
                                            text: "█"
                                            font.family: root.cyberHudMono
                                            font.pixelSize: 12 * s
                                            color: root.accentColor
                                            visible: root.loginStyle === "Cyber Terminal" && dotWrapper.isShown
                                        }

                                        // Modern Glass / M3 Shape Dot
                                        MaterialShape {
                                            anchors.centerIn: parent
                                            width: dotWrapper.isMorphedToCircle ? 8.5 * s : 12 * s
                                            height: width
                                            shape: dotWrapper.isMorphedToCircle ? MaterialShape.Circle : dotWrapper.randomShape
                                            color: "#ffffff"
                                            scale: dotWrapper.isShown ? 1.0 : 0.0
                                            rotation: dotWrapper.isShown ? (dotWrapper.isMorphedToCircle ? 0 : 15) : -25
                                            animationDuration: 250
                                            visible: root.loginStyle !== "Pixel Retro" && root.loginStyle !== "Cyber Terminal"

                                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                            Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Click Bloom Feedback across entire box (Zero scissor clipping!)
                    MouseArea {
                        id: boxPressMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                        z: 1
                        onPressed: {
                            passwordInput.forceActiveFocus()
                            bloomAnim.restart()
                        }
                    }

                    // Spinner while logging in
                    Item {
                        id: spinnerItem
                        width: 24 * s
                        height: 24 * s
                        anchors.centerIn: parent
                        visible: root.isLoggingIn

                        Text {
                            anchors.centerIn: parent
                            text: "󰑮"
                            font.family: root.monoFont
                            font.pixelSize: 18 * s
                            color: root.accentColor

                            RotationAnimator on rotation {
                                from: 0
                                to: 360
                                duration: 800
                                loops: Animation.Infinite
                                running: root.isLoggingIn
                            }
                        }
                    }

                    // Submit Action Arrow Pill (Morphs into authentic M3 Arrowhead when typing!)
                    Item {
                        id: submitArrow
                        z: 10
                        width: {
                            if (root.loginStyle === "Pixel Retro") return 54 * s
                            if (root.loginStyle === "Cyber Terminal") return 48 * s
                            return 32 * s
                        }
                        height: 32 * s
                        anchors.right: parent.right
                        anchors.rightMargin: 8 * s
                        anchors.verticalCenter: parent.verticalCenter
                        scale: submitMa.pressed ? 0.92 : (passwordInput.text.length > 0 ? 1.05 : 1.0)
                        visible: !root.isLoggingIn

                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                        // Background shape for Modern Glass / Editorial
                        MaterialShape {
                            anchors.fill: parent
                            shape: passwordInput.text.length > 0 ? MaterialShape.Arrow : MaterialShape.Circle
                            rotation: passwordInput.text.length > 0 ? 90 : 0
                            color: passwordInput.text.length > 0 ? root.accentColor : (submitMa.containsMouse ? Qt.alpha(root.accentColor, 0.25) : Qt.rgba(1, 1, 1, 0.08))
                            animationDuration: 280
                            visible: root.loginStyle !== "Pixel Retro" && root.loginStyle !== "Cyber Terminal"

                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on rotation { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                        }

                        // Retro Pixel Button Pill
                        Rectangle {
                            anchors.fill: parent
                            radius: 3 * s
                            color: passwordInput.text.length > 0 ? root.accentColor : (submitMa.containsMouse ? Qt.alpha(root.accentColor, 0.35) : Qt.rgba(1, 1, 1, 0.08))
                            border.color: root.accentColor
                            border.width: 1.5 * s
                            visible: root.loginStyle === "Pixel Retro" || root.loginStyle === "Cyber Terminal"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: root.loginStyle === "Pixel Retro" ? "LOGIN" : "EXEC"
                                font.family: root.loginStyle === "Pixel Retro" ? root.pixelFontFamily : root.cyberHudMono
                                font.pixelSize: 10 * s
                                font.bold: true
                                color: "#ffffff"
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰁔"
                            font.family: root.monoFont
                            font.pixelSize: 14 * s
                            color: submitMa.containsMouse ? "#ffffff" : root.textMuted
                            opacity: (passwordInput.text.length > 0 || root.loginStyle === "Pixel Retro" || root.loginStyle === "Cyber Terminal") ? 0.0 : 1.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }

                        MouseArea {
                            id: submitMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: doLogin()
                        }
                    }
                }

                // ─── Real Morphing MaterialShape Avatar Frame (Click to open User Menu!) ───
                Item {
                    id: avatarFrame
                    visible: root.avatarVisible && root.avatarOrientation !== "Hidden"
                    x: {
                        if (root.avatarOrientation === "Left") return 0
                        if (root.avatarOrientation === "Right") return loginContentInner.pwBoxW + 20 * s
                        if (root.avatarOrientation === "Center" || root.avatarOrientation === "Top Center" || root.avatarOrientation === "Bottom Center") return (loginContentInner.pwBoxW - width) / 2
                        if (root.avatarOrientation === "Top Left" || root.avatarOrientation === "Bottom Left") return 0
                        if (root.avatarOrientation === "Top Right" || root.avatarOrientation === "Bottom Right") return loginContentInner.pwBoxW - width
                        return loginContentInner.pwBoxW + 20 * s
                    }
                    y: {
                        if (root.avatarOrientation === "Center") {
                            return userDisplayNameRow.height + 10 * s
                        }
                        if (root.avatarOrientation === "Right" || root.avatarOrientation === "Left") {
                            return passwordBoxRect.y + (loginContentInner.pwBoxH - height) / 2
                        }
                        if (root.avatarOrientation === "Bottom Center" || root.avatarOrientation === "Bottom Left" || root.avatarOrientation === "Bottom Right") {
                            return passwordBoxRect.y + passwordBoxRect.height + 14 * s
                        }
                        return 0
                    }
                    width: loginContentInner.avatarSize
                    height: loginContentInner.avatarSize
                    scale: avatarMa.containsMouse ? 1.05 : 1.0

                    Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                    // Neon Glow Effect
                    MaterialShape {
                        id: avatarNeonGlow
                        anchors.fill: parent
                        anchors.margins: -5 * s
                        shape: root.currentM3Shape
                        animationDuration: 350
                        color: Qt.alpha(root.accentColor, 0.45)
                        visible: root.avatarStyle === "Neon Glow"
                        scale: 1.0 + (glowPulseAnim.running ? glowPulseAnim.pulseVal : 0.0)

                        SequentialAnimation {
                            id: glowPulseAnim
                            running: root.avatarStyle === "Neon Glow"
                            loops: Animation.Infinite
                            property real pulseVal: 0.0
                            NumberAnimation { target: glowPulseAnim; property: "pulseVal"; from: 0.0; to: 0.08; duration: 1200; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: glowPulseAnim; property: "pulseVal"; from: 0.08; to: 0.0; duration: 1200; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Glass Badge Backing
                    FrostedGlassCard {
                        id: avatarGlassBadge
                        anchors.fill: parent
                        anchors.margins: -8 * s
                        radius: width / 2
                        tintColor: Qt.alpha(root.glassBg, 0.65)
                        borderColor: Qt.alpha(root.glassBorder, 0.70)
                        borderWidth: 1.5 * s
                        visible: root.avatarStyle === "Glass Badge"
                    }

                    // Double Ring Outer Frame
                    MaterialShape {
                        id: avatarDoubleRing
                        anchors.fill: parent
                        anchors.margins: -6 * s
                        shape: root.currentM3Shape
                        animationDuration: 350
                        color: Qt.alpha(root.accentColor, 0.35)
                        visible: root.avatarStyle === "Double Ring"
                    }

                    MaterialShape {
                        id: avatarM3Border
                        anchors.fill: parent
                        shape: root.currentM3Shape
                        animationDuration: 350
                        color: avatarMa.containsMouse ? root.accentColor : (root.avatarStyle === "Neon Glow" ? root.accentColor : Qt.alpha(root.accentColor, 0.40))
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 3 * s

                        Item {
                            id: avatarContentGroup
                            anchors.fill: parent
                            visible: false

                            Image {
                                id: userFaceImg
                                anchors.fill: parent
                                source: root.getUserAvatar(root.activeUser.name, root.activeUser.icon)
                                cache: false
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                mipmap: true

                                property int fallbackStage: 0

                                function getNextFallback(login, stage) {
                                    if (!login || login === "") return ""
                                    if (stage === 1) return "file:///home/" + login + "/.face.icon"
                                    if (stage === 2) return "file:///usr/share/sddm/faces/" + login + ".face.icon"
                                    if (stage === 3) return "file:///var/lib/AccountsService/icons/" + login
                                    return ""
                                }

                                onSourceChanged: {
                                    fallbackStage = 0
                                }

                                onStatusChanged: {
                                    if (status === Image.Error && fallbackStage < 3) {
                                        fallbackStage++
                                        var next = getNextFallback(root.activeUser.name, fallbackStage)
                                        if (next !== "" && next !== source) {
                                            source = next
                                        }
                                    }
                                }
                            }

                            Desaturate {
                                anchors.fill: userFaceImg
                                source: userFaceImg
                                desaturation: (root.avatarTintMode === "Monochrome" || root.avatarTintMode === "Duo-tone") ? Math.min(1.0, root.avatarTintIntensity * 2.2) : 0.0
                                visible: desaturation > 0
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.accentColor
                                opacity: {
                                    if (root.avatarTintMode === "None" || root.avatarTintMode === "Monochrome") return 0.0
                                    if (root.avatarTintMode === "Subtle Glow") return Math.min(0.45, root.avatarTintIntensity * 0.6)
                                    if (root.avatarTintMode === "Duo-tone") return Math.min(0.70, root.avatarTintIntensity * 0.85)
                                    return 0.0
                                }
                            }
                        }

                        MaterialShape {
                            id: innerFaceMask
                            anchors.fill: parent
                            shape: root.currentM3Shape
                            animationDuration: 350
                            color: "#ffffff"
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: avatarContentGroup
                            maskSource: innerFaceMask
                            visible: userFaceImg.status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: root.monoFont
                            font.pixelSize: 32 * s
                            color: root.textPrimary
                            visible: userFaceImg.status !== Image.Ready
                        }
                    }

                    // Cyber Brackets Corner Lines
                    Item {
                        id: avatarCyberBrackets
                        anchors.fill: parent
                        anchors.margins: -7 * s
                        visible: root.avatarStyle === "Cyber Brackets"

                        readonly property real bLen: 10 * s
                        readonly property real bThick: 2 * s

                        // Top Left
                        Rectangle { x: 0; y: 0; width: avatarCyberBrackets.bLen; height: avatarCyberBrackets.bThick; color: root.accentColor }
                        Rectangle { x: 0; y: 0; width: avatarCyberBrackets.bThick; height: avatarCyberBrackets.bLen; color: root.accentColor }

                        // Top Right
                        Rectangle { x: parent.width - avatarCyberBrackets.bLen; y: 0; width: avatarCyberBrackets.bLen; height: avatarCyberBrackets.bThick; color: root.accentColor }
                        Rectangle { x: parent.width - avatarCyberBrackets.bThick; y: 0; width: avatarCyberBrackets.bThick; height: avatarCyberBrackets.bLen; color: root.accentColor }

                        // Bottom Left
                        Rectangle { x: 0; y: parent.height - avatarCyberBrackets.bThick; width: avatarCyberBrackets.bLen; height: avatarCyberBrackets.bThick; color: root.accentColor }
                        Rectangle { x: 0; y: parent.height - avatarCyberBrackets.bLen; width: avatarCyberBrackets.bThick; height: avatarCyberBrackets.bLen; color: root.accentColor }

                        // Bottom Right
                        Rectangle { x: parent.width - avatarCyberBrackets.bLen; y: parent.height - avatarCyberBrackets.bThick; width: avatarCyberBrackets.bLen; height: avatarCyberBrackets.bThick; color: root.accentColor }
                        Rectangle { x: parent.width - avatarCyberBrackets.bThick; y: parent.height - avatarCyberBrackets.bLen; width: avatarCyberBrackets.bThick; height: avatarCyberBrackets.bLen; color: root.accentColor }
                    }

                    MouseArea {
                        id: avatarMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.userListOpen = !root.userListOpen
                            root.sessionMenuOpen = false
                            root.settingsOpen = false
                            root.powerMenuOpen = false
                        }
                    }
                }

                // Caps Lock Warning Row
                Row {
                    anchors.left: passwordBoxRect.left
                    anchors.top: passwordBoxRect.bottom
                    anchors.topMargin: 8 * s
                    spacing: 6 * s
                    visible: root.capsLock && errorText.text === ""

                    Text {
                        text: "󰌌"
                        font.family: root.monoFont
                        font.pixelSize: 12 * s
                        color: "#f5a623"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Caps lock is ON"
                        font.family: root.sansFont
                        font.pixelSize: 11 * s
                        font.weight: Font.Medium
                        color: "#f5a623"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Error Message
                Text {
                    id: errorText
                    anchors.left: passwordBoxRect.left
                    anchors.top: passwordBoxRect.bottom
                    anchors.topMargin: 8 * s
                    text: ""
                    color: root.accentColor
                    font.family: root.sansFont
                    font.pixelSize: 12 * s
                    font.weight: Font.Bold
                    font.letterSpacing: 1 * s
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }
        }
    }

    // ──────────────────────────────────────────
    // User Switcher Flyout Modal (When clicking Avatar!)
    // ──────────────────────────────────────────
    Rectangle {
        id: userSwitcherModal
        anchors.left: (loginPanelContainer.x < 200 * s) ? loginPanelContainer.left : undefined
        anchors.right: (loginPanelContainer.x < 200 * s) ? undefined : loginPanelContainer.right
        anchors.top: (loginPanelContainer.y < 250 * s) ? loginPanelContainer.bottom : undefined
        anchors.bottom: (loginPanelContainer.y < 250 * s) ? undefined : loginPanelContainer.top
        anchors.topMargin: root.userListOpen ? 12 * s : 4 * s
        anchors.bottomMargin: root.userListOpen ? 12 * s : 4 * s
        width: 260 * s
        height: 46 * s + Math.max(1, (typeof userModel !== "undefined" ? userModel.rowCount() : 1)) * 44 * s
        radius: 18 * s
        color: "transparent"
        visible: opacity > 0

        FrostedGlassCard {
            radius: parent.radius
            tintColor: root.glassBg
            borderColor: root.glassBorder
            borderWidth: 1 * s
        }
        opacity: root.userListOpen ? 1.0 : 0.0
        scale: root.userListOpen ? 1.0 : 0.84
        transformOrigin: (loginPanelContainer.y < 250 * s) ? Item.TopRight : Item.BottomRight
        z: 60

        layer.enabled: true
        layer.effect: DropShadow { color: "#50000000"; radius: 20; samples: 16 }

        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 280; easing.type: root.userListOpen ? Easing.OutBack : Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        Column {
            anchors.fill: parent
            anchors.margins: 10 * s
            spacing: 4 * s

            // Title
            Item {
                width: parent.width
                height: 24 * s

                Text {
                    text: "Switch User"
                    font.family: root.sansFont
                    font.pixelSize: 12 * s
                    font.weight: Font.Bold
                    color: root.textSecondary
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "󰅖"
                    font.family: root.monoFont
                    font.pixelSize: 13 * s
                    color: userCloseMa.containsMouse ? "#ffffff" : root.textMuted
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        id: userCloseMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.userListOpen = false
                    }
                }
            }

            // Real SDDM User List Repeater (Zero Mock Accounts!)
            Repeater {
                id: userListRepeater
                model: typeof userModel !== "undefined" ? userModel : 1
                delegate: Rectangle {
                    property string itemLogin: (typeof model !== "undefined" && model.name) ? model.name : ((typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : "user")
                    property string itemRealName: (typeof model !== "undefined" && (model.realName || model.name)) ? (model.realName || model.name) : itemLogin
                    width: parent.width
                    height: 38 * s
                    radius: 10 * s
                    color: uItemMa.containsMouse ? Qt.alpha(root.accentColor, 0.25) : (root.currentUserIdx === index ? Qt.alpha(root.accentColor, 0.15) : "transparent")

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10 * s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10 * s

                        Text {
                            text: ""
                            font.family: root.monoFont
                            font.pixelSize: 14 * s
                            color: root.currentUserIdx === index ? root.accentColor : root.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: itemRealName
                            font.family: root.sansFont
                            font.pixelSize: 12 * s
                            font.weight: Font.Medium
                            color: root.currentUserIdx === index ? "#ffffff" : root.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12 * s
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰄬"
                        font.family: root.monoFont
                        font.pixelSize: 13 * s
                        color: root.accentColor
                        visible: root.currentUserIdx === index
                    }

                    MouseArea {
                        id: uItemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentUserIdx = index
                            passwordInput.text = ""
                            root.userListOpen = false
                            passwordInput.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    // ──────────────────────────────────────────
    // Bottom Bar: Settings, Session & Solid Clean Action Row
    // ──────────────────────────────────────────
    Item {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 35 * s
        height: 44 * s
        opacity: root.uiOpacity
        z: 40

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {}
        }

        // ─── Settings Morphing Container (Dynamically Themed Glass!) ───
        // ─── Settings Morphing Container (Caelestia Glass Settings Hub!) ───
Rectangle {
            id: morphingSettingsContainer
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            readonly property real activeTabHeight: {
                if (currentTab === 0) return tabClockCol.implicitHeight
                if (currentTab === 1) return tabLoginCol.implicitHeight
                if (currentTab === 2) return tabAvatarCol.implicitHeight
                return tabThemeCol.implicitHeight
            }
            readonly property real targetExpandedHeight: Math.min(root.height - 70 * s, 108 * s + activeTabHeight)
            width: root.settingsOpen ? 370 * s : 38 * s
            height: root.settingsOpen ? targetExpandedHeight : 38 * s
            radius: root.settingsOpen ? 20 * s : 12 * s
            color: "transparent"
            clip: true
            z: 50

            FrostedGlassCard {
                radius: morphingSettingsContainer.radius
                tintColor: root.settingsOpen ? root.glassBg : (settingsBtnMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : Qt.alpha(root.glassBg, 0.25))
                borderColor: root.settingsOpen ? root.glassBorder : (settingsBtnMa.containsMouse ? root.accentColor : Qt.alpha(root.glassBorder, 0.40))
                borderWidth: 1.2 * s
                showBorder: root.cardBorderEnabled
            }

            property int currentTab: 0
            property bool isTabSwitching: false

            onCurrentTabChanged: {
                isTabSwitching = true
                tabSwitchTimer.restart()
            }

            Timer {
                id: tabSwitchTimer
                interval: 340
                onTriggered: morphingSettingsContainer.isTabSwitching = false
            }

            Behavior on height {
                enabled: morphingSettingsContainer.isTabSwitching
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }

            state: root.settingsOpen ? "expanded" : "collapsed"

            states: [
                State {
                    name: "collapsed"
                    PropertyChanges {
                        target: morphingSettingsContainer
                        width: 38 * s
                        height: 38 * s
                        radius: 12 * s
                    }
                },
                State {
                    name: "expanded"
                    PropertyChanges {
                        target: morphingSettingsContainer
                        width: 370 * s
                        height: morphingSettingsContainer.targetExpandedHeight
                        radius: 20 * s
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "collapsed"; to: "expanded"
                    NumberAnimation { properties: "width,height"; duration: 420; easing.type: Easing.OutCubic }
                    NumberAnimation { properties: "radius"; duration: 300; easing.type: Easing.OutCubic }
                },
                Transition {
                    from: "expanded"; to: "collapsed"
                    NumberAnimation { properties: "width,height"; duration: 380; easing.type: Easing.OutCubic }
                    NumberAnimation { properties: "radius"; duration: 250; easing.type: Easing.OutCubic }
                }
            ]


            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on border.color { ColorAnimation { duration: 250 } }

            // Collapsed View: Gear Icon Button with Buttery Morph
            Item {
                anchors.fill: parent
                visible: opacity > 0
                opacity: root.settingsOpen ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 220 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    font.family: root.monoFont
                    font.pixelSize: 16 * s
                    color: settingsBtnMa.containsMouse ? root.accentColor : root.textPrimary
                    Behavior on color { ColorAnimation { duration: 200 } }
                    rotation: root.settingsOpen ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    id: settingsBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.settingsOpen = true
                        root.powerMenuOpen = false
                        root.isKeyboardOpen = false
                        root.sessionMenuOpen = false
                        root.userListOpen = false
                    }
                }
            }

            // Expanded View: Tailored Nothing OS / Caelestia Accordion Hub
            Item {
                id: settingsExpandedView
                anchors.fill: parent
                anchors.margins: 14 * s
                visible: opacity > 0
                opacity: root.settingsOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                // Top Header Row
                Item {
                    id: settingsHeaderBar
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 24 * s

                    Text {
                        text: "Appearance & Display"
                        font.family: root.sansFont
                        font.pixelSize: 11 * s
                        font.weight: Font.DemiBold
                        color: root.textSecondary
                        anchors.left: parent.left
                        anchors.leftMargin: 4 * s
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 24 * s
                        height: 24 * s
                        radius: 12 * s
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: closeSetMa.containsMouse ? Qt.alpha(root.accentColor, 0.25) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: root.monoFont
                            font.pixelSize: 12 * s
                            color: closeSetMa.containsMouse ? "#ffffff" : root.textMuted
                        }

                        MouseArea {
                            id: closeSetMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.settingsOpen = false
                                settingsCloseCleanupTimer.restart()
                            }
                        }
                    }
                }

                // Top Tab Bar (Caelestia Glass Desktop Style)
                Rectangle {
                    id: settingsTabBar
                    anchors.top: settingsHeaderBar.bottom
                    anchors.topMargin: 8 * s
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 34 * s
                    radius: 10 * s
                    color: Qt.alpha(root.glassBg, 0.6)
                    border.color: Qt.alpha(root.glassBorder, 0.5)
                    border.width: 1 * s

                    // Smooth Sliding Glowing Indicator
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2 * s
                        width: 22 * s
                        height: 2.5 * s
                        radius: 1.25 * s
                        color: root.accentColor
                        x: morphingSettingsContainer.currentTab * (parent.width / 4) + ((parent.width / 4) - width) / 2
                        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }

                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [
                                { name: "Clock",  icon: "󰥔" },
                                { name: "Login",  icon: "󰌾" },
                                { name: "Avatar", icon: "" },
                                { name: "Theme",  icon: "󰏘" }
                            ]
                            delegate: Rectangle {
                                width: parent.width / 4
                                height: parent.height
                                radius: 8 * s
                                color: morphingSettingsContainer.currentTab === index ? Qt.alpha(root.accentColor, 0.28) : (tabMa.containsMouse ? Qt.alpha(root.accentColor, 0.14) : "transparent")
                                Behavior on color { ColorAnimation { duration: 180 } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4 * s
                                    Text {
                                        text: modelData.icon
                                        font.family: root.monoFont
                                        font.pixelSize: 11 * s
                                        color: morphingSettingsContainer.currentTab === index ? "#ffffff" : root.textMuted
                                    }
                                    Text {
                                        text: modelData.name
                                        font.family: root.sansFont
                                        font.pixelSize: 10.5 * s
                                        font.weight: morphingSettingsContainer.currentTab === index ? Font.Bold : Font.Normal
                                        color: morphingSettingsContainer.currentTab === index ? "#ffffff" : root.textMuted
                                    }
                                }

                                MouseArea {
                                    id: tabMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        morphingSettingsContainer.currentTab = index
                                        settingsFlickable.contentY = 0
                                        closeAllSettingsDrawers()
                                    }
                                }
                            }
                        }
                    }
                }

                // Scrollable Content Viewport
                Flickable {
                    id: settingsFlickable
                    anchors.top: settingsTabBar.bottom
                    anchors.topMargin: 8 * s
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    contentWidth: width
                    contentHeight: tabContentArea.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: true

                    WheelHandler {
                        target: settingsFlickable
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function(event) {
                            var maxScroll = Math.max(0, settingsFlickable.contentHeight - settingsFlickable.height)
                            if (maxScroll <= 0) {
                                settingsFlickable.contentY = 0
                                return
                            }
                            var delta = event.angleDelta.y
                            var step = delta !== 0 ? delta : (event.pixelDelta.y * 4)
                            settingsFlickable.contentY = Math.max(0, Math.min(maxScroll, settingsFlickable.contentY - step * 0.75))
                        }
                    }

                    // Tab Content Stack Area
                    Item {
                        id: tabContentArea
                        width: settingsFlickable.width - (settingsFlickable.contentHeight > settingsFlickable.height ? 6 * s : 0)
                        implicitHeight: morphingSettingsContainer.activeTabHeight
                        height: implicitHeight

                        // ══════════════════════════════════════════
                        // TAB 0: CLOCK CUSTOMIZATION
                        // ══════════════════════════════════════════
                        Column {
                            id: tabClockCol
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 2 * s
                            opacity: morphingSettingsContainer.currentTab === 0 ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            // Row 0.1: Clock Style
                            Rectangle {
                                id: clockStyleRow
                                width: parent.width
                                height: root.clockStyleMenuOpen ? (48 * s + 150 * s) : 48 * s
                                topLeftRadius: 14 * s
                                topRightRadius: 14 * s
                                bottomLeftRadius: 4 * s
                                bottomRightRadius: 4 * s
                                clip: true
                                color: clockStyleRowMa.containsMouse || root.clockStyleMenuOpen ? Qt.alpha(root.accentColor, 0.16) : Qt.alpha(root.accentColor, 0.08)
                                Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Item {
                                    id: clockStyleHeaderBar
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 48 * s

                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 14 * s
                                        anchors.right: clockStyleSplitBtn.left
                                        anchors.rightMargin: 8 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2 * s

                                        Text {
                                            text: "Clock style"
                                            font.family: root.sansFont
                                            font.pixelSize: 13 * s
                                            font.weight: Font.Medium
                                            color: root.textPrimary
                                        }
                                        Text {
                                            text: "Choose intro clock layout"
                                            font.family: root.sansFont
                                            font.pixelSize: 10 * s
                                            color: root.textMuted
                                        }
                                    }

                                    Row {
                                        id: clockStyleSplitBtn
                                        anchors.right: parent.right
                                        anchors.rightMargin: 14 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2 * s

                                        Rectangle {
                                            height: 28 * s
                                            width: clockStyleBtnLabel.implicitWidth + 18 * s
                                            topLeftRadius: 14 * s
                                            bottomLeftRadius: 14 * s
                                            topRightRadius: 4 * s
                                            bottomRightRadius: 4 * s
                                            color: Qt.alpha(root.accentColor, 0.35)
                                            border.color: Qt.alpha(root.accentColor, 0.55)
                                            border.width: 1 * s

                                            Text {
                                                id: clockStyleBtnLabel
                                                anchors.centerIn: parent
                                                text: root.clockStyle
                                                font.family: root.sansFont
                                                font.pixelSize: 11 * s
                                                font.weight: Font.Medium
                                                color: "#ffffff"
                                            }
                                        }

                                        Rectangle {
                                            height: 28 * s
                                            width: 26 * s
                                            topLeftRadius: 4 * s
                                            bottomLeftRadius: 4 * s
                                            topRightRadius: 14 * s
                                            bottomRightRadius: 14 * s
                                            color: Qt.alpha(root.accentColor, 0.35)
                                            border.color: Qt.alpha(root.accentColor, 0.55)
                                            border.width: 1 * s

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰅀"
                                                font.family: root.monoFont
                                                font.pixelSize: 13 * s
                                                color: "#ffffff"
                                                rotation: root.clockStyleMenuOpen ? 180 : 0
                                                Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: clockStyleRowMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.clockStyleMenuOpen = !root.clockStyleMenuOpen
                                            if (root.clockStyleMenuOpen) {
                                                root.clockPosMenuOpen = false
                                            }
                                        }
                                    }
                                }

                                Item {
                                    id: clockStyleDrawer
                                    anchors.top: clockStyleHeaderBar.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 8 * s
                                    anchors.rightMargin: 8 * s
                                    height: 140 * s
                                    opacity: root.clockStyleMenuOpen ? 1 : 0
                                    visible: opacity > 0
                                    clip: true
                                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                    Flickable {
                                        id: clockStyleFlick
                                        anchors.fill: parent
                                        contentWidth: width
                                        contentHeight: clockStyleCol.implicitHeight
                                        clip: true
                                        boundsBehavior: Flickable.StopAtBounds

                                        WheelHandler {
                                            target: clockStyleFlick
                                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                            onWheel: function(event) {
                                                var maxScroll = Math.max(0, clockStyleFlick.contentHeight - clockStyleFlick.height)
                                                if (maxScroll <= 0) return
                                                var step = 32 * s
                                                if (event.angleDelta.y < 0) {
                                                    clockStyleFlick.contentY = Math.min(maxScroll, clockStyleFlick.contentY + step)
                                                } else {
                                                    clockStyleFlick.contentY = Math.max(0, clockStyleFlick.contentY - step)
                                                }
                                            }
                                        }

                                        Column {
                                            id: clockStyleCol
                                            width: parent.width - 8 * s
                                            spacing: 2 * s

                                            Repeater {
                                                model: [
                                                    "Caelestia Split",
                                                    "Classic Minimal",
                                                    "Two-Tier Stacked",
                                                    "Compact Capsule",
                                                    "Cyber HUD",
                                                    "Editorial Typographic",
                                                    "Neo-Digital Capsule",
                                                    "Pixel Retro"
                                                ]

                                                delegate: Rectangle {
                                                    width: parent.width
                                                    height: 28 * s
                                                    radius: 6 * s
                                                    color: clockStyleDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.clockStyle === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                                    Behavior on color { ColorAnimation { duration: 150 } }

                                                    Text {
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 10 * s
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: modelData
                                                        font.family: root.sansFont
                                                        font.pixelSize: 11 * s
                                                        color: root.clockStyle === modelData ? "#ffffff" : root.textSecondary
                                                    }

                                                    Text {
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: 10 * s
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "󰄬"
                                                        font.family: root.monoFont
                                                        font.pixelSize: 12 * s
                                                        color: root.accentColor
                                                        visible: root.clockStyle === modelData
                                                    }

                                                    MouseArea {
                                                        id: clockStyleDelMa
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            root.clockStyle = modelData
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: clockStyleScrollBar
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.topMargin: 4 * s
                                        anchors.bottomMargin: 4 * s
                                        width: 3 * s
                                        radius: 1.5 * s
                                        color: Qt.rgba(1, 1, 1, 0.08)
                                        visible: clockStyleFlick.contentHeight > clockStyleFlick.height

                                        Rectangle {
                                            width: parent.width
                                            radius: parent.radius
                                            color: root.accentColor
                                            opacity: 0.6
                                            height: Math.max(14 * s, (clockStyleFlick.height / clockStyleFlick.contentHeight) * parent.height)
                                            y: clockStyleFlick.contentHeight > clockStyleFlick.height ? (clockStyleFlick.contentY / (clockStyleFlick.contentHeight - clockStyleFlick.height)) * (parent.height - height) : 0
                                        }
                                    }
                                }
                            }

                    // Row 0.2: Clock Position (9-Grid Interactive Picker)
                    Rectangle {
                        id: clockPosRow
                        width: parent.width
                        height: root.clockPosMenuOpen ? (48 * s + 90 * s) : 48 * s
                        radius: 4 * s
                        clip: true
                        color: clockPosRowMa.containsMouse || root.clockPosMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: clockPosHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: clockPosSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Clock position"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Screen placement (9-grid)"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: clockPosSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: clockPosLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: clockPosLabel
                                        anchors.centerIn: parent
                                        text: root.getGridPosName(root.clockGridPos)
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.clockPosMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: clockPosRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.clockPosMenuOpen = !root.clockPosMenuOpen
                                    root.clockStyleMenuOpen = false
                                }
                            }
                        }

                        Item {
                            id: clockPosDrawer
                            anchors.top: clockPosHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 90 * s
                            opacity: root.clockPosMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Grid {
                                anchors.centerIn: parent
                                rows: 3
                                columns: 3
                                spacing: 6 * s

                                Repeater {
                                    model: 9
                                    delegate: Rectangle {
                                        width: 24 * s
                                        height: 24 * s
                                        radius: 6 * s
                                        color: root.clockGridPos === index ? root.accentColor : (gridCellMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : Qt.rgba(1, 1, 1, 0.12))
                                        border.color: root.clockGridPos === index ? "#ffffff" : Qt.rgba(1, 1, 1, 0.20)
                                        border.width: 1 * s

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 6 * s
                                            height: 6 * s
                                            radius: 3 * s
                                            color: "#ffffff"
                                            visible: root.clockGridPos === index
                                        }

                                        MouseArea {
                                            id: gridCellMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.clockGridPos = index
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 0.3: Clock Scale Slider
                    Rectangle {
                        width: parent.width
                        height: 54 * s
                        radius: 4 * s
                        color: Qt.alpha(root.accentColor, 0.08)

                        Item {
                            anchors.top: parent.top
                            anchors.topMargin: 8 * s
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            height: 16 * s

                            Text {
                                text: "Clock scale"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.clockScale.toFixed(1) + "x"
                                font.family: root.sansFont
                                font.pixelSize: 11 * s
                                font.weight: Font.Bold
                                color: root.accentColor
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Slider Track
                        Item {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 10 * s
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            height: 14 * s

                            Rectangle {
                                id: clockScaleTrack
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 5 * s
                                radius: 2.5 * s
                                color: Qt.rgba(1, 1, 1, 0.15)

                                Rectangle {
                                    height: parent.height
                                    radius: parent.radius
                                    width: Math.max(0, Math.min(parent.width, ((root.clockScale - 0.6) / 1.6) * parent.width))
                                    color: root.accentColor
                                }
                            }

                            Rectangle {
                                width: 14 * s
                                height: 14 * s
                                radius: 7 * s
                                anchors.verticalCenter: clockScaleTrack.verticalCenter
                                x: Math.max(0, Math.min(clockScaleTrack.width - width, ((root.clockScale - 0.6) / 1.6) * (clockScaleTrack.width - width)))
                                color: "#ffffff"
                                border.color: root.accentColor
                                border.width: 2 * s
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    var r = Math.max(0, Math.min(1.0, mouse.x / width))
                                    root.clockScale = 0.6 + r * 1.6
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        var r = Math.max(0, Math.min(1.0, mouse.x / width))
                                        root.clockScale = 0.6 + r * 1.6
                                    }
                                }
                            }
                        }
                    }

                    // Row 0.4: Frosted Card Background Toggle
                    Rectangle {
                        width: parent.width
                        height: 48 * s
                        topLeftRadius: 4 * s
                        topRightRadius: 4 * s
                        bottomLeftRadius: 14 * s
                        bottomRightRadius: 14 * s
                        color: clockCardRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: clockCardSwitch.left
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "Frosted card background"
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                            }
                            Text {
                                text: "Translucent backing plate on clock"
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                color: root.textMuted
                            }
                        }

                        Rectangle {
                            id: clockCardSwitch
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42 * s
                            height: 24 * s
                            radius: 12 * s
                            color: root.clockCardEnabled ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 18 * s
                                height: 18 * s
                                radius: 9 * s
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.clockCardEnabled ? parent.width - width - 3 * s : 3 * s
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.clockCardEnabled ? "󰄬" : "󰅖"
                                    font.family: root.monoFont
                                    font.pixelSize: 10 * s
                                    color: root.clockCardEnabled ? root.accentColor : root.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: clockCardRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clockCardEnabled = !root.clockCardEnabled
                        }
                    }

                    Item { width: parent.width; height: 18 * s }
                }

                    // ══════════════════════════════════════════
                    // TAB 1: LOGIN & BOX CUSTOMIZATION
                    // ══════════════════════════════════════════
                    Column {
                        id: tabLoginCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 2 * s
                        opacity: morphingSettingsContainer.currentTab === 1 ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    // Row 1.0: Login Style (Theme Layout)
                    Rectangle {
                        id: loginStyleRow
                        width: parent.width
                        height: root.loginStyleMenuOpen ? (48 * s + 130 * s) : 48 * s
                        topLeftRadius: 14 * s
                        topRightRadius: 14 * s
                        bottomLeftRadius: 4 * s
                        bottomRightRadius: 4 * s
                        clip: true
                        color: loginStyleRowMa.containsMouse || root.loginStyleMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: loginStyleHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: loginStyleSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Login style"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Overall login theme layout"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: loginStyleSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: loginStyleLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: loginStyleLabel
                                        anchors.centerIn: parent
                                        text: root.loginStyle
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.loginStyleMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: loginStyleRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.loginStyleMenuOpen = !root.loginStyleMenuOpen
                                    if (root.loginStyleMenuOpen) {
                                        root.boxMenuOpen = false
                                        root.loginPosMenuOpen = false
                                        root.unlockAnimMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: loginStyleDrawer
                            anchors.top: loginStyleHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.topMargin: 4 * s
                            anchors.bottomMargin: 8 * s
                            anchors.leftMargin: 8 * s
                            anchors.rightMargin: 8 * s
                            opacity: root.loginStyleMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Flickable {
                                id: loginStyleFlick
                                anchors.fill: parent
                                contentWidth: width
                                contentHeight: loginStyleCol.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                WheelHandler {
                                    target: loginStyleFlick
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                    onWheel: function(event) {
                                        var maxScroll = Math.max(0, loginStyleFlick.contentHeight - loginStyleFlick.height)
                                        if (maxScroll <= 0) return
                                        var step = 32 * s
                                        if (event.angleDelta.y < 0) {
                                            loginStyleFlick.contentY = Math.min(maxScroll, loginStyleFlick.contentY + step)
                                        } else {
                                            loginStyleFlick.contentY = Math.max(0, loginStyleFlick.contentY - step)
                                        }
                                    }
                                }

                                Column {
                                    id: loginStyleCol
                                    width: parent.width
                                    spacing: 2 * s

                                    Repeater {
                                        model: [
                                            "Modern Glass",
                                            "Pixel Retro",
                                            "Cyber Terminal",
                                            "Editorial Minimal"
                                        ]

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 28 * s
                                            radius: 6 * s
                                            color: loginStyleDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.loginStyle === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 10 * s
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData
                                                font.family: root.sansFont
                                                font.pixelSize: 11 * s
                                                color: root.loginStyle === modelData ? "#ffffff" : root.textSecondary
                                            }

                                            Text {
                                                anchors.right: parent.right
                                                anchors.rightMargin: 10 * s
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "󰄬"
                                                font.family: root.monoFont
                                                font.pixelSize: 12 * s
                                                color: root.accentColor
                                                visible: root.loginStyle === modelData
                                            }

                                            MouseArea {
                                                id: loginStyleDelMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.loginStyle = modelData
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 1.1: Password Box Style
                    Rectangle {
                        id: boxStyleRow
                        width: parent.width
                        height: root.boxMenuOpen ? (48 * s + boxContentCol.implicitHeight + 14 * s) : 48 * s
                        radius: 4 * s
                        clip: true
                        color: boxStyleRowMa.containsMouse || root.boxMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: boxStyleHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: boxStyleSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Input box shape"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Password box corner style"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: boxStyleSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: boxStyleLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: boxStyleLabel
                                        anchors.centerIn: parent
                                        text: root.boxStyle
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.boxMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: boxStyleRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.boxMenuOpen = !root.boxMenuOpen
                                    if (root.boxMenuOpen) {
                                        root.loginStyleMenuOpen = false
                                        root.loginPosMenuOpen = false
                                        root.unlockAnimMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: boxStyleDrawer
                            anchors.top: boxStyleHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8 * s
                            anchors.rightMargin: 8 * s
                            height: boxContentCol.implicitHeight
                            opacity: root.boxMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Column {
                                id: boxContentCol
                                width: parent.width
                                spacing: 2 * s

                                Repeater {
                                    model: ["Glass Pill", "Minimal Underline", "Split Badge", "Sharp M3 Card"]

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 26 * s
                                        radius: 6 * s
                                        color: boxStyleDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.boxStyle === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData
                                            font.family: root.sansFont
                                            font.pixelSize: 11 * s
                                            color: root.boxStyle === modelData ? "#ffffff" : root.textSecondary
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰄬"
                                            font.family: root.monoFont
                                            font.pixelSize: 12 * s
                                            color: root.accentColor
                                            visible: root.boxStyle === modelData
                                        }

                                        MouseArea {
                                            id: boxStyleDelMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.boxStyle = modelData
                                                root.boxShape = modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 1.2: Login Screen Position (9-Grid Interactive Picker)
                    Rectangle {
                        id: loginPosRow
                        width: parent.width
                        height: root.loginPosMenuOpen ? (48 * s + 90 * s) : 48 * s
                        radius: 4 * s
                        clip: true
                        color: loginPosRowMa.containsMouse || root.loginPosMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: loginPosHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: loginPosSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Login position"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Screen placement (9-grid)"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: loginPosSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: loginPosLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: loginPosLabel
                                        anchors.centerIn: parent
                                        text: root.getGridPosName(root.loginGridPos)
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.loginPosMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: loginPosRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.loginPosMenuOpen = !root.loginPosMenuOpen
                                    if (root.loginPosMenuOpen) {
                                        root.loginStyleMenuOpen = false
                                        root.boxMenuOpen = false
                                        root.unlockAnimMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: loginPosDrawer
                            anchors.top: loginPosHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 90 * s
                            opacity: root.loginPosMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Grid {
                                anchors.centerIn: parent
                                rows: 3
                                columns: 3
                                spacing: 6 * s

                                Repeater {
                                    model: 9
                                    delegate: Rectangle {
                                        width: 24 * s
                                        height: 24 * s
                                        radius: 6 * s
                                        color: root.loginGridPos === index ? root.accentColor : (gridLoginCellMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : Qt.rgba(1, 1, 1, 0.12))
                                        border.color: root.loginGridPos === index ? "#ffffff" : Qt.rgba(1, 1, 1, 0.20)
                                        border.width: 1 * s

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 6 * s
                                            height: 6 * s
                                            radius: 3 * s
                                            color: "#ffffff"
                                            visible: root.loginGridPos === index
                                        }

                                        MouseArea {
                                            id: gridLoginCellMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.loginGridPos = index
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 1.3: Login Container Scale Slider
                    Rectangle {
                        width: parent.width
                        height: 54 * s
                        radius: 4 * s
                        color: Qt.alpha(root.accentColor, 0.08)

                        Item {
                            anchors.top: parent.top
                            anchors.topMargin: 8 * s
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            height: 16 * s

                            Text {
                                text: "Login scale"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.loginScale.toFixed(1) + "x"
                                font.family: root.sansFont
                                font.pixelSize: 11 * s
                                font.weight: Font.Bold
                                color: root.accentColor
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Slider Track
                        Item {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 10 * s
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            height: 14 * s

                            Rectangle {
                                id: loginScaleTrack
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 5 * s
                                radius: 2.5 * s
                                color: Qt.rgba(1, 1, 1, 0.15)

                                Rectangle {
                                    height: parent.height
                                    radius: parent.radius
                                    width: Math.max(0, Math.min(parent.width, ((root.loginScale - 0.7) / 0.9) * parent.width))
                                    color: root.accentColor
                                }
                            }

                            Rectangle {
                                width: 14 * s
                                height: 14 * s
                                radius: 7 * s
                                anchors.verticalCenter: loginScaleTrack.verticalCenter
                                x: Math.max(0, Math.min(loginScaleTrack.width - width, ((root.loginScale - 0.7) / 0.9) * (loginScaleTrack.width - width)))
                                color: "#ffffff"
                                border.color: root.accentColor
                                border.width: 2 * s
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    var r = Math.max(0, Math.min(1.0, mouse.x / width))
                                    root.loginScale = 0.7 + r * 0.9
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        var r = Math.max(0, Math.min(1.0, mouse.x / width))
                                        root.loginScale = 0.7 + r * 0.9
                                    }
                                }
                            }
                        }
                    }

                    // Row 1.4: Frosted Card Background Toggle
                    Rectangle {
                        width: parent.width
                        height: 48 * s
                        radius: 4 * s
                        color: loginCardRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: loginCardSwitch.left
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "Frosted card background"
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                            }
                            Text {
                                text: "Translucent backing plate on box"
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                color: root.textMuted
                            }
                        }

                        Rectangle {
                            id: loginCardSwitch
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42 * s
                            height: 24 * s
                            radius: 12 * s
                            color: root.loginCardEnabled ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 18 * s
                                height: 18 * s
                                radius: 9 * s
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.loginCardEnabled ? parent.width - width - 3 * s : 3 * s
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.loginCardEnabled ? "󰄬" : "󰅖"
                                    font.family: root.monoFont
                                    font.pixelSize: 10 * s
                                    color: root.loginCardEnabled ? root.accentColor : root.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: loginCardRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.loginCardEnabled = !root.loginCardEnabled
                        }
                    }

                    // Row 1.5: Transition Style Selector
                    Rectangle {
                        id: rowUnlockAnim
                        width: parent.width
                        height: root.unlockAnimMenuOpen ? (48 * s + animContentCol.implicitHeight + 14 * s) : 48 * s
                        topLeftRadius: 4 * s
                        topRightRadius: 4 * s
                        bottomLeftRadius: 14 * s
                        bottomRightRadius: 14 * s
                        clip: true
                        color: unlockAnimRowMa.containsMouse || root.unlockAnimMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: unlockAnimHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: unlockAnimSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Transition"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Lock to login animation style"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: unlockAnimSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: unlockAnimLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: unlockAnimLabel
                                        anchors.centerIn: parent
                                        text: root.unlockAnimStyle
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.unlockAnimMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: unlockAnimRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.unlockAnimMenuOpen = !root.unlockAnimMenuOpen
                                    if (root.unlockAnimMenuOpen) {
                                        root.loginStyleMenuOpen = false
                                        root.boxMenuOpen = false
                                        root.loginPosMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: unlockAnimDrawer
                            anchors.top: unlockAnimHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8 * s
                            anchors.rightMargin: 8 * s
                            height: animContentCol.implicitHeight
                            opacity: root.unlockAnimMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Column {
                                id: animContentCol
                                width: parent.width
                                spacing: 2 * s

                                Repeater {
                                    model: ["Kinetic Slide", "Morph Dissolve", "Directional Sweep", "Zoom Velocity", "Split Horizontal", "Cyber Drop"]

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 26 * s
                                        radius: 6 * s
                                        color: animDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.unlockAnimStyle === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData
                                            font.family: root.sansFont
                                            font.pixelSize: 11 * s
                                            color: root.unlockAnimStyle === modelData ? "#ffffff" : root.textSecondary
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰄬"
                                            font.family: root.monoFont
                                            font.pixelSize: 12 * s
                                            color: root.accentColor
                                            visible: root.unlockAnimStyle === modelData
                                        }

                                        MouseArea {
                                            id: animDelMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.unlockAnimStyle = modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: parent.width; height: 18 * s }
                }

                    // ══════════════════════════════════════════
                    // TAB 2: AVATAR CUSTOMIZATION
                    // ══════════════════════════════════════════
                    Column {
                        id: tabAvatarCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 2 * s
                        opacity: morphingSettingsContainer.currentTab === 2 ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    // Row 2.0: Display Avatar Toggle (Matches frosted card switch)
                    Rectangle {
                        width: parent.width
                        height: 48 * s
                        topLeftRadius: 14 * s
                        topRightRadius: 14 * s
                        bottomLeftRadius: 4 * s
                        bottomRightRadius: 4 * s
                        color: avatarVisRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: switchAvatarVis.left
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Display avatar"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Show profile picture on login panel"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }
                        }

                        Rectangle {
                            id: switchAvatarVis
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42 * s
                            height: 24 * s
                            radius: 12 * s
                            color: root.avatarVisible ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 18 * s
                                height: 18 * s
                                radius: 9 * s
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.avatarVisible ? parent.width - width - 3 * s : 3 * s
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.avatarVisible ? "󰄬" : "󰅖"
                                    font.family: root.monoFont
                                    font.pixelSize: 10 * s
                                    color: root.avatarVisible ? root.accentColor : root.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: avatarVisRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.avatarVisible = !root.avatarVisible
                        }
                    }

                    // Row 2.1: Avatar Shape (Compact M3 Shape selector with smooth scrolling)
                    Rectangle {
                        id: rowShape
                        width: parent.width
                        height: root.shapeMenuOpen ? (48 * s + 150 * s) : 48 * s
                        radius: 4 * s
                        clip: true
                        color: shapeRowMa.containsMouse || root.shapeMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: shapeHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: shapeSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Avatar shape"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Profile picture mask geometry"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: shapeSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: shapeBtnLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: shapeBtnLabel
                                        anchors.centerIn: parent
                                        text: root.avatarShape
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.shapeMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: shapeRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.shapeMenuOpen = !root.shapeMenuOpen
                                    if (root.shapeMenuOpen) {
                                        root.avatarStyleMenuOpen = false
                                        root.avatarOrientMenuOpen = false
                                        root.avatarTintMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: shapeDrawer
                            anchors.top: shapeHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8 * s
                            anchors.rightMargin: 8 * s
                            height: 140 * s
                            opacity: root.shapeMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Flickable {
                                id: shapeFlick
                                anchors.fill: parent
                                contentWidth: width
                                contentHeight: shapeContentCol.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                WheelHandler {
                                    target: shapeFlick
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                    onWheel: function(event) {
                                        var maxScroll = Math.max(0, shapeFlick.contentHeight - shapeFlick.height)
                                        if (maxScroll <= 0) return
                                        var step = 32 * s
                                        if (event.angleDelta.y < 0) {
                                            shapeFlick.contentY = Math.min(maxScroll, shapeFlick.contentY + step)
                                        } else {
                                            shapeFlick.contentY = Math.max(0, shapeFlick.contentY - step)
                                        }
                                    }
                                }

                                Column {
                                    id: shapeContentCol
                                    width: parent.width - 8 * s
                                    spacing: 2 * s

                                    Repeater {
                                        model: [
                                            { name: "Cookie 9-Sided", shape: MaterialShape.Cookie9Sided },
                                            { name: "Triangle",       shape: MaterialShape.Triangle },
                                            { name: "Clamshell",      shape: MaterialShape.ClamShell },
                                            { name: "Cookie 4-Sided", shape: MaterialShape.Cookie4Sided },
                                            { name: "Cookie 7-Sided", shape: MaterialShape.Cookie7Sided },
                                            { name: "Sunny",          shape: MaterialShape.Sunny },
                                            { name: "Very Sunny",     shape: MaterialShape.VerySunny },
                                            { name: "Square",         shape: MaterialShape.Square },
                                            { name: "Circle",         shape: MaterialShape.Circle },
                                            { name: "Diamond",        shape: MaterialShape.Diamond },
                                            { name: "Heart",          shape: MaterialShape.Heart }
                                        ]

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 26 * s
                                            radius: 6 * s
                                            color: shapeDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.avatarShape === modelData.name ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 10 * s
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.name
                                                font.family: root.sansFont
                                                font.pixelSize: 11 * s
                                                color: root.avatarShape === modelData.name ? "#ffffff" : root.textSecondary
                                            }

                                            Text {
                                                anchors.right: parent.right
                                                anchors.rightMargin: 10 * s
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "󰄬"
                                                font.family: root.monoFont
                                                font.pixelSize: 12 * s
                                                color: root.accentColor
                                                visible: root.avatarShape === modelData.name
                                            }

                                            MouseArea {
                                                id: shapeDelMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.avatarShape = modelData.name
                                                    root.currentM3Shape = modelData.shape
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: shapeScrollBar
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 4 * s
                                anchors.bottomMargin: 4 * s
                                width: 3 * s
                                radius: 1.5 * s
                                color: Qt.rgba(1, 1, 1, 0.08)
                                visible: shapeFlick.contentHeight > shapeFlick.height

                                Rectangle {
                                    width: parent.width
                                    radius: parent.radius
                                    color: root.accentColor
                                    opacity: 0.6
                                    height: Math.max(14 * s, (shapeFlick.height / shapeFlick.contentHeight) * parent.height)
                                    y: shapeFlick.contentHeight > shapeFlick.height ? (shapeFlick.contentY / (shapeFlick.contentHeight - shapeFlick.height)) * (parent.height - height) : 0
                                }
                            }
                        }
                    }

                    // Row 2.2: Avatar Style (Frame and effect dropdown)
                    Rectangle {
                        id: rowAvatarStyle
                        width: parent.width
                        height: root.avatarStyleMenuOpen ? (48 * s + avatarStyleContentCol.implicitHeight + 14 * s) : 48 * s
                        radius: 4 * s
                        clip: true
                        color: avatarStyleRowMa.containsMouse || root.avatarStyleMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: avatarStyleHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: avatarStyleSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Avatar style"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Frame and effect"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: avatarStyleSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: avatarStyleLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: avatarStyleLabel
                                        anchors.centerIn: parent
                                        text: root.avatarStyle
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.avatarStyleMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: avatarStyleRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.avatarStyleMenuOpen = !root.avatarStyleMenuOpen
                                    if (root.avatarStyleMenuOpen) {
                                        root.shapeMenuOpen = false
                                        root.avatarOrientMenuOpen = false
                                        root.avatarTintMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: avatarStyleDrawer
                            anchors.top: avatarStyleHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8 * s
                            anchors.rightMargin: 8 * s
                            height: avatarStyleContentCol.implicitHeight
                            opacity: root.avatarStyleMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Column {
                                id: avatarStyleContentCol
                                width: parent.width
                                spacing: 2 * s

                                Repeater {
                                    model: ["Minimal Outline", "Neon Glow", "Double Ring", "Glass Badge", "Cyber Brackets"]

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 26 * s
                                        radius: 6 * s
                                        color: styleDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.avatarStyle === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData
                                            font.family: root.sansFont
                                            font.pixelSize: 11 * s
                                            color: root.avatarStyle === modelData ? "#ffffff" : root.textSecondary
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰄬"
                                            font.family: root.monoFont
                                            font.pixelSize: 12 * s
                                            color: root.accentColor
                                            visible: root.avatarStyle === modelData
                                        }

                                        MouseArea {
                                            id: styleDelMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.avatarStyle = modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 2.3: Avatar Placement (Relative to password input)
                    Rectangle {
                        id: avatarOrientRow
                        width: parent.width
                        height: root.avatarOrientMenuOpen ? (48 * s + 90 * s) : 48 * s
                        radius: 4 * s
                        clip: true
                        color: avatarOrientRowMa.containsMouse || root.avatarOrientMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: avatarOrientHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: avatarOrientSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Avatar placement"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Position relative to password box"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: avatarOrientSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: avatarOrientLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: avatarOrientLabel
                                        anchors.centerIn: parent
                                        text: root.avatarOrientation
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.avatarOrientMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: avatarOrientRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.avatarOrientMenuOpen = !root.avatarOrientMenuOpen
                                    if (root.avatarOrientMenuOpen) {
                                        root.shapeMenuOpen = false
                                        root.avatarStyleMenuOpen = false
                                        root.avatarTintMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: avatarOrientDrawer
                            anchors.top: avatarOrientHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 90 * s
                            opacity: root.avatarOrientMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Grid {
                                anchors.centerIn: parent
                                rows: 3
                                columns: 3
                                spacing: 6 * s

                                Repeater {
                                    model: 9
                                    delegate: Rectangle {
                                        width: 24 * s
                                        height: 24 * s
                                        radius: 6 * s
                                        color: root.getAvatarGridPos() === index ? root.accentColor : (gridAvatarCellMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : Qt.rgba(1, 1, 1, 0.12))
                                        border.color: root.getAvatarGridPos() === index ? "#ffffff" : Qt.rgba(1, 1, 1, 0.20)
                                        border.width: 1 * s

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 6 * s
                                            height: 6 * s
                                            radius: 3 * s
                                            color: "#ffffff"
                                            visible: root.getAvatarGridPos() === index
                                        }

                                        MouseArea {
                                            id: gridAvatarCellMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.setAvatarGridPos(index)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 2.4: Avatar Theme Tint (Color scheme overlay dropdown)
                    Rectangle {
                        id: rowAvatarTint
                        width: parent.width
                        height: root.avatarTintMenuOpen ? (48 * s + avatarTintContentCol.implicitHeight + 14 * s) : 48 * s
                        radius: 4 * s
                        clip: true
                        color: avatarTintRowMa.containsMouse || root.avatarTintMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: avatarTintHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: avatarTintSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Theme tint"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Color scheme overlay"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: avatarTintSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: avatarTintLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: avatarTintLabel
                                        anchors.centerIn: parent
                                        text: root.avatarTintMode
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.avatarTintMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: avatarTintRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.avatarTintMenuOpen = !root.avatarTintMenuOpen
                                    if (root.avatarTintMenuOpen) {
                                        root.shapeMenuOpen = false
                                        root.avatarStyleMenuOpen = false
                                        root.avatarOrientMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: avatarTintDrawer
                            anchors.top: avatarTintHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8 * s
                            anchors.rightMargin: 8 * s
                            height: avatarTintContentCol.implicitHeight
                            opacity: root.avatarTintMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Column {
                                id: avatarTintContentCol
                                width: parent.width
                                spacing: 2 * s

                                Repeater {
                                    model: ["None", "Subtle Glow", "Duo-tone", "Monochrome"]

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 26 * s
                                        radius: 6 * s
                                        color: tintDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.avatarTintMode === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData
                                            font.family: root.sansFont
                                            font.pixelSize: 11 * s
                                            color: root.avatarTintMode === modelData ? "#ffffff" : root.textSecondary
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰄬"
                                            font.family: root.monoFont
                                            font.pixelSize: 12 * s
                                            color: root.accentColor
                                            visible: root.avatarTintMode === modelData
                                        }

                                        MouseArea {
                                            id: tintDelMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.avatarTintMode = modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 2.5: Tint Intensity Slider (Active when tint mode is not None)
                    Rectangle {
                        id: rowAvatarTintIntensity
                        width: parent.width
                        height: root.avatarTintMode !== "None" ? 58 * s : 0
                        radius: 4 * s
                        clip: true
                        visible: height > 0
                        opacity: root.avatarTintMode !== "None" ? 1 : 0
                        color: Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10 * s
                            spacing: 8 * s

                            Item {
                                width: parent.width
                                height: 16 * s

                                Text {
                                    text: "Tint intensity"
                                    font.family: root.sansFont
                                    font.pixelSize: 12 * s
                                    font.weight: Font.DemiBold
                                    color: root.textPrimary
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: Math.round(root.avatarTintIntensity * 100) + "%"
                                    font.family: root.monoFont
                                    font.pixelSize: 11 * s
                                    color: root.accentColor
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item {
                                width: parent.width
                                height: 12 * s

                                Rectangle {
                                    id: avatarTintTrack
                                    anchors.fill: parent
                                    height: 4 * s
                                    radius: 2 * s
                                    color: Qt.rgba(1, 1, 1, 0.12)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        height: parent.height
                                        width: Math.max(0, Math.min(parent.width, ((root.avatarTintIntensity - 0.10) / 0.70) * parent.width))
                                        radius: 2 * s
                                        color: root.accentColor
                                    }
                                }

                                Rectangle {
                                    width: 12 * s
                                    height: 12 * s
                                    radius: 6 * s
                                    color: "#ffffff"
                                    anchors.verticalCenter: avatarTintTrack.verticalCenter
                                    x: Math.max(0, Math.min(avatarTintTrack.width - width, ((root.avatarTintIntensity - 0.10) / 0.70) * (avatarTintTrack.width - width)))
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: function(mouse) {
                                        var r = Math.max(0, Math.min(1, mouse.x / width))
                                        root.avatarTintIntensity = Math.round((0.10 + r * 0.70) * 100) / 100
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var r = Math.max(0, Math.min(1, mouse.x / width))
                                            root.avatarTintIntensity = Math.round((0.10 + r * 0.70) * 100) / 100
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Card 2.6: Live Glowing Avatar Preview Card
                    Rectangle {
                        width: parent.width
                        height: 72 * s
                        radius: 12 * s
                        color: Qt.alpha(root.accentColor, 0.08)

                        Row {
                            anchors.centerIn: parent
                            spacing: 16 * s

                            Item {
                                width: 44 * s
                                height: 44 * s
                                anchors.verticalCenter: parent.verticalCenter

                                // Preview Neon Glow
                                MaterialShape {
                                    anchors.fill: parent
                                    shape: root.currentM3Shape
                                    color: root.accentColor
                                    opacity: root.avatarStyle === "Neon Glow" ? 0.65 : 0.25
                                    scale: root.avatarStyle === "Neon Glow" ? 1.25 : 1.15
                                }

                                // Preview Double Ring Outer
                                MaterialShape {
                                    anchors.fill: parent
                                    anchors.margins: -4 * s
                                    shape: root.currentM3Shape
                                    color: Qt.alpha(root.accentColor, 0.40)
                                    visible: root.avatarStyle === "Double Ring"
                                }

                                // Preview Glass Badge Backing
                                FrostedGlassCard {
                                    anchors.fill: parent
                                    anchors.margins: -5 * s
                                    radius: width / 2
                                    tintColor: Qt.alpha(root.glassBg, 0.65)
                                    borderColor: Qt.alpha(root.glassBorder, 0.70)
                                    borderWidth: 1 * s
                                    visible: root.avatarStyle === "Glass Badge"
                                }

                                MaterialShape {
                                    anchors.fill: parent
                                    shape: root.currentM3Shape
                                    color: root.avatarStyle === "Neon Glow" ? root.accentColor : root.glassBorder
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 2 * s

                                    Item {
                                        id: previewContentGroup
                                        anchors.fill: parent
                                        visible: false

                                        Image {
                                            id: avatarPreviewFaceImg
                                            anchors.fill: parent
                                            source: root.getUserAvatar(root.activeUser.name, root.activeUser.icon)
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                            mipmap: true

                                            property int fallbackStage: 0

                                            function getNextFallback(login, stage) {
                                                if (!login || login === "") return ""
                                                if (stage === 1) return "file:///home/" + login + "/.face.icon"
                                                if (stage === 2) return "file:///usr/share/sddm/faces/" + login + ".face.icon"
                                                if (stage === 3) return "file:///var/lib/AccountsService/icons/" + login
                                                return ""
                                            }

                                            onSourceChanged: {
                                                fallbackStage = 0
                                            }

                                            onStatusChanged: {
                                                if (status === Image.Error && fallbackStage < 3) {
                                                    fallbackStage++
                                                    var next = getNextFallback(root.activeUser.name, fallbackStage)
                                                    if (next !== "" && next !== source) {
                                                        source = next
                                                    }
                                                }
                                            }
                                        }

                                        Desaturate {
                                            anchors.fill: avatarPreviewFaceImg
                                            source: avatarPreviewFaceImg
                                            desaturation: (root.avatarTintMode === "Monochrome" || root.avatarTintMode === "Duo-tone") ? Math.min(1.0, root.avatarTintIntensity * 2.2) : 0.0
                                            visible: desaturation > 0
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: root.accentColor
                                            opacity: {
                                                if (root.avatarTintMode === "None" || root.avatarTintMode === "Monochrome") return 0.0
                                                if (root.avatarTintMode === "Subtle Glow") return Math.min(0.45, root.avatarTintIntensity * 0.6)
                                                if (root.avatarTintMode === "Duo-tone") return Math.min(0.70, root.avatarTintIntensity * 0.85)
                                                return 0.0
                                            }
                                        }
                                    }

                                    MaterialShape {
                                        id: previewFaceMask
                                        anchors.fill: parent
                                        shape: root.currentM3Shape
                                        animationDuration: 350
                                        color: "#ffffff"
                                        visible: false
                                    }

                                    OpacityMask {
                                        anchors.fill: parent
                                        source: previewContentGroup
                                        maskSource: previewFaceMask
                                        visible: avatarPreviewFaceImg.status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        font.family: root.monoFont
                                        font.pixelSize: 22 * s
                                        color: "#ffffff"
                                        visible: avatarPreviewFaceImg.status !== Image.Ready
                                    }
                                }

                                // Preview Cyber Brackets
                                Item {
                                    anchors.fill: parent
                                    anchors.margins: -4 * s
                                    visible: root.avatarStyle === "Cyber Brackets"

                                    Rectangle { x: 0; y: 0; width: 6 * s; height: 1.5 * s; color: root.accentColor }
                                    Rectangle { x: 0; y: 0; width: 1.5 * s; height: 6 * s; color: root.accentColor }
                                    Rectangle { x: parent.width - 6 * s; y: 0; width: 6 * s; height: 1.5 * s; color: root.accentColor }
                                    Rectangle { x: parent.width - 1.5 * s; y: 0; width: 1.5 * s; height: 6 * s; color: root.accentColor }
                                    Rectangle { x: 0; y: parent.height - 1.5 * s; width: 6 * s; height: 1.5 * s; color: root.accentColor }
                                    Rectangle { x: 0; y: parent.height - 6 * s; width: 1.5 * s; height: 6 * s; color: root.accentColor }
                                    Rectangle { x: parent.width - 6 * s; y: parent.height - 1.5 * s; width: 6 * s; height: 1.5 * s; color: root.accentColor }
                                    Rectangle { x: parent.width - 1.5 * s; y: parent.height - 6 * s; width: 1.5 * s; height: 6 * s; color: root.accentColor }
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: root.avatarShape
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.DemiBold
                                    color: root.textPrimary
                                }
                                Text {
                                    text: root.avatarStyle + " · " + (root.avatarTintMode === "None" ? "Natural" : root.avatarTintMode)
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }
                        }
                    }

                    // Row 2.3: Avatar Size Slider
                    Rectangle {
                        id: rowAvatarScale
                        width: parent.width
                        height: 58 * s
                        radius: 12 * s
                        color: Qt.alpha(root.accentColor, 0.08)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10 * s
                            spacing: 8 * s

                            Item {
                                width: parent.width
                                height: 16 * s

                                Text {
                                    text: "Avatar size"
                                    font.family: root.sansFont
                                    font.pixelSize: 12 * s
                                    font.weight: Font.DemiBold
                                    color: root.textPrimary
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: root.avatarScale.toFixed(1) + "x"
                                    font.family: root.monoFont
                                    font.pixelSize: 11 * s
                                    color: root.accentColor
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item {
                                width: parent.width
                                height: 12 * s

                                Rectangle {
                                    id: avatarScaleTrack
                                    anchors.fill: parent
                                    height: 4 * s
                                    radius: 2 * s
                                    color: Qt.rgba(1, 1, 1, 0.12)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        height: parent.height
                                        width: Math.max(0, Math.min(parent.width, ((root.avatarScale - 0.6) / 0.8) * parent.width))
                                        radius: 2 * s
                                        color: root.accentColor
                                    }
                                }

                                Rectangle {
                                    width: 12 * s
                                    height: 12 * s
                                    radius: 6 * s
                                    color: "#ffffff"
                                    anchors.verticalCenter: avatarScaleTrack.verticalCenter
                                    x: Math.max(0, Math.min(avatarScaleTrack.width - width, ((root.avatarScale - 0.6) / 0.8) * (avatarScaleTrack.width - width)))
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: function(mouse) {
                                        var r = Math.max(0, Math.min(1, mouse.x / width))
                                        root.avatarScale = Math.round((0.6 + r * 0.8) * 10) / 10
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var r = Math.max(0, Math.min(1, mouse.x / width))
                                            root.avatarScale = Math.round((0.6 + r * 0.8) * 10) / 10
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: parent.width; height: 18 * s }
                }

                    // ══════════════════════════════════════════
                    // TAB 3: THEMES & DISPLAY CUSTOMIZATION
                    // ══════════════════════════════════════════
                    Column {
                        id: tabThemeCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 2 * s
                        opacity: morphingSettingsContainer.currentTab === 3 ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    // Row 3.0: 1-Click Complete Presets
                    Rectangle {
                        id: presetsRow
                        width: parent.width
                        height: 74 * s
                        radius: 8 * s
                        color: Qt.alpha(root.accentColor, 0.08)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8 * s
                            spacing: 6 * s

                            Row {
                                spacing: 6 * s
                                Text {
                                    text: "Presets"
                                    font.family: root.sansFont
                                    font.pixelSize: 12 * s
                                    font.weight: Font.Bold
                                    color: root.accentColor
                                }
                                Text {
                                    text: "· simple SWITCH"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Flickable {
                                width: parent.width
                                height: 32 * s
                                contentWidth: presetChipsRow.implicitWidth
                                boundsBehavior: Flickable.StopAtBounds
                                clip: true

                                Row {
                                    id: presetChipsRow
                                    spacing: 6 * s

                                    Repeater {
                                        model: [
                                            { name: "Pixel Sakura", color: "#ff7b90" },
                                            { name: "Cyber HUD", color: "#00f0ff" },
                                            { name: "Editorial Luxe", color: "#e2b774" },
                                            { name: "Neo Digital", color: "#ff3b5c" },
                                            { name: "Spectrum", color: "#6b8aff" }
                                        ]

                                        Rectangle {
                                            height: 28 * s
                                            width: presetChipText.implicitWidth + 24 * s
                                            radius: 14 * s
                                            color: chipMa.containsMouse ? Qt.alpha(modelData.color, 0.35) : Qt.alpha(modelData.color, 0.16)
                                            border.color: Qt.alpha(modelData.color, 0.55)
                                            border.width: 1 * s
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6 * s

                                                Rectangle {
                                                    width: 6 * s
                                                    height: 6 * s
                                                    radius: 3 * s
                                                    color: modelData.color
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Text {
                                                    id: presetChipText
                                                    text: modelData.name
                                                    font.family: root.sansFont
                                                    font.pixelSize: 10.5 * s
                                                    font.weight: Font.DemiBold
                                                    color: "#ffffff"
                                                }
                                            }

                                            MouseArea {
                                                id: chipMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: applyPreset(modelData.name)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 3.05: Interface Font
                    Rectangle {
                        id: uiFontRow
                        width: parent.width
                        height: root.fontMenuOpen ? (48 * s + 150 * s) : 48 * s
                        radius: 8 * s
                        clip: true
                        color: uiFontRowMa.containsMouse || root.fontMenuOpen ? Qt.alpha(root.accentColor, 0.16) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: uiFontHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: uiFontSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Interface font"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Global typography style"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: uiFontSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: uiFontBtnLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: uiFontBtnLabel
                                        anchors.centerIn: parent
                                        text: root.uiFontFamily
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 28 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: uiFontRowMa.containsMouse || root.fontMenuOpen ? Qt.alpha(root.accentColor, 0.45) : Qt.alpha(root.accentColor, 0.25)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.fontMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }

                            MouseArea {
                                id: uiFontRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.fontMenuOpen = !root.fontMenuOpen
                                    if (root.fontMenuOpen) {
                                        root.paletteMenuOpen = false
                                        root.variantMenuOpen = false
                                    }
                                }
                            }
                        }

                        // Compact Scrollable Drawer
                        Item {
                            id: uiFontDrawer
                            anchors.top: uiFontHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 6 * s
                            clip: true
                            opacity: root.fontMenuOpen ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            Flickable {
                                id: uiFontFlick
                                anchors.fill: parent
                                contentWidth: width
                                contentHeight: uiFontCol.implicitHeight
                                boundsBehavior: Flickable.StopAtBounds
                                clip: true

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    onWheel: function(event) {
                                        var maxScroll = Math.max(0, uiFontFlick.contentHeight - uiFontFlick.height)
                                        if (maxScroll <= 0) return
                                        var step = 32 * s
                                        if (event.angleDelta.y < 0) {
                                            uiFontFlick.contentY = Math.min(maxScroll, uiFontFlick.contentY + step)
                                        } else {
                                            uiFontFlick.contentY = Math.max(0, uiFontFlick.contentY - step)
                                        }
                                    }
                                }

                                Column {
                                    id: uiFontCol
                                    width: parent.width - 8 * s
                                    spacing: 2 * s

                                    Repeater {
                                        model: [
                                            "Google Sans",
                                            "Pixelify Sans",
                                            "Orbitron",
                                            "Share Tech Mono",
                                            "Oxanium",
                                            "Cinzel",
                                            "NDot Matrix",
                                            "Itim",
                                            "JetBrains Mono"
                                        ]

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 28 * s
                                            radius: 6 * s
                                            color: fontDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.uiFontFamily === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 10 * s
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData
                                                font.family: {
                                                    if (modelData === "Pixelify Sans") return root.pixelFontFamily
                                                    if (modelData === "Orbitron") return root.cyberDisplayFont
                                                    if (modelData === "Share Tech Mono") return root.cyberHudMono
                                                    if (modelData === "Oxanium") return root.techDisplayFont
                                                    if (modelData === "Cinzel") return root.cinzelFontFamily
                                                    if (modelData === "NDot Matrix") return root.dotMatrixFontFamily
                                                    if (modelData === "Itim") return root.itimFontFamily
                                                    if (modelData === "JetBrains Mono") return root.monoFont
                                                    return googleSansFont.name !== "" ? googleSansFont.name : "sans-serif"
                                                }
                                                font.pixelSize: 11 * s
                                                color: root.uiFontFamily === modelData ? "#ffffff" : root.textSecondary
                                            }

                                            Text {
                                                anchors.right: parent.right
                                                anchors.rightMargin: 10 * s
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "󰄬"
                                                font.family: root.monoFont
                                                font.pixelSize: 12 * s
                                                color: root.accentColor
                                                visible: root.uiFontFamily === modelData
                                            }

                                            MouseArea {
                                                id: fontDelMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.uiFontFamily = modelData
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Minimal Scrollbar
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 3 * s
                                radius: 1.5 * s
                                color: Qt.rgba(1, 1, 1, 0.08)
                                visible: uiFontFlick.contentHeight > uiFontFlick.height

                                Rectangle {
                                    width: parent.width
                                    height: Math.max(16 * s, uiFontFlick.height * (uiFontFlick.height / uiFontFlick.contentHeight))
                                    y: (uiFontFlick.contentY / (uiFontFlick.contentHeight - uiFontFlick.height)) * (parent.height - height)
                                    radius: parent.radius
                                    color: Qt.alpha(root.accentColor, 0.65)
                                }
                            }
                        }
                    }

                    // Row 3.1: Color Palette
                    Rectangle {
                        id: rowPal
                        width: parent.width
                        height: root.paletteMenuOpen ? (48 * s + 150 * s) : 48 * s
                        radius: 8 * s
                        clip: true
                        color: palRowMa.containsMouse || root.paletteMenuOpen ? Qt.alpha(root.accentColor, 0.16) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: palHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: palSplitBtn.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Color palette"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Select theme accent and glass tint"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: palSplitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: palBtnLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: palBtnLabel
                                        anchors.centerIn: parent
                                        text: root.colorScheme
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.paletteMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }

                            MouseArea {
                                id: palRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.paletteMenuOpen = !root.paletteMenuOpen
                                    if (root.paletteMenuOpen) {
                                        root.variantMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: palDrawer
                            anchors.top: palHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8 * s
                            anchors.rightMargin: 8 * s
                            height: 140 * s
                            opacity: root.paletteMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Flickable {
                                id: palFlick
                                anchors.fill: parent
                                contentWidth: width
                                contentHeight: palContentCol.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                WheelHandler {
                                    target: palFlick
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                    onWheel: function(event) {
                                        var maxScroll = Math.max(0, palFlick.contentHeight - palFlick.height)
                                        if (maxScroll <= 0) return
                                        var step = 32 * s
                                        if (event.angleDelta.y < 0) {
                                            palFlick.contentY = Math.min(maxScroll, palFlick.contentY + step)
                                        } else {
                                            palFlick.contentY = Math.max(0, palFlick.contentY - step)
                                        }
                                    }
                                }

                                Column {
                                    id: palContentCol
                                    width: parent.width - 8 * s
                                    spacing: 2 * s

                                Repeater {
                                    model: [
                                        { name: "Dynamic",              col: root.dynamicAccentColor, surf: Qt.darker(root.dynamicAccentColor, 3.5), sub: "wallpaper" },
                                        { name: "Catppuccin Mocha",     col: "#c2c1ff", surf: "#131317", sub: "catppuccin" },
                                        { name: "Catppuccin Macchiato",  col: "#bac3ff", surf: "#131317", sub: "catppuccin" },
                                        { name: "Catppuccin Frappe",     col: "#b7c4ff", surf: "#131317", sub: "catppuccin" },
                                        { name: "Catppuccin Latte",      col: "#3e7b9f", surf: "#f8f9fc", sub: "catppuccin" },
                                        { name: "Nord",                 col: "#88c0d0", surf: "#2e3440", sub: "nord" },
                                        { name: "Tokyo Night",          col: "#7aa2f7", surf: "#1a1b26", sub: "tokyonight" },
                                        { name: "Rose Pine Main",        col: "#c9bfff", surf: "#141317", sub: "rosepine" },
                                        { name: "Rose Pine Moon",        col: "#c6bfff", surf: "#141317", sub: "rosepine" },
                                        { name: "Dracula",              col: "#bd93f9", surf: "#282a36", sub: "dracula" },
                                        { name: "Gruvbox",              col: "#81d3e0", surf: "#101415", sub: "gruvbox" },
                                        { name: "Everforest",           col: "#7fbbb3", surf: "#252b2e", sub: "everforest" },
                                        { name: "OneDark",              col: "#a8c8ff", surf: "#121317", sub: "onedark" },
                                        { name: "Dark Green",           col: "#24bd5c", surf: "#1e1e24", sub: "darkgreen" },
                                        { name: "Astra",                col: "#5db5f5", surf: "#05131e", sub: "astra" },
                                        { name: "Caelestia",            col: "#9bd0cc", surf: "#0a0f0f", sub: "caelestia" },
                                        { name: "Nothing Red",          col: "#ff3b30", surf: "#16090a", sub: "nothing" },
                                        { name: "Sakura Pink",          col: "#ff7b90", surf: "#1f1014", sub: "sakura" },
                                        { name: "Cyber Cyan",           col: "#00f0ff", surf: "#06151a", sub: "cyber" },
                                        { name: "Editorial Gold",       col: "#e2b774", surf: "#191610", sub: "editorial" }
                                    ]

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 30 * s
                                        radius: 6 * s
                                        color: palDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.colorScheme === modelData.name ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Row {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8 * s

                                            Rectangle {
                                                width: 14 * s
                                                height: 14 * s
                                                radius: 7 * s
                                                color: modelData.surf
                                                clip: true
                                                anchors.verticalCenter: parent.verticalCenter
                                                border.color: Qt.rgba(1, 1, 1, 0.22)
                                                border.width: 0.7 * s

                                                Rectangle {
                                                    anchors.top: parent.top
                                                    anchors.bottom: parent.bottom
                                                    anchors.right: parent.right
                                                    width: parent.width / 2
                                                    color: modelData.col
                                                }
                                            }

                                            Row {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 6 * s

                                                Text {
                                                    text: modelData.name
                                                    font.family: root.sansFont
                                                    font.pixelSize: 11 * s
                                                    font.weight: root.colorScheme === modelData.name ? Font.DemiBold : Font.Normal
                                                    color: root.colorScheme === modelData.name ? "#ffffff" : root.textSecondary
                                                }

                                                Text {
                                                    text: "·  " + modelData.sub
                                                    font.family: root.sansFont
                                                    font.pixelSize: 9 * s
                                                    color: root.textMuted
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰄬"
                                            font.family: root.monoFont
                                            font.pixelSize: 12 * s
                                            color: root.accentColor
                                            visible: root.colorScheme === modelData.name
                                        }

                                        MouseArea {
                                            id: palDelMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.colorScheme = modelData.name
                                            }
                                        }
                                    }
                                }
                            } // end palContentCol
                            } // end palFlick

                            Rectangle {
                                id: palScrollBar
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 4 * s
                                anchors.bottomMargin: 4 * s
                                width: 3 * s
                                radius: 1.5 * s
                                color: Qt.rgba(1, 1, 1, 0.08)
                                visible: palFlick.contentHeight > palFlick.height

                                Rectangle {
                                    width: parent.width
                                    radius: parent.radius
                                    color: root.accentColor
                                    opacity: 0.6
                                    height: Math.max(14 * s, (palFlick.height / palFlick.contentHeight) * parent.height)
                                    y: palFlick.contentHeight > palFlick.height ? (palFlick.contentY / (palFlick.contentHeight - palFlick.height)) * (parent.height - height) : 0
                                }
                            }
                        }
                    }

                    // Row 3.1b: Material 3 / Caelestia Scheme Variant Selector (Image 3)
                    Rectangle {
                        id: rowVariant
                        width: parent.width
                        height: root.variantMenuOpen ? (52 * s + 150 * s) : 52 * s
                        radius: 8 * s
                        color: varRowMa.containsMouse || root.variantMenuOpen ? Qt.alpha(root.accentColor, 0.14) : Qt.alpha(root.accentColor, 0.08)
                        clip: true
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Item {
                            id: varHeaderBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 52 * s

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 14 * s
                                anchors.right: varRightBadge.left
                                anchors.rightMargin: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Text {
                                    text: "Scheme Variant"
                                    font.family: root.sansFont
                                    font.pixelSize: 13 * s
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                                Text {
                                    text: "Material 3 tonal palette tuning"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }

                            Row {
                                id: varRightBadge
                                anchors.right: parent.right
                                anchors.rightMargin: 14 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2 * s

                                Rectangle {
                                    height: 28 * s
                                    width: varBtnLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: varBtnLabel
                                        anchors.centerIn: parent
                                        text: root.schemeVariant
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                Rectangle {
                                    height: 28 * s
                                    width: 26 * s
                                    topLeftRadius: 4 * s
                                    bottomLeftRadius: 4 * s
                                    topRightRadius: 14 * s
                                    bottomRightRadius: 14 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        font.family: root.monoFont
                                        font.pixelSize: 13 * s
                                        color: "#ffffff"
                                        rotation: root.variantMenuOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }

                            MouseArea {
                                id: varRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.variantMenuOpen = !root.variantMenuOpen
                                    if (root.variantMenuOpen) {
                                        root.paletteMenuOpen = false
                                    }
                                }
                            }
                        }

                        Item {
                            id: varDrawer
                            anchors.top: varHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8 * s
                            anchors.rightMargin: 8 * s
                            height: 140 * s
                            opacity: root.variantMenuOpen ? 1 : 0
                            visible: opacity > 0
                            clip: true
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Flickable {
                                id: varFlick
                                anchors.fill: parent
                                contentWidth: width
                                contentHeight: varContentCol.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                WheelHandler {
                                    target: varFlick
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                    onWheel: function(event) {
                                        var maxScroll = Math.max(0, varFlick.contentHeight - varFlick.height)
                                        if (maxScroll <= 0) return
                                        var step = 32 * s
                                        if (event.angleDelta.y < 0) {
                                            varFlick.contentY = Math.min(maxScroll, varFlick.contentY + step)
                                        } else {
                                            varFlick.contentY = Math.max(0, varFlick.contentY - step)
                                        }
                                    }
                                }

                                Column {
                                    id: varContentCol
                                    width: parent.width - 8 * s
                                    spacing: 4 * s

                                Repeater {
                                    model: [
                                        { id: "Vibrant",    name: "Vibrant",     desc: "High chroma palette with maximum vibrancy", icon: "󰄛" },
                                        { id: "Tonal Spot", name: "Tonal Spot",  desc: "Default for Material theme colors. Pastel with low chroma", icon: "󰀲" },
                                        { id: "Expressive", name: "Expressive",  desc: "Medium chroma palette with playful contrasting hues", icon: "󰒲" },
                                        { id: "Fidelity",   name: "Fidelity",    desc: "Matches seed color directly even if bright", icon: "󰈈" },
                                        { id: "Fruit Salad",name: "Fruit Salad", desc: "Playful theme where seed hue shifts for unique contrast", icon: "󰃚" },
                                        { id: "Rainbow",    name: "Rainbow",     desc: "Colorful playful spectrum across all surfaces", icon: "󰋑" },
                                        { id: "Neutral",    name: "Neutral",     desc: "Close to grayscale with just a soft hint of chroma", icon: "󰌵" },
                                        { id: "Monochrome", name: "Monochrome",  desc: "Pure clean grayscale, zero chroma", icon: "󰔢" }
                                    ]

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 38 * s
                                        radius: 6 * s
                                        color: varItemMa.containsMouse ? Qt.alpha(root.accentColor, 0.28) : (root.schemeVariant === modelData.id ? Qt.alpha(root.accentColor, 0.18) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Row {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 10 * s

                                            Text {
                                                text: modelData.icon
                                                font.family: root.monoFont
                                                font.pixelSize: 15 * s
                                                color: root.accentColor
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 1 * s

                                                Text {
                                                    text: modelData.name
                                                    font.family: root.sansFont
                                                    font.pixelSize: 12 * s
                                                    font.weight: Font.Medium
                                                    color: root.schemeVariant === modelData.id ? "#ffffff" : root.textPrimary
                                                }

                                                Text {
                                                    text: modelData.desc
                                                    font.family: root.sansFont
                                                    font.pixelSize: 9 * s
                                                    color: root.textMuted
                                                    width: 220 * s
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰄬"
                                            font.family: root.monoFont
                                            font.pixelSize: 12 * s
                                            color: root.accentColor
                                            visible: root.schemeVariant === modelData.id
                                        }

                                        MouseArea {
                                            id: varItemMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.schemeVariant = modelData.id
                                            }
                                        }
                                    }
                                }
                            } // end varContentCol
                            } // end varFlick

                            Rectangle {
                                id: varScrollBar
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 4 * s
                                anchors.bottomMargin: 4 * s
                                width: 3 * s
                                radius: 1.5 * s
                                color: Qt.rgba(1, 1, 1, 0.08)
                                visible: varFlick.contentHeight > varFlick.height

                                Rectangle {
                                    width: parent.width
                                    radius: parent.radius
                                    color: root.accentColor
                                    opacity: 0.6
                                    height: Math.max(14 * s, (varFlick.height / varFlick.contentHeight) * parent.height)
                                    y: varFlick.contentHeight > varFlick.height ? (varFlick.contentY / (varFlick.contentHeight - varFlick.height)) * (parent.height - height) : 0
                                }
                            }
                        }
                    }

                    // Row 3.1c: Scheme Flavour Toggle (Default vs Hard / Deep OLED Dark)
                    Rectangle {
                        width: parent.width
                        height: 48 * s
                        radius: 8 * s
                        color: flavRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: flavSwitch.left
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "Hard Flavour"
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                            }
                            Text {
                                text: "Deep OLED high-contrast dark surfaces"
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                color: root.textMuted
                            }
                        }

                        Rectangle {
                            id: flavSwitch
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42 * s
                            height: 24 * s
                            radius: 12 * s
                            color: root.schemeFlavour === "Hard" ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 18 * s
                                height: 18 * s
                                radius: 9 * s
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.schemeFlavour === "Hard" ? parent.width - width - 3 * s : 3 * s
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.schemeFlavour === "Hard" ? "󰄬" : "󰅖"
                                    font.family: root.monoFont
                                    font.pixelSize: 10 * s
                                    color: root.schemeFlavour === "Hard" ? root.accentColor : root.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: flavRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.schemeFlavour = root.schemeFlavour === "Hard" ? "Default" : "Hard"
                            }
                        }
                    }

                    // Row 3.1d: Clock Card Outline Toggle (Matches Image 1)
                    Rectangle {
                        width: parent.width
                        height: 48 * s
                        radius: 8 * s
                        color: clockBrdRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: switchClockBrd.left
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "Clock Card Outline"
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                            }
                            Text {
                                text: "Show accent border outline on the clock card"
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                color: root.textMuted
                            }
                        }

                        Rectangle {
                            id: switchClockBrd
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42 * s
                            height: 24 * s
                            radius: 12 * s
                            color: root.clockBorderEnabled ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 18 * s
                                height: 18 * s
                                radius: 9 * s
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.clockBorderEnabled ? parent.width - width - 3 * s : 3 * s
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.clockBorderEnabled ? "󰄬" : "󰅖"
                                    font.family: root.monoFont
                                    font.pixelSize: 10 * s
                                    color: root.clockBorderEnabled ? root.accentColor : root.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: clockBrdRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clockBorderEnabled = !root.clockBorderEnabled
                        }
                    }

                    // Row 3.1e: Card & Menu Outlines Toggle (Matches Image 2)
                    Rectangle {
                        width: parent.width
                        height: 48 * s
                        radius: 8 * s
                        color: cardBrdRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: switchCardBrd.left
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "Card & Menu Outlines"
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                            }
                            Text {
                                text: "Show accent border outlines on frosted cards & menus"
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                color: root.textMuted
                            }
                        }

                        Rectangle {
                            id: switchCardBrd
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42 * s
                            height: 24 * s
                            radius: 12 * s
                            color: root.cardBorderEnabled ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 18 * s
                                height: 18 * s
                                radius: 9 * s
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.cardBorderEnabled ? parent.width - width - 3 * s : 3 * s
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.cardBorderEnabled ? "󰄬" : "󰅖"
                                    font.family: root.monoFont
                                    font.pixelSize: 10 * s
                                    color: root.cardBorderEnabled ? root.accentColor : root.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: cardBrdRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cardBorderEnabled = !root.cardBorderEnabled
                        }
                    }

                    // Row 3.2: 12-Hour Clock Toggle
                    Rectangle {
                        width: parent.width
                        height: 48 * s
                        radius: 4 * s
                        color: clock12hRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: switch12h.left
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "12-hour clock"
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                            }
                            Text {
                                text: "Use AM/PM format instead of 24h"
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                color: root.textMuted
                            }
                        }

                        Rectangle {
                            id: switch12h
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42 * s
                            height: 24 * s
                            radius: 12 * s
                            color: root.is12Hour ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 18 * s
                                height: 18 * s
                                radius: 9 * s
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.is12Hour ? parent.width - width - 3 * s : 3 * s
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.is12Hour ? "󰄬" : "󰅖"
                                    font.family: root.monoFont
                                    font.pixelSize: 10 * s
                                    color: root.is12Hour ? root.accentColor : root.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: clock12hRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.is12Hour = !root.is12Hour
                        }
                    }

                    // Row 3.3: Lava Lamp Blobs Toggle
                    Rectangle {
                        width: parent.width
                        height: 48 * s
                        radius: 8 * s
                        color: lavaRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: switchLava.left
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "M3 backgrounds"
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                            }
                            Text {
                                text: "Floating Material You geometric shapes"
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                color: root.textMuted
                            }
                        }

                        Rectangle {
                            id: switchLava
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42 * s
                            height: 24 * s
                            radius: 12 * s
                            color: root.showLavaBlobs ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 18 * s
                                height: 18 * s
                                radius: 9 * s
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.showLavaBlobs ? parent.width - width - 3 * s : 3 * s
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.showLavaBlobs ? "󰄬" : "󰅖"
                                    font.family: root.monoFont
                                    font.pixelSize: 10 * s
                                    color: root.showLavaBlobs ? root.accentColor : root.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: lavaRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showLavaBlobs = !root.showLavaBlobs
                        }
                    }

                    // Row 3.4: Frosted Glass Blur Toggle
                    Rectangle {
                        id: rowGlassBlurToggle
                        width: parent.width
                        height: 48 * s
                        radius: 8 * s
                        color: blurToggleMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: switchGlassBlur.left
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "Frosted backdrop blur"
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                            }
                            Text {
                                text: "Real-time blur on cards & menus"
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                color: root.textMuted
                            }
                        }

                        Rectangle {
                            id: switchGlassBlur
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42 * s
                            height: 24 * s
                            radius: 12 * s
                            color: root.glassBlurEnabled ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 18 * s
                                height: 18 * s
                                radius: 9 * s
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.glassBlurEnabled ? parent.width - width - 3 * s : 3 * s
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.glassBlurEnabled ? "󰄬" : "󰅖"
                                    font.family: root.monoFont
                                    font.pixelSize: 10 * s
                                    color: root.glassBlurEnabled ? root.accentColor : root.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: blurToggleMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.glassBlurEnabled = !root.glassBlurEnabled
                        }
                    }

                    // Row 3.5: Blur Radius Slider
                    Rectangle {
                        id: rowGlassBlurSlider
                        width: parent.width
                        height: 58 * s
                        radius: 8 * s
                        color: Qt.alpha(root.accentColor, 0.08)
                        visible: root.glassBlurEnabled

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10 * s
                            spacing: 8 * s

                            Item {
                                width: parent.width
                                height: 16 * s

                                Text {
                                    text: "Blur intensity"
                                    font.family: root.sansFont
                                    font.pixelSize: 12 * s
                                    font.weight: Font.DemiBold
                                    color: root.textPrimary
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: root.glassBlurRadius + "px"
                                    font.family: root.monoFont
                                    font.pixelSize: 11 * s
                                    color: root.accentColor
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item {
                                width: parent.width
                                height: 12 * s

                                Rectangle {
                                    id: blurTrack
                                    anchors.fill: parent
                                    height: 4 * s
                                    radius: 2 * s
                                    color: Qt.rgba(1, 1, 1, 0.12)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        height: parent.height
                                        width: Math.max(0, Math.min(parent.width, ((root.glassBlurRadius - 16) / 64) * parent.width))
                                        radius: 2 * s
                                        color: root.accentColor
                                    }
                                }

                                Rectangle {
                                    width: 12 * s
                                    height: 12 * s
                                    radius: 6 * s
                                    color: "#ffffff"
                                    anchors.verticalCenter: blurTrack.verticalCenter
                                    x: Math.max(0, Math.min(blurTrack.width - width, ((root.glassBlurRadius - 16) / 64) * (blurTrack.width - width)))
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: function(mouse) {
                                        var r = Math.max(0, Math.min(1, mouse.x / width))
                                        root.glassBlurRadius = Math.round(16 + r * 64)
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var r = Math.max(0, Math.min(1, mouse.x / width))
                                            root.glassBlurRadius = Math.round(16 + r * 64)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: parent.width; height: 18 * s }
                } // end tabThemeCol
            } // end tabContentArea
        } // end settingsFlickable

        Item {
            id: settingsScrollBar
            anchors.top: settingsFlickable.top
            anchors.bottom: settingsFlickable.bottom
            anchors.right: settingsFlickable.right
            anchors.rightMargin: 1 * s
            width: 3 * s
            visible: settingsFlickable.contentHeight > settingsFlickable.height
            z: 10

            Rectangle {
                width: 3 * s
                radius: 1.5 * s
                color: Qt.alpha(root.accentColor, 0.55)
                height: Math.max(16 * s, (settingsFlickable.height / Math.max(1, settingsFlickable.contentHeight)) * settingsFlickable.height)
                y: (settingsFlickable.contentHeight > settingsFlickable.height) ? ((settingsFlickable.contentY / Math.max(1, settingsFlickable.contentHeight - settingsFlickable.height)) * (settingsFlickable.height - height)) : 0
            }
        }
    } // end settingsExpandedView
} // end morphingSettingsContainer

        // ─── Morphing Session Pill-to-Menu Container (Kinetic Button-to-Menu Transformation!) ───
        Rectangle {
            id: morphingSessionContainer
            anchors.left: morphingSettingsContainer.right
            anchors.leftMargin: 10 * s
            anchors.bottom: parent.bottom
            width: root.sessionMenuOpen ? 240 * s : (sessionRow.implicitWidth + 24 * s)
            height: root.sessionMenuOpen ? (48 * s + Math.max(1, (typeof sessionModel !== "undefined" ? sessionModel.rowCount() : 1)) * 40 * s) : 38 * s
            radius: root.sessionMenuOpen ? 18 * s : 12 * s
            color: "transparent"

            FrostedGlassCard {
                radius: morphingSessionContainer.radius
                tintColor: root.sessionMenuOpen ? root.glassBg : (sessArea.containsMouse ? Qt.alpha(root.accentColor, 0.30) : Qt.alpha(root.glassBg, 0.25))
                borderColor: root.sessionMenuOpen ? root.glassBorder : (sessArea.containsMouse ? root.accentColor : Qt.alpha(root.glassBorder, 0.40))
                borderWidth: 1 * s
                showBorder: root.cardBorderEnabled
            }
            clip: true
            opacity: root.settingsOpen ? 0 : 1
            visible: opacity > 0
            z: 50

            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on border.color { ColorAnimation { duration: 250 } }

            // Collapsed State: Compact Session Pill Button
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 38 * s
                visible: !root.sessionMenuOpen
                opacity: root.sessionMenuOpen ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Row {
                    id: sessionRow
                    anchors.centerIn: parent
                    spacing: 8 * s

                    Text {
                        text: root.activeSession.icon
                        font.family: root.monoFont
                        font.pixelSize: 15 * s
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    Text {
                        id: sessionNameLabel
                        text: root.activeSession.name.split(" ")[0]
                        color: root.textSecondary
                        font.family: root.sansFont
                        font.pixelSize: 13 * s
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: sessArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.sessionMenuOpen = true
                        root.userListOpen = false
                        root.settingsOpen = false
                        root.powerMenuOpen = false
                    }
                }
            }

            // Expanded State: Session Picker Menu Card with Staggered Items
            Column {
                anchors.fill: parent
                anchors.margins: 10 * s
                spacing: 4 * s
                visible: root.sessionMenuOpen
                opacity: root.sessionMenuOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                // Header
                Item {
                    width: parent.width
                    height: 24 * s

                    Text {
                        text: "Desktop Sessions"
                        font.family: root.sansFont
                        font.pixelSize: 12 * s
                        font.weight: Font.Bold
                        color: root.textSecondary
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "󰅖"
                        font.family: root.monoFont
                        font.pixelSize: 13 * s
                        color: sessCloseMa.containsMouse ? "#ffffff" : root.textMuted
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            id: sessCloseMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sessionMenuOpen = false
                        }
                    }
                }

                // Real SDDM Session Items (Zero Mock Desktops!)
                Repeater {
                    model: typeof sessionModel !== "undefined" ? sessionModel : 1
                    delegate: Rectangle {
                        property string sessName: (typeof model !== "undefined" && model.name) ? model.name : "Hyprland"
                        width: parent.width
                        height: 36 * s
                        radius: 8 * s
                        color: sItemMa.containsMouse ? Qt.alpha(root.accentColor, 0.25) : (root.currentSessionIdx === index ? Qt.alpha(root.accentColor, 0.15) : "transparent")

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8 * s

                            Text {
                                text: getSessionIcon(sessName)
                                font.family: root.monoFont
                                font.pixelSize: 14 * s
                                color: root.currentSessionIdx === index ? root.accentColor : root.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: sessName
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.weight: Font.Medium
                                color: root.currentSessionIdx === index ? "#ffffff" : root.textPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰄬"
                            font.family: root.monoFont
                            font.pixelSize: 12 * s
                            color: root.accentColor
                            visible: root.currentSessionIdx === index
                        }

                        MouseArea {
                            id: sItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentSessionIdx = index
                                root.sessionMenuOpen = false
                            }
                        }
                    }
                }
            }
        }

        // ─── Right: Reliable Action Row (Right-to-Left Layout with Silky Delayed Action Blossom!) ───
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 10 * s
            layoutDirection: Qt.RightToLeft

            // 1. Power Pill
            Rectangle {
                id: expandablePowerContainer
                height: 38 * s
                width: root.powerMenuOpen ? (expandedPowerRow.implicitWidth + 30 * s) : 38 * s
                radius: 12 * s
                color: "transparent"
                clip: true

                FrostedGlassCard {
                    radius: parent.radius
                    tintColor: root.powerMenuOpen ? root.glassBg : (powerToggleMa.containsMouse ? Qt.alpha(root.accentColor, 0.28) : Qt.alpha(root.glassBg, 0.25))
                    borderColor: root.powerMenuOpen ? root.accentColor : (powerToggleMa.containsMouse ? root.accentColor : Qt.alpha(root.glassBorder, 0.40))
                    borderWidth: 1 * s
                    showBorder: root.cardBorderEnabled
                }

                Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }

                // Collapsed State: Single Power Icon (󰐥)
                Item {
                    anchors.fill: parent
                    visible: !root.powerMenuOpen
                    opacity: root.powerMenuOpen ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰐥"
                        font.family: root.monoFont
                        font.pixelSize: 16 * s
                        color: powerToggleMa.containsMouse ? root.accentColor : root.textPrimary
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: powerToggleMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.powerMenuOpen = true
                            root.settingsOpen = false
                            root.isKeyboardOpen = false
                            root.sessionMenuOpen = false
                            root.userListOpen = false
                        }
                    }
                }

                // Expanded State: Sleep, Reboot, Shut Down, Close (Glides in smoothly AFTER width expands!)
                Row {
                    id: expandedPowerRow
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -root.powerContentXOffset
                    spacing: 8 * s
                    visible: root.powerContentOpacity > 0
                    opacity: root.powerContentOpacity

                    // Suspend
                    Rectangle {
                        height: 28 * s
                        width: suspRow.implicitWidth + 14 * s
                        radius: 8 * s
                        color: suspMa.containsMouse ? Qt.alpha(root.accentColor, 0.25) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Row {
                            id: suspRow
                            anchors.centerIn: parent
                            spacing: 5 * s
                            Text { text: "󰤄"; font.family: root.monoFont; font.pixelSize: 13 * s; color: root.textPrimary; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Sleep"; font.family: root.sansFont; font.pixelSize: 12 * s; color: root.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: suspMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (typeof sddm !== "undefined") sddm.suspend() }
                        }
                    }

                    // Reboot
                    Rectangle {
                        height: 28 * s
                        width: rebRow.implicitWidth + 14 * s
                        radius: 8 * s
                        color: rebMa.containsMouse ? Qt.alpha(root.accentColor, 0.25) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Row {
                            id: rebRow
                            anchors.centerIn: parent
                            spacing: 5 * s
                            Text { text: "󰜉"; font.family: root.monoFont; font.pixelSize: 13 * s; color: root.textPrimary; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Reboot"; font.family: root.sansFont; font.pixelSize: 12 * s; color: root.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: rebMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (typeof sddm !== "undefined") sddm.reboot() }
                        }
                    }

                    // Shut Down
                    Rectangle {
                        height: 28 * s
                        width: shutRow.implicitWidth + 22 * s
                        radius: 8 * s
                        color: shutMa.containsMouse ? Qt.alpha(root.accentColor, 0.50) : Qt.alpha(root.accentColor, 0.25)
                        border.color: Qt.alpha(root.accentColor, 0.50)
                        border.width: 1 * s
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Row {
                            id: shutRow
                            anchors.centerIn: parent
                            spacing: 5 * s
                            Text { text: "󰐥"; font.family: root.monoFont; font.pixelSize: 13 * s; color: shutMa.containsMouse ? "#ffffff" : root.accentColor; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Shut Down"; font.family: root.sansFont; font.pixelSize: 12 * s; color: shutMa.containsMouse ? "#ffffff" : root.textPrimary; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: shutMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (typeof sddm !== "undefined") sddm.powerOff() }
                        }
                    }

                    // Close Flyout (󰅖)
                    Rectangle {
                        height: 28 * s
                        width: 28 * s
                        radius: 8 * s
                        color: closePowerMa.containsMouse ? Qt.alpha(root.accentColor, 0.25) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: root.monoFont
                            font.pixelSize: 12 * s
                            color: root.textMuted
                        }
                        MouseArea {
                            id: closePowerMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.powerMenuOpen = false
                        }
                    }
                }
            }

            // 2. Keyboard Button (Appears with the transition to the lockscreen login prompt)
            Rectangle {
                id: kbToggleBtn
                height: 38 * s
                width: root.isUnlocked ? 38 * s : 0
                opacity: root.isUnlocked ? 1.0 : 0.0
                scale: root.isUnlocked ? 1.0 : 0.7
                visible: opacity > 0.01
                clip: true
                radius: 12 * s
                color: "transparent"

                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

                FrostedGlassCard {
                    radius: parent.radius
                    tintColor: root.isKeyboardOpen ? Qt.alpha(root.accentColor, 0.40) : (kbBtnMa.containsMouse ? Qt.alpha(root.accentColor, 0.28) : Qt.alpha(root.glassBg, 0.25))
                    borderColor: root.isKeyboardOpen ? root.accentColor : (kbBtnMa.containsMouse ? root.accentColor : Qt.alpha(root.glassBorder, 0.40))
                    borderWidth: 1 * s
                    showBorder: root.cardBorderEnabled
                }

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }

                Text {
                    anchors.centerIn: parent
                    text: root.isKeyboardOpen ? "󰅖" : "󰌌"
                    font.family: root.monoFont
                    font.pixelSize: 16 * s
                    color: root.isKeyboardOpen ? "#ffffff" : (kbBtnMa.containsMouse ? root.accentColor : root.textPrimary)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: kbBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isKeyboardOpen = !root.isKeyboardOpen
                        if (typeof Qt.inputMethod !== "undefined" && Qt.inputMethod) {
                            Qt.inputMethod.hide()
                        }
                        if (root.isKeyboardOpen) {
                            root.powerMenuOpen = false
                            root.settingsOpen = false
                            root.sessionMenuOpen = false
                            root.userListOpen = false
                        }
                    }
                }
            }
        }
    }

    // ──────────────────────────────────────────
    // Virtual Keyboard (Themed Frosted Glass Container)
    // ──────────────────────────────────────────
    Rectangle {
        id: onScreenKeyboard
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.isKeyboardOpen ? 75 * s : -320 * s
        width: 780 * s
        height: 230 * s
        radius: 18 * s
        color: "transparent"

        FrostedGlassCard {
            radius: parent.radius
            tintColor: root.glassBg
            borderColor: root.glassBorder
            borderWidth: 1 * s
        }
        scale: root.isKeyboardOpen ? 1.0 : 0.90
        opacity: root.isKeyboardOpen ? 1 : 0
        visible: opacity > 0
        z: 45

        layer.enabled: true
        layer.effect: DropShadow { color: "#50000000"; radius: 20; samples: 16 }

        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        Column {
            id: keyboardContentCol
            anchors.centerIn: parent
            spacing: 7 * s

            // Row 1: Numbers
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5 * s
                Repeater {
                    model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="]
                    delegate: KeyButton { keyText: modelData; onKeyClicked: appendChar(keyText) }
                }
                KeyButton {
                    keyText: "󰁮"
                    btnWidth: 58 * s
                    accent: true
                    onKeyClicked: backspaceChar()
                }
            }

            // Row 2: QWERTY
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5 * s
                Repeater {
                    model: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]"]
                    delegate: KeyButton {
                        keyText: root.capsLock ? modelData.toUpperCase() : modelData
                        onKeyClicked: appendChar(keyText)
                    }
                }
            }

            // Row 3: ASDF
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5 * s
                KeyButton {
                    keyText: "󰘲"
                    btnWidth: 54 * s
                    accent: root.capsLock
                    onKeyClicked: root.capsLock = !root.capsLock
                }
                Repeater {
                    model: ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"]
                    delegate: KeyButton {
                        keyText: root.capsLock ? modelData.toUpperCase() : modelData
                        onKeyClicked: appendChar(keyText)
                    }
                }
                KeyButton {
                    keyText: "󰌑"
                    btnWidth: 58 * s
                    accent: true
                    onKeyClicked: doLogin()
                }
            }

            // Row 4: ZXCV & Space & Close
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5 * s
                Repeater {
                    model: ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"]
                    delegate: KeyButton {
                        keyText: root.capsLock ? modelData.toUpperCase() : modelData
                        onKeyClicked: appendChar(keyText)
                    }
                }
                KeyButton {
                    keyText: "Space"
                    btnWidth: 120 * s
                    onKeyClicked: appendChar(" ")
                }
                KeyButton {
                    keyText: "󰅖"
                    btnWidth: 44 * s
                    onKeyClicked: {
                        root.isKeyboardOpen = false
                        if (typeof Qt.inputMethod !== "undefined" && Qt.inputMethod) {
                            Qt.inputMethod.hide()
                        }
                        passwordInput.forceActiveFocus()
                    }
                }
            }
        }
    }

    // Keyboard Key Component (Themed Frosted Glass Keys)
    component KeyButton: Rectangle {
        id: kBtn
        property string keyText: ""
        property real btnWidth: 46 * s
        property real btnHeight: 38 * s
        property bool accent: false
        signal keyClicked()

        width: btnWidth
        height: btnHeight
        radius: 8 * s
        color: kMa.pressed ? Qt.alpha(root.accentColor, 0.45) : (kMa.containsMouse ? Qt.alpha(root.accentColor, 0.28) : (accent ? Qt.alpha(root.accentColor, 0.35) : Qt.alpha(root.accentColor, 0.08)))
        border.color: kMa.containsMouse ? root.accentColor : (accent ? root.accentColor : Qt.alpha(root.accentColor, 0.22))
        border.width: 1 * s

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        scale: kMa.pressed ? 0.92 : (kMa.containsMouse ? 1.05 : 1.0)
        Behavior on scale { NumberAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: kBtn.keyText
            color: root.textPrimary
            font.family: root.monoFont
            font.pixelSize: 13 * s
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: kMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                kBtn.keyClicked()
                passwordInput.forceActiveFocus()
            }
        }
    }

    function appendChar(c) {
        passwordInput.text += c
    }

    function backspaceChar() {
        if (passwordInput.text.length > 0) {
            passwordInput.text = passwordInput.text.slice(0, -1)
        }
    }

    // ──────────────────────────────────────────
    // Login & Error Handling Actions
    // ──────────────────────────────────────────
    function doLogin() {
        if (passwordInput.text.length === 0) return
        root.isLoggingIn = true
        loginTimeoutTimer.restart()
        var uname = root.activeUser.name
        if (typeof sddm !== "undefined") {
            sddm.login(uname, passwordInput.text, root.currentSessionIdx)
        }
    }

    Timer {
        id: loginTimeoutTimer
        interval: 2200
        running: false
        onTriggered: {
            if (root.isLoggingIn) {
                root.isLoggingIn = false
            }
        }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            root.isLoggingIn = false
            errorText.text = "ACCESS DENIED"
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
            shakeAnim.start()
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: loginPanelContainer; property: "anchors.rightMargin"; to: 125 * s; duration: 40 }
        NumberAnimation { target: loginPanelContainer; property: "anchors.rightMargin"; to: 95 * s; duration: 40 }
        NumberAnimation { target: loginPanelContainer; property: "anchors.rightMargin"; to: 118 * s; duration: 40 }
        NumberAnimation { target: loginPanelContainer; property: "anchors.rightMargin"; to: 102 * s; duration: 40 }
        NumberAnimation { target: loginPanelContainer; property: "anchors.rightMargin"; to: 110 * s; duration: 40 }
    }
}
