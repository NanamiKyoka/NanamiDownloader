// NIconButton.qml - 图标按钮组件
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Nanami.UI 1.0

Button {
    id: root

    // 属性定义
    property string iconName: ""
    property int iconSize: 18
    property color iconColor: Theme.textPrimary
    property color hoverColor: Theme.primary
    property color backgroundNormal: "transparent"
    property color backgroundHover: Theme.hover
    property color backgroundPressed: Theme.pressed
    property int buttonSize: 32
    property string tooltip: ""
    
    // 动画状态 - 使用硬编码默认值后备
    readonly property real _animHoverScale: 1.02
    readonly property real _animPressScale: 0.98
    readonly property real targetScale: pressed ? _animPressScale : (hovered ? _animHoverScale : 1.0)

    // 尺寸
    implicitWidth: buttonSize
    implicitHeight: buttonSize

    // 背景
    background: Rectangle {
        id: backgroundRect
        implicitWidth: root.buttonSize
        implicitHeight: root.buttonSize
        radius: 4
        color: Theme.background

        // 悬停状态层
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: backgroundHover
            opacity: root.enabled && root.hovered && !root.pressed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme ? Theme.durationFast : 150 } }
        }

        // 按下状态层
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: backgroundPressed
            opacity: root.enabled && root.pressed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme ? Theme.durationFast : 150 } }
        }
    }

    // 图标
    contentItem: Image {
        source: root.iconName
        width: root.iconSize
        height: root.iconSize
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectFit

        // 颜色叠加
        layer.enabled: true
        layer.effect: ColorOverlay {
            color: {
                if (!root.enabled)
                    return Theme.textDisabled;
                if (root.hovered)
                    return hoverColor;
                return iconColor;
            }
        }
    }

    // 缩放动画 - 使用 Theme 属性和硬编码默认值
    Behavior on scale {
        enabled: !Theme || Theme.animationsEnabled
        NumberAnimation { duration: Theme ? Theme.durationFast : 150; easing.type: Easing.OutCubic }
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

    // 工具提示
    ToolTip {
        visible: root.tooltip !== "" && root.hovered
        text: root.tooltip
        delay: 500
    }
}
