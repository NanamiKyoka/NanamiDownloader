import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.Core 1.0

Item {
    id: root
    
    opacity: 1
    scale: 1
    
    states: [
        State {
            name: "hidden"
            PropertyChanges { target: root; opacity: 0; scale: 0.95 }
        },
        State {
            name: "visible"
            PropertyChanges { target: root; opacity: 1; scale: 1 }
        }
    ]
    
    transitions: [
        Transition {
            from: "hidden"; to: "visible"
            SequentialAnimation {
                NumberAnimation { property: "scale"; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutCubic }
            }
        },
        Transition {
            from: "visible"; to: "hidden"
            SequentialAnimation {
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; duration: 200; easing.type: Easing.InCubic }
            }
        }
    ]
    
    property int filterType: 0

    function formatSize(bytes) {
        if (bytes === 0) return "0 B";
        var k = 1024;
        var sizes = ["B", "KB", "MB", "GB", "TB"];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return (bytes / Math.pow(k, i)).toFixed(2) + " " + sizes[i];
    }

    function formatTime(seconds) {
        if (seconds === Infinity || isNaN(seconds) || seconds < 0) return "--:--";
        if (seconds >= 3600) {
            var h = Math.floor(seconds / 3600);
            var m = Math.floor((seconds % 3600) / 60);
            return h + "h " + m + "m";
        }
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return m + "m " + s + "s";
    }

    component IconButton: Button {
        property string iconName
        property color iconColor: Theme.textSecondary

        width: 32; height: 32
        icon.source: iconName
        icon.color: iconColor
        icon.width: 22
        icon.height: 22
        display: AbstractButton.IconOnly

        background: Rectangle {
            color: parent.hovered ? (Theme.isDark ? "#444" : "#ddd") : "transparent"
            radius: 4
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: false }
    }

    component StatusIcon: Button {
        property string source
        property color color

        enabled: false
        flat: true
        icon.source: source
        icon.color: color
        icon.width: 22
        icon.height: 22
        display: AbstractButton.IconOnly
        background: null
        opacity: 1.0
    }

    DeleteConfirmDialog {
        id: deleteDialog
        anchors.centerIn: Overlay.overlay
        onConfirm: (gid, deleteFile) => {
            Downloader.handleDelete(gid, deleteFile)
            if (deleteFile) {
                window.showToast(qsTr("任务及文件已删除"))
            } else {
                window.showToast(qsTr("任务已移除"))
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: Theme.background

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                Text {
                    text: qsTr("下载任务")
                    font.bold: true
                    font.pixelSize: 18
                    color: Theme.textPrimary
                }

                ListView {
                    id: menuList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: [qsTr("全部任务"), qsTr("下载中"), qsTr("等待中"), qsTr("已停止"), qsTr("做种中")]
                    currentIndex: root.filterType

                    delegate: Item {
                        width: parent.width
                        height: 44

                        Rectangle {
                            anchors.fill: parent
                            color: index === root.filterType ? (Theme.isDark ? "#333" : "#e6f2ff") : "transparent"
                            radius: 8
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 4; height: 18
                                color: Theme.accent
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                visible: index === root.filterType
                                radius: 2
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.filterType = index
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15

                            StatusIcon {
                                source: {
                                    if(index === 0) return "qrc:/src/Icons/all.svg";
                                    if(index === 1) return "qrc:/src/Icons/play.svg";
                                    if(index === 2) return "qrc:/src/Icons/pause.svg";
                                    if(index === 3) return "qrc:/src/Icons/stop.svg";
                                    return "qrc:/src/Icons/connection.svg";
                                }
                                color: index === root.filterType ? Theme.accent : Theme.textSecondary
                            }

                            Text {
                                text: modelData
                                color: index === root.filterType ? Theme.accent : Theme.textSecondary
                                font.pixelSize: 14
                                font.weight: index === root.filterType ? Font.Bold : Font.Normal
                            }
                        }
                    }
                }
            }
            Rectangle { width: 1; height: parent.height; color: Theme.divider; anchors.right: parent.right }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.background

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: {
                                if (filterType === 0) return qsTr("全部任务");
                                if (filterType === 1) return qsTr("下载中");
                                if (filterType === 2) return qsTr("等待中");
                                if (filterType === 3) return qsTr("已停止");
                                return qsTr("做种中");
                            }
                            font.bold: true; font.pixelSize: 22; color: Theme.textPrimary
                        }
                        Text {
                            text: {
                                if (filterType === 0) return qsTr("所有状态的任务");
                                if (filterType === 1) return qsTr("当前下载任务");
                                if (filterType === 2) return qsTr("排队下载任务");
                                if (filterType === 3) return qsTr("已完成或停止的任务");
                                return qsTr("正在上传的任务");
                            }
                            font.pixelSize: 13; color: Theme.textSecondary
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        spacing: 10
                        visible: filterType !== 3
                        IconButton {
                            iconName: "qrc:/src/Icons/play.svg"
                            onClicked: { Downloader.unpauseAll(); window.showToast(qsTr("已全部开始")) }
                            ToolTip.visible: hovered; ToolTip.text: qsTr("全部开始")
                        }
                        IconButton {
                            iconName: "qrc:/src/Icons/pause.svg"
                            onClicked: { Downloader.pauseAll(); window.showToast(qsTr("已全部暂停")) }
                            ToolTip.visible: hovered; ToolTip.text: qsTr("全部暂停")
                        }
                        IconButton {
                            iconName: "qrc:/src/Icons/refresh.svg"
                            onClicked: { window.showToast(qsTr("列表已刷新")) }
                            ToolTip.visible: hovered; ToolTip.text: qsTr("刷新")
                        }
                        IconButton {
                            iconName: "qrc:/src/Icons/delete.svg"
                            onClicked: { Downloader.purgeDownloadResult(); window.showToast(qsTr("已清空移除记录")) }
                            ToolTip.visible: hovered; ToolTip.text: qsTr("删除所有")
                        }
                    }
                }

                ListView {
                    id: taskList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 16

                    add: Transition { NumberAnimation { property: "y"; from: 50; duration: 300; easing.type: Easing.OutQuad } NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 } }
                    addDisplaced: Transition { NumberAnimation { property: "y"; duration: 300; easing.type: Easing.OutQuad } }
                    remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 200 } NumberAnimation { property: "scale"; to: 0.9; duration: 200 } }

                    model: {
                        if (root.filterType === 0) return Downloader.allModel
                        if (root.filterType === 1) return Downloader.activeModel
                        if (root.filterType === 2) return Downloader.waitingModel
                        if (root.filterType === 3) return Downloader.stoppedModel
                        return Downloader.seedingModel
                    }

                    delegate: Rectangle {
                        width: taskList.width
                        height: 120
                        color: Theme.surface
                        radius: 8

                        border.color: hoverArea.containsMouse ? Theme.accent : Theme.divider
                        border.width: hoverArea.containsMouse ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onDoubleClicked: Downloader.openFile(model.path)
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: model.name
                                    font.pixelSize: 16
                                    color: Theme.textPrimary
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                Row {
                                    spacing: 8

                                    IconButton {
                                        iconName: {
                                            if (model.status === "seeding") return "qrc:/src/Icons/pause.svg"
                                            if (model.status === "active") return "qrc:/src/Icons/pause.svg"
                                            return "qrc:/src/Icons/play.svg"
                                        }
                                        iconColor: Theme.accent
                                        onClicked: {
                                            if (model.status === "active" || model.status === "seeding") {
                                                Downloader.pause(model.gid)
                                                window.showToast(qsTr("已暂停: ") + model.name)
                                            } else {
                                                if (model.status === "paused" || model.status === "waiting" || model.status === "complete") {
                                                    Downloader.unpause(model.gid)
                                                    window.showToast(qsTr("已开始: ") + model.name)
                                                } else {
                                                    Downloader.restartTask(model.gid)
                                                    window.showToast(qsTr("重新下载: ") + model.name)
                                                }
                                            }
                                        }
                                    }
                                    IconButton {
                                        iconName: "qrc:/src/Icons/folder.svg"
                                        onClicked: {
                                            Downloader.openFolder(model.path)
                                            window.showToast(qsTr("已打开文件夹"))
                                        }
                                    }
                                    IconButton {
                                        iconName: "qrc:/src/Icons/link.svg"
                                        onClicked: {
                                            Clipboard.copy(model.url)
                                            window.showToast(qsTr("链接已复制"))
                                        }
                                    }
                                    IconButton {
                                        iconName: "qrc:/src/Icons/delete.svg"
                                        onClicked: {
                                            deleteDialog.taskName = model.name
                                            deleteDialog.gid = model.gid
                                            deleteDialog.isPurge = true
                                            deleteDialog.open()
                                        }
                                    }
                                    IconButton {
                                        iconName: "qrc:/src/Icons/info.svg"
                                        onClicked: {
                                            window.showDetails(model.gid)
                                        }
                                        visible: model.gid.startsWith("bt_")
                                    }
                                }
                            }

                            Text {
                                text: qsTr("大小: ") + root.formatSize(model.totalLength) + qsTr(" - 进度: ") + (model.progress * 100).toFixed(2) + "%"
                                font.pixelSize: 12
                                color: Theme.textSecondary
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 6
                                color: Theme.isDark ? "#444" : "#eee"
                                radius: 3
                                Rectangle {
                                    width: parent.width * model.progress; height: parent.height
                                    color: Theme.accent; radius: 3
                                    Behavior on width { NumberAnimation { duration: 300 } }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: root.formatSize(model.completedLength) + "/" + root.formatSize(model.totalLength)
                                    font.pixelSize: 12; color: Theme.textSecondary
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: {
                                        if (model.status === "active") return root.formatSize(model.downloadSpeed) + "/s"
                                        if (model.status === "seeding") return qsTr("做种中")
                                        if (model.status === "complete") return qsTr("已完成")
                                        if (model.status === "error") return qsTr("错误")
                                        if (model.status === "removed") return qsTr("已移除")
                                        return qsTr("已停止")
                                    }
                                    font.pixelSize: 12; color: Theme.textSecondary
                                }
                                Text {
                                    property var remaining: model.downloadSpeed > 0 ? (model.totalLength - model.completedLength) / model.downloadSpeed : -1
                                    text: "  " + qsTr("剩余") + " " + root.formatTime(remaining)
                                    font.pixelSize: 12; color: Theme.textSecondary
                                    visible: model.status === "active"
                                }
                                Row {
                                    spacing: 4; visible: model.status === "active" || model.status === "seeding"
                                    StatusIcon {
                                        source: "qrc:/src/Icons/connection.svg"; color: Theme.textSecondary
                                        icon.width: 14; icon.height: 14
                                    }
                                    Text {
                                        text: model.connections
                                        font.pixelSize: 12; color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}