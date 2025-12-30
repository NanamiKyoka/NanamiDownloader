import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

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

    component SettingCard: Rectangle {
        id: cardRoot
        Layout.fillWidth: true
        Layout.preferredHeight: contentCol.implicitHeight + 40
        color: Theme.surface
        radius: 8
        border.color: Theme.divider
        border.width: 1
        default property alias content: contentCol.data
        property string title: ""
        property string desc: ""
        property string feedback: ""

        ColumnLayout {
            id: contentCol
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 20; spacing: 20

            ColumnLayout {
                spacing: 5
                Text { text: cardRoot.title; font.bold: true; font.pixelSize: 18; color: Theme.textPrimary }
                Text { text: cardRoot.desc; font.pixelSize: 13; color: Theme.textSecondary; visible: cardRoot.desc !== "" }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider; visible: cardRoot.title !== "" }
        }

        Text {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 20; anchors.bottomMargin: 15
            visible: cardRoot.feedback !== ""
            text: cardRoot.feedback
            color: "#28a745"
            font.pixelSize: 12
        }
    }

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

    component ActionButtons: RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: 12
        signal saveClicked()
        signal resetClicked()
        Button {
            text: qsTr("重置为默认值")
            flat: true
            Layout.preferredHeight: 36
            background: Rectangle { color: parent.hovered ? (Theme.isDark ? "#333" : "#eee") : "transparent"; border.color: Theme.divider; radius: 4; Behavior on color { ColorAnimation { duration: 150 } } }
            contentItem: Text { text: parent.text; color: Theme.textSecondary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: parent.resetClicked()
        }
        Button {
            text: qsTr("保存设置")
            Layout.preferredHeight: 36
            background: Rectangle { color: parent.down ? Qt.darker(Theme.accent, 1.1) : Theme.accent; radius: 4 }
            contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: {
                Downloader.applyGlobalSettings()
                parent.saveClicked()
            }
        }
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

            Text { text: qsTr("网盘挂载配置"); font.bold: true; font.pixelSize: 24; color: Theme.textPrimary }
            Text { text: qsTr("管理网盘服务的挂载状态与凭证"); color: Theme.textSecondary; font.pixelSize: 14 }

            SettingCard {
                title: qsTr("挂载开关")
                desc: qsTr("单独控制各网盘的显示与挂载")

                RowLayout {
                    Layout.fillWidth: true
                    CustomCheckBox {
                        text: qsTr("启用 百度网盘 挂载")
                        checked: Settings.enableBaiduMount
                        onToggled: Settings.setEnableBaiduMount(checked)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    CustomCheckBox {
                        text: qsTr("启用 迅雷云盘 挂载")
                        checked: Settings.enableThunderMount
                        onToggled: Settings.setEnableThunderMount(checked)
                    }
                }
            }

            SettingCard {
                title: qsTr("百度网盘")
                desc: qsTr("使用官方 API 模式下载，更稳定")
                visible: Settings.enableBaiduMount

                ColumnLayout {
                    spacing: 8
                    Text { text: qsTr("Refresh Token"); color: Theme.textSecondary; font.pixelSize: 13 }
                    TextField {
                        id: tokenField
                        text: Settings.baiduRefreshToken
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        color: Theme.textPrimary
                        placeholderText: qsTr("在此粘贴 Refresh Token")
                        background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                        selectByMouse: true; leftPadding: 10
                        onEditingFinished: Settings.setBaiduRefreshToken(text)
                        Binding { target: tokenField; property: "text"; value: Settings.baiduRefreshToken; when: !tokenField.activeFocus }
                    }
                    Text {
                        text: qsTr("如何获取: 使用 Alist 提供的工具获取 Token")
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://alistgo.com/zh/guide/drivers/baidu.html#%E5%88%B7%E6%96%B0%E4%BB%A4%E7%89%8C")
                        }
                    }
                }

                ActionButtons {
                    onSaveClicked: {
                        Settings.setBaiduRefreshToken(tokenField.text)
                        toast.show(qsTr("Token 已保存!"))
                    }
                    onResetClicked: {
                        Settings.setBaiduRefreshToken("")
                        toast.show(qsTr("已重置"))
                    }
                }
            }

            SettingCard {
                title: qsTr("迅雷云盘")
                desc: qsTr("使用 Username/Password 登录获取 Token")
                visible: Settings.enableThunderMount

                ColumnLayout {
                    spacing: 8
                    Text { text: qsTr("用户名 (手机号)"); color: Theme.textSecondary; font.pixelSize: 13 }
                    TextField {
                        id: thunderUser
                        text: Settings.thunderUsername
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        color: Theme.textPrimary
                        background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                        onEditingFinished: Settings.setThunderUsername(text)
                        Binding { target: thunderUser; property: "text"; value: Settings.thunderUsername; when: !thunderUser.activeFocus }
                    }

                    Text { text: qsTr("密码"); color: Theme.textSecondary; font.pixelSize: 13 }
                    TextField {
                        id: thunderPass
                        text: Settings.thunderPassword
                        echoMode: TextInput.Password
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        color: Theme.textPrimary
                        background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                        onEditingFinished: Settings.setThunderPassword(text)
                        Binding { target: thunderPass; property: "text"; value: Settings.thunderPassword; when: !thunderPass.activeFocus }
                    }

                    Text { text: qsTr("验证码 Token (Captcha Token)"); color: Theme.textSecondary; font.pixelSize: 13 }
                    TextField {
                        id: thunderCaptcha
                        text: Settings.thunderCaptchaToken
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        color: Theme.textPrimary
                        placeholderText: qsTr("如果在网页登录需要验证码，请在此填写获取的 Token")
                        background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                        onEditingFinished: Settings.setThunderCaptchaToken(text)
                        Binding { target: thunderCaptcha; property: "text"; value: Settings.thunderCaptchaToken; when: !thunderCaptcha.activeFocus }
                    }

                    Text { text: qsTr("信任密钥 (Credit Key)"); color: Theme.textSecondary; font.pixelSize: 13 }
                    TextField {
                        id: thunderCredit
                        text: Settings.thunderCreditKey
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        color: Theme.textPrimary
                        placeholderText: qsTr("如果登录需要验证，请在此填写验证后的 Credit Key")
                        background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                        onEditingFinished: Settings.setThunderCreditKey(text)
                        Binding { target: thunderCredit; property: "text"; value: Settings.thunderCreditKey; when: !thunderCredit.activeFocus }
                    }

                    Text { text: qsTr("设备 ID (Device ID)"); color: Theme.textSecondary; font.pixelSize: 13 }
                    TextField {
                        id: thunderDevice
                        text: Settings.thunderDeviceId
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        color: Theme.textPrimary
                        background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                        onEditingFinished: Settings.setThunderDeviceId(text)
                        Binding { target: thunderDevice; property: "text"; value: Settings.thunderDeviceId; when: !thunderDevice.activeFocus }
                    }

                    Text { text: qsTr("挂载目录 ID (Mount Path ID)"); color: Theme.textSecondary; font.pixelSize: 13 }
                    TextField {
                        id: thunderRoot
                        text: Settings.thunderMountPathId
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        color: Theme.textPrimary
                        placeholderText: qsTr("可选，默认为空 (根目录)")
                        background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                        onEditingFinished: Settings.setThunderMountPathId(text)
                        Binding { target: thunderRoot; property: "text"; value: Settings.thunderMountPathId; when: !thunderRoot.activeFocus }
                    }
                }

                ActionButtons {
                    onSaveClicked: {
                        Settings.setThunderUsername(thunderUser.text)
                        Settings.setThunderPassword(thunderPass.text)
                        Settings.setThunderCaptchaToken(thunderCaptcha.text)
                        Settings.setThunderCreditKey(thunderCredit.text)
                        Settings.setThunderDeviceId(thunderDevice.text)
                        Settings.setThunderMountPathId(thunderRoot.text)
                        Downloader.loginThunder()
                        toast.show(qsTr("迅雷配置已保存! 正在尝试登录..."))
                    }
                    onResetClicked: {
                        Settings.setThunderUsername("")
                        Settings.setThunderPassword("")
                        Settings.setThunderCaptchaToken("")
                        Settings.setThunderCreditKey("")
                        Settings.setThunderMountPathId("")
                        toast.show(qsTr("已重置"))
                    }
                }
            }
        }
    }
}