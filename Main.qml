import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0
import M3Shapes

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#030408"
    readonly property real s: height / 768

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

    // Customizable Appearance Properties with Real M3Shapes!
    property int currentM3Shape: MaterialShape.Cookie9Sided
    property string avatarShape: "Cookie 9-Sided" 
    property string boxShape: "Rounded"
    property string colorScheme: "Nothing Red"

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
        if (row === 1) return (root.height - itemH - bottomReserved) / 2
        return root.height - itemH - marginY - bottomReserved
    }

    // ──────────────────────────────────────────
    // Clock Customization Properties
    // ──────────────────────────────────────────
    property string clockStyle: "Caelestia Split" // "Caelestia Split", "Classic Minimal", "Two-Tier Stacked", "Compact Capsule"
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

    // ──────────────────────────────────────────
    // Login Container Customization Properties
    // ──────────────────────────────────────────
    property int loginGridPos: 5 // Default: 5 (Middle Right)
    property real loginScale: 1.0 // 0.7 to 1.6
    property bool loginCardEnabled: false
    property real loginCardOpacity: 0.40 // 0.15 to 0.85
    property string avatarOrientation: "Right" // "Right", "Left", "Top Center", "Top Left", "Top Right"
    property string boxStyle: "Glass Pill" // "Glass Pill", "Minimal Underline", "Split Badge", "Sharp M3 Card"

    function getBoxRadius(h) {
        if (boxStyle === "Glass Pill" || boxStyle === "Split Badge") return h / 2
        if (boxStyle === "Sharp M3 Card") return 6 * s
        if (boxStyle === "Minimal Underline") return 4 * s
        return 14 * s
    }

    // ──────────────────────────────────────────
    // Mock / Real Models for Users & Sessions (Allows testing dropdown menus!)
    // ──────────────────────────────────────────
    property var mockUserList: [
        { name: "retro", realName: "retro", icon: "file:///home/retro/.face" },
        { name: "astra", realName: "Astra", icon: "" },
        { name: "lumine", realName: "Lumine", icon: "" },
        { name: "guest", realName: "Guest Account", icon: "" }
    ]
    property int currentUserIdx: 0
    readonly property var activeUser: mockUserList[currentUserIdx]

    property var mockSessionList: [
        { name: "Hyprland (Wayland)", icon: "󰣇" },
        { name: "Hyprland (UWSM)",    icon: "󰣇" },
        { name: "Plasma 6 (Wayland)", icon: "" },
        { name: "GNOME (Wayland)",    icon: "" },
        { name: "Sway (Wayland)",     icon: "󰍹" }
    ]
    property int currentSessionIdx: 0
    readonly property var activeSession: mockSessionList[currentSessionIdx]

    // ──────────────────────────────────────────
    // Dynamic Themed Colors & Themed Glass Materials
    // ──────────────────────────────────────────
    readonly property color accentColor: {
        if (colorScheme === "Nothing Red")       return "#ff3b30"
        if (colorScheme === "Catppuccin Mocha") return "#cba6f7"
        if (colorScheme === "Nord")             return "#88c0d0"
        if (colorScheme === "Tokyo Night")      return "#7aa2f7"
        if (colorScheme === "Rose Pine")        return "#ebbcba"
        if (colorScheme === "Dracula")          return "#bd93f9"
        return "#ff3b30"
    }

    readonly property color highlightGlow: {
        if (colorScheme === "Nothing Red")       return "#60ff3b30"
        if (colorScheme === "Catppuccin Mocha") return "#60cba6f7"
        if (colorScheme === "Nord")             return "#6088c0d0"
        if (colorScheme === "Tokyo Night")      return "#607aa2f7"
        if (colorScheme === "Rose Pine")        return "#60ebbcba"
        if (colorScheme === "Dracula")          return "#60bd93f9"
        return "#60ff3b30"
    }

    readonly property color glassBg: {
        if (colorScheme === "Nothing Red")       return Qt.rgba(0.14, 0.04, 0.05, 0.62)
        if (colorScheme === "Catppuccin Mocha") return Qt.rgba(0.10, 0.07, 0.16, 0.62)
        if (colorScheme === "Nord")             return Qt.rgba(0.06, 0.11, 0.15, 0.62)
        if (colorScheme === "Tokyo Night")      return Qt.rgba(0.06, 0.08, 0.18, 0.62)
        if (colorScheme === "Rose Pine")        return Qt.rgba(0.13, 0.07, 0.10, 0.62)
        if (colorScheme === "Dracula")          return Qt.rgba(0.11, 0.06, 0.15, 0.62)
        return Qt.rgba(0.10, 0.05, 0.07, 0.62)
    }

    readonly property color glassBorder: {
        if (colorScheme === "Nothing Red")       return Qt.rgba(1, 0.23, 0.19, 0.38)
        if (colorScheme === "Catppuccin Mocha") return Qt.rgba(0.80, 0.65, 0.97, 0.38)
        if (colorScheme === "Nord")             return Qt.rgba(0.53, 0.75, 0.82, 0.38)
        if (colorScheme === "Tokyo Night")      return Qt.rgba(0.48, 0.64, 0.97, 0.38)
        if (colorScheme === "Rose Pine")        return Qt.rgba(0.92, 0.74, 0.73, 0.38)
        if (colorScheme === "Dracula")          return Qt.rgba(0.74, 0.58, 0.98, 0.38)
        return Qt.rgba(1, 0.23, 0.19, 0.38)
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
    readonly property string monoFont: nerdFont.name !== "" ? nerdFont.name : "JetBrainsMono Nerd Font, monospace"
    readonly property string sansFont: googleSansFont.name !== "" ? googleSansFont.name : "Google Sans Flex, Google Sans, Inter, sans-serif"

    // Startup Animation
    Component.onCompleted: {
        introFadeAnim.start()
        updateClock()
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
        root.boxMenuOpen = false
        root.clockStyleMenuOpen = false
        root.clockPosMenuOpen = false
        root.loginPosMenuOpen = false
        root.avatarOrientMenuOpen = false
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
        root.powerMenuOpen = false
        root.settingsOpen = false
        closeAllSettingsDrawers()
        passwordInput.text = ""
        errorText.text = ""
        globalKeyHandler.forceActiveFocus()
    }

    function handleEscape() {
        if (root.shapeMenuOpen || root.paletteMenuOpen || root.boxMenuOpen ||
            root.clockStyleMenuOpen || root.clockPosMenuOpen || root.loginPosMenuOpen || root.avatarOrientMenuOpen) {
            closeAllSettingsDrawers()
        } else if (root.userListOpen) {
            root.userListOpen = false
        } else if (root.sessionMenuOpen) {
            root.sessionMenuOpen = false
        } else if (root.settingsOpen) {
            root.settingsOpen = false
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
    }

    onIs12HourChanged: updateClock()

    // ──────────────────────────────────────────
    // Background & Deep Gaussian Blur Transition
    // ──────────────────────────────────────────
    Image {
        id: bgImage
        anchors.fill: parent
        source: "bg.jpg"
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width
        sourceSize.height: root.height
        smooth: true
        visible: false
    }

    Image {
        id: bgSharp
        anchors.fill: parent
        source: "bg.jpg"
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width
        sourceSize.height: root.height
        smooth: true
        opacity: root.isUnlocked ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    }

    FastBlur {
        id: bgBlur
        anchors.fill: parent
        source: bgImage
        radius: 48
        opacity: root.isUnlocked ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    }

    // Ambient floating lava lamp shapes
    Item {
        id: ambientShapesContainer
        anchors.fill: parent
        visible: root.showLavaBlobs
        opacity: root.isUnlocked ? 0.20 : 0.45
        Behavior on opacity { NumberAnimation { duration: 600 } }

        Repeater {
            model: 8
            delegate: Rectangle {
                id: shapeItem
                property real initialX: (index * 240 + 70) * s
                property real initialY: (index % 3 * 220 + 90) * s
                property real targetY: initialY + (index % 2 === 0 ? 80 * s : -80 * s)
                x: initialX
                y: initialY
                width: (90 + (index % 4) * 35) * s
                height: width
                radius: (index % 3 === 0) ? width / 2 : ((index % 2 === 0) ? 28 * s : 14 * s)
                color: Qt.alpha(root.accentColor, 0.15)
                border.color: Qt.alpha(root.accentColor, 0.25)
                border.width: 1 * s
                rotation: index * 45

                SequentialAnimation {
                    loops: Animation.Infinite
                    running: root.showLavaBlobs
                    NumberAnimation { target: shapeItem; property: "y"; to: shapeItem.targetY; duration: 4500 + index * 800; easing.type: Easing.InOutSine }
                    NumberAnimation { target: shapeItem; property: "y"; to: shapeItem.initialY; duration: 4500 + index * 800; easing.type: Easing.InOutSine }
                }

                NumberAnimation {
                    target: shapeItem
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 18000 + index * 3000
                    loops: Animation.Infinite
                    running: root.showLavaBlobs
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

    // Background Click Handler
    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: {
            if (root.settingsOpen) {
                root.settingsOpen = false
                root.shapeMenuOpen = false
                root.paletteMenuOpen = false
                root.boxMenuOpen = false
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
        x: root.getGridX(root.clockGridPos, width, 50 * s)
        y: root.getGridY(root.clockGridPos, height, 48 * s, 70 * s)
        width: Math.max(120 * s, clockCard.width * root.clockScale)
        height: Math.max(48 * s, clockCard.height * root.clockScale)
        opacity: (!root.isUnlocked) ? root.uiOpacity : 0
        visible: opacity > 0
        z: 5

        Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: root.updateClock()
        }

        Item {
            id: clockScaler
            anchors.centerIn: parent
            width: clockCard.width
            height: clockCard.height
            scale: root.clockScale
            transformOrigin: Item.Center

            // Toggleable Frosted Glass Background Card
            Rectangle {
                id: clockGlassCard
                anchors.fill: clockCard
                anchors.margins: -18 * s
                radius: 24 * s
                color: Qt.alpha(root.glassBg, root.clockCardOpacity)
                border.color: Qt.alpha(root.glassBorder, 0.40)
                border.width: 1.5 * s
                visible: root.clockCardEnabled
                opacity: root.clockCardEnabled ? 1 : 0
                layer.enabled: root.clockCardEnabled
                layer.effect: DropShadow { color: "#40000000"; radius: 18; samples: 16 }
                Behavior on opacity { NumberAnimation { duration: 300 } }
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            // Clock Content (Switchable between 4 styles)
            Item {
                id: clockCard
                width: childrenRect.width
                height: childrenRect.height

                // Style 1: Caelestia Split (Hours:Minutes | 3-Tier Date)
                Row {
                    id: styleCaelestiaSplit
                    visible: root.clockStyle === "Caelestia Split"
                    spacing: 16 * s
                    anchors.top: parent.top
                    anchors.left: parent.left

                    // Left: Digital Hours:Minutes
                    Row {
                        spacing: 4 * s
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.clockHours + ":" + root.clockMinutes
                            color: root.textPrimary
                            font.family: root.monoFont
                            font.pixelSize: 84 * s
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow { color: "#aa000000"; radius: 24; samples: 20 }
                        }

                        Text {
                            text: root.clockAmPm
                            color: root.accentColor
                            font.family: root.sansFont
                            font.pixelSize: 18 * s
                            font.weight: Font.Bold
                            visible: root.is12Hour
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 14 * s
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    // Center: Vertical Glass Divider
                    Rectangle {
                        width: 2 * s
                        height: 56 * s
                        radius: 1 * s
                        color: Qt.alpha(root.textPrimary, 0.25)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Right: 3-Tier Stacked Date Column
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * s

                        Text {
                            text: root.clockMonthName
                            color: root.accentColor
                            font.family: root.sansFont
                            font.pixelSize: 13 * s
                            font.letterSpacing: 2 * s
                            font.weight: Font.Bold
                            layer.enabled: true
                            layer.effect: DropShadow { color: "#80000000"; radius: 8; samples: 8 }
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }

                        Text {
                            text: root.clockDayNum
                            color: root.textPrimary
                            font.family: root.sansFont
                            font.pixelSize: 28 * s
                            font.weight: Font.ExtraBold
                            layer.enabled: true
                            layer.effect: DropShadow { color: "#aa000000"; radius: 14; samples: 12 }
                        }

                        Text {
                            text: root.clockWeekday
                            color: root.textSecondary
                            font.family: root.sansFont
                            font.pixelSize: 13 * s
                            font.weight: Font.Medium
                        }
                    }
                }

                // Style 2: Classic Minimal (Horizontal Time with Date subtitle below)
                Column {
                    id: styleClassicMinimal
                    visible: root.clockStyle === "Classic Minimal"
                    spacing: 6 * s
                    anchors.top: parent.top
                    anchors.left: parent.left

                    Row {
                        spacing: 10 * s

                        Text {
                            text: root.clockHours + ":" + root.clockMinutes
                            color: root.textPrimary
                            font.family: root.monoFont
                            font.pixelSize: 96 * s
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow { color: "#aa000000"; radius: 24; samples: 20 }
                        }

                        Text {
                            text: root.clockAmPm
                            color: root.accentColor
                            font.family: root.sansFont
                            font.pixelSize: 20 * s
                            font.weight: Font.Bold
                            visible: root.is12Hour
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 18 * s
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    Row {
                        spacing: 10 * s
                        Rectangle {
                            width: 7 * s
                            height: 7 * s
                            radius: 3.5 * s
                            color: root.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                        Text {
                            text: root.clockFullDate
                            color: root.textSecondary
                            font.family: root.sansFont
                            font.pixelSize: 13 * s
                            font.letterSpacing: 2 * s
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow { color: "#80000000"; radius: 10; samples: 10 }
                        }
                    }
                }

                // Style 3: Two-Tier Stacked (Hours stacked over Minutes)
                Row {
                    id: styleTwoTierStacked
                    visible: root.clockStyle === "Two-Tier Stacked"
                    spacing: 16 * s
                    anchors.top: parent.top
                    anchors.left: parent.left

                    Column {
                        spacing: -10 * s
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.clockHours
                            color: root.textPrimary
                            font.family: root.monoFont
                            font.pixelSize: 68 * s
                            font.weight: Font.ExtraBold
                            lineHeight: 0.9
                            layer.enabled: true
                            layer.effect: DropShadow { color: "#aa000000"; radius: 20; samples: 16 }
                        }

                        Text {
                            text: root.clockMinutes
                            color: root.accentColor
                            font.family: root.monoFont
                            font.pixelSize: 68 * s
                            font.weight: Font.ExtraBold
                            lineHeight: 0.9
                            layer.enabled: true
                            layer.effect: DropShadow { color: "#aa000000"; radius: 20; samples: 16 }
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * s

                        Rectangle {
                            height: 26 * s
                            width: twoTierDateText.implicitWidth + 18 * s
                            radius: 13 * s
                            color: Qt.alpha(root.accentColor, 0.20)
                            border.color: Qt.alpha(root.accentColor, 0.40)
                            border.width: 1 * s

                            Text {
                                id: twoTierDateText
                                anchors.centerIn: parent
                                text: (root.clockWeekday.substring(0, 3) + ", " + root.clockMonthName.substring(0, 3) + " " + root.clockDayNum).toUpperCase()
                                color: "#ffffff"
                                font.family: root.sansFont
                                font.pixelSize: 11 * s
                                font.weight: Font.Bold
                                font.letterSpacing: 1 * s
                            }
                        }

                        Text {
                            text: root.clockAmPm
                            color: root.textSecondary
                            font.family: root.sansFont
                            font.pixelSize: 15 * s
                            font.weight: Font.Bold
                            visible: root.is12Hour
                        }
                    }
                }

                // Style 4: Compact Capsule (Inline pill with time & date)
                Rectangle {
                    id: styleCompactCapsule
                    visible: root.clockStyle === "Compact Capsule"
                    height: 48 * s
                    width: capsuleRow.implicitWidth + 36 * s
                    radius: 24 * s
                    color: root.glassBg
                    border.color: root.glassBorder
                    border.width: 1.5 * s
                    layer.enabled: true
                    layer.effect: DropShadow { color: "#50000000"; radius: 12; samples: 12 }

                    Row {
                        id: capsuleRow
                        anchors.centerIn: parent
                        spacing: 12 * s

                        Text {
                            text: root.clockHours + ":" + root.clockMinutes + (root.is12Hour ? (" " + root.clockAmPm) : "")
                            color: root.textPrimary
                            font.family: root.monoFont
                            font.pixelSize: 18 * s
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 5 * s
                            height: 5 * s
                            radius: 2.5 * s
                            color: root.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }

                        Text {
                            text: root.clockWeekday.substring(0, 3) + ", " + root.clockMonthName.substring(0, 3) + " " + root.clockDayNum
                            color: root.textSecondary
                            font.family: root.sansFont
                            font.pixelSize: 14 * s
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
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

            Text { text: "✦"; color: "#ffffff"; font.family: root.monoFont; font.pixelSize: 12 * s; opacity: 0.8; anchors.verticalCenter: parent.verticalCenter }
            Text {
                id: unlockHint
                text: "Click anywhere or press any key to unlock"
                color: root.textSecondary
                font.family: root.sansFont
                font.pixelSize: 13 * s
                font.letterSpacing: 1.5 * s
                anchors.verticalCenter: parent.verticalCenter
            }
            Text { text: "✦"; color: "#ffffff"; font.family: root.monoFont; font.pixelSize: 12 * s; opacity: 0.8; anchors.verticalCenter: parent.verticalCenter }

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
        x: root.getGridX(root.loginGridPos, width, 50 * s)
        y: root.getGridY(root.loginGridPos, height, 48 * s, 70 * s) - (root.isKeyboardOpen ? 120 * s : 0)
        width: Math.max(280 * s, loginContentInner.width * root.loginScale)
        height: Math.max(90 * s, loginContentInner.height * root.loginScale)
        opacity: root.isUnlocked ? root.uiOpacity : 0
        visible: opacity > 0
        z: 10

        Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Item {
            id: loginScaler
            anchors.centerIn: parent
            width: loginContentInner.width
            height: loginContentInner.height
            scale: root.loginScale
            transformOrigin: Item.Center

            // Toggleable Frosted Glass Background Card
            Rectangle {
                id: loginGlassCard
                anchors.fill: loginContentInner
                anchors.margins: -18 * s
                radius: 24 * s
                color: Qt.alpha(root.glassBg, root.loginCardOpacity)
                border.color: Qt.alpha(root.glassBorder, 0.40)
                border.width: 1.5 * s
                visible: root.loginCardEnabled
                opacity: root.loginCardEnabled ? 1 : 0
                layer.enabled: root.loginCardEnabled
                layer.effect: DropShadow { color: "#40000000"; radius: 18; samples: 16 }
                Behavior on opacity { NumberAnimation { duration: 300 } }
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            Item {
                id: loginContentInner
                readonly property real pwBoxW: 280 * s
                readonly property real pwBoxH: 52 * s
                readonly property real avatarSize: 80 * s
                readonly property bool isTop: root.avatarOrientation === "Top Center" || root.avatarOrientation === "Top Left" || root.avatarOrientation === "Top Right"

                width: (root.avatarOrientation === "Right" || root.avatarOrientation === "Left") ? (pwBoxW + 20 * s + avatarSize) : pwBoxW
                height: isTop ? (avatarSize + 14 * s + pwBoxH + 28 * s) : Math.max(avatarSize, 30 * s + pwBoxH + 26 * s)

                // Username display with Accent Dot
                Row {
                    id: userDisplayNameRow
                    spacing: 8 * s
                    x: {
                        if (root.avatarOrientation === "Top Center") return (loginContentInner.pwBoxW - width) / 2
                        if (root.avatarOrientation === "Top Left") return loginContentInner.avatarSize + 14 * s
                        if (root.avatarOrientation === "Top Right") return Math.max(0, loginContentInner.pwBoxW - loginContentInner.avatarSize - 14 * s - width)
                        if (root.avatarOrientation === "Left") return loginContentInner.avatarSize + 20 * s
                        return 0
                    }
                    y: {
                        if (root.avatarOrientation === "Top Left" || root.avatarOrientation === "Top Right") {
                            return (loginContentInner.avatarSize - height) / 2
                        }
                        return Math.max(0, passwordBoxRect.y - height - 6 * s)
                    }

                    Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 6 * s
                        height: 6 * s
                        radius: 3 * s
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    Text {
                        id: userDisplayName
                        text: root.activeUser.realName
                        color: root.textPrimary
                        font.family: root.sansFont
                        font.pixelSize: 16 * s
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5 * s
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
                        if (loginContentInner.isTop) return loginContentInner.avatarSize + 14 * s
                        return 28 * s
                    }
                    width: loginContentInner.pwBoxW
                    height: loginContentInner.pwBoxH
                    radius: root.getBoxRadius(height)
                    color: root.boxStyle === "Minimal Underline" ? Qt.alpha(root.glassBg, 0.30) : (passwordInput.activeFocus ? Qt.alpha(root.accentColor, 0.28) : root.glassBg)
                    border.color: root.boxStyle === "Minimal Underline" ? "transparent" : (passwordInput.activeFocus ? root.accentColor : root.glassBorder)
                    border.width: root.boxStyle === "Minimal Underline" ? 0 : 1.5 * s

                    property real pressBloom: 0.0

                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: passwordInput.activeFocus ? root.highlightGlow : "#50000000"
                        radius: passwordInput.activeFocus ? 18 : 10
                        samples: 16
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
                        from: 0.50
                        to: 0.0
                        duration: 350
                        easing.type: Easing.OutQuad
                    }

                    // Inner Pill-Conforming Glow (Always matched to pill radius, zero rectangular clipping!)
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(root.accentColor, 0.35)
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
                        visible: root.boxStyle === "Minimal Underline"
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
                        visible: root.boxStyle === "Split Badge"
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
                            text: "󰌾"
                            font.family: root.monoFont
                            font.pixelSize: 16 * s
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
                            focus: true

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
                                anchors.left: parent.left
                                anchors.leftMargin: 4 * s
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Password..."
                                color: root.textMuted
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                visible: passwordInput.text.length === 0
                                opacity: 0.65
                            }

                            // Pre-allocated Fixed Pool of 24 Animated Dots (Zero lifecycle flicker!)
                            Row {
                                id: dotsContainer
                                anchors.left: parent.left
                                anchors.leftMargin: 4 * s
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4 * s

                                Repeater {
                                    id: dotsRepeater
                                    model: 24

                                    Item {
                                        id: dotWrapper
                                        property bool isShown: index < passwordInput.text.length
                                        width: isShown ? 12 * s : 0
                                        height: 12 * s
                                        visible: width > 0

                                        Behavior on width {
                                            NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                                        }

                                        MaterialShape {
                                            anchors.centerIn: parent
                                            width: 10 * s
                                            height: 10 * s
                                            shape: root.passwordM3Shapes[index % root.passwordM3Shapes.length]
                                            color: "#ffffff"
                                            scale: dotWrapper.isShown ? 1.0 : 0.0
                                            rotation: dotWrapper.isShown ? 0 : -25

                                            Behavior on scale {
                                                NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                                            }
                                            Behavior on rotation {
                                                NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                                            }
                                            Behavior on color {
                                                ColorAnimation { duration: 200 }
                                            }
                                        }
                                    }
                                }

                                // Pulsing Glowing Cursor Dot (Only visible when typing, never overlaps placeholder!)
                                Item {
                                    id: cursorPill
                                    width: 8 * s
                                    height: 8 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: passwordInput.activeFocus && passwordInput.text.length > 0

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 4 * s
                                        color: root.accentColor
                                        opacity: 0.9

                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            running: passwordInput.activeFocus
                                            NumberAnimation { from: 0.9; to: 0.2; duration: 550; easing.type: Easing.InOutQuad }
                                            NumberAnimation { from: 0.2; to: 0.9; duration: 550; easing.type: Easing.InOutQuad }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Click Bloom Feedback (Zero Frame Overflow!)
                    MouseArea {
                        id: boxPressMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                        z: -1
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

                    // Submit Action Arrow Pill
                    Rectangle {
                        id: submitArrow
                        width: 34 * s
                        height: 34 * s
                        radius: root.getBoxRadius(height)
                        anchors.right: parent.right
                        anchors.rightMargin: 8 * s
                        anchors.verticalCenter: parent.verticalCenter
                        color: passwordInput.text.length > 0 ? root.accentColor : (submitMa.containsMouse ? Qt.alpha(root.accentColor, 0.25) : Qt.rgba(1, 1, 1, 0.08))
                        scale: submitMa.pressed ? 0.92 : (passwordInput.text.length > 0 ? 1.05 : 1.0)
                        visible: !root.isLoggingIn

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰁔"
                            font.family: root.monoFont
                            font.pixelSize: 14 * s
                            color: passwordInput.text.length > 0 ? "#ffffff" : (submitMa.containsMouse ? "#ffffff" : root.textMuted)
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
                    x: {
                        if (root.avatarOrientation === "Left") return 0
                        if (root.avatarOrientation === "Right") return loginContentInner.pwBoxW + 20 * s
                        if (root.avatarOrientation === "Top Center") return (loginContentInner.pwBoxW - width) / 2
                        if (root.avatarOrientation === "Top Left") return 0
                        if (root.avatarOrientation === "Top Right") return loginContentInner.pwBoxW - width
                        return loginContentInner.pwBoxW + 20 * s
                    }
                    y: {
                        if (root.avatarOrientation === "Right" || root.avatarOrientation === "Left") {
                            return passwordBoxRect.y + (loginContentInner.pwBoxH - height) / 2
                        }
                        return 0
                    }
                    width: loginContentInner.avatarSize
                    height: loginContentInner.avatarSize
                    scale: avatarMa.containsMouse ? 1.05 : 1.0

                    Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                        MaterialShape {
                        id: avatarM3Mask
                        anchors.fill: parent
                        shape: root.currentM3Shape
                        animationDuration: 350
                        color: "#ffffff"
                        visible: false
                    }

                    MaterialShape {
                        id: avatarM3Border
                        anchors.fill: parent
                        shape: root.currentM3Shape
                        animationDuration: 350
                        color: avatarMa.containsMouse ? root.accentColor : Qt.alpha(root.accentColor, 0.40)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 3 * s

                        Image {
                            id: userFaceImg
                            anchors.fill: parent
                            source: root.activeUser.icon !== "" ? root.activeUser.icon : "file:///home/" + root.activeUser.name + "/.face"
                            cache: false
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                            visible: false
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
                            source: userFaceImg
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
        anchors.topMargin: 10 * s
        anchors.bottomMargin: 10 * s
        width: 260 * s
        height: root.userListOpen ? (46 * s + root.mockUserList.length * 44 * s) : 0
        radius: 18 * s
        color: root.glassBg
        border.color: root.glassBorder
        border.width: 1 * s
        clip: true
        visible: root.userListOpen
        opacity: root.userListOpen ? 1 : 0
        z: 60

        layer.enabled: true
        layer.effect: DropShadow { color: "#50000000"; radius: 20; samples: 16 }

        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
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

            // User List Repeater
            Repeater {
                model: root.mockUserList
                delegate: Rectangle {
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
                            text: modelData.realName
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
            width: root.settingsOpen ? 370 * s : 38 * s
            height: root.settingsOpen ? Math.min(root.height - 80 * s, settingsContentCol.implicitHeight + 28 * s) : 38 * s
            radius: root.settingsOpen ? 20 * s : 12 * s
            color: root.settingsOpen ? root.glassBg : (settingsBtnMa.containsMouse ? Qt.alpha(root.accentColor, 0.28) : root.glassBg)
            border.color: root.settingsOpen ? root.glassBorder : (settingsBtnMa.containsMouse ? root.accentColor : root.glassBorder)
            border.width: 1 * s
            clip: true
            z: 50

            property int currentTab: 0

            layer.enabled: true
            layer.effect: DropShadow { color: "#50000000"; radius: root.settingsOpen ? 22 : 16; samples: 16 }

            Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on border.color { ColorAnimation { duration: 250 } }

            // Collapsed View: Gear Icon Button
            Item {
                anchors.fill: parent
                visible: !root.settingsOpen
                opacity: root.settingsOpen ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    font.family: root.monoFont
                    font.pixelSize: 16 * s
                    color: settingsBtnMa.containsMouse ? root.accentColor : root.textPrimary
                    Behavior on color { ColorAnimation { duration: 200 } }
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
            Column {
                id: settingsContentCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14 * s
                spacing: 4 * s
                visible: root.settingsOpen
                opacity: root.settingsOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }

                // Top Header Row
                Item {
                    width: parent.width
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
                                closeAllSettingsDrawers()
                            }
                        }
                    }
                }

                // Top Tab Bar (Caelestia Glass Desktop Style from recording_20260902_22-41-06.mp4)
                Rectangle {
                    width: parent.width
                    height: 34 * s
                    radius: 10 * s
                    color: Qt.alpha(root.glassBg, 0.6)
                    border.color: Qt.alpha(root.glassBorder, 0.5)
                    border.width: 1 * s

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

                                // Glowing underline indicator
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2 * s
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 18 * s
                                    height: 2 * s
                                    radius: 1 * s
                                    color: root.accentColor
                                    visible: morphingSettingsContainer.currentTab === index
                                }

                                MouseArea {
                                    id: tabMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        morphingSettingsContainer.currentTab = index
                                        closeAllSettingsDrawers()
                                    }
                                }
                            }
                        }
                    }
                }

                // ══════════════════════════════════════════
                // TAB 0: CLOCK CUSTOMIZATION
                // ══════════════════════════════════════════
                Column {
                    width: parent.width
                    spacing: 2 * s
                    visible: morphingSettingsContainer.currentTab === 0

                    // Row 0.1: Clock Style
                    Rectangle {
                        width: parent.width
                        height: root.clockStyleMenuOpen ? (48 * s + clockStyleDrawer.height) : 48 * s
                        topLeftRadius: 14 * s
                        topRightRadius: 14 * s
                        bottomLeftRadius: 4 * s
                        bottomRightRadius: 4 * s
                        clip: true
                        color: clockStyleRowMa.containsMouse || root.clockStyleMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
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
                                    width: clockStyleLabel.implicitWidth + 18 * s
                                    topLeftRadius: 14 * s
                                    bottomLeftRadius: 14 * s
                                    topRightRadius: 4 * s
                                    bottomRightRadius: 4 * s
                                    color: Qt.alpha(root.accentColor, 0.35)
                                    border.color: Qt.alpha(root.accentColor, 0.55)
                                    border.width: 1 * s

                                    Text {
                                        id: clockStyleLabel
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
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
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
                                    root.clockPosMenuOpen = false
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
                            height: root.clockStyleMenuOpen ? 112 * s : 0
                            visible: root.clockStyleMenuOpen

                            ListView {
                                anchors.fill: parent
                                clip: true
                                model: ["Caelestia Split", "Classic Minimal", "Two-Tier Stacked", "Compact Capsule"]
                                spacing: 2 * s

                                delegate: Rectangle {
                                    width: ListView.view ? ListView.view.width : 0
                                    height: 26 * s
                                    radius: 6 * s
                                    color: clockStyleDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.clockStyle === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")

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
                                            root.clockStyleMenuOpen = false
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 0.2: Clock Position (9-Grid Interactive Picker)
                    Rectangle {
                        width: parent.width
                        height: root.clockPosMenuOpen ? (48 * s + clockPosDrawer.height) : 48 * s
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
                            height: root.clockPosMenuOpen ? 90 * s : 0
                            visible: root.clockPosMenuOpen

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
                                                root.clockPosMenuOpen = false
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
                }

                // ══════════════════════════════════════════
                // TAB 1: LOGIN & BOX CUSTOMIZATION
                // ══════════════════════════════════════════
                Column {
                    width: parent.width
                    spacing: 2 * s
                    visible: morphingSettingsContainer.currentTab === 1

                    // Row 1.1: Password Box Style
                    Rectangle {
                        width: parent.width
                        height: root.boxMenuOpen ? (48 * s + boxStyleDrawer.height) : 48 * s
                        topLeftRadius: 14 * s
                        topRightRadius: 14 * s
                        bottomLeftRadius: 4 * s
                        bottomRightRadius: 4 * s
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
                                    root.loginPosMenuOpen = false
                                    root.avatarOrientMenuOpen = false
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
                            height: root.boxMenuOpen ? 112 * s : 0
                            visible: root.boxMenuOpen

                            ListView {
                                anchors.fill: parent
                                clip: true
                                model: ["Glass Pill", "Minimal Underline", "Split Badge", "Sharp M3 Card"]
                                spacing: 2 * s

                                delegate: Rectangle {
                                    width: ListView.view ? ListView.view.width : 0
                                    height: 26 * s
                                    radius: 6 * s
                                    color: boxStyleDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.boxStyle === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")

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
                                            root.boxMenuOpen = false
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 1.2: Login Screen Position (9-Grid Interactive Picker)
                    Rectangle {
                        width: parent.width
                        height: root.loginPosMenuOpen ? (48 * s + loginPosDrawer.height) : 48 * s
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
                                    root.boxMenuOpen = false
                                    root.avatarOrientMenuOpen = false
                                }
                            }
                        }

                        Item {
                            id: loginPosDrawer
                            anchors.top: loginPosHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: root.loginPosMenuOpen ? 90 * s : 0
                            visible: root.loginPosMenuOpen

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
                                                root.loginPosMenuOpen = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 1.3: Avatar Orientation
                    Rectangle {
                        width: parent.width
                        height: root.avatarOrientMenuOpen ? (48 * s + avatarOrientDrawer.height) : 48 * s
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
                                    text: "Relative to password input"
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
                                    root.boxMenuOpen = false
                                    root.loginPosMenuOpen = false
                                }
                            }
                        }

                        Item {
                            id: avatarOrientDrawer
                            anchors.top: avatarOrientHeaderBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8 * s
                            anchors.rightMargin: 8 * s
                            height: root.avatarOrientMenuOpen ? 138 * s : 0
                            visible: root.avatarOrientMenuOpen

                            ListView {
                                anchors.fill: parent
                                clip: true
                                model: ["Right", "Left", "Top Center", "Top Left", "Top Right"]
                                spacing: 2 * s

                                delegate: Rectangle {
                                    width: ListView.view ? ListView.view.width : 0
                                    height: 26 * s
                                    radius: 6 * s
                                    color: orientDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.avatarOrientation === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        color: root.avatarOrientation === modelData ? "#ffffff" : root.textSecondary
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰄬"
                                        font.family: root.monoFont
                                        font.pixelSize: 12 * s
                                        color: root.accentColor
                                        visible: root.avatarOrientation === modelData
                                    }

                                    MouseArea {
                                        id: orientDelMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.avatarOrientation = modelData
                                            root.avatarOrientMenuOpen = false
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 1.4: Login Container Scale Slider
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

                    // Row 1.5: Frosted Card Background Toggle
                    Rectangle {
                        width: parent.width
                        height: 48 * s
                        topLeftRadius: 4 * s
                        topRightRadius: 4 * s
                        bottomLeftRadius: 14 * s
                        bottomRightRadius: 14 * s
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
                }

                // ══════════════════════════════════════════
                // TAB 2: AVATAR CUSTOMIZATION
                // ══════════════════════════════════════════
                Column {
                    width: parent.width
                    spacing: 2 * s
                    visible: morphingSettingsContainer.currentTab === 2

                    // Row 2.1: Avatar Shape (11 M3 Shapes with Triangle!)
                    Rectangle {
                        id: rowShape
                        width: parent.width
                        height: root.shapeMenuOpen ? (48 * s + shapeDrawer.height) : 48 * s
                        topLeftRadius: 14 * s
                        topRightRadius: 14 * s
                        bottomLeftRadius: 4 * s
                        bottomRightRadius: 4 * s
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
                            height: root.shapeMenuOpen ? 140 * s : 0
                            visible: root.shapeMenuOpen

                            ListView {
                                anchors.fill: parent
                                clip: true
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
                                spacing: 2 * s

                                delegate: Rectangle {
                                    width: ListView.view ? ListView.view.width : 0
                                    height: 26 * s
                                    radius: 6 * s
                                    color: shapeDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.avatarShape === modelData.name ? Qt.alpha(root.accentColor, 0.18) : "transparent")

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
                                            root.shapeMenuOpen = false
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Card 2.2: Live Glowing Avatar Preview Card
                    Rectangle {
                        width: parent.width
                        height: 70 * s
                        topLeftRadius: 4 * s
                        topRightRadius: 4 * s
                        bottomLeftRadius: 14 * s
                        bottomRightRadius: 14 * s
                        color: Qt.alpha(root.accentColor, 0.08)

                        Row {
                            anchors.centerIn: parent
                            spacing: 16 * s

                            Item {
                                width: 44 * s
                                height: 44 * s
                                anchors.verticalCenter: parent.verticalCenter

                                MaterialShape {
                                    anchors.fill: parent
                                    shape: root.currentM3Shape
                                    color: root.accentColor
                                    opacity: 0.25
                                    scale: 1.15
                                }

                                MaterialShape {
                                    anchors.fill: parent
                                    shape: root.currentM3Shape
                                    color: root.glassBorder
                                }

                                Image {
                                    id: avatarPreviewFaceImg
                                    anchors.fill: parent
                                    anchors.margins: 2 * s
                                    source: (root.activeUser.icon && root.activeUser.icon !== "") ? root.activeUser.icon : "file:///home/" + root.activeUser.name + "/.face"
                                    fillMode: Image.PreserveAspectCrop
                                    visible: false
                                }

                                MaterialShape {
                                    id: previewFaceMask
                                    anchors.fill: parent
                                    anchors.margins: 2 * s
                                    shape: root.currentM3Shape
                                    animationDuration: 350
                                    color: "#ffffff"
                                    visible: false
                                }

                                OpacityMask {
                                    anchors.fill: parent
                                    anchors.margins: 2 * s
                                    source: avatarPreviewFaceImg
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
                                    text: "Live active profile mask"
                                    font.family: root.sansFont
                                    font.pixelSize: 10 * s
                                    color: root.textMuted
                                }
                            }
                        }
                    }
                }

                // ══════════════════════════════════════════
                // TAB 3: THEMES & DISPLAY CUSTOMIZATION
                // ══════════════════════════════════════════
                Column {
                    width: parent.width
                    spacing: 2 * s
                    visible: morphingSettingsContainer.currentTab === 3

                    // Row 3.1: Color Palette
                    Rectangle {
                        width: parent.width
                        height: root.paletteMenuOpen ? (48 * s + palDrawer.height) : 48 * s
                        topLeftRadius: 14 * s
                        topRightRadius: 14 * s
                        bottomLeftRadius: 4 * s
                        bottomRightRadius: 4 * s
                        clip: true
                        color: palRowMa.containsMouse || root.paletteMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
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
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
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
                            height: root.paletteMenuOpen ? 140 * s : 0
                            visible: root.paletteMenuOpen

                            ListView {
                                anchors.fill: parent
                                clip: true
                                model: [
                                    { name: "Nothing Red",       col: "#ff3b30" },
                                    { name: "Catppuccin Mocha", col: "#cba6f7" },
                                    { name: "Nord",             col: "#88c0d0" },
                                    { name: "Tokyo Night",      col: "#7aa2f7" },
                                    { name: "Rose Pine",        col: "#ebbcba" },
                                    { name: "Dracula",          col: "#bd93f9" }
                                ]
                                spacing: 2 * s

                                delegate: Rectangle {
                                    width: ListView.view ? ListView.view.width : 0
                                    height: 26 * s
                                    radius: 6 * s
                                    color: palDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.colorScheme === modelData.name ? Qt.alpha(root.accentColor, 0.18) : "transparent")

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8 * s

                                        Rectangle {
                                            width: 10 * s
                                            height: 10 * s
                                            radius: 5 * s
                                            color: modelData.col
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: modelData.name
                                            font.family: root.sansFont
                                            font.pixelSize: 11 * s
                                            color: root.colorScheme === modelData.name ? "#ffffff" : root.textSecondary
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
                                        visible: root.colorScheme === modelData.name
                                    }

                                    MouseArea {
                                        id: palDelMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.colorScheme = modelData.name
                                            root.paletteMenuOpen = false
                                        }
                                    }
                                }
                            }
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
                        topLeftRadius: 4 * s
                        topRightRadius: 4 * s
                        bottomLeftRadius: 14 * s
                        bottomRightRadius: 14 * s
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
                                text: "Lava lamp background"
                                font.family: root.sansFont
                                font.pixelSize: 13 * s
                                font.weight: Font.Medium
                                color: root.textPrimary
                            }
                            Text {
                                text: "Animate blobs on idle screen"
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
                }
            }
        }

        // ─── Morphing Session Pill-to-Menu Container (Kinetic Button-to-Menu Transformation!) ───
        Rectangle {
            id: morphingSessionContainer
            anchors.left: morphingSettingsContainer.right
            anchors.leftMargin: 10 * s
            anchors.bottom: parent.bottom
            width: root.sessionMenuOpen ? 240 * s : (sessionRow.implicitWidth + 24 * s)
            height: root.sessionMenuOpen ? (48 * s + root.mockSessionList.length * 40 * s) : 38 * s
            radius: root.sessionMenuOpen ? 18 * s : 12 * s
            color: root.sessionMenuOpen ? root.glassBg : (sessArea.containsMouse ? Qt.alpha(root.accentColor, 0.28) : root.glassBg)
            border.color: root.sessionMenuOpen ? root.glassBorder : (sessArea.containsMouse ? root.accentColor : root.glassBorder)
            border.width: 1 * s
            clip: true
            opacity: root.settingsOpen ? 0 : 1
            visible: opacity > 0
            z: 50

            layer.enabled: true
            layer.effect: DropShadow { color: "#50000000"; radius: root.sessionMenuOpen ? 20 : 10; samples: 16 }

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

                // Session Items
                Repeater {
                    model: root.mockSessionList
                    delegate: Rectangle {
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
                                text: modelData.icon
                                font.family: root.monoFont
                                font.pixelSize: 14 * s
                                color: root.currentSessionIdx === index ? root.accentColor : root.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.name
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
                color: root.powerMenuOpen ? root.glassBg : (powerToggleMa.containsMouse ? Qt.alpha(root.accentColor, 0.28) : root.glassBg)
                border.color: root.powerMenuOpen ? root.accentColor : (powerToggleMa.containsMouse ? root.accentColor : root.glassBorder)
                border.width: 1 * s
                clip: true

                layer.enabled: true
                layer.effect: DropShadow { color: "#50000000"; radius: 16; samples: 12 }

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

            // 2. Keyboard Button
            Rectangle {
                id: kbToggleBtn
                height: 38 * s
                width: 38 * s
                radius: 12 * s
                color: root.isKeyboardOpen ? Qt.alpha(root.accentColor, 0.35) : (kbBtnMa.containsMouse ? Qt.alpha(root.accentColor, 0.28) : root.glassBg)
                border.color: root.isKeyboardOpen ? root.accentColor : (kbBtnMa.containsMouse ? root.accentColor : root.glassBorder)
                border.width: 1 * s

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
        color: root.glassBg
        border.color: root.glassBorder
        border.width: 1 * s
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
