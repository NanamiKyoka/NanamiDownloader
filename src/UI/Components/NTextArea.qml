// NTextArea.qml - Ant Design 风格多行文本框组件
import QtQuick
import QtQuick.Controls
import Nanami.UI 1.0

TextArea {
    id: root

    // 属性定义
    property string size: "middle"      // small, middle, large
    property string status: "normal"    // normal, error, warning
    property bool autoSize: false
    property int minRows: 2
    property int maxRows: 6

    // 尺寸映射
    readonly property var sizeMap: ({
            "small": {
                fontSize: Theme.fontSM,
                lineHeight: 20
            },
            "middle": {
                fontSize: Theme.fontMD,
                lineHeight: 22
            },
            "large": {
                fontSize: Theme.fontLG,
                lineHeight: 24
            }
        })

    font.pixelSize: sizeMap[size] ? sizeMap[size].fontSize : 14
    color: Theme.textPrimary
    placeholderTextColor: Theme.textHint
    selectionColor: Theme.primary
    selectedTextColor: "#ffffff"
    wrapMode: TextEdit.Wrap
    selectByMouse: true

    leftPadding: Theme.spacingMD
    rightPadding: Theme.spacingMD
    topPadding: Theme.spacingSM + Theme.spacingXS
    bottomPadding: Theme.spacingSM + Theme.spacingXS

    // 自动高度
    implicitHeight: {
        if (autoSize) {
            var lineCount = Math.max(minRows, Math.min(maxRows, root.lineCount));
            return lineCount * (sizeMap[size] ? sizeMap[size].lineHeight : 22) + topPadding + bottomPadding;
        }
        return 80; // 默认高度
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
                duration: Theme.durationFast || 150
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Theme.durationFast || 150
            }
        }
    }

    // 禁用状态
    opacity: enabled ? 1.0 : 0.6
}
