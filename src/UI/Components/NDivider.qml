// NDivider.qml - 分隔线组件
import QtQuick

Rectangle {
    id: root

    // 属性定义
    property string type: "horizontal"  // horizontal, vertical
    property string orientation: "center"  // left, center, right (仅 horizontal 有效)
    property bool dashed: false
    property string text: ""

    // 颜色
    color: Theme.divider

    // 根据类型设置尺寸
    width: type === "horizontal" ? (parent ? parent.width : 100) : 1
    height: type === "horizontal" ? 1 : (parent ? parent.height : 100)

    // 虚线效果
    Rectangle {
        visible: root.dashed && root.type === "horizontal"
        anchors.fill: parent
        color: "transparent"

        Repeater {
            model: Math.floor(parent.width / 8)
            delegate: Rectangle {
                width: 4
                height: 1
                x: index * 8
                color: root.color
            }
        }
    }

    // 文本标签
    Rectangle {
        visible: root.text !== "" && root.type === "horizontal"
        anchors.centerIn: parent
        width: textLabel.width + 16
        height: textLabel.height + 8
        color: Theme.background

        Text {
            id: textLabel
            anchors.centerIn: parent
            text: root.text
            font.pixelSize: 12
            color: Theme.textSecondary
        }
    }
}
