import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0
import Nanami.UI.Components 1.0

Popup {
    id: root
    width: 500
    height: 320
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape

    property real startScale: 0.85
    property real endScale: 1
    property real startOpacity: 0
    property real endOpacity: 1

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "scale"; from: startScale; to: endScale; duration: 250; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; from: startOpacity; to: endOpacity; duration: 250; easing.type: Easing.OutCubic }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "scale"; from: endScale; to: startScale; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; from: endOpacity; to: startOpacity; duration: 200; easing.type: Easing.InCubic }
        }
    }

    signal minimizeToTray(bool rememberChoice)
    signal exitApp(bool rememberChoice)

    background: Rectangle {
        color: Theme.surface
        radius: 8
        border.color: Theme.divider
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        RowLayout {
            spacing: 10
            Text {
                text: "ⓘ"
                color: "#e6a23c"
                font.pixelSize: 24
            }
            Text {
                text: qsTr("关闭确认")
                color: Theme.textPrimary
                font.pixelSize: 18
                font.bold: true
            }
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("您想退出应用程序还是将其最小化到系统托盘？")
            color: Theme.textPrimary
            font.pixelSize: 16
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("提示：最小化到托盘后，应用程序将继续在后台运行。您可以从系统托盘还原窗口。")
            color: Theme.textSecondary
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }

        NCheckbox {
            id: rememberCb
            text: qsTr("记住我的选择")
        }

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
                text: qsTr("最小化到托盘")
                variant: "default"
                onClicked: root.minimizeToTray(rememberCb.checked)
            }

            NButton {
                text: qsTr("退出")
                variant: "primary"
                onClicked: root.exitApp(rememberCb.checked)
            }
        }
    }
}