import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0

Popup {
    id: root
    width: 400
    height: 450
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
        NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150 }
        NumberAnimation { property: "scale"; from: 1.0; to: 0.9; duration: 150; easing.type: Easing.InCubic }
    }

    background: Rectangle {
        color: Theme.surface
        radius: 12
        border.color: Theme.divider
        border.width: 1
    }

    contentItem: Item {
        id: flipContainer
        anchors.fill: parent

        property bool flipped: false
        property real angle: 0

        transform: Rotation {
            id: mainRotation
            origin.x: flipContainer.width / 2
            origin.y: flipContainer.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: flipContainer.angle
        }

        states: State {
            name: "back"
            when: flipContainer.flipped
            PropertyChanges { target: flipContainer; angle: 180 }
        }

        transitions: Transition {
            NumberAnimation { property: "angle"; duration: 600; easing.type: Easing.OutCubic }
        }

        Item {
            id: frontSide
            anchors.fill: parent
            visible: flipContainer.angle < 90

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140

                    Image {
                        source: "qrc:/src/Icons/icon.svg"
                        width: 80
                        height: 80
                        anchors.centerIn: parent
                        mipmap: true
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5

                    Text {
                        text: "NanamiDownloader"
                        font.bold: true
                        font.pixelSize: 20
                        color: Theme.textPrimary
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        text: "Version 1.1.1"
                        font.pixelSize: 13
                        color: Theme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: 24
                    Layout.topMargin: 30
                    spacing: 12

                    component LinkItem: Item {
                        property string icon
                        property string label
                        property string url
                        property bool isAction: false
                        Layout.fillWidth: true
                        height: 30

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 15

                            Text { text: icon; font.pixelSize: 16; Layout.alignment: Qt.AlignVCenter }
                            Text {
                                text: label
                                color: Theme.textPrimary
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text { text: "›"; color: Theme.textSecondary; font.pixelSize: 18; Layout.alignment: Qt.AlignVCenter }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (parent.isAction) {
                                    flipContainer.flipped = true
                                } else {
                                    Qt.openUrlExternally(parent.url)
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: parent.hovered ? (Theme.isDark ? "#ffffff" : "#000000") : "transparent"
                            opacity: 0.05
                            radius: 6
                            z: -1
                        }
                    }

                    LinkItem { icon: "🐙"; label: "GitHub Repository"; url: "https://github.com/NanamiKyoka/NanamiDownloader" }
                    LinkItem { icon: "🐞"; label: "Report Issues"; url: "https://github.com/NanamiKyoka/NanamiDownloader/issues" }
                    LinkItem { icon: "❤️"; label: "Credits"; isAction: true }
                }

                Item { Layout.fillHeight: true }

                Text {
                    text: "Copyright © 2025 NanamiKyoka \nAll rights reserved."
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 20
                    lineHeight: 1.2
                }
            }
        }

        Item {
            id: backSide
            anchors.fill: parent
            visible: flipContainer.angle >= 90

            transform: Rotation {
                origin.x: backSide.width / 2
                origin.y: backSide.height / 2
                axis { x: 0; y: 1; z: 0 }
                angle: 180
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Text {
                    text: "Credits"
                    font.bold: true
                    font.pixelSize: 18
                    color: Theme.textPrimary
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.divider
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    contentWidth: availableWidth

                    ColumnLayout {
                        width: parent.width
                        spacing: 15

                        component CreditItem: ColumnLayout {
                            property string name
                            property string license
                            property string url

                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: name
                                color: Theme.textPrimary
                                font.bold: true
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            RowLayout {
                                spacing: 10
                                Layout.alignment: Qt.AlignHCenter

                                Text {
                                    text: license
                                    color: Theme.textSecondary
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: "🔗 Homepage"
                                    color: Theme.accent
                                    font.pixelSize: 12
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally(url)
                                    }
                                }
                            }
                        }

                        CreditItem { name: "Qt Framework"; license: "LGPL v3"; url: "https://www.qt.io" }
                        CreditItem { name: "Libtorrent (Rasterbar)"; license: "BSD"; url: "https://github.com/arvidn/libtorrent" }
                        CreditItem { name: "Aria2"; license: "GPL"; url: "https://github.com/aria2/aria2" }
                        CreditItem { name: "FFmpeg"; license: "GPL v3"; url: "https://ffmpeg.org" }
                        CreditItem { name: "N_m3u8DL-RE"; license: "MIT"; url: "https://github.com/nilaoda/N_m3u8DL-RE" }
                        CreditItem { name: "OpenSSL"; license: "Apache 2.0"; url: "https://www.openssl.org" }
                        CreditItem { name: "Boost"; license: "Boost Software License"; url: "https://www.boost.org" }

                        Item { height: 10 }
                    }
                }

                Button {
                    text: qsTr("返回")
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: flipContainer.flipped = false
                    palette.button: Theme.surface
                    palette.buttonText: Theme.textPrimary
                    palette.highlight: Theme.accent
                    hoverEnabled: true
                }
            }
        }
    }
}