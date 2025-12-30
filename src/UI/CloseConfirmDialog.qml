import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

    component CustomCheckBox: CheckBox {
        id: ccb
        indicator: Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            x: ccb.leftPadding
            y: parent.height / 2 - height / 2
            radius: 4
            color: ccb.checked ? Theme.accent : "transparent"
            border.color: ccb.checked ? Theme.accent : (Theme.isDark ? "#666" : "#bbb")
            border.width: 1.5
            Text {
                anchors.centerIn: parent; text: "✓"; font.pixelSize: 14; font.bold: true; color: "white"; visible: ccb.checked
            }
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        contentItem: Text {
            text: ccb.text; font: ccb.font; color: Theme.textPrimary; verticalAlignment: Text.AlignVCenter; leftPadding: ccb.indicator.width + ccb.spacing
        }
    }

    background: Rectangle {
        color: Theme.isDark ? "#2b2b2b" : "#ffffff"
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

        CustomCheckBox {
            id: rememberCb
            text: qsTr("记住我的选择")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 12

            Button {
                text: qsTr("取消")
                flat: true
                Layout.preferredWidth: 80
                Layout.preferredHeight: 36
                background: Rectangle {
                    color: parent.hovered ? (Theme.isDark ? "#3e3e3e" : "#eeeeee") : "transparent"
                    border.color: Theme.divider
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.close()
            }

            Button {
                text: qsTr("最小化到托盘")
                Layout.preferredHeight: 36
                background: Rectangle {
                    color: parent.hovered ? (Theme.isDark ? "#3e3e3e" : "#eeeeee") : "transparent"
                    border.color: Theme.divider
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.minimizeToTray(rememberCb.checked)
            }

            Button {
                text: qsTr("退出")
                Layout.preferredWidth: 80
                Layout.preferredHeight: 36
                background: Rectangle {
                    color: parent.down ? "#d9363e" : "#ff4d4f"
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                onClicked: root.exitApp(rememberCb.checked)
            }
        }
    }
}