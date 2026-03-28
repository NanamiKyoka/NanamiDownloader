// NCard.qml - Ant Design 风格卡片组件
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    // 属性定义
    property string title: ""
    property string extra: ""
    property bool bordered: true
    property bool shadow: false
    property var actions: []

    default property alias content: contentContainer.data 

    // 尺寸 - 自动根据内容撑开高度
    implicitWidth: 300
    implicitHeight: mainLayout.implicitHeight

    // 样式
    color: Theme.surface
    border.color: bordered ? Theme.border : "transparent"
    border.width: bordered ? 1 : 0
    radius: Theme.borderRadiusMedium

    // 阴影效果
    Rectangle {
        visible: shadow
        anchors.fill: parent
        color: "transparent"
        radius: parent.radius
        z: -1
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.1
            radius: parent.radius
            anchors.margins: -2
        }
    }

    // 主布局
    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // 头部
        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: (root.title !== "" || root.extra !== "") ? 48 : 0
            visible: root.title !== "" || root.extra !== ""
            color: "transparent"

            // 标题
            Text {
                anchors {
                    left: parent.left
                    leftMargin: Theme.spacingMD
                    verticalCenter: parent.verticalCenter
                }
                text: root.title
                font.pixelSize: Theme.fontLG
                font.bold: true
                color: Theme.textPrimary
            }

            // 额外操作
            Text {
                anchors {
                    right: parent.right
                    rightMargin: Theme.spacingMD
                    verticalCenter: parent.verticalCenter
                }
                text: root.extra
                font.pixelSize: Theme.fontMD
                color: Theme.primary
                visible: root.extra !== ""
            }

            // 底部分隔线
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 1
                color: Theme.divider
                visible: root.bordered && (root.title !== "" || root.extra !== "")
            }
        }

        // 内容区域容器
        ColumnLayout {
            id: contentContainer
            Layout.fillWidth: true
            
            Layout.margins: Theme.spacingMD
            spacing: Theme.spacingSM
            
            // 这里是子控件实际插入的地方
        }

        // 底部操作栏
        Rectangle {
            id: actionsRow
            Layout.fillWidth: true
            Layout.preferredHeight: actions.length > 0 ? 48 : 0
            visible: actions.length > 0
            color: "transparent"

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 1
                color: Theme.divider
            }

            Row {
                anchors.centerIn: parent
                spacing: Theme.spacingMD
                Repeater {
                    model: root.actions
                    delegate: Text {
                        text: modelData
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontMD
                    }
                }
            }
        }
    }
}
