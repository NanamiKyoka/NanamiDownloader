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
                Layout.fillWidth: true
                spacing: 5
                Text {
                    text: cardRoot.title
                    font.bold: true
                    font.pixelSize: 18
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                Text {
                    text: cardRoot.desc
                    font.pixelSize: 13
                    color: Theme.textSecondary
                    visible: cardRoot.desc !== ""
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider; visible: cardRoot.title !== "" }
        }

        Text {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 20; anchors.bottomMargin: 15
            visible: cardRoot.feedback !== ""
            text: cardRoot.feedback
            color: "#28a745"
            font.pixelSize: 12
            width: parent.width - 40
            wrapMode: Text.WordWrap
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
            wrapMode: Text.WordWrap
        }
    }

    component BlueSwitch: Switch {
        indicator: Rectangle {
            implicitWidth: 44; implicitHeight: 24; radius: 12
            color: parent.checked ? "#007bff" : (Theme.isDark ? "#444" : "#ccc")
            border.width: 0
            Rectangle {
                x: parent.parent.checked ? parent.width - width - 2 : 2
                y: 2; width: 20; height: 20; radius: 10
                color: "white"
                Behavior on x { NumberAnimation { duration: 150 } }
            }
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    component SpeedInputRow: ColumnLayout {
        id: speedRow
        property string label
        property string suffix
        property var value: 0
        signal valueSubmitted(int newValue)

        spacing: 8
        Text { text: label; color: Theme.textSecondary; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        RowLayout {
            Layout.fillWidth: true
            TextField {
                id: tf
                text: String(speedRow.value === undefined ? 0 : speedRow.value)
                Layout.preferredWidth: 240
                Layout.preferredHeight: 36
                color: Theme.textPrimary
                background: Rectangle {
                    color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"
                    border.color: parent.activeFocus ? Theme.accent : Theme.divider
                    border.width: 1
                    radius: 4
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
                selectByMouse: true
                leftPadding: 10
                validator: IntValidator { bottom: 0; top: 999999 }
                onEditingFinished: speedRow.valueSubmitted(parseInt(text))

                Binding { target: tf; property: "text"; value: String(speedRow.value === undefined ? 0 : speedRow.value); when: !tf.activeFocus }
            }
            Text { text: suffix; color: Theme.textSecondary; font.pixelSize: 13; visible: suffix !== ""; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        }
    }

    component StandardSpinBoxRow: ColumnLayout {
        id: stdSpinRow
        property string label
        property string suffix
        property int value: 0
        property int from: 0
        property int to: 999999
        signal commit(int val)

        spacing: 8
        Text { text: label; color: Theme.textSecondary; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        RowLayout {
            Layout.fillWidth: true
            SpinBox {
                id: spin
                from: parent.from; to: parent.to
                value: stdSpinRow.value
                Layout.preferredWidth: 240
                Layout.preferredHeight: 36
                editable: true

                contentItem: TextInput {
                    text: parent.textFromValue(parent.value, parent.locale)
                    font: parent.font; color: Theme.textPrimary; selectionColor: Theme.accent; selectedTextColor: "white"
                    horizontalAlignment: Qt.AlignHCenter; verticalAlignment: Qt.AlignVCenter
                    readOnly: !parent.editable; validator: parent.validator; inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onEditingFinished: spin.valueModified()
                }
                background: Rectangle {
                    color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
                up.indicator: Rectangle {
                    x: parent.width - width - 1; y: 1; width: 24; height: parent.height / 2 - 1; color: "transparent"
                    Text { text: "▴"; color: parent.pressed ? Theme.accent : Theme.textSecondary; anchors.centerIn: parent; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; onPressed: spin.increase(); }
                }
                down.indicator: Rectangle {
                    x: parent.width - width - 1; y: parent.height / 2; width: 24; height: parent.height / 2 - 1; color: "transparent"
                    Text { text: "▾"; color: parent.pressed ? Theme.accent : Theme.textSecondary; anchors.centerIn: parent; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; onPressed: spin.decrease(); }
                }
                onValueModified: stdSpinRow.commit(value)
            }
            Text { text: suffix; color: Theme.textSecondary; font.pixelSize: 13; visible: suffix !== ""; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        }
    }

    component CustomComboBoxRow: ColumnLayout {
        id: comboRow
        property string label
        property alias model: combo.model
        property alias currentIndex: combo.currentIndex
        property alias comboObj: combo
        property string suffixText: ""
        signal commit()

        spacing: 8
        Text { text: label; color: Theme.textSecondary; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        RowLayout {
            Layout.fillWidth: true
            ComboBox {
                id: combo
                Layout.preferredWidth: 240; Layout.preferredHeight: 36
                model: parent.model
                delegate: ItemDelegate {
                    width: combo.width
                    contentItem: Text { text: modelData; color: highlighted ? "white" : Theme.textPrimary; font: combo.font; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: highlighted ? Theme.accent : (Theme.isDark ? "#2b2b2b" : "#ffffff") }
                    highlighted: combo.highlightedIndex === index
                }
                indicator: Canvas {
                    x: combo.width - width - 10; y: combo.topPadding + (combo.availableHeight - height) / 2; width: 10; height: 6; contextType: "2d"
                    onPaint: { var ctx = getContext("2d"); ctx.reset(); ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.lineTo(width / 2, height); ctx.closePath(); ctx.fillStyle = Theme.textSecondary; ctx.fill(); }
                }
                contentItem: Text { leftPadding: 10; rightPadding: combo.indicator.width + combo.spacing; text: combo.displayText; font: combo.font; color: Theme.textPrimary; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: combo.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                popup: Popup {
                    y: combo.height - 1; width: combo.width; implicitHeight: contentItem.implicitHeight; padding: 1
                    contentItem: ListView { clip: true; implicitHeight: contentHeight; model: combo.popup.visible ? combo.delegateModel : null; currentIndex: combo.highlightedIndex; ScrollIndicator.vertical: ScrollIndicator { } }
                    background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#ffffff"; border.color: Theme.divider; radius: 4 }
                }
                onActivated: comboRow.commit()
            }
            Text { text: suffixText; color: Theme.textSecondary; font.pixelSize: 12; visible: suffixText !== ""; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        }
    }

    component NormalInputRow: ColumnLayout {
        id: normalInpRow
        property string label
        property alias text: inputField.text
        property alias placeholderText: inputField.placeholderText
        signal commit()

        spacing: 8
        Text { text: label; color: Theme.textSecondary; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        TextField {
            id: inputField
            Layout.fillWidth: true; Layout.preferredHeight: 36
            color: Theme.textPrimary
            background: Rectangle { color: parent.activeFocus?Theme.surface:(Theme.isDark?"#2b2b2b":"#f5f5f5"); border.color: parent.activeFocus?Theme.accent:Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
            selectByMouse: true; leftPadding: 10
            onEditingFinished: normalInpRow.commit()
            Binding { target: inputField; property: "text"; value: normalInpRow.text; when: !inputField.activeFocus }
        }
    }

    component ActionButtons: RowLayout {
        Layout.alignment: Qt.AlignRight
        Layout.fillWidth: true
        spacing: 12
        signal saveClicked()
        signal resetClicked()

        Item { Layout.fillWidth: true }

        Button {
            text: qsTr("重置为默认值")
            flat: true
            Layout.preferredHeight: 36
            background: Rectangle { color: parent.hovered ? (Theme.isDark ? "#333" : "#eee") : "transparent"; border.color: Theme.divider; radius: 4; Behavior on color { ColorAnimation { duration: 150 } } }
            contentItem: Text {
                text: parent.text; color: Theme.textSecondary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit; minimumPixelSize: 10; font.pixelSize: 13
            }
            onClicked: parent.resetClicked()
        }
        Button {
            text: qsTr("保存设置")
            Layout.preferredHeight: 36
            background: Rectangle { color: parent.down ? Qt.darker(Theme.accent, 1.1) : Theme.accent; radius: 4 }
            contentItem: Text {
                text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit; minimumPixelSize: 10; font.pixelSize: 13
            }
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

            Text { text: qsTr("高级设置"); font.bold: true; font.pixelSize: 24; color: Theme.textPrimary }
            Text { text: qsTr("高级配置选项"); color: Theme.textSecondary; font.pixelSize: 14; Layout.fillWidth: true; wrapMode: Text.WordWrap }

            SettingCard {
                id: speedCard
                title: qsTr("速度控制")
                desc: qsTr("配置下载和上传速度限制")

                SpeedInputRow { label: qsTr("全局下载限速"); suffix: qsTr("KB/s (0 = 无限制)"); value: Settings.globalMaxDownloadSpeed; onValueSubmitted: (v) => Settings.setGlobalMaxDownloadSpeed(v) }
                SpeedInputRow { label: qsTr("全局上传限速"); suffix: qsTr("KB/s (0 = 无限制, 用于 BitTorrent 种子传输)"); value: Settings.globalMaxUploadSpeed; onValueSubmitted: (v) => Settings.setGlobalMaxUploadSpeed(v) }
                SpeedInputRow { label: qsTr("最低限速"); suffix: qsTr("KB/s (0 = 禁用, 如果速度低于此持续 60s 则断开连接)"); value: Settings.minSpeedLimit; onValueSubmitted: (v) => Settings.setMinSpeedLimit(v) }

                Text { text: qsTr("修改上述值，然后点击 \"保存设置\" 应用。"); color: Theme.textSecondary; font.pixelSize: 12; topPadding: 10; Layout.fillWidth: true; wrapMode: Text.WordWrap }

                ActionButtons {
                    onSaveClicked: {
                        toast.show(qsTr("速度控制设置已保存并成功应用!"))
                        speedCard.feedback = qsTr("✓ 已保存设置: 下载=%1 KB/s, 上传=%2 KB/s, 最低速度=%3 KB/s").arg(Settings.globalMaxDownloadSpeed).arg(Settings.globalMaxUploadSpeed).arg(Settings.minSpeedLimit)
                    }
                    onResetClicked: {
                        Settings.setGlobalMaxDownloadSpeed(0)
                        Settings.setGlobalMaxUploadSpeed(0)
                        Settings.setMinSpeedLimit(0)
                        toast.show(qsTr("速度设置已重置"))
                    }
                }
            }

            SettingCard {
                title: qsTr("连接与性能")
                desc: qsTr("配置连接参数和下载性能")

                StandardSpinBoxRow { label: qsTr("最大同时下载数"); suffix: qsTr("同时并行下载的任务数"); from: 1; to: 100; value: Settings.maxConcurrentDownloads; onCommit: (v) => Settings.setMaxConcurrentDownloads(v) }
                StandardSpinBoxRow { label: qsTr("每台服务器最大连接数"); suffix: qsTr("连接越多 = 速度越快，但可能会被服务器屏蔽"); from: 1; to: 16; value: Settings.maxConnectionPerServer; onCommit: (v) => Settings.setMaxConnectionPerServer(v) }
                StandardSpinBoxRow { label: qsTr("文件分段 (分割)"); suffix: qsTr("分割下载文件的段数"); from: 1; to: 16; value: Settings.split; onCommit: (v) => Settings.setSplit(v) }

                CustomComboBoxRow {
                    id: splitSizeCombo
                    label: qsTr("最小分割尺寸")
                    model: ["1M", "5M", "10M", "20M", "50M", "100M"]
                    currentIndex: model.indexOf(Settings.minSplitSize) !== -1 ? model.indexOf(Settings.minSplitSize) : 0
                    suffixText: qsTr("不要分割小于此大小的文件")
                    onCommit: Settings.setMinSplitSize(comboObj.displayText)
                }

                Text { text: qsTr("调整上述参数并点击 \"保存设置\" 应用。"); color: Theme.textSecondary; font.pixelSize: 12; topPadding: 10; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                ActionButtons {
                    onSaveClicked: toast.show(qsTr("连接与性能设置已保存!"))
                    onResetClicked: {
                        Settings.setMaxConcurrentDownloads(16)
                        Settings.setMaxConnectionPerServer(16)
                        Settings.setSplit(16)
                        Settings.setMinSplitSize("20M")
                        splitSizeCombo.currentIndex = 3
                        toast.show(qsTr("连接设置已重置"))
                    }
                }
            }

            SettingCard {
                title: qsTr("代理规则")
                desc: qsTr("根据 URL 匹配设置特定代理 (Aria2/M3U8)")

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: qsTr("规则列表 (每行一条: 域名或正则|代理地址)"); color: Theme.textSecondary; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    TextArea {
                        id: proxyRulesArea
                        text: Settings.proxyRules
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        color: Theme.textPrimary
                        background: Rectangle {
                            color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"
                            border.color: parent.activeFocus ? Theme.accent : Theme.divider
                            border.width: 1
                            radius: 4
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                        selectByMouse: true
                        wrapMode: TextEdit.NoWrap
                        leftPadding: 10; topPadding: 10
                        placeholderText: "example.com|http://127.0.0.1:8888\n.*\\.google\\.com|socks5://127.0.0.1:1080"
                        onEditingFinished: Settings.setProxyRules(text)
                        Binding { target: proxyRulesArea; property: "text"; value: Settings.proxyRules; when: !proxyRulesArea.activeFocus }
                    }
                    Text { text: qsTr("支持 http, https, socks5 代理。支持正则表达式。"); color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }

                ActionButtons {
                    onSaveClicked: {
                        Settings.setProxyRules(proxyRulesArea.text)
                        toast.show(qsTr("代理规则已保存!"))
                    }
                    onResetClicked: {
                        Settings.setProxyRules("")
                        toast.show(qsTr("代理规则已清空"))
                    }
                }
            }

            SettingCard {
                id: actionCard
                title: qsTr("下载后操作")
                desc: qsTr("配置下载完成、失败或启动后的自动操作")

                CustomComboBoxRow {
                    id: completeActionCombo
                    label: qsTr("全部下载完成时")
                    model: [qsTr("什么都不做"), qsTr("播放声音"), qsTr("关闭计算机")]
                    currentIndex: Settings.onDownloadComplete
                    onCommit: Settings.setOnDownloadComplete(currentIndex)
                }
                CustomComboBoxRow {
                    id: failureActionCombo
                    label: qsTr("下载失败时")
                    model: [qsTr("什么都不做"), qsTr("自动重试")]
                    currentIndex: Settings.onDownloadFailure
                    onCommit: Settings.setOnDownloadFailure(currentIndex)
                    suffixText: qsTr("重试次数由下方的 '最大重试次数' 决定")
                }

                ActionButtons {
                    onSaveClicked: toast.show(qsTr("操作设置已保存!"))
                    onResetClicked: {
                        Settings.setOnDownloadComplete(0)
                        Settings.setOnDownloadFailure(0)
                        completeActionCombo.currentIndex = 0
                        failureActionCombo.currentIndex = 0
                        toast.show(qsTr("操作设置已重置"))
                    }
                }
            }


            SettingCard {
                title: qsTr("超时和重试设置")
                desc: qsTr("为不稳定网络配置连接超时和重试行为")

                StandardSpinBoxRow { label: qsTr("超时"); suffix: qsTr("秒钟 HTTP/FTP 连接建立后超时"); value: Settings.timeout; onCommit: (v) => Settings.setTimeout(v); to: 86400 }
                StandardSpinBoxRow { label: qsTr("连接超时"); suffix: qsTr("秒钟 建立初始连接的超时"); value: Settings.connectTimeout; onCommit: (v) => Settings.setConnectTimeout(v); to: 86400 }
                StandardSpinBoxRow { label: qsTr("最大重试次数"); suffix: qsTr("次 重试次数 (0 = 无限制)"); value: Settings.maxTries; onCommit: (v) => Settings.setMaxTries(v); to: 9999 }
                StandardSpinBoxRow { label: qsTr("重试等待时间"); suffix: qsTr("秒钟 重试之间的等待时间 (0 = 禁用)"); value: Settings.retryWait; onCommit: (v) => Settings.setRetryWait(v); to: 3600 }

                Text { text: qsTr("修改上述值，然后点击 \"保存设置\" 应用。"); color: Theme.textSecondary; font.pixelSize: 12; topPadding: 10; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                ActionButtons {
                    onSaveClicked: toast.show(qsTr("超时设置已保存!"))
                    onResetClicked: {
                        Settings.setTimeout(60)
                        Settings.setConnectTimeout(60)
                        Settings.setMaxTries(5)
                        Settings.setRetryWait(0)
                        toast.show(qsTr("超时设置已重置"))
                    }
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: tipText.implicitHeight + 20; color: Theme.isDark ? "#383838" : "#f9f9f9"; radius: 4; border.color: Theme.divider
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 5
                        Text { text: "💡"; font.pixelSize: 14 }
                        Text { id: tipText; text: qsTr("提示: 针对不稳定的网络连接，增加超时和重试值"); color: Theme.textPrimary; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }
                }
            }

            SettingCard {
                title: qsTr("BitTorrent 高级选项")
                desc: qsTr("为 BitTorrent 下载配置 DHT、对等连接和加密")

                RowLayout {
                    Layout.fillWidth: true
                    CustomCheckBox { id: dhtCb; checked: Settings.enableDht; onToggled: Settings.setEnableDht(checked) }
                    ColumnLayout { spacing: 2; Layout.fillWidth: true; Text { text: qsTr("启用 DHT (去中心化网络)"); color: Theme.textPrimary; font.pixelSize: 14 } Text { text: qsTr("为 Torrent 下载找到更多用户。还可启用 UDP Tracker 支持。"); color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap } }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider; opacity: 0.5 }
                StandardSpinBoxRow { label: qsTr("Torrent 最大连接数"); suffix: qsTr("每个 Torrent 最大连接数量 (0 = 无限制)"); value: Settings.btMaxPeers; onCommit: (v) => Settings.setBtMaxPeers(v) }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider; opacity: 0.5 }
                RowLayout {
                    Layout.fillWidth: true
                    CustomCheckBox { id: cryptoCb; checked: Settings.btRequireCrypto; onToggled: Settings.setBtRequireCrypto(checked) }
                    ColumnLayout { spacing: 2; Layout.fillWidth: true; Text { text: qsTr("要求加密连接"); color: Theme.textPrimary; font.pixelSize: 14 } Text { text: qsTr("只接受加密的 BitTorrent 握手。拒绝传统的未加密连接。"); color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap } }
                }

                Text { text: qsTr("修改上述值，然后点击 \"保存设置\" 应用。"); color: Theme.textSecondary; font.pixelSize: 12; topPadding: 10; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                ActionButtons {
                    onSaveClicked: toast.show(qsTr("BitTorrent 设置已保存!"))
                    onResetClicked: {
                        Settings.setEnableDht(true)
                        Settings.setBtMaxPeers(55)
                        Settings.setBtRequireCrypto(false)
                        toast.show(qsTr("BitTorrent 设置已重置"))
                    }
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: btTip.implicitHeight + 20; color: Theme.isDark ? "#383838" : "#f9f9f9"; radius: 4; border.color: Theme.divider
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 5
                        Text { text: "💡"; font.pixelSize: 14 }
                        Text { id: btTip; text: qsTr("提示: 对于私人 Torrent，无论是否进行此设置，DHT 都会自动禁用"); color: "#8a6d3b"; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 12 }
                    }
                }
            }

            SettingCard {
                title: qsTr("用户代理（UA设置）")
                desc: qsTr("配置 HTTP/HTTPS 用户代理字符串，以便与不同服务器兼容")

                Component.onCompleted: {
                    if (uaCombo.currentIndex !== Settings.userAgentIndex) {
                        uaCombo.currentIndex = Settings.userAgentIndex
                        if (Settings.userAgentIndex !== 9) {
                            var ua = ""
                            if(Settings.userAgentIndex === 0) ua = "aria2/1.36.0"
                            if(Settings.userAgentIndex === 1) ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                            if(Settings.userAgentIndex === 2) ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0"
                            if(Settings.userAgentIndex === 3) ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
                            if(Settings.userAgentIndex === 4) ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
                            if(Settings.userAgentIndex === 5) ua = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
                            if(Settings.userAgentIndex === 6) ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
                            if(Settings.userAgentIndex === 7) ua = "Wget/1.21.3"
                            if(Settings.userAgentIndex === 8) ua = "curl/8.5.0"
                            if (ua !== "") {
                                uaTextField.text = ua
                            }
                        }
                    }
                }

                CustomComboBoxRow {
                    id: uaCombo
                    label: qsTr("预设用户代理")
                    model: [qsTr("Aria2 默认值 (aria2/1.36.0)"), qsTr("Chrome 120 (Windows)"), qsTr("Firefox 121 (Windows)"), qsTr("Safari 17 (macOS)"), qsTr("Edge 120 (Windows)"), qsTr("Chrome 120 (安卓)"), qsTr("Safari (iPhone)"), qsTr("Wget 1.21"), qsTr("cURL 8.5"), qsTr("自定义")]
                    currentIndex: Settings.userAgentIndex
                    onCommit: {
                        Settings.setUserAgentIndex(currentIndex)
                        var ua = ""
                        if(currentIndex === 0) ua = "aria2/1.36.0"
                        if(currentIndex === 1) ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                        if(currentIndex === 2) ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0"
                        if(currentIndex === 3) ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
                        if(currentIndex === 4) ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
                        if(currentIndex === 5) ua = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
                        if(currentIndex === 6) ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
                        if(currentIndex === 7) ua = "Wget/1.21.3"
                        if(currentIndex === 8) ua = "curl/8.5.0"
                        if(currentIndex !== 9) {
                            Settings.setUserAgent(ua)
                            uaTextField.text = ua
                        } else {
                            uaTextField.text = Settings.userAgent
                        }
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Text { text: qsTr("自定义用户代理"); color: Theme.textSecondary; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    TextField {
                        id: uaTextField
                        text: Settings.userAgent
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        enabled: uaCombo.currentIndex === 9
                        color: Theme.textPrimary
                        background: Rectangle {
                            color: enabled ? (parent.activeFocus?Theme.surface:(Theme.isDark?"#2b2b2b":"#f5f5f5")) : (Theme.isDark?"#333":"#e0e0e0")
                            border.color: parent.activeFocus?Theme.accent:Theme.divider; border.width: 1; radius: 4;
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                        selectByMouse: true; leftPadding: 10
                        onEditingFinished: {
                            Settings.setUserAgent(text)
                            if(uaCombo.currentIndex !== 9) {
                                uaCombo.currentIndex = 9
                                Settings.setUserAgentIndex(9)
                            }
                        }
                        Binding {
                            target: uaTextField;
                            property: "text";
                            value: Settings.userAgent;
                            when: !uaTextField.activeFocus
                        }
                    }
                }

                ActionButtons {
                    onSaveClicked: toast.show(qsTr("用户代理设置已保存!"))
                    onResetClicked: {
                        Settings.setUserAgentIndex(0)
                        Settings.setUserAgent("aria2/1.36.0")
                        toast.show(qsTr("用户代理已重置"))
                    }
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: uaTip.implicitHeight + 20; color: Theme.isDark ? "#383838" : "#f9f9f9"; radius: 4; border.color: Theme.divider
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 5
                        Text { text: "💡"; font.pixelSize: 14 }
                        Text { id: uaTip; text: qsTr("提示: 某些服务器可能会阻止从 Aria2 下载。使用浏览器用户代理可绕过限制。"); color: "#8a6d3b"; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 12 }
                    }
                }
            }

            SettingCard {
                title: qsTr("Aria2 RPC 设置")
                desc: qsTr("配置 Aria2 远程 RPC 监听端口")

                ColumnLayout {
                    spacing: 8
                    Text { text: qsTr("RPC 监听端口"); color: Theme.textSecondary; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    RowLayout {
                        TextField {
                            id: portField
                            text: Settings.rpcPort.toString()
                            Layout.preferredWidth: 240; Layout.preferredHeight: 36
                            color: Theme.textPrimary
                            background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                            selectByMouse: true; leftPadding: 10
                            validator: IntValidator { bottom: 1024; top: 65535 }
                            onEditingFinished: Settings.setRpcPort(parseInt(text))
                            Binding { target: portField; property: "text"; value: String(Settings.rpcPort); when: !portField.activeFocus }
                        }
                        Text { text: "(1024-65535)"; color: Theme.textSecondary; font.pixelSize: 13 }
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Text { text: qsTr("RPC 密钥"); color: Theme.textSecondary; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        TextField {
                            id: secretField
                            text: Settings.rpcSecret
                            Layout.fillWidth: true; Layout.preferredHeight: 36
                            color: Theme.textPrimary
                            echoMode: showSecret.checked ? TextInput.Normal : TextInput.Password
                            background: Rectangle { color: Theme.isDark ? "#2b2b2b" : "#f5f5f5"; border.color: parent.activeFocus ? Theme.accent : Theme.divider; border.width: 1; radius: 4; Behavior on border.color { ColorAnimation { duration: 150 } } }
                            selectByMouse: true; leftPadding: 10
                            onEditingFinished: Settings.setRpcSecret(text)
                            Binding { target: secretField; property: "text"; value: Settings.rpcSecret; when: !secretField.activeFocus }
                        }
                        CustomCheckBox { id: showSecret; text: qsTr("显示") }
                        Button {
                            text: qsTr("生成随机密钥"); Layout.preferredHeight: 36
                            background: Rectangle { color: parent.hovered ? (Theme.isDark ? "#333" : "#eee") : "transparent"; border.color: Theme.divider; radius: 4 }
                            contentItem: Text { text: parent.text; color: Theme.textSecondary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: { var c = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"; var l = 32; var r = ""; for(var i=0; i<l; i++) r += c.charAt(Math.floor(Math.random()*c.length)); Settings.setRpcSecret(r) }
                        }
                    }
                }

                ActionButtons {
                    onSaveClicked: toast.show(qsTr("RPC 设置已保存 (需重启生效)!"))
                    onResetClicked: {
                        Settings.setRpcPort(16888)
                        Settings.setRpcSecret("")
                        toast.show(qsTr("RPC 设置已重置"))
                    }
                }
                Rectangle {
                    Layout.fillWidth: true;
                    implicitHeight: infoCol.implicitHeight + 24
                    color: Theme.isDark ? "#252526" : "#f0f0f0"; radius: 4
                    ColumnLayout {
                        id: infoCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 6
                        RowLayout { Text { text: "ⓘ"; color: "#007bff"; font.pixelSize: 16 } Text { text: qsTr("重要信息"); color: "#007bff"; font.bold: true; font.pixelSize: 13 } }
                        Text { text: qsTr("• RPC 端口用于应用程序和 Aria2 引擎之间的通信\n• 默认端口为 16888\n• RPC 密钥用于应用程序和 Aria2 引擎之间的身份验证\n• 默认密钥为空\n• 为了安全起见，建议使用强随机密钥\n• 确保该端口未被其他应用程序使用"); color: Theme.textSecondary; font.pixelSize: 12; lineHeight: 1.4; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        RowLayout { Text { text: "⚠️"; font.pixelSize: 12 } Text { text: qsTr("更改端口或密钥后必须重启应用程序！"); color: "#e6a23c"; font.bold: true; font.pixelSize: 12 } }
                        Text { text: qsTr("• 选择 1024 到 65535 之间的端口号\n• 更改会立即保存，但只有在重启后才会生效"); color: Theme.textSecondary; font.pixelSize: 12; lineHeight: 1.4; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }
                }
            }

            SettingCard {
                title: qsTr("BitTorrent Trackers")
                desc: qsTr("为 BitTorrent 下载配置 Trackers")

                Text { text: qsTr("Trackers 源"); color: Theme.textSecondary; Layout.fillWidth: true; wrapMode: Text.WordWrap }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    color: "transparent"
                    border.color: Theme.divider
                    border.width: 1
                    radius: 4

                    ScrollView {
                        anchors.fill: parent
                        clip: true
                        ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }

                        GridLayout {
                            width: parent.width
                            columns: 3
                            columnSpacing: 10
                            rowSpacing: 5

                            Repeater {
                                model: [
                                    {key: "XIU2-best-link", name: "XIU2 Best (Link)"},
                                    {key: "XIU2-best-cdn", name: "XIU2 Best (CDN)"},
                                    {key: "XIU2-all-link", name: "XIU2 All (Link)"},
                                    {key: "XIU2-all-cdn", name: "XIU2 All (CDN)"},
                                    {key: "XIU2-http-link", name: "XIU2 HTTP (Link)"},
                                    {key: "XIU2-http-cdn", name: "XIU2 HTTP (CDN)"},
                                    {key: "XIU2-nohttp-link", name: "XIU2 No-HTTP (Link)"},
                                    {key: "XIU2-nohttp-cdn", name: "XIU2 No-HTTP (CDN)"},
                                    {key: "ngosang-best-link", name: "Ngosang Best (Link)"},
                                    {key: "ngosang-best-mirror", name: "Ngosang Best (Mirror)"},
                                    {key: "ngosang-best-cdn", name: "Ngosang Best (CDN)"},
                                    {key: "ngosang-all-link", name: "Ngosang All (Link)"},
                                    {key: "ngosang-all-mirror", name: "Ngosang All (Mirror)"},
                                    {key: "ngosang-all-cdn", name: "Ngosang All (CDN)"},
                                    {key: "ngosang-all_udp-link", name: "Ngosang All UDP (Link)"},
                                    {key: "ngosang-all_udp-mirror", name: "Ngosang All UDP (Mirror)"},
                                    {key: "ngosang-all_udp-cdn", name: "Ngosang All UDP (CDN)"},
                                    {key: "ngosang-all_http-link", name: "Ngosang All HTTP (Link)"},
                                    {key: "ngosang-all_http-mirror", name: "Ngosang All HTTP (Mirror)"},
                                    {key: "ngosang-all_http-cdn", name: "Ngosang All HTTP (CDN)"},
                                    {key: "ngosang-all_https-link", name: "Ngosang All HTTPS (Link)"},
                                    {key: "ngosang-all_https-mirror", name: "Ngosang All HTTPS (Mirror)"},
                                    {key: "ngosang-all_https-cdn", name: "Ngosang All HTTPS (CDN)"},
                                ]

                                CustomCheckBox {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    checked: Settings.hasTrackerSource(modelData.key)
                                    onToggled: {
                                        if (checked) Settings.addTrackerSource(modelData.key)
                                        else Settings.removeTrackerSource(modelData.key)
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.topMargin: 10
                    Button {
                        text: qsTr("同步 Trackers")
                        background: Rectangle { color: "#007bff"; radius: 4 }
                        contentItem: Text { text: parent.text; color: "white"; anchors.centerIn: parent }
                        onClicked: {
                            toast.show(qsTr("正在同步 Trackers ，请稍候..."))
                            Downloader.fetchTrackers()
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: qsTr("启用每日自动更新"); color: Theme.textPrimary }
                    BlueSwitch {
                        checked: Settings.autoUpdateTrackers
                        onToggled: Settings.setAutoUpdateTrackers(checked)
                    }
                }

                Text { text: qsTr("当前 Trackers 列表"); color: Theme.textSecondary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    clip: true
                    ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }

                    Column {
                        width: parent.width
                        Repeater {
                            model: Settings.btTrackers ? Settings.btTrackers.split(",").filter(function(item) { return item.trim() !== ""; }) : []
                            Text {
                                text: modelData ? modelData.trim() : ""
                                width: parent.width
                                color: Theme.textSecondary
                                wrapMode: Text.Wrap
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            SettingCard {
                title: qsTr("其他")
                desc: qsTr("其他杂项设置")

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: qsTr("启用网盘挂载")
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                    BlueSwitch {
                        checked: Settings.enableCloudMount
                        onToggled: Settings.setEnableCloudMount(checked)
                    }
                }
            }
        }
    }
}