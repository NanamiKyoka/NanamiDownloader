// NSpinBox.qml - Ant Design 风格数字输入框组件
import QtQuick
import QtQuick.Controls
import Nanami.UI 1.0

SpinBox {
    id: root

    // 属性定义
    property string size: "middle"      // small, middle, large
    property string status: "normal"    // normal, error, warning

    // 尺寸映射
    readonly property var sizeMap: ({
            "small": {
                height: Theme.inputHeightSM,
                fontSize: Theme.fontSM,
                iconSize: Theme.iconSizeSM
            },
            "middle": {
                height: Theme.inputHeight,
                fontSize: Theme.fontMD,
                iconSize: Theme.iconSize
            },
            "large": {
                height: Theme.inputHeightLG,
                fontSize: Theme.fontLG,
                iconSize: Theme.iconSizeLG
            }
        })

    implicitHeight: sizeMap[size] ? sizeMap[size].height : 32
    implicitWidth: 100
    font.pixelSize: sizeMap[size] ? sizeMap[size].fontSize : 14
    editable: true

    contentItem: TextInput {
        z: 2
        text: root.textFromValue(root.value, root.locale)
        font: root.font
        color: Theme.textPrimary
        selectionColor: Theme.primary
        selectedTextColor: "#ffffff"
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }

    background: Rectangle {
        color: root.activeFocus ? Theme.surface : Theme.surfaceVariant
        border.color: {
            if (root.status === "error")
                return Theme.error;
            if (root.status === "warning")
                return Theme.warning;
            return root.activeFocus ? Theme.primary : Theme.border;
        }
        border.width: root.activeFocus ? 2 : 1
        radius: Theme.borderRadiusMedium

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationFast
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Theme.durationFast
            }
        }
    }

    up.indicator: Rectangle {
        x: parent.width - width - 2
        y: 2
        width: (sizeMap[size] ? sizeMap[size].height : 32) - 4
        height: parent.height / 2 - 2
        color: root.up.pressed ? Theme.hover : "transparent"
        radius: Theme.borderRadiusSmall

        Text {
            text: "▲"
            font.pixelSize: (sizeMap[size] ? sizeMap[size].iconSize : 14) * 0.5
            color: root.up.hovered ? Theme.primary : Theme.textSecondary
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: root.increase()
        }
    }

    down.indicator: Rectangle {
        x: parent.width - width - 2
        y: parent.height / 2
        width: (sizeMap[size] ? sizeMap[size].height : 32) - 4
        height: parent.height / 2 - 2
        color: root.down.pressed ? Theme.hover : "transparent"
        radius: Theme.borderRadiusSmall

        Text {
            text: "▼"
            font.pixelSize: (sizeMap[size] ? sizeMap[size].iconSize : 14) * 0.5
            color: root.down.hovered ? Theme.primary : Theme.textSecondary
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: root.decrease()
        }
    }

    // 禁用状态
    opacity: enabled ? 1.0 : 0.6
}
