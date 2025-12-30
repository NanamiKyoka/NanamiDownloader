import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: isIdle ? 48 : 160
    height: 48
    radius: 24
    color: Theme.isDark ? "#2d2d2d" : "#ffffff"
    border.color: Theme.divider
    border.width: 1

    property bool isIdle: Downloader.totalDownloadSpeedString === "0 B/s"

    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        color: Theme.isDark ? "#50000000" : "#20000000"
        radius: 8
        samples: 16
        verticalOffset: 2
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: iconContainer
            width: 32
            height: 32
            x: root.isIdle ? (root.width - width) / 2 : 16
            y: (root.height - height) / 2

            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            Image {
                id: iconImg
                source: "qrc:/src/Icons/speed.svg"
                anchors.fill: parent
                visible: false
                fillMode: Image.PreserveAspectFit
            }

            ColorOverlay {
                anchors.fill: iconImg
                source: iconImg
                color: root.isIdle ? Theme.textSecondary : Theme.accent
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Item {
            anchors.left: iconContainer.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 20
            height: parent.height
            opacity: root.isIdle ? 0 : 1
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: 200 } }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 0

                Text {
                    text: "MAX"
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.accent
                    Layout.fillWidth: true
                }

                Text {
                    text: Downloader.totalDownloadSpeedString
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.accent
                    Layout.fillWidth: true
                }
            }
        }
    }
}