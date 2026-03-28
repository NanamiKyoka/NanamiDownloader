// NComboBox.qml - Ant Design 风格下拉框组件
import QtQuick
import QtQuick.Controls
import Nanami.UI 1.0

ComboBox {
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
    font.pixelSize: sizeMap[size] ? sizeMap[size].fontSize : 14

    delegate: ItemDelegate {
        width: root.width
        height: sizeMap[size] ? sizeMap[size].height : 32

        contentItem: Text {
            text: modelData
            font: root.font
            color: highlighted ? "#ffffff" : Theme.textPrimary
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: highlighted ? Theme.primary : (Theme.isDark ? "#2b2b2b" : "#ffffff")
            radius: Theme.borderRadiusSmall

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                }
            }
        }

        highlighted: root.highlightedIndex === index
    }

    indicator: Canvas {
        x: root.width - width - Theme.spacingMD
        y: (root.height - height) / 2
        width: (sizeMap[size] ? sizeMap[size].iconSize : 14) * 0.6
        height: width * 0.6
        contextType: "2d"

        property color arrowColor: Theme.textSecondary

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = arrowColor;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            ctx.beginPath();
            ctx.moveTo(0, height * 0.3);
            ctx.lineTo(width / 2, height * 0.7);
            ctx.lineTo(width, height * 0.3);
            ctx.stroke();
        }
    }

    contentItem: Text {
        leftPadding: Theme.spacingMD
        rightPadding: root.indicator.width + root.spacing * 2
        text: root.displayText
        font: root.font
        color: Theme.textPrimary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        color: root.popup.visible ? Theme.surface : Theme.surfaceVariant
        border.color: {
            if (root.status === "error")
                return Theme.error;
            if (root.status === "warning")
                return Theme.warning;
            return root.popup.visible || root.activeFocus ? Theme.primary : Theme.border;
        }
        border.width: (root.popup.visible || root.activeFocus) ? 2 : 1
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

    popup: Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: contentItem.implicitHeight + Theme.spacingSM * 2
        padding: Theme.spacingXS

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: Theme.isDark ? "#2b2b2b" : "#ffffff"
            border.color: Theme.border
            radius: Theme.borderRadiusMedium
        }
    }

    // 禁用状态
    opacity: enabled ? 1.0 : 0.6
}
