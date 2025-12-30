import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 500
    height: root.isPurge ? 360 : 320
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape

    property string taskName: ""
    property string gid: ""
    property bool isPurge: false

    signal confirm(string gid, bool deleteFile)

    component CustomCheckBox: CheckBox {
        id: ccb
        indicator: Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            x: ccb.leftPadding
            y: parent.height / 2 - height / 2
            radius: 4
            color: ccb.checked ? Theme.accent : "transparent"
            border.color: ccb.checked ? Theme.accent : (Theme.isDark ? "#666" : "#bbb")
            border.width: 1.5
            Text {
                anchors.centerIn: parent; text: "✓"; font.pixelSize: 14; font.bold: true; color: "white"; visible: ccb.checked
            }
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        contentItem: Text {
            text: ccb.text; font: ccb.font; color: Theme.textPrimary; verticalAlignment: Text.AlignVCenter; leftPadding: ccb.indicator.width + ccb.spacing
        }
    }

    background: Rectangle {
        color: Theme.isDark ? "#2b2b2b" : "#ffffff"
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
                text: "⚠️"
                color: "#e6a23c"
                font.pixelSize: 24
            }
            Text {
                text: qsTr("删除确认")
                color: Theme.textPrimary
                font.pixelSize: 18
                font.bold: true
            }
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("您确定要删除此下载任务吗?")
            color: Theme.textPrimary
            font.pixelSize: 16
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
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

        CustomCheckBox {
            id: deleteFileCb
            text: qsTr("同时删除下载的文件")
            visible: root.isPurge
            checked: false
        }

        Text {
            Layout.fillWidth: true
            text: root.isPurge
                ? (deleteFileCb.checked ? qsTr("警告：下载的文件将被永久删除，无法恢复！") : qsTr("这只会删除任务记录。下载的文件将被保留。"))
                : qsTr("任务将被移动到 '已停止' 列表 (状态: 已移除)。")
            color: (root.isPurge && deleteFileCb.checked) ? "#ff4d4f" : Theme.textSecondary
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 12

            Button {
                text: qsTr("取消")
                flat: true
                Layout.preferredWidth: 80
                Layout.preferredHeight: 36
                background: Rectangle {
                    color: parent.hovered ? (Theme.isDark ? "#3e3e3e" : "#eeeeee") : "transparent"
                    border.color: Theme.divider
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.close()
            }

            Button {
                text: qsTr("删除")
                Layout.preferredWidth: 80
                Layout.preferredHeight: 36
                background: Rectangle {
                    color: parent.down ? "#d9363e" : "#ff4d4f"
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                onClicked: {
                    root.confirm(root.gid, deleteFileCb.checked)
                    root.close()
                }
            }
        }
    }
}