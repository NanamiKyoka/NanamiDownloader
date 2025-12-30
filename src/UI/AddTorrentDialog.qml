import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform 1.1
import QtQuick.Controls.Basic

Popup {
    id: root
    width: 800
    height: 600
    modal: false
    focus: true
    closePolicy: Popup.NoAutoClose
    anchors.centerIn: Overlay.overlay

    property string gid: ""
    property string torrentName: ""
    property string torrentSize: ""
    property string selectedSizeStr: "0 B"
    property var fileList: []
    property bool isLoading: true
    property var rootTree: null
    property bool isBaidu: false

    signal accepted(string gid, string savePath, var selectedIndexes)
    signal rejected(string gid)

    ListModel { id: displayModel }

    function formatSize(bytes) {
        if (bytes === 0) return "0 B";
        var k = 1024;
        var sizes = ["B", "KB", "MB", "GB", "TB"];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return (bytes / Math.pow(k, i)).toFixed(2) + " " + sizes[i];
    }

    function showLoading(tGid) {
        gid = tGid
        torrentName = qsTr("正在获取元数据...")
        torrentSize = "--"
        selectedSizeStr = "--"
        fileList = []
        displayModel.clear()
        isLoading = true
        isBaidu = false
        open()
    }

    function showMetadata(tGid, tName, tSize, tFiles) {
        if (gid !== "" && gid !== tGid) return;

        gid = tGid
        torrentName = tName
        torrentSize = tSize
        fileList = tFiles
        isBaidu = gid.startsWith("baidu_")

        var rootItem = { name: "root", children: [], type: "root", checked: true, expanded: true, path: "" }

        function getFolder(pathParts) {
            var current = rootItem;
            var currentPath = "";
            for (var i = 0; i < pathParts.length; i++) {
                var part = pathParts[i];
                currentPath += (currentPath ? "/" : "") + part;
                var found = null;
                for(var j=0; j<current.children.length; j++) {
                    if (current.children[j].name === part && current.children[j].type === "folder") {
                        found = current.children[j];
                        break;
                    }
                }
                if (!found) {
                    found = { name: part, children: [], type: "folder", checked: true, expanded: true, path: currentPath };
                    current.children.push(found);
                }
                current = found;
            }
            return current;
        }

        for(var i=0; i<tFiles.length; i++) {
            var f = tFiles[i];
            var pathStr = f.path.replace(/\\/g, "/");
            if (pathStr.startsWith("/")) pathStr = pathStr.substring(1);

            var parts = pathStr.split("/");
            var fileName = parts.pop();
            var folder = getFolder(parts);

            folder.children.push({
                name: fileName,
                index: f.index,
                size: f.sizeStr,
                bytes: f.size,
                type: "file",
                checked: true,
                expanded: false,
                path: (folder.path ? folder.path + "/" : "") + fileName
            });
        }

        rootTree = rootItem;
        calculateStats();
        refreshDisplay();

        isLoading = false
        if (!opened) open()
    }

    function calculateStats() {
        if (!rootTree) return;
        var total = 0;
        function traverse(node) {
            if (node.type === "file" && node.checked) {
                total += (node.bytes || 0);
            }
            if (node.children) {
                for(var i=0; i<node.children.length; i++) traverse(node.children[i]);
            }
        }
        traverse(rootTree);
        selectedSizeStr = formatSize(total);
    }

    function refreshDisplay() {
        displayModel.clear();
        if (!rootTree) return;

        function traverse(node, depth) {
            if (node.type !== "root") {
                displayModel.append({
                    "name": node.name,
                    "type": node.type,
                    "depth": depth,
                    "expanded": node.expanded,
                    "checked": node.checked,
                    "size": node.size || "",
                    "index": node.index === undefined ? -1 : node.index,
                    "hasChildren": !!(node.children && node.children.length > 0),
                    "nodePath": node.path
                });
            }

            if (node.type === "root" || (node.expanded && node.children)) {
                var d = (node.type === "root") ? -1 : depth;
                for(var i=0; i<node.children.length; i++) {
                    traverse(node.children[i], d + 1);
                }
            }
        }

        traverse(rootTree, 0);
    }

    function findNodeByPath(path) {
        if (!rootTree) return null;
        function search(node) {
            if (node.path === path) return node;
            if (node.children) {
                for(var i=0; i<node.children.length; i++) {
                    var res = search(node.children[i]);
                    if (res) return res;
                }
            }
            return null;
        }
        if (path === "") return rootTree;
        return search(rootTree);
    }

    function toggleNodeCheck(node, state) {
        node.checked = state;
        if (node.children) {
            for(var i=0; i<node.children.length; i++) {
                toggleNodeCheck(node.children[i], state);
            }
        }
    }

    function destroyDialog() {
        root.destroy()
    }

    background: Rectangle {
        color: Theme.surface
        radius: 10
        border.color: Theme.divider
        border.width: 1

        MouseArea {
            anchors.fill: parent
            property point lastMousePos
            onPressed: { lastMousePos = Qt.point(mouseX, mouseY) }
            onPositionChanged: {
                if (pressed) {
                    var deltaX = mouseX - lastMousePos.x
                    var deltaY = mouseY - lastMousePos.y
                    root.x += deltaX
                    root.y += deltaY
                }
            }
        }
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
                        text: "⬇"
                        color: "white"
                        font.pixelSize: 22
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: root.isBaidu ? qsTr("百度网盘下载") : qsTr("Torrent 添加")
                        color: Theme.textPrimary
                        font.bold: true
                        font.pixelSize: 16
                    }
                    Text {
                        text: root.isLoading ? qsTr("正在获取元数据...") : qsTr("选择文件并开始下载")
                        color: Theme.textSecondary
                        font.pixelSize: 12
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.isLoading
                spacing: 20

                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: root.isLoading
                }
                Text {
                    text: qsTr("正在解析...")
                    color: Theme.textSecondary
                    font.pixelSize: 14
                }
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("后台隐藏")
                    palette.button: Theme.surface
                    palette.buttonText: Theme.textPrimary
                    palette.highlight: Theme.accent
                    onClicked: {
                        root.close()
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15
                visible: !root.isLoading

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("名称:"); color: Theme.textSecondary; width: 60 }
                    TextField {
                        text: root.torrentName
                        readOnly: true
                        Layout.fillWidth: true
                        color: Theme.textPrimary
                        background: InputBackground {}
                        leftPadding: 10
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("保存到:"); color: Theme.textSecondary; width: 60 }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        TextField {
                            id: pathField
                            text: Settings.downloadPath
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
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: qsTr("文件列表 (已选 %1 / 总计 %2)").arg(root.selectedSizeStr).arg(root.torrentSize)
                        font.bold: true;
                        color: Theme.textPrimary
                    }
                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("全选")
                        Layout.preferredHeight: 28
                        Layout.preferredWidth: 60
                        background: Rectangle {
                            color: parent.hovered ? (Theme.isDark ? "#444" : "#ddd") : "transparent"
                            border.color: Theme.divider
                            border.width: 1
                            radius: 4
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.textPrimary
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (rootTree) toggleNodeCheck(rootTree, true);
                            calculateStats();
                            refreshDisplay();
                        }
                    }
                    Button {
                        text: qsTr("全不选")
                        Layout.preferredHeight: 28
                        Layout.preferredWidth: 60
                        background: Rectangle {
                            color: parent.hovered ? (Theme.isDark ? "#444" : "#ddd") : "transparent"
                            border.color: Theme.divider
                            border.width: 1
                            radius: 4
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.textPrimary
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (rootTree) toggleNodeCheck(rootTree, false);
                            calculateStats();
                            refreshDisplay();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.isDark ? "#2b2b2b" : "#f9f9f9"
                    border.color: Theme.divider
                    radius: 4

                    ListView {
                        id: fileView
                        anchors.fill: parent
                        anchors.margins: 5
                        clip: true
                        model: displayModel

                        delegate: RowLayout {
                            width: fileView.width
                            height: 28
                            spacing: 5

                            Item { width: model.depth * 20 }

                            Item {
                                width: 20
                                height: 20
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
                                            var node = findNodeByPath(model.nodePath);
                                            if (node) {
                                                node.expanded = !node.expanded;
                                                refreshDisplay();
                                            }
                                        }
                                    }
                                }
                            }

                            CheckBox {
                                checked: model.checked
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: 18
                                implicitWidth: 18
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
                                onClicked: {
                                    var node = findNodeByPath(model.nodePath);
                                    if (node) {
                                        toggleNodeCheck(node, checked);
                                        calculateStats();
                                        refreshDisplay();
                                    }
                                }
                            }

                            Text {
                                text: (model.type === "folder" ? "📁 " : "") + model.name
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                                color: Theme.textPrimary
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: model.size
                                color: Theme.textSecondary
                                font.pixelSize: 12
                                Layout.rightMargin: 10
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        ScrollBar.vertical: ScrollBar { active: true }
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
                spacing: 10

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("取消")
                    flat: true
                    onClicked: {
                        root.rejected(root.gid)
                        root.close()
                        root.destroyDialog()
                    }
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
                }

                Button {
                    text: qsTr("立即下载")
                    enabled: !root.isLoading
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 32
                    background: Rectangle {
                        color: parent.enabled ? (parent.down ? Qt.darker(Theme.accent, 1.1) : Theme.accent) : (Theme.isDark ? "#444" : "#ccc")
                        radius: 4
                    }
                    contentItem: Text {
                        text: qsTr("立即下载")
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        var indexes = []
                        function collectIndexes(node) {
                            if (node.type === "file" && node.checked) {
                                indexes.push(node.index);
                            }
                            if (node.children) {
                                for(var i=0; i<node.children.length; i++) {
                                    collectIndexes(node.children[i]);
                                }
                            }
                        }
                        if (rootTree) collectIndexes(rootTree);

                        root.accepted(root.gid, pathField.text, indexes)
                        root.close()
                        root.destroyDialog()
                    }
                }
            }
        }
    }

    FolderDialog {
        id: folderPicker
        onAccepted: pathField.text = folder.toString().replace("file:///", "")
    }
}