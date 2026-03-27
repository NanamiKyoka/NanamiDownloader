// NButton.qml - Ant Design 风格按钮组件
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Nanami.UI 1.0

Button {
    id: root

    // 属性定义
    property string variant: "default"  // default, primary, dashed, text, link
    property string size: "middle"      // small, middle, large
    property bool loading: false
    property string iconSource: ""
    property color iconColor: {
        if (!enabled)
            return Theme.textDisabled;
        if (variant === "primary")
            return "#ffffff";
        return Theme.textPrimary;
    }
    
    // 动画状态 - 使用硬编码默认值后备
    readonly property real _animHoverScale: 1.02
    readonly property real _animPressScale: 0.98
    readonly property real targetScale: pressed ? _animPressScale : (hovered ? _animHoverScale : 1.0)

    // 尺寸映射
    readonly property var sizeMap: ({
            "small": {
                height: 24,
                fontSize: 12,
                padding: 8,
                iconSize: 14
            },
            "middle": {
                height: 32,
                fontSize: 13,
                padding: 12,
                iconSize: 18
            },
            "large": {
                height: 40,
                fontSize: 14,
                padding: 16,
                iconSize: 22
            }
        })

    implicitHeight: sizeMap[size].height
    implicitWidth: contentRow.implicitWidth + sizeMap[size].padding * 2

    // 样式配置
    flat: variant === "text" || variant === "link"
    enabled: !loading

    // 颜色配置
    readonly property color bgColor: {
        if (!enabled) {
            return variant === "primary" ? Theme.primary : Theme.disabled;
        }
        if (pressed) {
            return variant === "primary" ? Qt.darker(Theme.primary, 1.1) : variant === "dashed" ? Theme.pressed : variant === "text" || variant === "link" ? "transparent" : Theme.pressed;
        }
        if (hovered) {
            return variant === "primary" ? Qt.lighter(Theme.primary, 1.1) : variant === "dashed" ? Theme.hover : variant === "text" || variant === "link" ? Theme.hover : Theme.hover;
        }
        return variant === "primary" ? Theme.primary : variant === "dashed" ? "transparent" : variant === "text" || variant === "link" ? "transparent" : Theme.surface;
    }

    readonly property color borderColor: {
        if (!enabled)
            return Theme.border;
        if (pressed || hovered)
            return variant === "primary" ? Qt.darker(Theme.primary, 1.1) : Theme.borderFocus;
        return variant === "primary" ? Theme.primary : variant === "dashed" ? Theme.border : variant === "text" || variant === "link" ? "transparent" : Theme.border;
    }

    readonly property color textColor: {
        if (!enabled)
            return Theme.textDisabled;
        if (variant === "primary")
            return "#ffffff";
        if (variant === "link")
            return Theme.primary;
        return Theme.textPrimary;
    }

    // 背景
    background: Rectangle {
        id: backgroundRect
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        border.color: borderColor
        border.width: variant === "text" || variant === "link" ? 0 : 1
        radius: 4
        color: Theme.surface

        // Primary 状态层
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.primary
            opacity: {
                if (!root.enabled) return variant === "primary" ? 0.5 : 0
                if (variant !== "primary") return 0
                if (root.pressed) return 1
                if (root.hovered) return 1
                return 1
            }
            Behavior on opacity { NumberAnimation { duration: Theme ? Theme.durationFast : 150 } }
        }

        // 悬停状态层
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.hover
            opacity: root.enabled && root.hovered && variant !== "primary" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme ? Theme.durationFast : 150 } }
        }

        // 按下状态层
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.pressed
            opacity: root.enabled && root.pressed && variant !== "primary" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme ? Theme.durationFast : 150 } }
        }

        // 边框颜色动画
        Behavior on border.color {
            enabled: !Theme || Theme.animationsEnabled
            ColorAnimation { duration: Theme ? Theme.durationFast : 150; easing.type: Easing.OutCubic }
        }

        // 加载动画
        Rectangle {
            visible: root.loading
            anchors.fill: parent
            color: Theme.background
            opacity: 0.3
        }

        // 涟漪效果
        Rectangle {
            id: ripple
            visible: false
            color: "#ffffff"
            opacity: 0.3
            radius: width / 2

            PropertyAnimation on opacity {
                id: rippleAnim
                from: 0.3
                to: 0
                duration: 300
                onFinished: ripple.visible = false
            }
        }
    }

    // 内容
    contentItem: RowLayout {
        id: contentRow
        spacing: 8

        // 图标
        Image {
            id: btnIcon
            source: iconSource
            visible: iconSource !== ""
            Layout.preferredWidth: sizeMap[size].iconSize
            Layout.preferredHeight: sizeMap[size].iconSize

            layer.enabled: true
            layer.effect: ColorOverlay {
                color: iconColor
            }
        }

        // 加载指示器
        BusyIndicator {
            visible: root.loading
            running: root.loading
            Layout.preferredWidth: sizeMap[size].iconSize
            Layout.preferredHeight: sizeMap[size].iconSize
        }

        // 文本
        Text {
            id: btnText
            text: root.text
            font.pixelSize: sizeMap[size].fontSize
            color: textColor
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }

    // 缩放动画 - 使用 Theme 属性和硬编码默认值
    Behavior on scale {
        enabled: !Theme || Theme.animationsEnabled
        NumberAnimation { duration: Theme ? Theme.durationFast : 150; easing.type: Easing.OutCubic }
    }
    
    // 组件加载完成时应用初始缩放
    Component.onCompleted: {
        scale = 1.0
    }

    // 点击效果
    onPressed: {
        ripple.x = mouseArea.mouseX - ripple.width / 2;
        ripple.y = mouseArea.mouseY - ripple.height / 2;
        ripple.visible = true;
        rippleAnim.start();
    }
    
    // 应用目标缩放
    onTargetScaleChanged: {
        var animationsEnabled = true
        if (Theme) {
            animationsEnabled = Theme.animationsEnabled
        }
        if (animationsEnabled) {
            scale = targetScale
        } else {
            scale = 1.0
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: false
    }
}
