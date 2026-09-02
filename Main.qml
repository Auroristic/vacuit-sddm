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
    property bool clockShowOnLogin: true

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

    function lockScreen() {
        root.isUnlocked = false
        root.userListOpen = false
        root.sessionMenuOpen = false
        root.isKeyboardOpen = false
        root.powerMenuOpen = false
        root.settingsOpen = false
        root.shapeMenuOpen = false
        root.paletteMenuOpen = false
        root.boxMenuOpen = false
        passwordInput.text = ""
        errorText.text = ""
        globalKeyHandler.forceActiveFocus()
    }

    function handleEscape() {
        if (root.shapeMenuOpen) {
            root.shapeMenuOpen = false
        } else if (root.paletteMenuOpen) {
            root.paletteMenuOpen = false
        } else if (root.boxMenuOpen) {
            root.boxMenuOpen = false
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
        opacity: (!root.isUnlocked) ? root.uiOpacity : (root.clockShowOnLogin ? (root.uiOpacity * 0.90) : 0)
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
                                            color: root.accentColor
                                            scale: dotWrapper.isShown ? 1.0 : 0.0

                                            Behavior on scale {
                                                NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                                            }
                                            Behavior on color {
                                                ColorAnimation { duration: 200 }
                                            }
                                        }
                                    }
                                }

                                // Pulsing Glowing Cursor Dot
                                Item {
                                    id: cursorPill
                                    width: 8 * s
                                    height: 8 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: passwordInput.activeFocus

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
            width: root.settingsOpen ? 480 * s : 38 * s
            height: root.settingsOpen ? 520 * s : 38 * s
            radius: root.settingsOpen ? 22 * s : 12 * s
            color: root.settingsOpen ? root.glassBg : (settingsBtnMa.containsMouse ? Qt.alpha(root.accentColor, 0.28) : root.glassBg)
            border.color: root.settingsOpen ? root.glassBorder : (settingsBtnMa.containsMouse ? root.accentColor : root.glassBorder)
            border.width: 1 * s
            clip: true
            z: 50

            property int currentTab: 0

            layer.enabled: true
            layer.effect: DropShadow { color: "#50000000"; radius: root.settingsOpen ? 24 : 16; samples: 20 }

            Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
            Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
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

            // Expanded View: Tabbed Personalization Hub
            Item {
                anchors.fill: parent
                anchors.margins: 16 * s
                visible: root.settingsOpen
                opacity: root.settingsOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }

                // Header Bar
                Item {
                    id: settingsHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 28 * s

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8 * s

                        Rectangle {
                            width: 8 * s
                            height: 8 * s
                            radius: 4 * s
                            color: root.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }

                        Text {
                            text: "Caelestia Glass Settings"
                            font.family: root.sansFont
                            font.pixelSize: 14 * s
                            font.weight: Font.Bold
                            color: root.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        width: 26 * s
                        height: 26 * s
                        radius: 13 * s
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: closeSetMa.containsMouse ? Qt.alpha(root.accentColor, 0.25) : Qt.rgba(1, 1, 1, 0.06)

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
                            onClicked: root.settingsOpen = false
                        }
                    }
                }

                // Tab Bar
                Row {
                    id: settingsTabBar
                    anchors.top: settingsHeader.bottom
                    anchors.topMargin: 12 * s
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 32 * s
                    spacing: 6 * s

                    Repeater {
                        model: ["Clock", "Login", "Avatar", "Palette"]
                        delegate: Rectangle {
                            width: (settingsTabBar.width - (3 * 6 * s)) / 4
                            height: parent.height
                            radius: 8 * s
                            color: morphingSettingsContainer.currentTab === index ? Qt.alpha(root.accentColor, 0.35) : (tabBtnMa.containsMouse ? Qt.alpha(root.accentColor, 0.15) : Qt.rgba(1, 1, 1, 0.05))
                            border.color: morphingSettingsContainer.currentTab === index ? root.accentColor : Qt.rgba(1, 1, 1, 0.10)
                            border.width: 1 * s

                            Behavior on color { ColorAnimation { duration: 180 } }
                            Behavior on border.color { ColorAnimation { duration: 180 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: root.sansFont
                                font.pixelSize: 11 * s
                                font.weight: morphingSettingsContainer.currentTab === index ? Font.Bold : Font.Medium
                                color: morphingSettingsContainer.currentTab === index ? "#ffffff" : root.textSecondary
                            }

                            MouseArea {
                                id: tabBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: morphingSettingsContainer.currentTab = index
                            }
                        }
                    }
                }

                // Tab Content Scroll Area
                Flickable {
                    id: settingsFlickable
                    anchors.top: settingsTabBar.bottom
                    anchors.topMargin: 12 * s
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    contentWidth: width
                    contentHeight: tabContentCol.implicitHeight + 20 * s
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: tabContentCol
                        width: parent.width
                        spacing: 12 * s

                        // ══════════════════════════════════════════
                        // TAB 0: CLOCK SETTINGS
                        // ══════════════════════════════════════════
                        Column {
                            width: parent.width
                            spacing: 10 * s
                            visible: morphingSettingsContainer.currentTab === 0

                            // 1. Clock Style Selector
                            Text {
                                text: "Clock Style"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.weight: Font.DemiBold
                                color: root.textSecondary
                            }

                            Grid {
                                columns: 2
                                spacing: 6 * s
                                width: parent.width

                                Repeater {
                                    model: ["Caelestia Split", "Classic Minimal", "Two-Tier Stacked", "Compact Capsule"]
                                    delegate: Rectangle {
                                        width: (tabContentCol.width - 6 * s) / 2
                                        height: 32 * s
                                        radius: 8 * s
                                        color: root.clockStyle === modelData ? Qt.alpha(root.accentColor, 0.35) : (cStyleMa.containsMouse ? Qt.alpha(root.accentColor, 0.15) : Qt.rgba(1, 1, 1, 0.06))
                                        border.color: root.clockStyle === modelData ? root.accentColor : Qt.rgba(1, 1, 1, 0.10)
                                        border.width: 1 * s

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6 * s

                                            Text {
                                                text: modelData
                                                font.family: root.sansFont
                                                font.pixelSize: 11 * s
                                                font.weight: root.clockStyle === modelData ? Font.Bold : Font.Normal
                                                color: root.clockStyle === modelData ? "#ffffff" : root.textPrimary
                                            }

                                            Text {
                                                text: "󰄬"
                                                font.family: root.monoFont
                                                font.pixelSize: 10 * s
                                                color: root.accentColor
                                                visible: root.clockStyle === modelData
                                            }
                                        }

                                        MouseArea {
                                            id: cStyleMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.clockStyle = modelData
                                        }
                                    }
                                }
                            }

                            // 2. 9-Grid Position Picker
                            Row {
                                width: parent.width
                                spacing: 14 * s

                                Column {
                                    spacing: 4 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Screen Position"
                                        font.family: root.sansFont
                                        font.pixelSize: 12 * s
                                        font.weight: Font.DemiBold
                                        color: root.textSecondary
                                    }
                                    Text {
                                        text: root.gridPositionNames[root.clockGridPos]
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Bold
                                        color: root.accentColor
                                    }
                                }

                                Grid {
                                    columns: 3
                                    spacing: 3 * s
                                    anchors.verticalCenter: parent.verticalCenter

                                    Repeater {
                                        model: 9
                                        delegate: Rectangle {
                                            width: 28 * s
                                            height: 18 * s
                                            radius: 4 * s
                                            color: root.clockGridPos === index ? root.accentColor : (cgMa.containsMouse ? Qt.alpha(root.accentColor, 0.3) : Qt.rgba(1, 1, 1, 0.08))
                                            border.color: root.clockGridPos === index ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                                            border.width: 1 * s

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: index === 0 ? "TL" : index === 1 ? "TC" : index === 2 ? "TR" : index === 3 ? "ML" : index === 4 ? "MC" : index === 5 ? "MR" : index === 6 ? "BL" : index === 7 ? "BC" : "BR"
                                                font.family: root.monoFont
                                                font.pixelSize: 7 * s
                                                font.weight: Font.Bold
                                                color: root.clockGridPos === index ? "#ffffff" : root.textSecondary
                                            }

                                            MouseArea {
                                                id: cgMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.clockGridPos = index
                                            }
                                        }
                                    }
                                }
                            }

                            // 3. Clock Scale Slider
                            Column {
                                width: parent.width
                                spacing: 4 * s

                                Row {
                                    width: parent.width
                                    Text {
                                        text: "Clock Scale"
                                        font.family: root.sansFont
                                        font.pixelSize: 12 * s
                                        font.weight: Font.DemiBold
                                        color: root.textSecondary
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        text: root.clockScale.toFixed(2) + "x"
                                        font.family: root.monoFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Bold
                                        color: root.accentColor
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: 24 * s

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 5 * s
                                        radius: 2.5 * s
                                        color: Qt.rgba(1, 1, 1, 0.15)

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: clockHandle.x + clockHandle.width / 2
                                            radius: 2.5 * s
                                            color: root.accentColor
                                        }
                                    }

                                    Rectangle {
                                        id: clockHandle
                                        width: 16 * s
                                        height: 16 * s
                                        radius: 8 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(parent.width - width, ((root.clockScale - 0.6) / (2.2 - 0.6)) * (parent.width - width)))
                                        color: "#ffffff"
                                        border.color: root.accentColor
                                        border.width: 2 * s
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPositionChanged: (mouse) => {
                                            if (pressed) {
                                                var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                                root.clockScale = 0.6 + ratio * (2.2 - 0.6)
                                            }
                                        }
                                        onPressed: (mouse) => {
                                            var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                            root.clockScale = 0.6 + ratio * (2.2 - 0.6)
                                        }
                                    }
                                }
                            }

                            // 4. Frosted Glass Background Card & Opacity
                            Row {
                                width: parent.width
                                spacing: 10 * s

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Frosted Background Card"
                                        font.family: root.sansFont
                                        font.pixelSize: 12 * s
                                        font.weight: Font.DemiBold
                                        color: root.textPrimary
                                    }
                                    Text {
                                        text: "Deep glass blur behind clock"
                                        font.family: root.sansFont
                                        font.pixelSize: 10 * s
                                        color: root.textMuted
                                    }
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 38 * s
                                    height: 22 * s
                                    radius: 11 * s
                                    color: root.clockCardEnabled ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    Rectangle {
                                        width: 16 * s
                                        height: 16 * s
                                        radius: 8 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.clockCardEnabled ? parent.width - width - 3 * s : 3 * s
                                        color: "#ffffff"
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.clockCardEnabled = !root.clockCardEnabled
                                    }
                                }
                            }

                            // Opacity Slider (when Card enabled)
                            Column {
                                width: parent.width
                                spacing: 4 * s
                                opacity: root.clockCardEnabled ? 1 : 0.4
                                enabled: root.clockCardEnabled

                                Row {
                                    width: parent.width
                                    Text {
                                        text: "Card Opacity"
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        color: root.textSecondary
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        text: Math.round(root.clockCardOpacity * 100) + "%"
                                        font.family: root.monoFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Bold
                                        color: root.accentColor
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: 24 * s

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 5 * s
                                        radius: 2.5 * s
                                        color: Qt.rgba(1, 1, 1, 0.15)

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: clockOpHandle.x + clockOpHandle.width / 2
                                            radius: 2.5 * s
                                            color: root.accentColor
                                        }
                                    }

                                    Rectangle {
                                        id: clockOpHandle
                                        width: 16 * s
                                        height: 16 * s
                                        radius: 8 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(parent.width - width, ((root.clockCardOpacity - 0.15) / (0.85 - 0.15)) * (parent.width - width)))
                                        color: "#ffffff"
                                        border.color: root.accentColor
                                        border.width: 2 * s
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPositionChanged: (mouse) => {
                                            if (pressed) {
                                                var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                                root.clockCardOpacity = 0.15 + ratio * (0.85 - 0.15)
                                            }
                                        }
                                        onPressed: (mouse) => {
                                            var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                            root.clockCardOpacity = 0.15 + ratio * (0.85 - 0.15)
                                        }
                                    }
                                }
                            }

                            // 5. Show on Login Toggle
                            Row {
                                width: parent.width
                                spacing: 10 * s

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Keep Clock Visible on Login"
                                        font.family: root.sansFont
                                        font.pixelSize: 12 * s
                                        font.weight: Font.DemiBold
                                        color: root.textPrimary
                                    }
                                    Text {
                                        text: "Clock remains visible after unlock"
                                        font.family: root.sansFont
                                        font.pixelSize: 10 * s
                                        color: root.textMuted
                                    }
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 38 * s
                                    height: 22 * s
                                    radius: 11 * s
                                    color: root.clockShowOnLogin ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    Rectangle {
                                        width: 16 * s
                                        height: 16 * s
                                        radius: 8 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.clockShowOnLogin ? parent.width - width - 3 * s : 3 * s
                                        color: "#ffffff"
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.clockShowOnLogin = !root.clockShowOnLogin
                                    }
                                }
                            }
                        }

                        // ══════════════════════════════════════════
                        // TAB 1: LOGIN & BOX SETTINGS
                        // ══════════════════════════════════════════
                        Column {
                            width: parent.width
                            spacing: 10 * s
                            visible: morphingSettingsContainer.currentTab === 1

                            // 1. 9-Grid Position Picker
                            Row {
                                width: parent.width
                                spacing: 14 * s

                                Column {
                                    spacing: 4 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Container Position"
                                        font.family: root.sansFont
                                        font.pixelSize: 12 * s
                                        font.weight: Font.DemiBold
                                        color: root.textSecondary
                                    }
                                    Text {
                                        text: root.gridPositionNames[root.loginGridPos]
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Bold
                                        color: root.accentColor
                                    }
                                }

                                Grid {
                                    columns: 3
                                    spacing: 3 * s
                                    anchors.verticalCenter: parent.verticalCenter

                                    Repeater {
                                        model: 9
                                        delegate: Rectangle {
                                            width: 28 * s
                                            height: 18 * s
                                            radius: 4 * s
                                            color: root.loginGridPos === index ? root.accentColor : (lgMa.containsMouse ? Qt.alpha(root.accentColor, 0.3) : Qt.rgba(1, 1, 1, 0.08))
                                            border.color: root.loginGridPos === index ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                                            border.width: 1 * s

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: index === 0 ? "TL" : index === 1 ? "TC" : index === 2 ? "TR" : index === 3 ? "ML" : index === 4 ? "MC" : index === 5 ? "MR" : index === 6 ? "BL" : index === 7 ? "BC" : "BR"
                                                font.family: root.monoFont
                                                font.pixelSize: 7 * s
                                                font.weight: Font.Bold
                                                color: root.loginGridPos === index ? "#ffffff" : root.textSecondary
                                            }

                                            MouseArea {
                                                id: lgMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.loginGridPos = index
                                            }
                                        }
                                    }
                                }
                            }

                            // 2. Container Scale Slider
                            Column {
                                width: parent.width
                                spacing: 4 * s

                                Row {
                                    width: parent.width
                                    Text {
                                        text: "Container Scale"
                                        font.family: root.sansFont
                                        font.pixelSize: 12 * s
                                        font.weight: Font.DemiBold
                                        color: root.textSecondary
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        text: root.loginScale.toFixed(2) + "x"
                                        font.family: root.monoFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Bold
                                        color: root.accentColor
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: 24 * s

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 5 * s
                                        radius: 2.5 * s
                                        color: Qt.rgba(1, 1, 1, 0.15)

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: loginHandle.x + loginHandle.width / 2
                                            radius: 2.5 * s
                                            color: root.accentColor
                                        }
                                    }

                                    Rectangle {
                                        id: loginHandle
                                        width: 16 * s
                                        height: 16 * s
                                        radius: 8 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(parent.width - width, ((root.loginScale - 0.7) / (1.6 - 0.7)) * (parent.width - width)))
                                        color: "#ffffff"
                                        border.color: root.accentColor
                                        border.width: 2 * s
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPositionChanged: (mouse) => {
                                            if (pressed) {
                                                var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                                root.loginScale = 0.7 + ratio * (1.6 - 0.7)
                                            }
                                        }
                                        onPressed: (mouse) => {
                                            var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                            root.loginScale = 0.7 + ratio * (1.6 - 0.7)
                                        }
                                    }
                                }
                            }

                            // 3. Avatar Relative Orientation
                            Column {
                                width: parent.width
                                spacing: 4 * s

                                Text {
                                    text: "Avatar Orientation"
                                    font.family: root.sansFont
                                    font.pixelSize: 12 * s
                                    font.weight: Font.DemiBold
                                    color: root.textSecondary
                                }

                                Row {
                                    spacing: 4 * s
                                    width: parent.width

                                    Repeater {
                                        model: ["Right", "Left", "Top Center", "Top Left", "Top Right"]
                                        delegate: Rectangle {
                                            width: (tabContentCol.width - (4 * 4 * s)) / 5
                                            height: 28 * s
                                            radius: 6 * s
                                            color: root.avatarOrientation === modelData ? Qt.alpha(root.accentColor, 0.35) : (aoMa.containsMouse ? Qt.alpha(root.accentColor, 0.15) : Qt.rgba(1, 1, 1, 0.06))
                                            border.color: root.avatarOrientation === modelData ? root.accentColor : Qt.rgba(1, 1, 1, 0.10)
                                            border.width: 1 * s

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData === "Top Center" ? "Top Ctr" : modelData
                                                font.family: root.sansFont
                                                font.pixelSize: 9 * s
                                                font.weight: root.avatarOrientation === modelData ? Font.Bold : Font.Normal
                                                color: root.avatarOrientation === modelData ? "#ffffff" : root.textSecondary
                                            }

                                            MouseArea {
                                                id: aoMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.avatarOrientation = modelData
                                            }
                                        }
                                    }
                                }
                            }

                            // 4. Password Box Style
                            Column {
                                width: parent.width
                                spacing: 4 * s

                                Text {
                                    text: "Password Box Style"
                                    font.family: root.sansFont
                                    font.pixelSize: 12 * s
                                    font.weight: Font.DemiBold
                                    color: root.textSecondary
                                }

                                Grid {
                                    columns: 2
                                    spacing: 6 * s
                                    width: parent.width

                                    Repeater {
                                        model: ["Glass Pill", "Minimal Underline", "Split Badge", "Sharp M3 Card"]
                                        delegate: Rectangle {
                                            width: (tabContentCol.width - 6 * s) / 2
                                            height: 32 * s
                                            radius: 8 * s
                                            color: root.boxStyle === modelData ? Qt.alpha(root.accentColor, 0.35) : (bStyleMa.containsMouse ? Qt.alpha(root.accentColor, 0.15) : Qt.rgba(1, 1, 1, 0.06))
                                            border.color: root.boxStyle === modelData ? root.accentColor : Qt.rgba(1, 1, 1, 0.10)
                                            border.width: 1 * s

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6 * s

                                                Text {
                                                    text: modelData
                                                    font.family: root.sansFont
                                                    font.pixelSize: 11 * s
                                                    font.weight: root.boxStyle === modelData ? Font.Bold : Font.Normal
                                                    color: root.boxStyle === modelData ? "#ffffff" : root.textPrimary
                                                }

                                                Text {
                                                    text: "󰄬"
                                                    font.family: root.monoFont
                                                    font.pixelSize: 10 * s
                                                    color: root.accentColor
                                                    visible: root.boxStyle === modelData
                                                }
                                            }

                                            MouseArea {
                                                id: bStyleMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.boxStyle = modelData
                                            }
                                        }
                                    }
                                }
                            }

                            // 5. Frosted Glass Background Card
                            Row {
                                width: parent.width
                                spacing: 10 * s

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Frosted Background Card"
                                        font.family: root.sansFont
                                        font.pixelSize: 12 * s
                                        font.weight: Font.DemiBold
                                        color: root.textPrimary
                                    }
                                    Text {
                                        text: "Deep glass card behind login controls"
                                        font.family: root.sansFont
                                        font.pixelSize: 10 * s
                                        color: root.textMuted
                                    }
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 38 * s
                                    height: 22 * s
                                    radius: 11 * s
                                    color: root.loginCardEnabled ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    Rectangle {
                                        width: 16 * s
                                        height: 16 * s
                                        radius: 8 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.loginCardEnabled ? parent.width - width - 3 * s : 3 * s
                                        color: "#ffffff"
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.loginCardEnabled = !root.loginCardEnabled
                                    }
                                }
                            }
                        }

                        // ══════════════════════════════════════════
                        // TAB 2: AVATAR & M3 SHAPES
                        // ══════════════════════════════════════════
                        Column {
                            width: parent.width
                            spacing: 12 * s
                            visible: morphingSettingsContainer.currentTab === 2

                            Text {
                                text: "Select Material 3 Shape"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.weight: Font.DemiBold
                                color: root.textSecondary
                            }

                            // 11 Shapes Grid (with Triangle!)
                            Grid {
                                columns: 3
                                spacing: 6 * s
                                width: parent.width

                                Repeater {
                                    model: [
                                        { name: "Triangle",        shape: MaterialShape.Triangle },
                                        { name: "Cookie 9-Sided", shape: MaterialShape.Cookie9Sided },
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
                                        width: (tabContentCol.width - 12 * s) / 3
                                        height: 30 * s
                                        radius: 6 * s
                                        color: root.avatarShape === modelData.name ? Qt.alpha(root.accentColor, 0.35) : (shGridMa.containsMouse ? Qt.alpha(root.accentColor, 0.15) : Qt.rgba(1, 1, 1, 0.06))
                                        border.color: root.avatarShape === modelData.name ? root.accentColor : Qt.rgba(1, 1, 1, 0.10)
                                        border.width: 1 * s

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            font.family: root.sansFont
                                            font.pixelSize: 10 * s
                                            font.weight: root.avatarShape === modelData.name ? Font.Bold : Font.Normal
                                            color: root.avatarShape === modelData.name ? "#ffffff" : root.textPrimary
                                        }

                                        MouseArea {
                                            id: shGridMa
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

                            // Live Shape Preview
                            Rectangle {
                                width: parent.width
                                height: 110 * s
                                radius: 14 * s
                                color: Qt.alpha(root.glassBg, 0.50)
                                border.color: root.glassBorder
                                border.width: 1 * s

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 20 * s

                                    // Big M3 Shape Preview
                                    Item {
                                        width: 72 * s
                                        height: 72 * s
                                        anchors.verticalCenter: parent.verticalCenter

                                        MaterialShape {
                                            anchors.fill: parent
                                            shape: root.currentM3Shape
                                            animationDuration: 350
                                            color: root.accentColor
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }

                                        Item {
                                            anchors.fill: parent
                                            anchors.margins: 4 * s

                                            Image {
                                                id: avatarPreviewImg
                                                anchors.fill: parent
                                                source: root.activeUser.icon !== "" ? root.activeUser.icon : "file:///home/" + root.activeUser.name + "/.face"
                                                cache: false
                                                fillMode: Image.PreserveAspectCrop
                                                smooth: true
                                                mipmap: true
                                                visible: false
                                            }

                                            MaterialShape {
                                                id: previewMask
                                                anchors.fill: parent
                                                shape: root.currentM3Shape
                                                animationDuration: 350
                                                color: "#ffffff"
                                                visible: false
                                            }

                                            OpacityMask {
                                                anchors.fill: parent
                                                source: avatarPreviewImg
                                                maskSource: previewMask
                                                visible: avatarPreviewImg.status === Image.Ready
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: ""
                                                font.family: root.monoFont
                                                font.pixelSize: 28 * s
                                                color: "#ffffff"
                                                visible: avatarPreviewImg.status !== Image.Ready
                                            }
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4 * s

                                        Text {
                                            text: root.avatarShape
                                            font.family: root.sansFont
                                            font.pixelSize: 15 * s
                                            font.weight: Font.Bold
                                            color: "#ffffff"
                                        }

                                        Text {
                                            text: "Kinetic morphing M3 geometry"
                                            font.family: root.sansFont
                                            font.pixelSize: 11 * s
                                            color: root.textSecondary
                                        }

                                        Text {
                                            text: "Used for avatar frame & typed dots"
                                            font.family: root.sansFont
                                            font.pixelSize: 10 * s
                                            color: root.accentColor
                                        }
                                    }
                                }
                            }
                        }

                        // ══════════════════════════════════════════
                        // TAB 3: PALETTE & DISPLAY
                        // ══════════════════════════════════════════
                        Column {
                            width: parent.width
                            spacing: 12 * s
                            visible: morphingSettingsContainer.currentTab === 3

                            Text {
                                text: "Theme Accent & Color Palette"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.weight: Font.DemiBold
                                color: root.textSecondary
                            }

                            Grid {
                                columns: 2
                                spacing: 6 * s
                                width: parent.width

                                Repeater {
                                    model: [
                                        { name: "Nothing Red",       color: "#ff3b30" },
                                        { name: "Catppuccin Mocha", color: "#cba6f7" },
                                        { name: "Nord",             color: "#88c0d0" },
                                        { name: "Tokyo Night",      color: "#7aa2f7" },
                                        { name: "Rose Pine",        color: "#ebbcba" },
                                        { name: "Dracula",          color: "#bd93f9" }
                                    ]
                                    delegate: Rectangle {
                                        width: (tabContentCol.width - 6 * s) / 2
                                        height: 36 * s
                                        radius: 8 * s
                                        color: root.colorScheme === modelData.name ? Qt.alpha(modelData.color, 0.35) : (palGridMa.containsMouse ? Qt.alpha(modelData.color, 0.15) : Qt.rgba(1, 1, 1, 0.06))
                                        border.color: root.colorScheme === modelData.name ? modelData.color : Qt.rgba(1, 1, 1, 0.10)
                                        border.width: 1 * s

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Row {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8 * s

                                            Rectangle {
                                                width: 12 * s
                                                height: 12 * s
                                                radius: 6 * s
                                                color: modelData.color
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: modelData.name
                                                font.family: root.sansFont
                                                font.pixelSize: 11 * s
                                                font.weight: root.colorScheme === modelData.name ? Font.Bold : Font.Normal
                                                color: root.colorScheme === modelData.name ? "#ffffff" : root.textPrimary
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10 * s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰄬"
                                            font.family: root.monoFont
                                            font.pixelSize: 11 * s
                                            color: modelData.color
                                            visible: root.colorScheme === modelData.name
                                        }

                                        MouseArea {
                                            id: palGridMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.colorScheme = modelData.name
                                        }
                                    }
                                }
                            }

                            // 12-Hour Clock
                            Row {
                                width: parent.width
                                spacing: 10 * s

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "12-Hour Clock Format"
                                        font.family: root.sansFont
                                        font.pixelSize: 12 * s
                                        font.weight: Font.DemiBold
                                        color: root.textPrimary
                                    }
                                    Text {
                                        text: "Display time with AM/PM indicators"
                                        font.family: root.sansFont
                                        font.pixelSize: 10 * s
                                        color: root.textMuted
                                    }
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 38 * s
                                    height: 22 * s
                                    radius: 11 * s
                                    color: root.is12Hour ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    Rectangle {
                                        width: 16 * s
                                        height: 16 * s
                                        radius: 8 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.is12Hour ? parent.width - width - 3 * s : 3 * s
                                        color: "#ffffff"
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.is12Hour = !root.is12Hour
                                    }
                                }
                            }

                            // Lava Lamp Blobs
                            Row {
                                width: parent.width
                                spacing: 10 * s

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Ambient Lava Blobs"
                                        font.family: root.sansFont
                                        font.pixelSize: 12 * s
                                        font.weight: Font.DemiBold
                                        color: root.textPrimary
                                    }
                                    Text {
                                        text: "Smooth ambient blobs on idle screen"
                                        font.family: root.sansFont
                                        font.pixelSize: 10 * s
                                        color: root.textMuted
                                    }
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 38 * s
                                    height: 22 * s
                                    radius: 11 * s
                                    color: root.showLavaBlobs ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    Rectangle {
                                        width: 16 * s
                                        height: 16 * s
                                        radius: 8 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.showLavaBlobs ? parent.width - width - 3 * s : 3 * s
                                        color: "#ffffff"
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.showLavaBlobs = !root.showLavaBlobs
                                    }
                                }
                            }
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
