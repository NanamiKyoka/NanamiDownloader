import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0

Rectangle {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 60
    color: Theme.sidebar

    signal pageSelected(int index)
    signal infoClicked()
    signal restoreTorrentsClicked()

    property bool hasPendingTorrents: false

    component SidebarButton: Button {
        property string iconSource
        property bool isActive: false
        property bool isThemeBtn: false
        property bool isPendingBtn: false

        icon.source: iconSource
        icon.color: isPendingBtn ? "#FFA500" : (isActive ? "white" : "#aaaaaa")
        icon.width: 26
        icon.height: 26
        display: AbstractButton.IconOnly

        width: 40; height: 40
        opacity: isActive || isPendingBtn ? 1.0 : 0.7

        background: Rectangle {
            id: bg
            color: isActive ? "#007bff" : (isPendingBtn ? "#443300" : "transparent")
            radius: 8
            border.color: isPendingBtn ? "#FFA500" : "transparent"
            border.width: isPendingBtn ? 1 : 0
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                anchors.fill: parent
                color: "white"
                opacity: parent.hovered && !parent.isActive && !parent.isPendingBtn ? 0.1 : 0
                radius: 8
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        rotation: 0
        Behavior on rotation { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: false
        }
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        spacing: 15

        SidebarButton {
            id: homeBtn
            iconSource: "qrc:/src/Icons/home.svg"
            isActive: window.currentPage === 0
            onClicked: {
                root.pageSelected(0)
            }
        }

        SidebarButton {
            iconSource: "qrc:/src/Icons/add.svg"
            onClicked: newTaskDialog.open()
        }

        SidebarButton {
            id: pendingBtn
            iconSource: "qrc:/src/Icons/link.svg"
            visible: root.hasPendingTorrents
            isPendingBtn: true
            onClicked: root.restoreTorrentsClicked()

            SequentialAnimation {
                running: parent.visible
                loops: Animation.Infinite
                NumberAnimation { target: pendingBtn; property: "scale"; from: 1.0; to: 1.1; duration: 800; easing.type: Easing.InOutQuad }
                NumberAnimation { target: pendingBtn; property: "scale"; from: 1.1; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
            }
        }

        SidebarButton {
            id: baiduBtn
            iconSource: "qrc:/src/Icons/Drivers/baidu.svg"
            isActive: window.currentPage === 3
            visible: Settings.enableCloudMount && Settings.enableBaiduMount
            onClicked: {
                root.pageSelected(3)
            }
        }

        SidebarButton {
            id: thunderBtn
            iconSource: "qrc:/src/Icons/Drivers/thunder.svg"
            isActive: window.currentPage === 4
            visible: Settings.enableCloudMount && Settings.enableThunderMount
            onClicked: {
                root.pageSelected(4)
            }
        }
    }

    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        spacing: 15

        SidebarButton {
            id: themeBtn
            isThemeBtn: true
            iconSource: Theme.isDark ? "qrc:/src/Icons/moon.svg" : "qrc:/src/Icons/sun.svg"
            onClicked: {
                themeBtn.rotation += 360
                Theme.isDark = !Theme.isDark
            }
        }

        SidebarButton {
            id: settingsBtn
            iconSource: "qrc:/src/Icons/settings.svg"
            isActive: window.currentPage === 1
            onClicked:
            {
                root.pageSelected(1)
            }
        }

        SidebarButton {
            iconSource: "qrc:/src/Icons/info.svg"
            onClicked: root.infoClicked()
        }
    }
}