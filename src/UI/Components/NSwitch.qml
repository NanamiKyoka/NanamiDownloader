// NSwitch.qml - Ant Design 风格开关组件
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Switch {
    id: root

    // 属性定义
    property string size: "default"  // small, default

    // 尺寸映射
    readonly property var sizeMap: ({
            "small": {
                width: 28,
                height: 16,
                circleSize: 12,
                circleMargin: 2
            },
            "default": {
                width: 44,
                height: 22,
                circleSize: 18,
                circleMargin: 2
            }
        })

    implicitWidth: sizeMap[size].width
    implicitHeight: sizeMap[size].height

    // 背景轨道
    indicator: Rectangle {
        implicitWidth: sizeMap[size].width
        implicitHeight: sizeMap[size].height
        x: root.leftPadding
        y: parent.height / 2 - height / 2
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.border
        opacity: root.enabled ? 1 : 0.6

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        // 圆形滑块
        Rectangle {
            x: root.checked ? parent.width - width - sizeMap[size].circleMargin : sizeMap[size].circleMargin
            y: (parent.height - height) / 2
            width: sizeMap[size].circleSize
            height: sizeMap[size].circleSize
            radius: width / 2
            color: "white"

            Behavior on x {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutCubic
                }
            }
        }
    }

    // 内容项（用于布局，不显示文字）
    contentItem: Text {
        text: root.text
        font.pixelSize: 13
        color: Theme.textPrimary
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.indicator.width + root.spacing
    }
}
