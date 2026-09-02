import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: glassBackdrop
    anchors.fill: parent
    z: -1

    property real radius: parent.radius !== undefined ? parent.radius : 16 * root.s
    property color tintColor: root.glassBg
    property color borderColor: root.glassBorder
    property real borderWidth: 1.2 * root.s

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: glassBackdrop.width
            height: glassBackdrop.height
            radius: glassBackdrop.radius
        }
    }

    ShaderEffectSource {
        sourceItem: fullGlassBlur
        live: true
        recursive: false
        width: root.width
        height: root.height
        x: -glassBackdrop.mapToItem(root, 0, 0).x
        y: -glassBackdrop.mapToItem(root, 0, 0).y
    }

    Rectangle {
        anchors.fill: parent
        radius: glassBackdrop.radius
        color: glassBackdrop.tintColor
        border.color: glassBackdrop.borderColor
        border.width: glassBackdrop.borderWidth
    }
}
