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
        MaterialShape.ClamShell,
        MaterialShape.Sunny,
        MaterialShape.Cookie4Sided,
        MaterialShape.Heart,
        MaterialShape.Diamond,
        MaterialShape.VerySunny,
        MaterialShape.Cookie7Sided
    ]

    function getBoxRadius(h) {
        if (boxShape === "Pill") return h / 2
        if (boxShape === "Rounded") return 14 * s
        if (boxShape === "Sharp") return 4 * s
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
        lockClock.text = getFormattedTime()
        ampmLabel.text = getFormattedAmPm()
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
    Item {
        id: lockscreenView
        anchors.fill: parent
        opacity: (!root.isUnlocked) ? root.uiOpacity : 0
        visible: opacity > 0
        z: 5

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Column {
            anchors.right: parent.right
            anchors.rightMargin: 120 * s
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.isUnlocked ? -40 * s : 0
            spacing: 12 * s
            transformOrigin: Item.Right

            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

            Row {
                anchors.right: parent.right
                spacing: 14 * s

                Text {
                    id: lockClock
                    text: root.getFormattedTime()
                    color: root.textPrimary
                    font.family: root.monoFont
                    font.pixelSize: 112 * s
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                    layer.enabled: true
                    layer.effect: DropShadow { color: "#aa000000"; radius: 24; samples: 20 }
                }

                Text {
                    id: ampmLabel
                    text: root.getFormattedAmPm()
                    color: root.accentColor
                    font.family: root.sansFont
                    font.pixelSize: 22 * s
                    font.weight: Font.Bold
                    visible: root.is12Hour
                    anchors.bottom: lockClock.bottom
                    anchors.bottomMargin: 24 * s
                    Behavior on color { ColorAnimation { duration: 250 } }
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: root.updateClock()
                }
            }

            Row {
                anchors.right: parent.right
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
                    text: Qt.formatDate(new Date(), "dddd, MMMM d, yyyy").toUpperCase()
                    color: root.textSecondary
                    font.family: root.sansFont
                    font.pixelSize: 14 * s
                    font.letterSpacing: 2 * s
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                    layer.enabled: true
                    layer.effect: DropShadow { color: "#80000000"; radius: 10; samples: 10 }
                }
            }
        }

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
    Item {
        id: loginPanelContainer
        anchors.right: parent.right
        anchors.rightMargin: 110 * s
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.isKeyboardOpen ? -140 * s : 0
        width: 440 * s
        height: 220 * s
        opacity: root.isUnlocked ? root.uiOpacity : 0
        visible: opacity > 0
        z: 10

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

        Item {
            anchors.fill: parent

            // Username display with Accent Dot
            Row {
                anchors.right: avatarFrame.left
                anchors.rightMargin: 20 * s
                anchors.bottom: passwordBoxRect.top
                anchors.bottomMargin: 10 * s
                spacing: 8 * s

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

            // ─── Themed Glass Password Box (Guaranteed Zero Overlap with Lock Icon!) ───
            Rectangle {
                id: passwordBoxRect
                anchors.right: avatarFrame.left
                anchors.rightMargin: 20 * s
                anchors.verticalCenter: avatarFrame.verticalCenter
                width: 275 * s
                height: 52 * s
                radius: root.getBoxRadius(height)
                color: passwordInput.activeFocus ? Qt.alpha(root.accentColor, 0.28) : root.glassBg
                border.color: passwordInput.activeFocus ? root.accentColor : root.glassBorder
                border.width: 1.5 * s

                property real pressBloom: 0.0

                layer.enabled: true
                layer.effect: DropShadow {
                    color: passwordInput.activeFocus ? root.highlightGlow : "#50000000"
                    radius: passwordInput.activeFocus ? 18 : 10
                    samples: 16
                }

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

                // Inner Pill-Conforming Glow (Always 100% matched to pill radius, zero rectangular clipping!)
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.alpha(root.accentColor, 0.35)
                    opacity: passwordBoxRect.pressBloom
                    visible: opacity > 0
                }

                // Lock Icon with Fixed Safe Bounds
                Item {
                    id: lockIconContainer
                    width: 28 * s
                    height: parent.height
                    anchors.left: parent.left
                    anchors.leftMargin: 12 * s

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
                        color: "transparent"
                        echoMode: TextInput.NoEcho
                        font.family: root.monoFont
                        font.pixelSize: 14 * s
                        focus: root.isUnlocked
                        clip: true
                        cursorVisible: false
                        cursorDelegate: Item { width: 0; height: 0 }

                        onTextEdited: errorText.text = ""
                        Keys.onReturnPressed: doLogin()
                        Keys.onEnterPressed: doLogin()
                        Keys.onEscapePressed: function(event) {
                            handleEscape()
                            event.accepted = true
                        }

                        // Elegant M3 Shape Password Dots (Permanent Fixed Pool - Zero Refresh / Zero Flash!)
                        Row {
                            anchors.centerIn: parent
                            spacing: 6 * s
                            visible: passwordInput.text.length > 0
                            opacity: passwordInput.text.length > 0 ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Repeater {
                                id: dotsRepeater
                                model: 24 // Fixed pool of 24 characters: NEVER re-created, NEVER flashes!
                                delegate: Item {
                                    id: dotItem
                                    readonly property bool isShown: index < passwordInput.text.length
                                    visible: isShown || scale > 0.05
                                    width: isShown ? 12 * s : 0
                                    height: 12 * s
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on width {
                                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                    }

                                    // Each character typed has a permanent distinct M3 shape
                                    MaterialShape {
                                        anchors.fill: parent
                                        shape: root.passwordM3Shapes[index % root.passwordM3Shapes.length]
                                        color: "#ffffff"
                                        animationDuration: 0
                                    }

                                    scale: isShown ? 1.0 : 0.0
                                    rotation: isShown ? 0 : -25
                                    opacity: isShown ? 1.0 : 0.0

                                    Behavior on scale {
                                        NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
                                    }
                                    Behavior on rotation {
                                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation { duration: 100 }
                                    }
                                }
                            }
                        }

                        // Clean Centered Placeholder Text (Zero Overlap! No animation on top!)
                        Text {
                            anchors.centerIn: parent
                            text: "Enter your password"
                            color: root.textMuted
                            font.family: root.sansFont
                            font.pixelSize: 13 * s
                            font.letterSpacing: 0.5 * s
                            opacity: passwordInput.text.length === 0 ? 1 : 0
                            visible: opacity > 0

                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: boxPressMa
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onPressed: function(mouse) {
                                bloomAnim.restart()
                                passwordInput.forceActiveFocus()
                            }
                        }
                    }
                }

                // Logging In State
                Row {
                    anchors.centerIn: parent
                    spacing: 8 * s
                    visible: root.isLoggingIn

                    Text {
                        text: "Authenticating..."
                        color: root.textPrimary
                        font.family: root.sansFont
                        font.pixelSize: 13 * s
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: loginSpinner
                        text: "󰑮"
                        font.family: root.monoFont
                        font.pixelSize: 16 * s
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter

                        NumberAnimation {
                            target: loginSpinner
                            property: "rotation"
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                            running: root.isLoggingIn
                        }
                    }
                }

                // Themed Submit Arrow Button
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
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 82 * s
                height: 82 * s
                scale: avatarMa.containsMouse ? 1.05 : 1.0
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
                anchors.right: passwordBoxRect.right
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
                anchors.right: passwordBoxRect.right
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

    // ──────────────────────────────────────────
    // User Switcher Flyout Modal (When clicking Avatar!)
    // ──────────────────────────────────────────
    Rectangle {
        id: userSwitcherModal
        anchors.right: loginPanelContainer.right
        anchors.bottom: loginPanelContainer.top
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
        Rectangle {
            id: morphingSettingsContainer
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: root.settingsOpen ? 350 * s : 38 * s
            height: root.settingsOpen ? (296 * s + (root.shapeMenuOpen ? 130 * s : (root.paletteMenuOpen ? 110 * s : (root.boxMenuOpen ? 80 * s : 0)))) : 38 * s
            radius: root.settingsOpen ? 20 * s : 12 * s
            color: root.settingsOpen ? root.glassBg : (settingsBtnMa.containsMouse ? Qt.alpha(root.accentColor, 0.28) : root.glassBg)
            border.color: root.settingsOpen ? root.glassBorder : (settingsBtnMa.containsMouse ? root.accentColor : root.glassBorder)
            border.width: 1 * s
            clip: true
            z: 50

            layer.enabled: true
            layer.effect: DropShadow { color: "#50000000"; radius: 20; samples: 16 }

            Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on border.color { ColorAnimation { duration: 250 } }

            // Collapsed View: Gear Icon
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

            // Expanded View: Tailored M3 Settings
            Column {
                id: settingsCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14 * s
                spacing: 2 * s
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
                                root.shapeMenuOpen = false
                                root.paletteMenuOpen = false
                                root.boxMenuOpen = false
                            }
                        }
                    }
                }

                // ── Row 1: Avatar Shape (Scrollable Dropdown Drawer) ──
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
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

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
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

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
                                root.paletteMenuOpen = false
                                root.boxMenuOpen = false
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
                        height: root.shapeMenuOpen ? 130 * s : 0
                        visible: root.shapeMenuOpen

                        ListView {
                            anchors.fill: parent
                            clip: true
                            model: [
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
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Row 2: 12-Hour Clock ──
                Rectangle {
                    width: parent.width
                    height: 48 * s
                    radius: 4 * s
                    color: clockRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
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
                            id: thumb12h
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
                        id: clockRowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.is12Hour = !root.is12Hour
                        }
                    }
                }

                // ── Row 3: Color Palette (Click to live-morph every glass background!) ──
                Rectangle {
                    width: parent.width
                    height: root.paletteMenuOpen ? (48 * s + palDrawer.height) : 48 * s
                    radius: 4 * s
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
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

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
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

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
                                root.shapeMenuOpen = false
                                root.boxMenuOpen = false
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
                        height: root.paletteMenuOpen ? 110 * s : 0
                        visible: root.paletteMenuOpen

                        ListView {
                            anchors.fill: parent
                            clip: true
                            model: ["Nothing Red", "Catppuccin Mocha", "Nord", "Tokyo Night", "Rose Pine", "Dracula"]
                            spacing: 2 * s

                            delegate: Rectangle {
                                width: ListView.view ? ListView.view.width : 0
                                height: 26 * s
                                radius: 6 * s
                                color: palDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.colorScheme === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    font.family: root.sansFont
                                    font.pixelSize: 11 * s
                                    color: root.colorScheme === modelData ? "#ffffff" : root.textSecondary
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰄬"
                                    font.family: root.monoFont
                                    font.pixelSize: 12 * s
                                    color: root.accentColor
                                    visible: root.colorScheme === modelData
                                }

                                MouseArea {
                                    id: palDelMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.colorScheme = modelData
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Row 4: Input Box Shape ──
                Rectangle {
                    id: rowBox
                    width: parent.width
                    height: root.boxMenuOpen ? (48 * s + boxDrawer.height) : 48 * s
                    radius: 4 * s
                    clip: true
                    color: boxRowMa.containsMouse || root.boxMenuOpen ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                    Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Item {
                        id: boxHeaderBar
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48 * s

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.right: boxSplitBtn.left
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
                            id: boxSplitBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Rectangle {
                                height: 28 * s
                                width: boxBtnLabel.implicitWidth + 18 * s
                                topLeftRadius: 14 * s
                                bottomLeftRadius: 14 * s
                                topRightRadius: 4 * s
                                bottomRightRadius: 4 * s
                                color: Qt.alpha(root.accentColor, 0.35)
                                border.color: Qt.alpha(root.accentColor, 0.55)
                                border.width: 1 * s
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                Text {
                                    id: boxBtnLabel
                                    anchors.centerIn: parent
                                    text: root.boxShape
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
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

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
                            id: boxRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.boxMenuOpen = !root.boxMenuOpen
                                root.shapeMenuOpen = false
                                root.paletteMenuOpen = false
                            }
                        }
                    }

                    Item {
                        id: boxDrawer
                        anchors.top: boxHeaderBar.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8 * s
                        anchors.rightMargin: 8 * s
                        height: root.boxMenuOpen ? 80 * s : 0
                        visible: root.boxMenuOpen

                        ListView {
                            anchors.fill: parent
                            clip: true
                            model: ["Rounded", "Pill", "Sharp"]
                            spacing: 2 * s

                            delegate: Rectangle {
                                width: ListView.view ? ListView.view.width : 0
                                height: 26 * s
                                radius: 6 * s
                                color: boxDelMa.containsMouse ? Qt.alpha(root.accentColor, 0.30) : (root.boxShape === modelData ? Qt.alpha(root.accentColor, 0.18) : "transparent")

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    font.family: root.sansFont
                                    font.pixelSize: 11 * s
                                    color: root.boxShape === modelData ? "#ffffff" : root.textSecondary
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰄬"
                                    font.family: root.monoFont
                                    font.pixelSize: 12 * s
                                    color: root.accentColor
                                    visible: root.boxShape === modelData
                                }

                                MouseArea {
                                    id: boxDelMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.boxShape = modelData
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Row 5: Lava Lamp Animation ──
                Rectangle {
                    width: parent.width
                    height: 48 * s
                    topLeftRadius: 4 * s
                    topRightRadius: 4 * s
                    bottomLeftRadius: 14 * s
                    bottomRightRadius: 14 * s
                    color: blobRowMa.containsMouse ? Qt.alpha(root.accentColor, 0.20) : Qt.alpha(root.accentColor, 0.08)
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14 * s
                        anchors.right: switchBlobs.left
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
                        id: switchBlobs
                        anchors.right: parent.right
                        anchors.rightMargin: 14 * s
                        anchors.verticalCenter: parent.verticalCenter
                        width: 42 * s
                        height: 24 * s
                        radius: 12 * s
                        color: root.showLavaBlobs ? root.accentColor : Qt.rgba(1, 1, 1, 0.15)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            id: thumbBlobs
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
                        id: blobRowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showLavaBlobs = !root.showLavaBlobs
                    }
                }
            }
        }

        // ─── Session Flyout Picker (Opens above Session Pill!) ───
        Rectangle {
            id: sessionMenuModal
            anchors.left: sessionPill.left
            anchors.bottom: sessionPill.top
            anchors.bottomMargin: 10 * s
            width: 230 * s
            height: root.sessionMenuOpen ? (46 * s + root.mockSessionList.length * 40 * s) : 0
            radius: 16 * s
            color: root.glassBg
            border.color: root.glassBorder
            border.width: 1 * s
            clip: true
            visible: root.sessionMenuOpen
            opacity: root.sessionMenuOpen ? 1 : 0
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

        // Left: Session Pill (Click to open Session Menu!)
        Rectangle {
            id: sessionPill
            anchors.left: morphingSettingsContainer.right
            anchors.leftMargin: 10 * s
            anchors.bottom: parent.bottom
            height: 38 * s
            width: sessionRow.implicitWidth + 24 * s
            radius: 12 * s
            color: sessArea.containsMouse ? Qt.alpha(root.accentColor, 0.28) : root.glassBg
            border.color: sessArea.containsMouse ? root.accentColor : root.glassBorder
            border.width: 1 * s
            opacity: root.settingsOpen ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on border.color { ColorAnimation { duration: 250 } }

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
                    root.sessionMenuOpen = !root.sessionMenuOpen
                    root.userListOpen = false
                    root.settingsOpen = false
                    root.powerMenuOpen = false
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
