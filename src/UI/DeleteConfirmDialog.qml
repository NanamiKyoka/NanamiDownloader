import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0
import Nanami.UI.Components 1.0

Popup {
    id: root
    width: 500
    height: root.isPurge ? 400 : 360
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape

    property string taskName: ""
    property string gid: ""
    property bool isPurge: false

    signal confirm(string gid, bool deleteFile)

    // 用于存储不再提示时的选择
    property bool savedDeleteFileChoice: false

    function openDialog(taskName, gid, isPurge) {
        root.taskName = taskName
        root.gid = gid
        root.isPurge = isPurge

        // 如果不需要确认，直接执行默认操作
        if (!Settings.confirmDelete) {
            root.confirm(gid, Settings.deleteWithFile)
            return
        }

        // 恢复上次的选择
        deleteFileCb.checked = Settings.deleteWithFile
        dontAskAgainCb.checked = false
        root.open()
    }

    background: Rectangle {
        color: Theme.surface
        radius: 8
        border.color: Theme.divider
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

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

        NCheckbox {
            id: deleteFileCb
            text: qsTr("同时删除下载的文件")
            visible: root.isPurge
            checked: Settings.deleteWithFile
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

        NCheckbox {
            id: dontAskAgainCb
            text: qsTr("不再提示，记住此次选择")
            visible: root.isPurge
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 12

            NButton {
                text: qsTr("取消")
                variant: "default"
                onClicked: root.close()
            }

            NButton {
                text: qsTr("删除")
                variant: "primary"
                onClicked: {
                    // 如果勾选了不再提示，保存设置
                    if (dontAskAgainCb.checked && root.isPurge) {
                        Settings.setConfirmDelete(false)
                        Settings.setDeleteWithFile(deleteFileCb.checked)
                    }
                    root.confirm(root.gid, deleteFileCb.checked)
                    root.close()
                }
            }
        }
    }
}