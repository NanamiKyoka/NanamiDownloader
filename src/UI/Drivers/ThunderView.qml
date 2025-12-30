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

    property var pathStack: [{"id": "", "name": "Root"}]
    property var selectedIndexes: []

    function getCurrentParentId() {
        if (pathStack.length === 0) return ""
        return pathStack[pathStack.length - 1].id
    }

    function getPathString() {
        var str = ""
        for (var i = 0; i < pathStack.length; i++) {
            str += "/" + pathStack[i].name
        }
        return str.replace("/Root", "") || "/"
    }

    function refresh() {
        if (Settings.thunderUsername === "" || Settings.thunderPassword === "") {
            return
        }
        Downloader.loadThunderPath(getCurrentParentId())
    }

    // Auto-refresh on first load
    Component.onCompleted: {
        refresh()
    }

    // Auto-refresh when becoming visible if empty
    onVisibleChanged: {
        if (visible && Downloader.thunderModel.count === 0) {
            refresh()
        }
    }

    ThunderVerificationDialog {
        id: verifyDialog
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        RowLayout {
            spacing: 10
            Button {
                text: "←"
                enabled: pathStack.length > 1
                palette.button: Theme.isDark ? "#36393F" : "#F0F0F0"
                palette.buttonText: Theme.textPrimary
                palette.highlight: Theme.accent
                palette.highlightedText: ThemeController.textInverted
                onClicked: {
                    if (pathStack.length > 1) {
                        var newStack = pathStack.slice(0, -1)
                        pathStack = newStack
                        refresh()
                    }
                }
            }
            Text {
                text: qsTr("当前路径: ") + getPathString()
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideLeft
                color: Theme.textPrimary
            }
            Button {
                text: qsTr("刷新")
                palette.button: Theme.isDark ? "#36393F" : "#F0F0F0"
                palette.buttonText: Theme.textPrimary
                palette.highlight: Theme.accent
                palette.highlightedText: ThemeController.textInverted
                onClicked: refresh()
            }
            Button {
                text: qsTr("下载选中")
                enabled: selectedIndexes.length > 0
                palette.button: Theme.isDark ? "#36393F" : "#F0F0F0"
                palette.buttonText: Theme.textPrimary
                palette.highlight: Theme.accent
                palette.highlightedText: ThemeController.textInverted
                onClicked: {
                    Downloader.downloadThunderFiles(selectedIndexes)
                }
            }
            Button {
                text: qsTr("删除选中")
                enabled: selectedIndexes.length > 0
                palette.button: Theme.isDark ? "#36393F" : "#F0F0F0"
                palette.buttonText: Theme.textPrimary
                palette.highlight: Theme.accent
                palette.highlightedText: ThemeController.textInverted
                onClicked: {
                    Downloader.deleteThunderFiles(selectedIndexes)
                    refresh()
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Downloader.thunderModel

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
                                var newStack = pathStack.concat({"id": model.id, "name": model.name})
                                pathStack = newStack
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

                        CheckBox {
                            id: checkBox
                            anchors.centerIn: parent
                            checked: selectedIndexes.indexOf(index) !== -1
                            onToggled: {
                                var idx = selectedIndexes.indexOf(index)
                                if (checked && idx === -1) selectedIndexes.push(index)
                                else if (!checked && idx !== -1) selectedIndexes.splice(idx, 1)
                                selectedIndexes = selectedIndexes.concat([])
                            }
                            contentItem: Text { text: ""; color: Theme.textPrimary }
                            indicator: Rectangle {
                                x: 0
                                y: parent.height / 2 - height / 2
                                implicitWidth: 18
                                implicitHeight: 18
                                radius: 3
                                color: parent.checked ? Theme.accent : "transparent"
                                border.color: parent.checked ? Theme.accent : Theme.textSecondary
                                antialiasing: true
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "white"
                                    visible: checkBox.checked
                                }
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
                        onTriggered: Downloader.downloadThunderFiles([index])
                    }
                    MenuItem {
                        text: qsTr("删除")
                        onTriggered: {
                            Downloader.deleteThunderFiles([index])
                            refresh()
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: Downloader
        function onThunderFilesLoaded() {
            selectedIndexes = []
        }
        function onAuthRequired() {
            refresh()
        }
        function onThunderVerificationRequired(data) {
            verifyDialog.jsonData = data
            verifyDialog.open()
        }
    }
}