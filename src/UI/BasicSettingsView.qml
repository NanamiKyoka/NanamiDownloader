import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform 1.1
import Nanami.UI.Components 1.0

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    component SettingRow: RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        spacing: Theme.spacingMD
    }

    Flickable {
        anchors.fill: parent
        contentHeight: settingsCol.height + 60
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.DragAndOvershootBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: settingsCol
            width: Math.min(parent.width - 60, 800)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 30
            spacing: 20

            Text {
                text: qsTr("基本设置")
                font.bold: true
                font.pixelSize: 24
                color: Theme.textPrimary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            NCard {
                title: qsTr("应用行为")
                Layout.fillWidth: true
                SettingRow {
                    Text {
                        text: qsTr("界面语言")
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NComboBox {
                        Layout.preferredWidth: 150
                        model: ["简体中文", "繁体中文", "English", "日本語", "한국어"]
                        currentIndex: {
                            if (Settings.language === "zh_TW")
                                return 1;
                            if (Settings.language === "en_US")
                                return 2;
                            if (Settings.language === "ja_JP")
                                return 3;
                            if (Settings.language === "ko_KR")
                                return 4;
                            return 0;
                        }
                        onActivated: function (index) {
                            if (index === 0)
                                Settings.setLanguage("zh_CN");
                            else if (index === 1)
                                Settings.setLanguage("zh_TW");
                            else if (index === 2)
                                Settings.setLanguage("en_US");
                            else if (index === 3)
                                Settings.setLanguage("ja_JP");
                            else if (index === 4)
                                Settings.setLanguage("ko_KR");
                        }
                    }
                }
                SettingRow {
                    Text {
                        text: qsTr("恢复未完成的任务")
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NSwitch {
                        checked: Settings.resumeTasks
                        onToggled: Settings.setResumeTasks(checked)
                    }
                }
                SettingRow {
                    Text {
                        text: qsTr("显示关闭确认")
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NSwitch {
                        checked: Settings.confirmExit
                        onToggled: {
                            Settings.setConfirmExit(checked);
                            if (checked)
                                Settings.setCloseAction(0);
                        }
                    }
                }
                SettingRow {
                    Text {
                        text: qsTr("删除任务确认")
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NSwitch {
                        checked: Settings.confirmDelete
                        onToggled: Settings.setConfirmDelete(checked)
                    }
                }
                SettingRow {
                    visible: !Settings.confirmDelete
                    Text {
                        text: qsTr("删除时同时删除文件")
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NSwitch {
                        checked: Settings.deleteWithFile
                        onToggled: Settings.setDeleteWithFile(checked)
                    }
                }
                SettingRow {
                    Text {
                        text: qsTr("记住窗口位置")
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NSwitch {
                        checked: Settings.rememberWindowPosition
                        onToggled: Settings.setRememberWindowPosition(checked)
                    }
                }
                SettingRow {
                    Text {
                        text: qsTr("开机自启动")
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NSwitch {
                        checked: Settings.autoStart
                        onToggled: Settings.setAutoStart(checked)
                    }
                }
            }

            NCard {
                title: qsTr("下载设置")
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: qsTr("默认下载路径")
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        NInput {
                            text: Settings.downloadPath
                            Layout.fillWidth: true
                            readOnly: true
                        }
                        NIconButton {
                            iconName: "qrc:/src/Icons/folder.svg"
                            onClicked: folderDialog.open()
                        }
                    }
                }
            }

            NCard {
                title: qsTr("网络代理")
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMD

                    // Aria2 代理
                    Text {
                        text: qsTr("Aria2 代理")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSM
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        NInput {
                            text: Settings.aria2ProxyUrl
                            placeholderText: qsTr("http://[user:pass@]host:port (仅支持 HTTP)")
                            Layout.fillWidth: true
                            onEditingFinished: {
                                Settings.setAria2ProxyUrl(text);
                                Downloader.applyGlobalSettings();
                            }
                        }
                        NSwitch {
                            checked: Settings.aria2ProxyEnabled
                            onToggled: {
                                Settings.setAria2ProxyEnabled(checked);
                                Downloader.applyGlobalSettings();
                            }
                        }
                    }

                    // M3U8 代理
                    Text {
                        text: qsTr("M3U8 代理")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSM
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        NInput {
                            text: Settings.m3u8ProxyUrl
                            placeholderText: qsTr("http://[user:pass@]host:port (推荐 HTTP)")
                            Layout.fillWidth: true
                            onEditingFinished: Settings.setM3u8ProxyUrl(text)
                        }
                        NSwitch {
                            checked: Settings.m3u8ProxyEnabled
                            onToggled: Settings.setM3u8ProxyEnabled(checked)
                        }
                    }

                    // BT 代理
                    Text {
                        text: qsTr("BT 代理")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSM
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        NInput {
                            text: Settings.btProxyUrl
                            placeholderText: qsTr("http://或 socks5://[user:pass@]host:port")
                            Layout.fillWidth: true
                            onEditingFinished: {
                                Settings.setBtProxyUrl(text);
                                Downloader.applyGlobalSettings();
                            }
                        }
                        NSwitch {
                            checked: Settings.btProxyEnabled
                            onToggled: {
                                Settings.setBtProxyEnabled(checked);
                                Downloader.applyGlobalSettings();
                            }
                        }
                    }
                }
            }

            NCard {
                title: qsTr("智能监听")
                Layout.fillWidth: true
                SettingRow {
                    Text {
                        text: qsTr("自动监听剪贴板链接")
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NSwitch {
                        checked: Settings.monitorClipboard
                        onToggled: Settings.setMonitorClipboard(checked)
                    }
                }
            }
        }
    }

    FolderDialog {
        id: folderDialog
        onAccepted: Settings.setDownloadPath(folder.toString().replace("file:///", ""))
    }
}
