// NTooltip.qml - 工具提示组件
import QtQuick
import QtQuick.Controls

Popup {
    id: root

    // 属性定义
    property string placement: "top"  // top, bottom, left, right
    property color backgroundColor: Theme.textPrimary
    property color textColor: "#ffffff"
    property int arrowSize: 6

    // 默认关闭策略
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // 背景
    background: Rectangle {
        color: root.backgroundColor
        radius: 4

        // 箭头
        Rectangle {
            id: arrow
            width: root.arrowSize
            height: root.arrowSize
            color: root.backgroundColor
            rotation: 45

            // 根据位置设置箭头位置
            anchors {
                top: root.placement === "bottom" ? parent.top : undefined
                bottom: root.placement === "top" ? parent.bottom : undefined
                left: root.placement === "right" ? parent.left : undefined
                right: root.placement === "left" ? parent.right : undefined
                horizontalCenter: (root.placement === "top" || root.placement === "bottom") ? parent.horizontalCenter : undefined
                verticalCenter: (root.placement === "left" || root.placement === "right") ? parent.verticalCenter : undefined
                margins: -width / 2
            }
        }
    }

    // 内容
    contentItem: Text {
        text: root.text
        font.pixelSize: 12
        color: root.textColor
        padding: 8
    }

    // 位置调整
    function updatePosition() {
        if (!parent)
            return;

        var pos = mapFromItem(parent, parent.width / 2, parent.height / 2);
        var offset = 8;

        switch (placement) {
            case "top":
                x = pos.x - width / 2;
                y = pos.y - height - offset;
                break;
            case "bottom":
                x = pos.x - width / 2;
                y = pos.y + offset;
                break;
            case "left":
                x = pos.x - width - offset;
                y = pos.y - height / 2;
                break;
            case "right":
                x = pos.x + offset;
                y = pos.y - height / 2;
                break;
        }
    }

    onOpened: updatePosition()
}
