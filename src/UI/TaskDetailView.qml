import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.Core 1.0

Item {
    id: root
    width: 800
    height: 600

    x: parent ? parent.width : Screen.width
    y: parent ? (parent.height - height) / 2 : (Screen.height - height) / 2

    property real targetX: parent ? (parent.width - width) / 2 : (Screen.width - width) / 2
    property real offScreenX: parent ? parent.width : Screen.width

    states: [
        State {
            name: "hidden"
            when: !root.visible
            PropertyChanges { target: root; x: root.offScreenX; opacity: 0 }
        },
        State {
            name: "visible"
            when: root.visible
            PropertyChanges { target: root; x: root.targetX; opacity: 1 }
        },
        State {
            name: "hiddenRight"
            PropertyChanges { target: root; x: root.offScreenX; opacity: 0 }
        }
    ]

    transitions: [
        Transition {
            from: "hidden"
            to: "visible"
            NumberAnimation { properties: "x,opacity"; duration: 300; easing.type: Easing.OutCubic }
        },
        Transition {
            from: "visible"
            to: "hidden"
            NumberAnimation { properties: "x,opacity"; duration: 300; easing.type: Easing.InCubic }
        },
        Transition {
            from: "visible"
            to: "hiddenRight"
            NumberAnimation { properties: "x,opacity"; duration: 300; easing.type: Easing.InCubic }
        }
    ]

    property string gid: ""
    property var details: ({})
    property var folderStates: ({})

    property var trackerWidths: [300, 100, 80, 80, 300]
    property var peerWidths: [150, 250, 80, 80, 100, 100]
    property var contentWidths: [400, 100, 100, 100]

    onVisibleChanged: {
        if (visible) {
            state = "visible"
        }
    }

    function getColumnWidth(type, index) {
        if (type === "tracker") return trackerWidths[index]
        if (type === "peer") return peerWidths[index]
        if (type === "content") return contentWidths[index]
        return 100
    }

    function setColumnWidth(type, index, newWidth) {
        var arr = []
        var source = []
        if (type === "tracker") source = trackerWidths
        else if (type === "peer") source = peerWidths
        else source = contentWidths

        for(var i=0; i<source.length; i++) arr.push(source[i])
        arr[index] = newWidth

        if (type === "tracker") trackerWidths = arr
        else if (type === "peer") peerWidths = arr
        else contentWidths = arr
    }

    function getTotalWidth(type) {
        var arr = (type === "tracker") ? trackerWidths : ((type === "peer") ? peerWidths : contentWidths)
        var sum = 0
        for(var i=0; i<arr.length; i++) sum += arr[i]
        return Math.max(sum, root.width)
    }

    Timer {
        interval: 2000
        running: root.visible && root.gid !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.gid !== "") {
                var d = Downloader.getTaskDetails(root.gid)
                root.details = d
                refreshModels()
            }
        }
    }

    ListModel { id: trackerModel }
    ListModel { id: peerModel }
    ListModel { id: fileModel }

    function refreshModels() {
        if (details.trackers) {
            updateModel(trackerModel, details.trackers, ["url", "status", "seeds", "peers", "downloaded", "message"])
        }
        if (details.peers) {
            updateModel(peerModel, details.peers, ["ip", "client", "flags", "progress", "downSpeed", "upSpeed"])
        }
        if (details.files) {
            var files = details.files
            var rootItem = { name: "root", children: [], type: "root", checked: true, expanded: true, path: "root" }

            function getFolder(pathParts, parent) {
                var current = parent;
                var currentPath = parent.path;
                for (var i = 0; i < pathParts.length; i++) {
                    var part = pathParts[i];
                    currentPath += "/" + part;
                    var found = null;
                    if (!current.children) current.children = [];
                    for(var j=0; j<current.children.length; j++) {
                        if (current.children[j].name === part && current.children[j].type === "folder") {
                            found = current.children[j];
                            break;
                        }
                    }
                    if (!found) {
                        var isExp = true;
                        if (folderStates[currentPath] !== undefined) isExp = folderStates[currentPath];

                        found = { name: part, children: [], type: "folder", checked: true, expanded: isExp, path: currentPath };
                        current.children.push(found);
                    }
                    current = found;
                }
                return current;
            }

            for(var i=0; i<files.length; i++) {
                var f = files[i];
                var parts = f.name.replace(/\\/g, "/").split("/");
                var fileName = parts.pop();
                var folder = getFolder(parts, rootItem);

                folder.children.push({
                    name: fileName,
                    size: f.size,
                    progress: f.progress,
                    priority: f.priority,
                    type: "file",
                    index: f.index,
                    checked: f.checked,
                    expanded: false,
                    path: (folder.path ? folder.path + "/" : "") + fileName
                });
            }

            var flatList = []
            function traverse(node, depth) {
                if (node.type !== "root") {
                    flatList.push({
                        "name": node.name,
                        "size": node.size || "",
                        "progress": node.progress || "",
                        "priority": node.priority || "",
                        "depth": depth,
                        "type": node.type,
                        "expanded": node.expanded !== undefined ? node.expanded : false,
                        "hasChildren": !!(node.children && node.children.length > 0),
                        "index": node.index === undefined ? -1 : node.index,
                        "checked": node.checked === undefined ? false : node.checked,
                        "nodePath": node.path
                    })
                }
                if (node.type === "root" || (node.expanded && node.children)) {
                    var d = (node.type === "root") ? -1 : depth;
                    for(var k=0; k<node.children.length; k++) {
                        traverse(node.children[k], d + 1)
                    }
                }
            }
            traverse(rootItem, -1)

            fileModel.clear()
            for(var m=0; m<flatList.length; m++) {
                fileModel.append(flatList[m])
            }
        }
    }

    function updateModel(model, data, fields) {
        if (model.count !== data.length) {
            model.clear()
            for (var i=0; i<data.length; i++) {
                model.append(data[i])
            }
        } else {
            for (var i=0; i<data.length; i++) {
                for (var j=0; j<fields.length; j++) {
                    var field = fields[j]
                    if (model.get(i)[field] !== data[i][field]) {
                        model.setProperty(i, field, data[i][field])
                    }
                }
            }
        }
    }

    component ResizableHeader: Rectangle {
        id: headerRoot
        property var modelLabels: []
        property string columnType: ""

        color: Theme.surface
        height: 30

        Row {
            anchors.fill: parent
            Repeater {
                model: modelLabels
                delegate: Rectangle {
                    height: 30
                    width: root.getColumnWidth(headerRoot.columnType, index)
                    color: "transparent"
                    clip: true

                    Text {
                        text: modelData
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: 1
                        height: 20
                        color: Theme.divider
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: index < modelLabels.length - 1
                    }

                    MouseArea {
                        width: 10
                        height: parent.height
                        anchors.right: parent.right
                        anchors.rightMargin: -5
                        cursorShape: Qt.SplitHCursor
                        preventStealing: true

                        property int startX: 0
                        property int startWidth: 0

                        onPressed: {
                            startX = mapToItem(headerRoot, mouseX, 0).x
                            startWidth = parent.width
                        }

                        onPositionChanged: {
                            if (pressed) {
                                var currentX = mapToItem(headerRoot, mouseX, 0).x
                                var delta = currentX - startX
                                var newW = Math.max(40, startWidth + delta)
                                root.setColumnWidth(headerRoot.columnType, index, newW)
                            }
                        }
                    }
                }
            }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.divider; anchors.bottom: parent.bottom }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: Theme.surface
                border.color: Theme.divider
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: [qsTr("普通"), "Tracker", qsTr("用户"), qsTr("内容")]
                        delegate: Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 100
                            color: tabBar.currentIndex === index ? (Theme.isDark ? "#333" : "#e6f2ff") : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: tabBar.currentIndex === index ? Theme.accent : Theme.textPrimary
                                font.bold: tabBar.currentIndex === index
                            }

                            Rectangle {
                                width: parent.width
                                height: 3
                                color: Theme.accent
                                anchors.bottom: parent.bottom
                                visible: tabBar.currentIndex === index
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: tabBar.currentIndex = index
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("返回")
                        flat: true
                        Layout.rightMargin: 10
                        onClicked: {
                            root.state = "hiddenRight"
                            closeTimer.start()
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.textSecondary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle { color: "transparent" }
                    }

                    Timer {
                        id: closeTimer
                        interval: 300
                        onTriggered: window.closeDetails()
                    }
                }
            }

            SwipeView {
                id: tabBar
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: false

                Item {
                    ScrollView {
                        anchors.fill: parent
                        contentWidth: parent.width

                        ColumnLayout {
                            width: parent.width
                            anchors.margins: 20
                            spacing: 15

                            GroupBox {
                                title: qsTr("信息")
                                Layout.fillWidth: true
                                Layout.leftMargin: 20; Layout.rightMargin: 20; Layout.topMargin: 20
                                background: Rectangle { color: "transparent"; border.color: Theme.divider; radius: 4 }
                                label: Text { text: parent.title; color: Theme.textPrimary; font.bold: true }

                                GridLayout {
                                    columns: 4
                                    rowSpacing: 10
                                    columnSpacing: 20

                                    Text { text: qsTr("总大小:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.totalSize : "-"; color: Theme.textPrimary }

                                    Text { text: qsTr("区块:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? (root.details.general.completedPieces + " / " + root.details.general.pieces) : "-"; color: Theme.textPrimary }

                                    Text { text: qsTr("添加于:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.addedOn : "-"; color: Theme.textPrimary }

                                    Text { text: qsTr("完成于:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.completedOn : "-"; color: Theme.textPrimary }

                                    Text { text: "Info Hash:"; color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.hash : "-"; color: Theme.textPrimary; Layout.columnSpan: 3; elide: Text.ElideRight; Layout.fillWidth: true }

                                    Text { text: qsTr("保存路径:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.savePath : "-"; color: Theme.textPrimary; Layout.columnSpan: 3; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }

                            GroupBox {
                                title: qsTr("传输")
                                Layout.fillWidth: true
                                Layout.leftMargin: 20; Layout.rightMargin: 20
                                background: Rectangle { color: "transparent"; border.color: Theme.divider; radius: 4 }
                                label: Text { text: parent.title; color: Theme.textPrimary; font.bold: true }

                                GridLayout {
                                    columns: 4
                                    rowSpacing: 10
                                    columnSpacing: 20

                                    Text { text: qsTr("已下载:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.downloaded : "-"; color: Theme.textPrimary }

                                    Text { text: qsTr("已上传:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.uploaded : "-"; color: Theme.textPrimary }

                                    Text { text: qsTr("下载速度:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.downloadSpeed : "-"; color: Theme.textPrimary }

                                    Text { text: qsTr("上传速度:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.uploadSpeed : "-"; color: Theme.textPrimary }

                                    Text { text: qsTr("分享率:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? root.details.general.shareRatio : "-"; color: Theme.textPrimary }

                                    Text { text: qsTr("连接:"); color: Theme.textSecondary }
                                    Text { text: root.details.general ? (root.details.general.connections + " (" + qsTr("种子") + ": " + root.details.general.seeds + ", " + qsTr("用户") + ": " + root.details.general.peers + ")") : "-"; color: Theme.textPrimary }
                                }
                            }
                        }
                    }
                }

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        ResizableHeader {
                            Layout.fillWidth: true
                            modelLabels: ["URL", qsTr("状态"), qsTr("做种"), qsTr("用户"), qsTr("信息")]
                            columnType: "tracker"
                        }

                        ListView {
                            id: trackerList
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: trackerModel
                            clip: true
                            contentWidth: root.getTotalWidth("tracker")

                            delegate: Rectangle {
                                width: trackerList.contentWidth
                                height: 30
                                color: index % 2 === 0 ? (Theme.isDark ? "#2b2b2b" : "#f9f9f9") : "transparent"
                                Row {
                                    height: parent.height
                                    Item { width: root.trackerWidths[0]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.url; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.trackerWidths[1]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.status; elide: Text.ElideRight; color: model.status === "Error" ? "#ff4d4f" : Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.trackerWidths[2]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.seeds; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.trackerWidths[3]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.peers; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.trackerWidths[4]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.message; elide: Text.ElideRight; color: Theme.textSecondary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                }
                            }
                            ScrollBar.horizontal: ScrollBar { active: true }
                            ScrollBar.vertical: ScrollBar { active: true }
                        }
                    }
                }

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        ResizableHeader {
                            Layout.fillWidth: true
                            modelLabels: ["IP", qsTr("客户端"), "Flags", qsTr("进度"), qsTr("↓ 速度"), qsTr("↑ 速度")]
                            columnType: "peer"
                        }

                        ListView {
                            id: peerList
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: peerModel
                            clip: true
                            contentWidth: root.getTotalWidth("peer")

                            delegate: Rectangle {
                                width: peerList.contentWidth
                                height: 30
                                color: index % 2 === 0 ? (Theme.isDark ? "#2b2b2b" : "#f9f9f9") : "transparent"
                                Row {
                                    height: parent.height
                                    Item { width: root.peerWidths[0]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.ip; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.peerWidths[1]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.client; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.peerWidths[2]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.flags; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.peerWidths[3]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.progress; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.peerWidths[4]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.downSpeed; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.peerWidths[5]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.upSpeed; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                }
                            }
                            ScrollBar.horizontal: ScrollBar { active: true }
                            ScrollBar.vertical: ScrollBar { active: true }
                        }
                    }
                }

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        ResizableHeader {
                            Layout.fillWidth: true
                            modelLabels: [qsTr("名称"), qsTr("大小"), qsTr("进度"), qsTr("优先级")]
                            columnType: "content"
                        }

                        ListView {
                            id: contentList
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: fileModel
                            clip: true
                            contentWidth: root.getTotalWidth("content")

                            delegate: Rectangle {
                                width: contentList.contentWidth
                                height: 30
                                color: index % 2 === 0 ? (Theme.isDark ? "#2b2b2b" : "#f9f9f9") : "transparent"
                                Row {
                                    height: parent.height

                                    Item {
                                        width: root.contentWidths[0]; height: parent.height
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 5
                                            Item { width: 10 + model.depth * 20 }

                                            Item {
                                                width: 15; height: 15
                                                Layout.alignment: Qt.AlignVCenter
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: model.hasChildren ? (model.expanded ? "▼" : "▶") : ""
                                                    color: Theme.textSecondary
                                                    font.pixelSize: 10
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (model.hasChildren) {
                                                            folderStates[model.nodePath] = !model.expanded
                                                            refreshModels();
                                                        }
                                                    }
                                                }
                                            }

                                            CheckBox {
                                                checked: model.checked
                                                enabled: model.type === "file"
                                                Layout.alignment: Qt.AlignVCenter
                                                implicitHeight: 18
                                                implicitWidth: 18
                                                onClicked: Downloader.setFilePriority(root.gid, model.index, checked)

                                                indicator: Rectangle {
                                                    width: 16
                                                    height: 16
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    radius: 3
                                                    color: parent.checked ? Theme.accent : "transparent"
                                                    border.color: parent.checked ? Theme.accent : Theme.textSecondary
                                                    Text {
                                                        anchors.centerIn: parent; text: "✓"; font.pixelSize: 12; color: "white"; visible: parent.parent.checked
                                                    }
                                                }
                                            }

                                            Text {
                                                text: (model.type === "folder" ? "📁 " : "") + model.name
                                                elide: Text.ElideMiddle
                                                color: Theme.textPrimary
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }
                                    }

                                    Item { width: root.contentWidths[1]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.size; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.contentWidths[2]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.progress; elide: Text.ElideRight; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                    Item { width: root.contentWidths[3]; height: parent.height; Text { anchors.fill: parent; anchors.leftMargin: 10; text: model.priority; elide: Text.ElideRight; color: model.priority === "Ignored" ? Theme.textSecondary : Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter } }
                                }
                            }
                            ScrollBar.horizontal: ScrollBar { active: true }
                            ScrollBar.vertical: ScrollBar { active: true }
                        }
                    }
                }
            }
        }
    }
}