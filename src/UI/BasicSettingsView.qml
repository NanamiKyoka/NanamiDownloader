import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform 1.1

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    component SettingCard: Rectangle {
        id: cardRoot
        Layout.fillWidth: true
        Layout.preferredHeight: contentCol.height + 30
        color: Theme.surface
        radius: 8
        border.color: Theme.divider
        border.width: 1
        default property alias content: contentCol.data
        property string title: ""

        ColumnLayout {
            id: contentCol
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 15; spacing: 15
            Text { text: cardRoot.title; font.bold: true; font.pixelSize: 14; color: Theme.textPrimary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }
        }
    }

    component SettingRow: RowLayout { Layout.fillWidth: true; spacing: 10 }

    component BlueSwitch: Switch {
        indicator: Rectangle {
            implicitWidth: 40; implicitHeight: 22; radius: 11
            color: parent.checked ? "#007bff" : (Theme.isDark ? "#444" : "#ddd")
            Rectangle { x: parent.parent.checked ? parent.width-width-2 : 2; y: 2; width: 18; height: 18; radius: 9; color: "#ffffff"; Behavior on x { NumberAnimation{duration:150} } }
        }
    }

    component CustomSwitch: Switch {
        indicator: Rectangle {
            implicitWidth: 40; implicitHeight: 22; radius: 11
            color: parent.checked ? Theme.accent : (Theme.isDark ? "#444" : "#ddd")
            Rectangle { x: parent.parent.checked ? parent.width-width-2 : 2; y: 2; width: 18; height: 18; radius: 9; color: "#ffffff"; Behavior on x { NumberAnimation{duration:150} } }
        }
        contentItem: Text {
            text: parent.text; font: parent.font; opacity: parent.enabled?1.0:0.3; color: Theme.textPrimary; verticalAlignment: Text.AlignVCenter; leftPadding: parent.indicator.width+parent.spacing
            wrapMode: Text.WordWrap
        }
    }

    component SettingInput: TextField {
        signal commit()
        color: Theme.textPrimary
        background: Rectangle {
            color: parent.activeFocus?Theme.surface:(Theme.isDark?"#2b2b2b":"#f5f5f5");
            border.color: parent.activeFocus?Theme.accent:Theme.divider;
            border.width: parent.activeFocus?2:1;
            radius: 4
            Behavior on border.color { ColorAnimation { duration: 200 } }
            Behavior on border.width { NumberAnimation { duration: 200 } }
        }
        selectByMouse: true; leftPadding: 10
        onEditingFinished: commit()
    }

    Flickable {
        anchors.fill: parent
        contentHeight: settingsCol.height + 60
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.DragAndOvershootBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: settingsCol
            width: Math.min(parent.width - 60, 800)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 30; spacing: 20

            Text { text: qsTr("基本设置"); font.bold: true; font.pixelSize: 24; color: Theme.textPrimary; Layout.fillWidth: true; wrapMode: Text.WordWrap }

            SettingCard {
                title: qsTr("应用行为")
                SettingRow {
                    Text { text: qsTr("界面语言"); color: Theme.textPrimary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    ComboBox {
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 32
                        model: ["简体中文", "繁体中文", "English", "日本語", "한국어"]
                        currentIndex: {
                            if (Settings.language === "zh_TW") return 1
                            if (Settings.language === "en_US") return 2
                            if (Settings.language === "ja_JP") return 3
                            if (Settings.language === "ko_KR") return 4
                            return 0
                        }
                        onActivated: function(index) {
                            if (index === 0) Settings.setLanguage("zh_CN")
                            else if (index === 1) Settings.setLanguage("zh_TW")
                            else if (index === 2) Settings.setLanguage("en_US")
                            else if (index === 3) Settings.setLanguage("ja_JP")
                            else if (index === 4) Settings.setLanguage("ko_KR")
                        }

                        delegate: ItemDelegate {
                            width: parent.width
                            contentItem: Text {
                                text: modelData
                                color: highlighted ? "white" : Theme.textPrimary
                                font: parent.font
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: highlighted ? Theme.accent : (Theme.isDark ? "#2b2b2b" : "#ffffff")
                            }
                        }
                        contentItem: Text {
                            leftPadding: 10
                            rightPadding: parent.indicator.width + parent.spacing
                            text: parent.displayText
                            font: parent.font
                            color: Theme.textPrimary
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        background: Rectangle {
                            color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"
                            border.color: parent.activeFocus ? Theme.accent : Theme.divider
                            border.width: 1
                            radius: 4
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
                SettingRow {
                    Text { text: qsTr("恢复未完成的任务"); color: Theme.textPrimary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    CustomSwitch { checked: Settings.resumeTasks; onToggled: Settings.setResumeTasks(checked) }
                }
                SettingRow {
                    Text { text: qsTr("显示关闭确认"); color: Theme.textPrimary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    CustomSwitch { checked: Settings.confirmExit; onToggled: { Settings.setConfirmExit(checked); if(checked) Settings.setCloseAction(0) } }
                }
                SettingRow {
                    Text { text: qsTr("记住窗口位置"); color: Theme.textPrimary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    CustomSwitch { checked: Settings.rememberWindowPosition; onToggled: Settings.setRememberWindowPosition(checked) }
                }
                SettingRow {
                    Text { text: qsTr("开机自启动"); color: Theme.textPrimary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    CustomSwitch { checked: Settings.autoStart; onToggled: Settings.setAutoStart(checked) }
                }
            }

            SettingCard {
                title: qsTr("下载设置")
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8
                    Text { text: qsTr("默认下载路径"); color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    RowLayout {
                        Layout.fillWidth: true
                        SettingInput { text: Settings.downloadPath; Layout.fillWidth: true; readOnly: true }
                        Button {
                            width: 40; icon.source: "qrc:/src/Icons/folder.svg"; icon.color: Theme.textPrimary; icon.width: 18; icon.height: 18; display: AbstractButton.IconOnly
                            background: Rectangle { color: parent.hovered?(Theme.isDark?"#444":"#ddd"):"transparent"; radius: 4; border.color: Theme.divider; border.width: 1 }
                            onClicked: folderDialog.open()
                        }
                    }
                }
            }

            SettingCard {
                title: qsTr("网络代理")

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 10

                    Text { text: qsTr("Aria2 代理"); color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    RowLayout {
                        Layout.fillWidth: true
                        SettingInput {
                            text: Settings.aria2ProxyUrl
                            placeholderText: qsTr("http://[user:pass@]host:port (仅支持 HTTP))")
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            onCommit: { Settings.setAria2ProxyUrl(text); Downloader.applyGlobalSettings() }
                        }
                        BlueSwitch {
                            checked: Settings.aria2ProxyEnabled
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: parent.height
                            onToggled: { Settings.setAria2ProxyEnabled(checked); Downloader.applyGlobalSettings() }
                        }
                    }

                    Text { text: qsTr("M3U8 代理"); color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    RowLayout {
                        Layout.fillWidth: true
                        SettingInput {
                            text: Settings.m3u8ProxyUrl
                            placeholderText: qsTr("http://[user:pass@]host:port (推荐 HTTP)")
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            onCommit: Settings.setM3u8ProxyUrl(text)
                        }
                        BlueSwitch {
                            checked: Settings.m3u8ProxyEnabled
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: parent.height
                            onToggled: Settings.setM3u8ProxyEnabled(checked)
                        }
                    }

                    Text { text: qsTr("BT 代理"); color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    RowLayout {
                        Layout.fillWidth: true
                        SettingInput {
                            text: Settings.btProxyUrl
                            placeholderText: qsTr("http://[user:pass@]host:port 或 socks5://[user:pass@]host:port")
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            onCommit: { Settings.setBtProxyUrl(text); Downloader.applyGlobalSettings() }
                        }
                        BlueSwitch {
                            checked: Settings.btProxyEnabled
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: parent.height
                            onToggled: { Settings.setBtProxyEnabled(checked); Downloader.applyGlobalSettings() }
                        }
                    }
                }
            }

            SettingCard {
                title: qsTr("智能监听")
                SettingRow {
                    Text { text: qsTr("自动监听剪贴板链接"); color: Theme.textPrimary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    CustomSwitch { checked: Settings.monitorClipboard; onToggled: Settings.setMonitorClipboard(checked) }
                }
            }
        }
    }

    FolderDialog {
        id: folderDialog
        onAccepted: Settings.setDownloadPath(folder.toString().replace("file:///", ""))
    }
}