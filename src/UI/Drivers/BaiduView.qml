import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.Core 1.0
import Nanami.UI 1.0
import Nanami.UI.Components 1.0

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

    property string currentPath: "/"
    property var selectedIndexes: []

    function refresh() {
        Downloader.loadBaiduPath(currentPath)
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        RowLayout {
            spacing: 10
            NButton {
                text: "←"
                enabled: currentPath !== "/"
                onClicked: {
                    var parts = currentPath.split("/")
                    parts.pop()
                    if (parts.length === 1 && parts[0] === "") parts = ["", ""]
                    var newPath = parts.join("/")
                    if (newPath === "") newPath = "/"
                    currentPath = newPath
                    refresh()
                }
            }
            Text {
                text: qsTr("当前路径: ") + currentPath
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideLeft
                color: Theme.textPrimary
            }
            NButton {
                text: qsTr("刷新")
                onClicked: refresh()
            }
            NButton {
                text: qsTr("下载选中")
                enabled: selectedIndexes.length > 0
                onClicked: {
                    Downloader.downloadBaiduFiles(selectedIndexes)
                }
            }
            NButton {
                text: qsTr("删除选中")
                enabled: selectedIndexes.length > 0
                onClicked: {
                    Downloader.deleteBaiduFiles(selectedIndexes)
                    refresh()
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Downloader.baiduModel

            delegate: Rectangle {
                width: listView.width
                height: 40
                color: selectedIndexes.indexOf(index) !== -1 ? (Theme.isDark ? "#444" : "#e0e0e0") : "transparent"

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            var relativeX = mouse.x - checkBoxArea.x
                            var relativeY = mouse.y - checkBoxArea.y
                            if (!(relativeX >= 0 && relativeX <= checkBoxArea.width &&
                                relativeY >= 0 && relativeY <= checkBoxArea.height)) {
                                if (!model.isDir) {
                                    var idx = selectedIndexes.indexOf(index)
                                    if (idx === -1) selectedIndexes.push(index)
                                    else selectedIndexes.splice(idx, 1)
                                    selectedIndexes = selectedIndexes.concat([])
                                }
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            contextMenu.popup()
                        }
                    }
                    onDoubleClicked: (mouse) => {
                        var relativeX = mouse.x - checkBoxArea.x
                        var relativeY = mouse.y - checkBoxArea.y
                        if (!(relativeX >= 0 && relativeX <= checkBoxArea.width &&
                            relativeY >= 0 && relativeY <= checkBoxArea.height)) {
                            if (model.isDir) {
                                var p = model.path
                                currentPath = p
                                selectedIndexes = []
                                refresh()
                            }
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10

                    Item {
                        id: checkBoxArea
                        width: 20
                        height: 20
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                        NCheckbox {
                            id: checkBox
                            anchors.centerIn: parent
                            checked: selectedIndexes.indexOf(index) !== -1
                            onToggled: {
                                var idx = selectedIndexes.indexOf(index)
                                if (checked && idx === -1) selectedIndexes.push(index)
                                else if (!checked && idx !== -1) selectedIndexes.splice(idx, 1)
                                selectedIndexes = selectedIndexes.concat([])
                            }
                        }
                    }

                    Text {
                        text: model.isDir ? "📁" : "📄"
                        font.pixelSize: 16
                    }

                    Text {
                        text: model.name
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                        color: Theme.textPrimary
                    }

                    Text {
                        text: model.sizeString
                        color: Theme.textSecondary
                        width: 80
                    }

                    Text {
                        text: model.timeString
                        color: Theme.textSecondary
                        width: 140
                    }
                }

                Menu {
                    id: contextMenu
                    MenuItem {
                        text: qsTr("下载")
                        enabled: !model.isDir
                        onTriggered: Downloader.downloadBaiduFiles([index])
                    }
                    MenuItem {
                        text: qsTr("删除")
                        onTriggered: {
                            Downloader.deleteBaiduFiles([index])
                            refresh()
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: Downloader
        function onBaiduFilesLoaded() {
            selectedIndexes = []
        }
    }
}