import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0
import Nanami.UI.Components 1.0

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Toast 提示
    Rectangle {
        id: toast
        z: 999
        width: toastText.implicitWidth + 40
        height: 40
        radius: Theme.borderRadiusMedium
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
                font.pixelSize: Theme.fontMD
            }
        }

        Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }

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

    // 设置卡片组件
    component SettingCard: NCard {
        id: cardRoot
        Layout.fillWidth: true
        property string desc: ""

        // 描述信息
        Text {
            text: cardRoot.desc
            font.pixelSize: Theme.fontSM
            color: Theme.textSecondary
            visible: cardRoot.desc !== ""
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    // 速度输入行
    component SpeedInputRow: ColumnLayout {
        id: speedRow
        property string label
        property string suffix
        property var value: 0
        signal valueSubmitted(int newValue)

        spacing: Theme.spacingSM
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight

        Text {
            text: label
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSM
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            NInput {
                id: speedInput
                text: String(speedRow.value === undefined ? 0 : speedRow.value)
                Layout.preferredWidth: 240
                validator: IntValidator { bottom: 0; top: 999999 }
                onEditingFinished: speedRow.valueSubmitted(parseInt(text))

                Binding { target: speedInput; property: "text"; value: String(speedRow.value === undefined ? 0 : speedRow.value); when: !speedInput.activeFocus }
            }
            Text {
                text: suffix
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSM
                visible: suffix !== ""
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // 标准数字输入行
    component StandardSpinBoxRow: ColumnLayout {
        id: stdSpinRow
        property string label
        property string suffix
        property int value: 0
        property int from: 0
        property int to: 999999
        signal commit(int val)

        spacing: Theme.spacingSM
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight

        Text {
            text: label
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSM
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            NSpinBox {
                id: spin
                from: stdSpinRow.from
                to: stdSpinRow.to
                value: stdSpinRow.value
                Layout.preferredWidth: 240
                onValueChanged: stdSpinRow.commit(value)
            }
            Text {
                text: suffix
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSM
                visible: suffix !== ""
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // 下拉选择行
    component CustomComboBoxRow: ColumnLayout {
        id: comboRow
        property string label
        property alias model: combo.model
        property alias currentIndex: combo.currentIndex
        property alias comboObj: combo
        property string suffixText: ""
        signal commit()

        spacing: Theme.spacingSM
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight

        Text {
            text: label
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSM
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            NComboBox {
                id: combo
                Layout.preferredWidth: 240
                onActivated: comboRow.commit()
            }
            Text {
                text: suffixText
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSM
                visible: suffixText !== ""
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // 普通输入行
    component NormalInputRow: ColumnLayout {
        id: normalInpRow
        property string label
        property alias text: inputField.text
        property alias placeholderText: inputField.placeholderText
        signal commit()

        spacing: Theme.spacingSM
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight

        Text {
            text: label
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSM
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        NInput {
            id: inputField
            Layout.fillWidth: true
            onEditingFinished: normalInpRow.commit()
            Binding { target: inputField; property: "text"; value: normalInpRow.text; when: !inputField.activeFocus }
        }
    }

    // 操作按钮组
    component ActionButtons: RowLayout {
        Layout.alignment: Qt.AlignRight
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        spacing: Theme.spacingMD

        signal saveClicked()
        signal resetClicked()

        Item { Layout.fillWidth: true }

        NButton {
            text: qsTr("重置为默认值")
            variant: "default"
            onClicked: parent.resetClicked()
        }
        NButton {
            text: qsTr("保存设置")
            variant: "primary"
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
            anchors.top: parent.top
            anchors.topMargin: 30
            spacing: 20

            Text {
                text: qsTr("高级设置")
                font.bold: true
                font.pixelSize: 24
                color: Theme.textPrimary
            }
            Text {
                text: qsTr("高级配置选项")
                color: Theme.textSecondary
                font.pixelSize: Theme.fontMD
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            // 速度控制
            SettingCard {
                id: speedCard
                title: qsTr("速度控制")
                desc: qsTr("配置下载和上传速度限制")

                SpeedInputRow {
                    label: qsTr("全局下载限速")
                    suffix: qsTr("KB/s (0 = 无限制)")
                    value: Settings.globalMaxDownloadSpeed
                    onValueSubmitted: (v) => Settings.setGlobalMaxDownloadSpeed(v)
                }
                SpeedInputRow {
                    label: qsTr("全局上传限速")
                    suffix: qsTr("KB/s (0 = 无限制, 用于 BitTorrent 种子传输)")
                    value: Settings.globalMaxUploadSpeed
                    onValueSubmitted: (v) => Settings.setGlobalMaxUploadSpeed(v)
                }
                SpeedInputRow {
                    label: qsTr("最低限速")
                    suffix: qsTr("KB/s (0 = 禁用, 如果速度低于此持续 60s 则断开连接)")
                    value: Settings.minSpeedLimit
                    onValueSubmitted: (v) => Settings.setMinSpeedLimit(v)
                }

                Text {
                    text: qsTr("修改上述值，然后点击 \"保存设置\" 应用。")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSM
                    topPadding: 10
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                ActionButtons {
                    onSaveClicked: {
                        toast.show(qsTr("速度控制设置已保存并成功应用!"))
                    }
                    onResetClicked: {
                        Settings.setGlobalMaxDownloadSpeed(0)
                        Settings.setGlobalMaxUploadSpeed(0)
                        Settings.setMinSpeedLimit(0)
                        toast.show(qsTr("速度设置已重置"))
                    }
                }
            }

            // 连接与性能
            SettingCard {
                title: qsTr("连接与性能")
                desc: qsTr("配置连接参数和下载性能")

                StandardSpinBoxRow {
                    label: qsTr("最大同时下载数")
                    suffix: qsTr("同时并行下载的任务数")
                    from: 1; to: 100
                    value: Settings.maxConcurrentDownloads
                    onCommit: (v) => Settings.setMaxConcurrentDownloads(v)
                }
                StandardSpinBoxRow {
                    label: qsTr("每台服务器最大连接数")
                    suffix: qsTr("连接越多 = 速度越快，但可能会被服务器屏蔽")
                    from: 1; to: 16
                    value: Settings.maxConnectionPerServer
                    onCommit: (v) => Settings.setMaxConnectionPerServer(v)
                }
                StandardSpinBoxRow {
                    label: qsTr("文件分段 (分割)")
                    suffix: qsTr("分割下载文件的段数")
                    from: 1; to: 16
                    value: Settings.split
                    onCommit: (v) => Settings.setSplit(v)
                }

                CustomComboBoxRow {
                    id: splitSizeCombo
                    label: qsTr("最小分割尺寸")
                    model: ["1M", "5M", "10M", "20M", "50M", "100M"]
                    currentIndex: model.indexOf(Settings.minSplitSize) !== -1 ? model.indexOf(Settings.minSplitSize) : 0
                    suffixText: qsTr("不要分割小于此大小的文件")
                    onCommit: Settings.setMinSplitSize(comboObj.displayText)
                }

                Text {
                    text: qsTr("调整上述参数并点击 \"保存设置\" 应用。")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSM
                    topPadding: 10
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
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

            // 代理规则
            SettingCard {
                title: qsTr("代理规则")
                desc: qsTr("根据 URL 匹配设置特定代理 (Aria2/M3U8)")

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    spacing: Theme.spacingSM
                    Text {
                        text: qsTr("规则列表 (每行一条: 域名或正则|代理地址)")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSM
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NTextArea {
                        id: proxyRulesArea
                        text: Settings.proxyRules
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        placeholderText: "example.com|http://127.0.0.1:8888\n.*\\.google\\.com|socks5://127.0.0.1:1080"
                        onEditingFinished: Settings.setProxyRules(text)
                        Binding { target: proxyRulesArea; property: "text"; value: Settings.proxyRules; when: !proxyRulesArea.activeFocus }
                    }
                    Text {
                        text: qsTr("支持 http, https, socks5 代理。支持正则表达式。")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSM
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
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

            // 下载后操作
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

            // 超时和重试设置
            SettingCard {
                title: qsTr("超时和重试设置")
                desc: qsTr("为不稳定网络配置连接超时和重试行为")

                StandardSpinBoxRow {
                    label: qsTr("超时")
                    suffix: qsTr("秒钟 HTTP/FTP 连接建立后超时")
                    value: Settings.timeout
                    onCommit: (v) => Settings.setTimeout(v)
                    to: 86400
                }
                StandardSpinBoxRow {
                    label: qsTr("连接超时")
                    suffix: qsTr("秒钟 建立初始连接的超时")
                    value: Settings.connectTimeout
                    onCommit: (v) => Settings.setConnectTimeout(v)
                    to: 86400
                }
                StandardSpinBoxRow {
                    label: qsTr("最大重试次数")
                    suffix: qsTr("次 重试次数 (0 = 无限制)")
                    value: Settings.maxTries
                    onCommit: (v) => Settings.setMaxTries(v)
                    to: 9999
                }
                StandardSpinBoxRow {
                    label: qsTr("重试等待时间")
                    suffix: qsTr("秒钟 重试之间的等待时间 (0 = 禁用)")
                    value: Settings.retryWait
                    onCommit: (v) => Settings.setRetryWait(v)
                    to: 3600
                }

                Text {
                    text: qsTr("修改上述值，然后点击 \"保存设置\" 应用。")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSM
                    topPadding: 10
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
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

                // 提示框
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: tipText.implicitHeight + 20
                    color: Theme.isDark ? "#383838" : "#f9f9f9"
                    radius: Theme.borderRadiusMedium
                    border.color: Theme.divider
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        Text { text: "💡"; font.pixelSize: Theme.fontMD }
                        Text {
                            id: tipText
                            text: qsTr("提示: 针对不稳定的网络连接，增加超时和重试值")
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSM
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // BitTorrent 高级选项
            SettingCard {
                title: qsTr("BitTorrent 高级选项")
                desc: qsTr("为 BitTorrent 下载配置 DHT、对等连接和加密")

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    NCheckbox {
                        id: dhtCb
                        checked: Settings.enableDht
                        onToggled: Settings.setEnableDht(checked)
                    }
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("启用 DHT (去中心化网络)")
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontMD
                        }
                        Text {
                            text: qsTr("为 Torrent 下载找到更多用户。还可启用 UDP Tracker 支持。")
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSM
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                NDivider { Layout.fillWidth: true; opacity: 0.5 }

                StandardSpinBoxRow {
                    label: qsTr("Torrent 最大连接数")
                    suffix: qsTr("每个 Torrent 最大连接数量 (0 = 无限制)")
                    value: Settings.btMaxPeers
                    onCommit: (v) => Settings.setBtMaxPeers(v)
                }

                NDivider { Layout.fillWidth: true; opacity: 0.5 }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    NCheckbox {
                        id: cryptoCb
                        checked: Settings.btRequireCrypto
                        onToggled: Settings.setBtRequireCrypto(checked)
                    }
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("要求加密连接")
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontMD
                        }
                        Text {
                            text: qsTr("只接受加密的 BitTorrent 握手。拒绝传统的未加密连接。")
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSM
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Text {
                    text: qsTr("修改上述值，然后点击 \"保存设置\" 应用。")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSM
                    topPadding: 10
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                ActionButtons {
                    onSaveClicked: toast.show(qsTr("BitTorrent 设置已保存!"))
                    onResetClicked: {
                        Settings.setEnableDht(true)
                        Settings.setBtMaxPeers(55)
                        Settings.setBtRequireCrypto(false)
                        toast.show(qsTr("BitTorrent 设置已重置"))
                    }
                }

                // 提示框
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: btTip.implicitHeight + 20
                    color: Theme.isDark ? "#383838" : "#f9f9f9"
                    radius: Theme.borderRadiusMedium
                    border.color: Theme.divider
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        Text { text: "💡"; font.pixelSize: Theme.fontMD }
                        Text {
                            id: btTip
                            text: qsTr("提示: 对于私人 Torrent，无论是否进行此设置，DHT 都会自动禁用")
                            color: "#8a6d3b"
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            font.pixelSize: Theme.fontSM
                        }
                    }
                }
            }

            // 用户代理设置
            SettingCard {
                id: uaCard
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
                    spacing: Theme.spacingSM
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    Text {
                        text: qsTr("自定义用户代理")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSM
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    NInput {
                        id: uaTextField
                        text: Settings.userAgent
                        Layout.fillWidth: true
                        enabled: uaCombo.currentIndex === 9
                        onEditingFinished: {
                            Settings.setUserAgent(text)
                            if(uaCombo.currentIndex !== 9) {
                                uaCombo.currentIndex = 9
                                Settings.setUserAgentIndex(9)
                            }
                        }
                        Binding {
                            target: uaTextField
                            property: "text"
                            value: Settings.userAgent
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

                // 提示框
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: uaTip.implicitHeight + 20
                    color: Theme.isDark ? "#383838" : "#f9f9f9"
                    radius: Theme.borderRadiusMedium
                    border.color: Theme.divider
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        Text { text: "💡"; font.pixelSize: Theme.fontMD }
                        Text {
                            id: uaTip
                            text: qsTr("提示: 某些服务器可能会阻止从 Aria2 下载。使用浏览器用户代理可绕过限制。")
                            color: "#8a6d3b"
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            font.pixelSize: Theme.fontSM
                        }
                    }
                }
            }

            // Aria2 RPC 设置
            SettingCard {
                title: qsTr("Aria2 RPC 设置")
                desc: qsTr("配置 Aria2 远程 RPC 监听端口")

                ColumnLayout {
                    spacing: Theme.spacingSM
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    Text {
                        text: qsTr("RPC 监听端口")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSM
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        NInput {
                            id: portField
                            text: Settings.rpcPort.toString()
                            Layout.preferredWidth: 240
                            validator: IntValidator { bottom: 1024; top: 65535 }
                            onEditingFinished: Settings.setRpcPort(parseInt(text))
                            Binding { target: portField; property: "text"; value: String(Settings.rpcPort); when: !portField.activeFocus }
                        }
                        Text {
                            text: "(1024-65535)"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSM
                        }
                    }
                }

                ColumnLayout {
                    spacing: Theme.spacingSM
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    Text {
                        text: qsTr("RPC 密钥")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSM
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        spacing: Theme.spacingMD
                        NInput {
                            id: secretField
                            text: Settings.rpcSecret
                            Layout.fillWidth: true
                            echoMode: showSecret.checked ? TextInput.Normal : TextInput.Password
                            onEditingFinished: Settings.setRpcSecret(text)
                            Binding { target: secretField; property: "text"; value: Settings.rpcSecret; when: !secretField.activeFocus }
                        }
                        NCheckbox {
                            id: showSecret
                            text: qsTr("显示")
                        }
                        NButton {
                            text: qsTr("生成随机密钥")
                            variant: "default"
                            onClicked: {
                                var c = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                var l = 32
                                var r = ""
                                for(var i=0; i<l; i++) r += c.charAt(Math.floor(Math.random()*c.length))
                                Settings.setRpcSecret(r)
                            }
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

                // 信息框
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: infoCol.implicitHeight + 24
                    color: Theme.isDark ? "#252526" : "#f0f0f0"
                    radius: Theme.borderRadiusMedium
                    ColumnLayout {
                        id: infoCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6
                        RowLayout {
                            Text { text: "ⓘ"; color: Theme.primary; font.pixelSize: 16 }
                            Text { text: qsTr("重要信息"); color: Theme.primary; font.bold: true; font.pixelSize: Theme.fontSM }
                        }
                        Text {
                            text: qsTr("• RPC 端口用于应用程序和 Aria2 引擎之间的通信\n• 默认端口为 16888\n• RPC 密钥用于应用程序和 Aria2 引擎之间的身份验证\n• 默认密钥为空\n• 为了安全起见，建议使用强随机密钥\n• 确保该端口未被其他应用程序使用")
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSM
                            lineHeight: 1.4
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                        RowLayout {
                            Text { text: "⚠️"; font.pixelSize: Theme.fontSM }
                            Text { text: qsTr("更改端口或密钥后必须重启应用程序！"); color: "#e6a23c"; font.bold: true; font.pixelSize: Theme.fontSM }
                        }
                        Text {
                            text: qsTr("• 选择 1024 到 65535 之间的端口号\n• 更改会立即保存，但只有在重启后才会生效")
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSM
                            lineHeight: 1.4
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // BitTorrent Trackers
            SettingCard {
                title: qsTr("BitTorrent Trackers")
                desc: qsTr("为 BitTorrent 下载配置 Trackers")

                Text {
                    text: qsTr("Trackers 源")
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    color: "transparent"
                    border.color: Theme.divider
                    border.width: 1
                    radius: Theme.borderRadiusMedium

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

                                NCheckbox {
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
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    NButton {
                        text: qsTr("同步 Trackers")
                        variant: "primary"
                        onClicked: {
                            toast.show(qsTr("正在同步 Trackers ，请稍候..."))
                            Downloader.fetchTrackers()
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: qsTr("启用每日自动更新")
                        color: Theme.textPrimary
                    }
                    NSwitch {
                        checked: Settings.autoUpdateTrackers
                        onToggled: Settings.setAutoUpdateTrackers(checked)
                    }
                }

                Text {
                    text: qsTr("当前 Trackers 列表")
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
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
                                font.pixelSize: Theme.fontSM
                            }
                        }
                    }
                }
            }

            // 其他设置
            SettingCard {
                title: qsTr("其他")
                desc: qsTr("其他杂项设置")

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    Text {
                        text: qsTr("启用网盘挂载")
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontMD
                        Layout.fillWidth: true
                    }
                    NSwitch {
                        checked: Settings.enableCloudMount
                        onToggled: Settings.setEnableCloudMount(checked)
                    }
                }
            }
        }
    }
}