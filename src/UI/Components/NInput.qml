// NInput.qml - Ant Design 风格输入框组件
import QtQuick
import QtQuick.Controls

TextField {
    id: root

    // 属性定义
    property string size: "middle"      // small, middle, large
    property string status: ""          // "", error, warning
    property bool allowClear: false
    property string prefix: ""
    property string suffix: ""
    property string prefixIcon: ""
    property string suffixIcon: ""

    // 尺寸映射
    readonly property var sizeMap: ({
            "small": {
                height: 24,
                fontSize: 12,
                padding: 8
            },
            "middle": {
                height: 32,
                fontSize: 13,
                padding: 12
            },
            "large": {
                height: 40,
                fontSize: 14,
                padding: 16
            }
        })

    implicitHeight: sizeMap[size].height
    leftPadding: (prefix !== "" || prefixIcon !== "") ? 32 : sizeMap[size].padding
    rightPadding: (suffix !== "" || suffixIcon !== "" || allowClear) ? 32 : sizeMap[size].padding

    // 颜色配置
    readonly property color borderColor: {
        if (!enabled)
            return Theme.border;
        if (status === "error")
            return Theme.error;
        if (status === "warning")
            return Theme.warning;
        if (activeFocus)
            return Theme.primary;
        if (hovered)
            return Theme.borderFocus;
        return Theme.border;
    }

    readonly property color bgColor: {
        if (!enabled)
            return Theme.disabled;
        return Theme.surface;
    }

    // 背景
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: root.implicitHeight
        color: bgColor
        border.width: 1
        radius: 4

        // 边框颜色动画
        border.color: borderColor
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        // 悬停状态层
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.hover
            opacity: root.enabled && root.hovered && !root.activeFocus ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // 聚焦状态层
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Theme.primary
            border.width: 2
            opacity: root.enabled && root.activeFocus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    // 字体
    font.pixelSize: sizeMap[size].fontSize
    color: enabled ? Theme.textPrimary : Theme.textDisabled
    placeholderTextColor: Theme.textHint

    // 前缀图标
    Image {
        id: prefixIconImg
        source: prefixIcon
        visible: prefixIcon !== ""
        anchors {
            left: parent.left
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
        width: 16
        height: 16
    }

    // 前缀文字
    Text {
        id: prefixText
        text: prefix
        visible: prefix !== "" && prefixIcon === ""
        anchors {
            left: parent.left
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
        font.pixelSize: sizeMap[size].fontSize
        color: Theme.textSecondary
    }

    // 后缀图标
    Image {
        id: suffixIconImg
        source: suffixIcon
        visible: suffixIcon !== ""
        anchors {
            right: clearBtn.left
            rightMargin: 4
            verticalCenter: parent.verticalCenter
        }
        width: 16
        height: 16
    }

    // 后缀文字
    Text {
        id: suffixText
        text: suffix
        visible: suffix !== "" && suffixIcon === ""
        anchors {
            right: clearBtn.left
            rightMargin: 4
            verticalCenter: parent.verticalCenter
        }
        font.pixelSize: sizeMap[size].fontSize
        color: Theme.textSecondary
    }

    // 清除按钮
    Rectangle {
        id: clearBtn
        visible: allowClear && root.text !== "" && root.enabled
        anchors {
            right: parent.right
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        width: 16
        height: 16
        radius: 8
        color: Theme.textHint

        Text {
            anchors.centerIn: parent
            text: "×"
            color: "white"
            font.pixelSize: 12
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.clear()
            cursorShape: Qt.PointingHandCursor
        }
    }
}
