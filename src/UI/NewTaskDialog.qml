import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform 1.1

Popup {
    id: root
    width: 720
    height: 500
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay

    property int currentTab: 0
    property string downloadPath: Settings.downloadPath
    property bool advancedVisible: false
    property var torrentPaths: []

    signal taskAdded()

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
        NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150 }
        NumberAnimation { property: "scale"; from: 1.0; to: 0.9; duration: 150; easing.type: Easing.InCubic }
    }

    function prefillLink(link) {
        root.currentTab = 0
        if (linkInput.text === "") {
            linkInput.text = link
        } else if (!linkInput.text.includes(link)) {
            linkInput.text += "\n" + link
        }
    }

    function cleanFileUrl(url) {
        var path = url.toString()
        if (Qt.platform.os === "windows") {
            path = path.replace(/^(file:\/{3})/, "")
        } else {
            path = path.replace(/^(file:\/\/)/, "")
        }
        return decodeURIComponent(path)
    }

    background: Rectangle {
        color: Theme.surface
        radius: 10
        border.color: Theme.divider
        border.width: 1
    }

    component InputBackground: Rectangle {
        property bool isFocused: parent.activeFocus
        color: Theme.isDark ? "#252525" : "#ffffff"
        border.color: isFocused ? Theme.accent : Theme.divider
        border.width: isFocused ? 2 : 1
        radius: 6
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }

    contentItem: ColumnLayout {
        spacing: 0
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Rectangle {
                    width: 36
                    height: 36
                    radius: 10
                    color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: "white"
                        font.pixelSize: 22
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: qsTr("添加新的下载任务")
                        color: Theme.textPrimary
                        font.bold: true
                        font.pixelSize: 16
                    }
                    Text {
                        text: qsTr("支持 HTTP, HTTPS, FTP, Magnet, M3U8, Torrent")
                        color: Theme.textSecondary
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    flat: true
                    onClicked: root.close()
                    contentItem: Text {
                        text: "✕"
                        color: Theme.textSecondary
                        font.pixelSize: 18
                    }
                    background: Rectangle {
                        color: parent.hovered ? (Theme.isDark ? "#333" : "#eee") : "transparent"
                        radius: 4
                    }
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: false }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "transparent"

            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: 20
                spacing: 25

                Repeater {
                    model: [qsTr("链接任务"), qsTr("种子文件")]
                    delegate: Item {
                        width: 70
                        height: 40
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.currentTab === index ? Theme.accent : Theme.textSecondary
                            font.bold: root.currentTab === index
                            font.pixelSize: 14
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on font.bold { PropertyAnimation { duration: 200 } }
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            height: 3
                            width: parent.width
                            radius: 1.5
                            color: Theme.accent
                            opacity: root.currentTab === index ? 1 : 0
                            Behavior on opacity { OpacityAnimator { duration: 200 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = index
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: -1

            ColumnLayout {
                width: parent.width
                spacing: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: 20
                    Layout.rightMargin: 30
                    spacing: 20

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160

                        TextArea {
                            id: linkInput
                            anchors.fill: parent
                            anchors.margins: 1
                            placeholderText: qsTr("输入下载 URL (每行一个)，自动识别 M3U8 磁力链接...")
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            background: InputBackground {}
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            leftPadding: 12
                            rightPadding: 12
                            topPadding: 12
                            bottomPadding: 12
                            x: root.currentTab === 0 ? 0 : -width
                            opacity: root.currentTab === 0 ? 1 : 0
                            visible: root.currentTab === 0
                            Behavior on x { enabled: linkInput.visible; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        Rectangle {
                            id: torrentContent
                            anchors.fill: parent
                            color: Theme.isDark ? "#252525" : "#f8f8f8"
                            radius: 6
                            border.color: Theme.divider
                            x: root.currentTab === 1 ? 0 : parent.width
                            opacity: root.currentTab === 1 ? 1 : 0
                            visible: root.currentTab === 1
                            Behavior on x { enabled: torrentContent.visible; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            DropArea {
                                anchors.fill: parent
                                onEntered: (drag) => {
                                    drag.accept(drag.hasUrls)
                                }
                                onDropped: (drop) => {
                                    if (drop.hasUrls) {
                                        var paths = []
                                        for (var i = 0; i < drop.urls.length; i++) {
                                            var path = cleanFileUrl(drop.urls[i])
                                            if (path.toLowerCase().endsWith(".torrent")) {
                                                paths.push(path)
                                            }
                                        }
                                        if (paths.length > 0) {
                                            root.torrentPaths = paths
                                        } else {
                                            window.showToast(qsTr("未检测到 .torrent 文件"))
                                        }
                                    }
                                }
                            }

                            Canvas {
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.strokeStyle = Theme.divider
                                    ctx.lineWidth = 2
                                    ctx.setLineDash([6, 6])
                                    ctx.beginPath()
                                    ctx.rect(2, 2, width-4, height-4)
                                    ctx.stroke()
                                }
                            }
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 15
                                Text {
                                    text: "📂"
                                    font.pixelSize: 48
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: {
                                        if (root.torrentPaths.length === 0) return qsTr("点击或拖拽 .torrent 文件至此")
                                        if (root.torrentPaths.length === 1) {
                                            var p = root.torrentPaths[0]
                                            if (Qt.platform.os === "windows") return p.split("\\").pop()
                                            return p.split("/").pop()
                                        }
                                        return qsTr("已选择 %1 个文件").arg(root.torrentPaths.length)
                                    }
                                    color: root.torrentPaths.length > 0 ? Theme.accent : Theme.textSecondary
                                    font.bold: root.torrentPaths.length > 0
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    id: torrentPathTip
                                    visible: root.torrentPaths.length > 0
                                    text: root.torrentPaths.length === 1 ? root.torrentPaths[0] : qsTr("松开鼠标以添加")
                                    color: Theme.textSecondary
                                    font.pixelSize: 12
                                    Layout.maximumWidth: 400
                                    elide: Text.ElideMiddle
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: torrentPicker.open()
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: qsTr("下载设置")
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 110
                            color: "transparent"
                            border.color: Theme.divider
                            radius: 6

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 15

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 15

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: qsTr("重命名:")
                                            color: Theme.textSecondary
                                            font.pixelSize: 12
                                            width: 45
                                        }
                                        TextField {
                                            id: renameField
                                            placeholderText: qsTr("可选文件名 (仅单任务有效)")
                                            Layout.fillWidth: true
                                            enabled: root.currentTab === 0 || root.torrentPaths.length <= 1
                                            color: Theme.textPrimary
                                            background: InputBackground {}
                                            selectByMouse: true
                                            leftPadding: 10
                                        }
                                    }

                                    RowLayout {
                                        Text {
                                            text: qsTr("分块:")
                                            color: Theme.textSecondary
                                            font.pixelSize: 12
                                        }
                                        SpinBox {
                                            id: splitField
                                            from: 1
                                            to: 64
                                            value: 16
                                            editable: true
                                            width: 100
                                            contentItem: TextInput {
                                                z: 2
                                                text: splitField.textFromValue(splitField.value, splitField.locale)
                                                font.pixelSize: 16
                                                color: Theme.textPrimary
                                                selectionColor: Theme.accent
                                                selectedTextColor: "#ffffff"
                                                horizontalAlignment: Qt.AlignHCenter
                                                verticalAlignment: Qt.AlignVCenter
                                                readOnly: !splitField.editable
                                                validator: splitField.validator
                                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                            }
                                            background: InputBackground {}

                                            up.indicator: Rectangle {
                                                x: parent.width - width - 2
                                                y: 2
                                                width: 20
                                                height: parent.height / 2 - 2
                                                color: splitField.up.pressed ? (Theme.isDark ? "#444" : "#ddd") : "transparent"
                                                Text {
                                                    text: "▲"
                                                    color: Theme.textSecondary
                                                    anchors.centerIn: parent
                                                    font.pixelSize: 10
                                                }
                                            }
                                            down.indicator: Rectangle {
                                                x: parent.width - width - 2
                                                y: parent.height / 2
                                                width: 20
                                                height: parent.height / 2 - 2
                                                color: splitField.down.pressed ? (Theme.isDark ? "#444" : "#ddd") : "transparent"
                                                Text {
                                                    text: "▼"
                                                    color: Theme.textSecondary
                                                    anchors.centerIn: parent
                                                    font.pixelSize: 10
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: qsTr("保存到:")
                                        color: Theme.textSecondary
                                        font.pixelSize: 12
                                        width: 45
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 5
                                        TextField {
                                            id: pathField
                                            text: root.downloadPath.replace("file:///", "")
                                            Layout.fillWidth: true
                                            readOnly: true
                                            color: Theme.textPrimary
                                            background: InputBackground { color: Theme.isDark ? "#2b2b2b" : "#f0f0f0" }
                                            leftPadding: 10
                                        }
                                        Button {
                                            width: 36
                                            height: 30
                                            icon.source: "qrc:/src/Icons/folder.svg"
                                            icon.color: Theme.textPrimary
                                            icon.width: 18
                                            icon.height: 18
                                            display: AbstractButton.IconOnly
                                            background: Rectangle {
                                                color: parent.hovered ? (Theme.isDark ? "#444" : "#ddd") : "transparent"
                                                radius: 4
                                                border.color: Theme.divider
                                                border.width: 1
                                            }
                                            onClicked: folderPicker.open()
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: false }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.advancedVisible
                        spacing: 8
                        Behavior on visible { NumberAnimation { duration: 200 } }

                        Text {
                            text: qsTr("高级选项")
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: advancedCol.implicitHeight + 30
                            color: "transparent"
                            border.color: Theme.divider
                            radius: 6

                            ColumnLayout {
                                id: advancedCol
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 12

                                RowLayout {
                                    Text {
                                        text: "User-Agent:"
                                        color: Theme.textSecondary
                                        width: 80
                                        font.pixelSize: 12
                                    }
                                    TextField {
                                        id: uaField
                                        Layout.fillWidth: true
                                        color: Theme.textPrimary
                                        background: InputBackground {}
                                        selectByMouse: true
                                        leftPadding: 10
                                    }
                                }
                                RowLayout {
                                    Text {
                                        text: "Referer:"
                                        color: Theme.textSecondary
                                        width: 80
                                        font.pixelSize: 12
                                    }
                                    TextField {
                                        id: refererField
                                        Layout.fillWidth: true
                                        color: Theme.textPrimary
                                        background: InputBackground {}
                                        selectByMouse: true
                                        leftPadding: 10
                                    }
                                }
                                RowLayout {
                                    Text {
                                        text: "Cookie:"
                                        color: Theme.textSecondary
                                        width: 80
                                        font.pixelSize: 12
                                    }
                                    TextField {
                                        id: cookieField
                                        Layout.fillWidth: true
                                        color: Theme.textPrimary
                                        background: InputBackground {}
                                        selectByMouse: true
                                        leftPadding: 10
                                    }
                                }

                                RowLayout {
                                    Text {
                                        text: "M3U8 Key:"
                                        color: Theme.textSecondary
                                        width: 80
                                        font.pixelSize: 12
                                    }
                                    TextField {
                                        id: keyField
                                        Layout.fillWidth: true
                                        placeholderText: qsTr("可选 (如果 M3U8 加密)")
                                        color: Theme.textPrimary
                                        background: InputBackground {}
                                        selectByMouse: true
                                        leftPadding: 10
                                    }
                                }

                                ColumnLayout {
                                    spacing: 5
                                    Text {
                                        text: qsTr("定制接头 (Header: Value):")
                                        color: Theme.textSecondary
                                        font.pixelSize: 12
                                    }
                                    TextArea {
                                        id: headersField
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 60
                                        color: Theme.textPrimary
                                        background: InputBackground {}
                                        selectByMouse: true
                                        leftPadding: 10
                                        topPadding: 10
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20

                CheckBox {
                    id: advCb
                    text: qsTr("高级选项")
                    checked: root.advancedVisible
                    font.pixelSize: 13
                    onToggled: {
                        root.advancedVisible = checked
                        if (!checked) {
                            uaField.text = ""
                            refererField.text = ""
                            cookieField.text = ""
                            headersField.text = ""
                            keyField.text = ""
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font: parent.font
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: parent.indicator.width + parent.spacing
                    }
                    indicator: Rectangle {
                        x: 0
                        y: parent.height / 2 - height / 2
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 3
                        color: parent.checked ? Theme.accent : "transparent"
                        border.color: parent.checked ? Theme.accent : Theme.textSecondary
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Text {
                            anchors.centerIn: parent; text: "✓"; font.pixelSize: 14; font.bold: true; color: "white"; visible: advCb.checked
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("取消")
                    flat: true
                    onClicked: root.close()
                    contentItem: Text {
                        text: qsTr("取消")
                        color: Theme.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.down ? (Theme.isDark ? "#333" : "#eee") : "transparent"
                        border.color: Theme.divider
                        radius: 4
                    }
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 32
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: false }
                }

                Button {
                    text: qsTr("添加任务")
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 32
                    background: Rectangle {
                        color: parent.down ? Qt.darker(Theme.accent, 1.1) : Theme.accent
                        radius: 4
                    }
                    contentItem: Text {
                        text: qsTr("添加任务")
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: false }

                    onClicked: {
                        var options = {
                            "dir": pathField.text,
                            "split": splitField.value.toString()
                        }

                        if (renameField.text !== "" && (root.currentTab === 0 || root.torrentPaths.length <= 1)) {
                            options["out"] = renameField.text
                        }

                        var headerObj = {}
                        if (uaField.text !== "") headerObj["User-Agent"] = uaField.text
                        if (refererField.text !== "") headerObj["Referer"] = refererField.text
                        if (cookieField.text !== "") headerObj["Cookie"] = cookieField.text

                        var headerList = []
                        if (uaField.text !== "") headerList.push("User-Agent: " + uaField.text)
                        if (refererField.text !== "") headerList.push("Referer: " + refererField.text)
                        if (cookieField.text !== "") headerList.push("Cookie: " + cookieField.text)
                        if (headersField.text !== "") {
                            var lines = headersField.text.split("\n")
                            for(var h in lines) {
                                if(lines[h].trim() !== "") headerList.push(lines[h].trim())
                            }
                        }

                        if (headerList.length > 0) options["header"] = headerList
                        var hasTask = false

                        if (root.currentTab === 0 && linkInput.text.trim() !== "") {
                            var links = linkInput.text.split("\n")
                            for (var k = 0; k < links.length; ++k) {
                                var url = links[k].trim()
                                if(url !== "") {
                                    if (url.toLowerCase().indexOf(".m3u8") !== -1) {
                                        var m3u8Options = {
                                            "headers": headerObj,
                                            "key": keyField.text
                                        }
                                        Downloader.downloadM3u8(url, renameField.text, pathField.text, m3u8Options)
                                    } else {
                                        Downloader.addUri(url, options)
                                    }
                                    hasTask = true
                                }
                            }
                        }
                        else if (root.currentTab === 1 && root.torrentPaths.length > 0) {
                            for (var t = 0; t < root.torrentPaths.length; ++t) {
                                var tPath = root.torrentPaths[t]
                                var tOptions = JSON.parse(JSON.stringify(options))
                                if (root.torrentPaths.length > 1) {
                                    delete tOptions["out"]
                                }
                                Downloader.addTorrent(tPath, tOptions)
                            }
                            hasTask = true
                        }

                        if (hasTask) {
                            linkInput.text = ""
                            root.torrentPaths = []
                            renameField.text = ""
                            root.close()
                            root.taskAdded()
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: torrentPicker
        fileMode: FileDialog.OpenFiles
        nameFilters: [qsTr("Torrent files (*.torrent)")]
        onAccepted: {
            var paths = []
            for (var i = 0; i < files.length; i++) {
                paths.push(cleanFileUrl(files[i]))
            }
            root.torrentPaths = paths
        }
    }

    FolderDialog {
        id: folderPicker
        onAccepted: root.downloadPath = folder.toString().replace("file:///", "")
    }
}