// NPopupAnimation.qml - 弹窗/对话框动画组件
// 用于为 Dialog、Popup 等组件提供统一的入场/退场动画
import QtQuick
import Nanami.UI 1.0

Item {
    id: root
    
    // 目标组件（Popup 或 Dialog）
    property Popup target: null
    
    // 动画配置 - 使用硬编码默认值
    readonly property int _defaultDuration: 250
    readonly property real _defaultEnterScale: 0.95
    readonly property real _defaultExitScale: 1.05
    property int enterDuration: _defaultDuration
    property int exitDuration: _defaultDuration
    property real enterScale: _defaultEnterScale
    property real exitScale: _defaultExitScale
    
    // 状态
    readonly property bool shouldAnimate: target && (!Theme || Theme.animationsEnabled)
    
    // 入场动画
    ParallelAnimation {
        id: enterAnimation
        running: false
        
        NumberAnimation {
            target: root.target
            property: "opacity"
            from: 0
            to: 1
            duration: root.shouldAnimate ? root.enterDuration : 0
            easing.type: Easing.OutCubic
        }
        
        NumberAnimation {
            target: root.target
            property: "scale"
            from: root.enterScale
            to: 1
            duration: root.shouldAnimate ? root.enterDuration : 0
            easing.type: Easing.OutBack
        }
    }
    
    // 退场动画
    ParallelAnimation {
        id: exitAnimation
        running: false
        
        NumberAnimation {
            target: root.target
            property: "opacity"
            from: 1
            to: 0
            duration: root.shouldAnimate ? root.exitDuration : 0
            easing.type: Easing.InCubic
        }
        
        NumberAnimation {
            target: root.target
            property: "scale"
            from: 1
            to: root.exitScale
            duration: root.shouldAnimate ? root.exitDuration : 0
            easing.type: Easing.InCubic
        }
        
        onFinished: {
            if (root.target) {
                root.target.visible = false
            }
        }
    }
    
    // 监听目标打开状态
    Connections {
        target: root.target
        function onOpenedChanged() {
            if (root.target.opened) {
                // 打开时触发入场动画
                if (root.shouldAnimate) {
                    root.target.scale = root.enterScale
                    root.target.opacity = 0
                    enterAnimation.start()
                } else {
                    root.target.scale = 1
                    root.target.opacity = 1
                }
            }
        }
        function onVisibleChanged() {
            if (!root.target.visible && !root.target.opened) {
                // 关闭时重置状态
                root.target.scale = 1
                root.target.opacity = 1
            }
        }
    }
    
    // 手动触发入场动画
    function animateIn() {
        if (root.shouldAnimate) {
            root.target.scale = root.enterScale
            root.target.opacity = 0
            enterAnimation.start()
        } else {
            root.target.scale = 1
            root.target.opacity = 1
        }
    }
    
    // 手动触发退场动画
    function animateOut() {
        if (root.shouldAnimate) {
            exitAnimation.start()
        } else {
            root.target.visible = false
        }
    }
}