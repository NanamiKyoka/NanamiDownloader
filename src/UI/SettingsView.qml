import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nanami.UI 1.0

Item {
    id: root

    opacity: 1
    scale: 1

    states: [
        State {
            name: "hidden"
            PropertyChanges { target: root; opacity: 0; scale: 0.95 }
        },
        State {
            name: "visible"
            PropertyChanges { target: root; opacity: 1; scale: 1 }
        }
    ]

    transitions: [
        Transition {
            from: "hidden"; to: "visible"
            SequentialAnimation {
                NumberAnimation { property: "scale"; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutCubic }
            }
        },
        Transition {
            from: "visible"; to: "hidden"
            SequentialAnimation {
                NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; duration: 200; easing.type: Easing.InCubic }
            }
        }
    ]

    property int currentSettingTab: 0

    property var menuModel: Settings.enableCloudMount
        ? [qsTr("基础设置"), qsTr("高级设置"), qsTr("网盘挂载"), qsTr("实验室")]
        : [qsTr("基础设置"), qsTr("高级设置"), qsTr("实验室")]

    function getSwipeIndex(menuIndex) {
        if (Settings.enableCloudMount) return menuIndex;
        if (menuIndex >= 2) return menuIndex + 1;
        return menuIndex;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: Theme.background

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                Text {
                    text: qsTr("偏好设置")
                    font.bold: true
                    font.pixelSize: 20
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                ListView {
                    id: settingsMenu
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.menuModel
                    currentIndex: root.currentSettingTab
                    spacing: 5

                    delegate: Item {
                        width: 180
                        height: 44

                        property bool isHovered: mouseArea.containsMouse
                        property bool isSelected: index === root.currentSettingTab

                        Rectangle {
                            width: parent.width
                            height: parent.height
                            anchors.centerIn: parent
                            radius: 8
                            // 使用两层实现平滑过渡：基础层 + 选中层
                            color: Theme.background

                            // 选中状态背景
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: Theme.isDark ? "#333" : "#e6f2ff"
                                opacity: isSelected ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // 悬停状态背景
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: Theme.hover
                                opacity: isHovered && !isSelected ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            Rectangle {
                                width: 4; height: 18
                                color: Theme.accent
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                visible: index === root.currentSettingTab
                                radius: 2
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentSettingTab = index
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 25
                            spacing: 10

                            Text {
                                text: {
                                    if (Settings.enableCloudMount) {
                                        if(index === 0) return "⚙️"
                                        if(index === 1) return "🛠️"
                                        if(index === 2) return "☁️"
                                        return "🧪"
                                    } else {
                                        if(index === 0) return "⚙️"
                                        if(index === 1) return "🛠️"
                                        return "🧪"
                                    }
                                }
                                font.pixelSize: 14
                            }

                            Text {
                                text: modelData
                                color: index === root.currentSettingTab ? Theme.accent : Theme.textSecondary
                                font.pixelSize: 14
                                font.weight: index === root.currentSettingTab ? Font.Bold : Font.Normal
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
            Rectangle { width: 1; height: parent.height; color: Theme.divider; anchors.right: parent.right }
        }

        SwipeView {
            id: contentSwipe
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: getSwipeIndex(root.currentSettingTab)
            interactive: false
            clip: true
            orientation: Qt.Vertical

            BasicSettingsView {}

            AdvancedSettingsView {}

            CloudMountSettingsView {}

            Item {
                Text {
                    anchors.centerIn: parent
                    text: qsTr("实验室功能开发中...")
                    color: Theme.textSecondary
                    font.pixelSize: 16
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}