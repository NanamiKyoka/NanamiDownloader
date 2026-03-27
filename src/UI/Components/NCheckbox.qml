// NCheckbox.qml - Ant Design 风格复选框组件
import QtQuick
import QtQuick.Controls

CheckBox {
    id: root

    // 属性定义
    property string size: "default"  // small, default
    property bool indeterminate: false

    // 尺寸映射
    readonly property var sizeMap: ({
            "small": {
                boxSize: 14,
                fontSize: 12,
                spacing: 4
            },
            "default": {
                boxSize: 16,
                fontSize: 13,
                spacing: 8
            }
        })

    spacing: sizeMap[size].spacing

    // 指示器
    indicator: Rectangle {
        implicitWidth: sizeMap[size].boxSize
        implicitHeight: sizeMap[size].boxSize
        x: root.leftPadding
        y: parent.height / 2 - height / 2
        radius: 2
        border.color: {
            if (!root.enabled)
                return Theme.border;
            if (root.checked || (root.indeterminate || false))
                return Theme.primary;
            if (root.hovered)
                return Theme.primary;
            return Theme.border;
        }
        border.width: 1
        color: {
            if (!root.enabled)
                return Theme.disabled;
            if (root.checked || (root.indeterminate || false))
                return Theme.primary;
            return "transparent";
        }

        // 勾选标记
        Text {
            anchors.centerIn: parent
            text: "✓"
            visible: root.checked && !root.indeterminate
            color: "white"
            font.pixelSize: sizeMap[size].boxSize * 0.75
            font.bold: true
        }

        // 半选标记
        Rectangle {
            anchors.centerIn: parent
            visible: root.indeterminate || false
            width: parent.width * 0.5
            height: 2
            color: "white"
        }
    }

    // 内容项
    contentItem: Text {
        text: root.text
        font.pixelSize: sizeMap[size].fontSize
        color: root.enabled ? Theme.textPrimary : Theme.textDisabled
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.indicator.width + root.spacing
    }
}
