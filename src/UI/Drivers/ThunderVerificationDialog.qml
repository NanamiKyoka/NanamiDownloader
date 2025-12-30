import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0

Popup {
    id: root
    width: 650
    height: 520
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: Overlay.overlay

    property string jsonData: ""

    background: Rectangle {
        color: Theme.isDark ? "#2b2b2b" : "#ffffff"
        radius: 8
        border.color: Theme.divider
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 15

        RowLayout {
            spacing: 10
            Text {
                text: "🔒"
                font.pixelSize: 24
            }
            Text {
                text: qsTr("迅雷安全验证 (1007)")
                color: Theme.textPrimary
                font.pixelSize: 18
                font.bold: true
            }
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("检测到风险登录，需要手动验证。请按照以下步骤操作：")
            color: Theme.textSecondary
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            color: "transparent"
            border.color: Theme.divider
            radius: 4

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5
                Text { text: "1. 复制以下代码"; color: Theme.accent; font.bold: true }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    TextArea {
                        text: root.jsonData
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        color: Theme.textPrimary
                        font.family: "Consolas"
                    }
                }
            }
        }

        Button {
            text: qsTr("复制代码")
            Layout.alignment: Qt.AlignRight
            onClicked: {
                Clipboard.copy(root.jsonData)
                window.showToast(qsTr("代码已复制"))
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            Text { text: "2. 打开验证页面并执行代码"; color: Theme.accent; font.bold: true }

            Text {
                text: "• 点击下方按钮打开验证页面（建议使用电脑浏览器）\n• 按 F12 打开控制台 (Console)\n• 输入 `reviewCb(` 并粘贴代码，最后输入 `)` 回车"
                color: Theme.textPrimary
                font.pixelSize: 13
                lineHeight: 1.4
            }

            Rectangle {
                color: Theme.isDark ? "#383838" : "#f0f0f0"
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 4
                Text {
                    anchors.centerIn: parent
                    text: "reviewCb(" + (root.jsonData.substring(0, 20)) + "...)"
                    font.family: "Consolas"
                    color: "gray"
                }
            }
        }

        Button {
            text: qsTr("打开验证页面 (https://i.xunlei.com/xlcaptcha/android.html)")
            Layout.fillWidth: true
            highlighted: true
            onClicked: Qt.openUrlExternally("https://i.xunlei.com/xlcaptcha/android.html")
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 12

            Button {
                text: qsTr("取消")
                flat: true
                onClicked: root.close()
            }

            Button {
                text: qsTr("我已完成验证")
                background: Rectangle {
                    color: "#28a745"
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                onClicked: {
                    root.close()
                    Downloader.loginThunder()
                }
            }
        }
    }

    // Auto-update verifyUrl from property
    onJsonDataChanged: {
        if (jsonData !== "") open()
    }
}