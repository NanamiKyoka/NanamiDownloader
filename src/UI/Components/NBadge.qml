// NBadge.qml - 徽标组件
import QtQuick

Item {
    id: root

    // 属性定义
    property int count: 0
    property string status: ""  // success, error, default, warning, processing
    property string text: ""
    property bool dot: false
    property bool showZero: false
    property int overflowCount: 99
    property int offsetX: 0
    property int offsetY: 0

    // 尺寸
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    // 状态颜色映射
    readonly property var statusColors: ({
            "success": Theme.success,
            "error": Theme.error,
            "warning": Theme.warning,
            "default": Theme.textSecondary,
            "processing": Theme.primary
        })

    // 内容区域
    default property alias content: contentArea.children

    Item {
        id: contentArea
        anchors.fill: parent
    }

    // 徽标
    Rectangle {
        id: badgeRect
        anchors {
            right: contentArea.right
            top: contentArea.top
            rightMargin: -offsetX
            topMargin: offsetY
        }
        width: dot ? 8 : Math.max(20, badgeText.width + 12)
        height: dot ? 8 : 20
        radius: dot ? 4 : 10
        color: status !== "" ? statusColors[status] : Theme.error
        visible: (dot && count > 0) || (!dot && (count > 0 || showZero))

        // 处理中的动画
        SequentialAnimation on opacity {
            running: root.status === "processing"
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.4; duration: 1000 }
            NumberAnimation { from: 0.4; to: 1; duration: 1000 }
        }

        // 数字文本
        Text {
            id: badgeText
            anchors.centerIn: parent
            text: count > overflowCount ? overflowCount + "+" : count.toString()
            font.pixelSize: 12
            font.bold: true
            color: "white"
            visible: !dot && text === ""
        }

        // 自定义文本
        Text {
            anchors.centerIn: parent
            text: root.text
            font.pixelSize: 12
            font.bold: true
            color: "white"
            visible: root.text !== ""
        }
    }
}
