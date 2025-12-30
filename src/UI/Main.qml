import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.platform 1.1

import Nanami.Core 1.0
import Nanami.UI 1.0
import "qrc:/src/UI/Drivers"

ApplicationWindow {
    id: window
    visible: true
    width: 1100
    height: 700
    title: "NanamiDownloader"
    color: Theme.background

    property int currentPage: 0
    property bool isQuitting: false
    property string currentGid: ""

    function showToast(message) {
        toast.show(message)
    }

    function showDetails(gid) {
        currentGid = gid
        currentPage = 2
    }

    function closeDetails() {
        currentPage = 0
        currentGid = ""
    }

    Rectangle {
        id: toast
        z: 999
        width: toastText.implicitWidth + 40
        height: 40
        radius: 6
        color: Theme.isDark ? "#333" : "#d4edda"
        border.color: Theme.isDark ? "#444" : "#c3e6cb"
        border.width: 1
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: 0
        visible: opacity > 0

        property string message: ""

        RowLayout {
            anchors.centerIn: parent
            Text {
                id: toastText
                text: toast.message
                color: Theme.isDark ? "#fff" : "#155724"
                font.pixelSize: 14
            }
        }

        Behavior on opacity { NumberAnimation { duration: 300 } }

        Timer {
            id: toastTimer
            interval: 2000
            onTriggered: toast.opacity = 0
        }

        function show(msg) {
            message = msg
            opacity = 1
            toastTimer.restart()
        }
    }

    AboutDialog {
        id: aboutDialog
    }

    Window {
        id: customTrayMenu
        width: 140
        height: menuCol.implicitHeight + 10
        flags: Qt.Popup | Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint
        color: "transparent"
        visible: false

        component MenuBtn: Rectangle {
            id: btnRoot
            width: parent.width
            height: 36
            color: mouse.containsMouse ? (Theme.isDark ? "#3e3e3e" : "#eeeeee") : "transparent"
            radius: 4

            property string text
            property string iconSrc
            signal clicked()

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    customTrayMenu.close()
                    btnRoot.clicked()
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: btnRoot.text
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.divider
            border.width: 1
            radius: 6

            Column {
                id: menuCol
                anchors.centerIn: parent
                width: parent.width - 10
                spacing: 2

                MenuBtn {
                    text: qsTr("显示主界面")
                    onClicked: {
                        window.show()
                        window.raise()
                        window.requestActivate()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.divider
                    opacity: 0.5
                }

                MenuBtn {
                    text: qsTr("退出")
                    onClicked: {
                        window.isQuitting = true
                        window.saveWindowGeometry()
                        Qt.quit()
                    }
                }
            }
        }

        onActiveChanged: {
            if (!active) visible = false
        }
    }

    SystemTrayIcon {
        id: trayIcon
        visible: true
        icon.source: "qrc:/src/Icons/icon.svg"
        tooltip: "NanamiDownloader"

        onActivated: (reason) => {
            if (reason === SystemTrayIcon.Trigger) {
                if (window.visible && window.visibility !== Window.Minimized) {
                    window.hide()
                } else {
                    window.show()
                    window.raise()
                    window.requestActivate()
                }
            } else if (reason === SystemTrayIcon.Context) {
                var pos = CursorPosProvider.cursorPosition()
                var menuX = pos.x
                var menuY = pos.y

                if (menuY + customTrayMenu.height > Screen.desktopAvailableHeight) {
                    menuY -= customTrayMenu.height
                }

                customTrayMenu.x = menuX
                customTrayMenu.y = menuY
                customTrayMenu.show()
                customTrayMenu.requestActivate()
            }
        }
    }

    Component.onCompleted: {
        if (Settings.rememberWindowPosition) {
            if (Settings.windowWidth > 0 && Settings.windowHeight > 0) {
                window.width = Settings.windowWidth
                window.height = Settings.windowHeight
            }
            if (Settings.windowX >= 0 && Settings.windowY >= 0) {
                window.x = Settings.windowX
                window.y = Settings.windowY
            }
        }
        Downloader.startServices()
    }

    function saveWindowGeometry() {
        if (Settings.rememberWindowPosition && window.visibility !== Window.Minimized && window.visibility !== Window.Hidden) {
            Settings.windowWidth = window.width
            Settings.windowHeight = window.height
            Settings.windowX = window.x
            Settings.windowY = window.y
        }
    }

    onClosing: (close) => {
        if (isQuitting) {
            close.accepted = true
            return
        }

        if (Settings.confirmExit) {
            close.accepted = false
            closeConfirmDialog.open()
            return
        }

        if (Settings.closeAction === 1) {
            close.accepted = false
            window.hide()
        } else {
            saveWindowGeometry()
            close.accepted = true
            Qt.quit()
        }
    }

    property bool pendingTorrentsAvailable: false

    function checkPendingTorrents() {
        var count = 0
        for (var key in activeTorrentDialogs) {
            if (activeTorrentDialogs[key] && !activeTorrentDialogs[key].opened) {
                count++
            }
        }
        pendingTorrentsAvailable = count > 0
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            hasPendingTorrents: window.pendingTorrentsAvailable
            onPageSelected: (index) => {
                window.currentPage = index
            }
            onInfoClicked: {
                aboutDialog.open()
            }
            onRestoreTorrentsClicked: {
                for (var key in activeTorrentDialogs) {
                    if (activeTorrentDialogs[key] && !activeTorrentDialogs[key].opened) {
                        activeTorrentDialogs[key].open()
                        break
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Loader {
                anchors.fill: parent
                active: window.currentPage === 0
                sourceComponent: TaskListView {
                    anchors.fill: parent
                }
            }

            SettingsView {
                id: settingsView
                anchors.fill: parent
                opacity: window.currentPage === 1 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            Loader {
                anchors.fill: parent
                active: window.currentPage === 2
                sourceComponent: TaskDetailView {
                    anchors.fill: parent
                    gid: window.currentGid
                    onVisibleChanged: {
                        if (visible) {
                            state = "visible"
                        } else {
                            state = "hiddenRight"
                        }
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: window.currentPage === 3 && Settings.enableBaiduMount
                sourceComponent: BaiduView {
                    anchors.fill: parent
                }
            }

            Loader {
                anchors.fill: parent
                active: window.currentPage === 4 && Settings.enableThunderMount
                sourceComponent: ThunderView {
                    anchors.fill: parent
                }
            }
        }
    }

    SpeedWidget {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24

        opacity: (window.currentPage === 0 && window.visible) ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
    }

    NewTaskDialog {
        id: newTaskDialog
        anchors.centerIn: Overlay.overlay
    }

    Component {
        id: torrentDialogComponent
        AddTorrentDialog {
            onAccepted: (gid, savePath, selectedIndexes) => {
                Downloader.confirmTorrent(gid, savePath, selectedIndexes)
                showToast(qsTr("Torrent 已添加到队列"))
            }
            onRejected: (gid) => {
                Downloader.cancelTorrent(gid)
            }
            onClosed: {
                window.checkPendingTorrents()
            }
        }
    }

    property var activeTorrentDialogs: ({})

    function getOrCreateTorrentDialog(gid) {
        if (activeTorrentDialogs[gid]) {
            return activeTorrentDialogs[gid]
        }
        var dialog = torrentDialogComponent.createObject(window, { "gid": gid })
        var offset = Object.keys(activeTorrentDialogs).length * 20
        dialog.x += offset
        dialog.y += offset

        activeTorrentDialogs[gid] = dialog

        dialog.Component.onDestruction.connect(function() {
            delete activeTorrentDialogs[gid]
            window.checkPendingTorrents()
        })

        return dialog
    }

    OverwriteConfirmDialog {
        id: overwriteDialog
        onConfirm: (gid) => Downloader.overwriteTorrent(gid)
        onReject: (gid) => Downloader.continueTorrent(gid)
    }

    Connections {
        target: Downloader
        function onMagnetLinkAdded(gid) {
            var dialog = getOrCreateTorrentDialog(gid)
            dialog.showLoading(gid)
            window.show()
            window.raise()
            window.requestActivate()
        }
        function onTorrentMetadataLoaded(gid, name, size, files) {
            var dialog = getOrCreateTorrentDialog(gid)
            dialog.showMetadata(gid, name, size, files)
        }
        function onErrorOccurred(msg) {
            showToast(msg)
        }
        function onTaskExists(gid, name) {
            overwriteDialog.gid = gid
            overwriteDialog.taskName = name
            overwriteDialog.open()
        }
    }

    Connections {
        target: Clipboard
        function onLinkDetected(link) {
            if (Settings.monitorClipboard) {
                window.show()
                window.raise()
                window.requestActivate()

                if (!newTaskDialog.opened) {
                    newTaskDialog.open()
                }
                newTaskDialog.prefillLink(link)
            }
        }
    }

    Connections {
        target: SingleInstance
        function onRaiseWindowRequested() {
            window.show()
            window.raise()
            window.requestActivate()
        }
    }

    CloseConfirmDialog {
        id: closeConfirmDialog
        anchors.centerIn: Overlay.overlay
        onMinimizeToTray: (rememberChoice) => {
            if (rememberChoice) {
                Settings.confirmExit = false
                Settings.closeAction = 1
            }
            closeConfirmDialog.close()
            window.hide()
        }
        onExitApp: (rememberChoice) => {
            if (rememberChoice) {
                Settings.confirmExit = false
                Settings.closeAction = 2
            }
            window.isQuitting = true
            saveWindowGeometry()
            Qt.quit()
        }
    }
}