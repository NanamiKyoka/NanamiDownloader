import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0
import Nanami.UI.Components 1.0

Popup {
    id: root
    width: 450
    height: 250
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: Overlay.overlay

    property string taskName: ""
    property string gid: ""

    signal confirm(string gid)
    signal reject(string gid)

    background: Rectangle {
        color: Theme.surface
        radius: 8
        border.color: Theme.divider
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        RowLayout {
            spacing: 10
            Text {
                text: "❓"
                font.pixelSize: 24
            }
            Text {
                text: qsTr("任务已存在")
                color: Theme.textPrimary
                font.pixelSize: 18
                font.bold: true
            }
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("该下载任务已存在于列表中：")
            color: Theme.textPrimary
            font.pixelSize: 15
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Theme.isDark ? "#383838" : "#f5f5f5"
            radius: 4
            Text {
                anchors.centerIn: parent
                text: root.taskName
                color: Theme.textPrimary
                font.bold: true
                elide: Text.ElideMiddle
                width: parent.width - 20
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Text {
            text: qsTr("您想重新配置此任务（重新选择文件/路径）吗？\n取消将继续当前状态。")
            color: Theme.textSecondary
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 12

            NButton {
                text: qsTr("继续下载")
                variant: "default"
                onClicked: {
                    root.reject(root.gid)
                    root.close()
                }
            }

            NButton {
                text: qsTr("重新配置")
                variant: "primary"
                onClicked: {
                    root.confirm(root.gid)
                    root.close()
                }
            }
        }
    }
}