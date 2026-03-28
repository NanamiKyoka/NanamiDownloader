// NListItemAnimation.qml - 列表项动画组件
// 用于为 ListView 的 delegate 提供入场/删除动画
import QtQuick
import Nanami.UI 1.0

Item {
    id: root
    
    // 目标组件（通常是 delegate 的根元素）
    property Item target: null
    
    // 动画配置 - 使用硬编码默认值
    readonly property int _defaultDuration: 250
    property int enterDuration: _defaultDuration
    property int exitDuration: _defaultDuration
    property int enterDelay: 0  // 入场延迟，可用于交错动画
    
    // 状态
    readonly property bool shouldAnimate: !Theme || Theme.animationsEnabled
    
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
            property: "x"
            from: -20
            to: 0
            duration: root.shouldAnimate ? root.enterDuration : 0
            easing.type: Easing.OutCubic
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
            property: "height"
            to: 0
            duration: root.shouldAnimate ? root.exitDuration : 0
            easing.type: Easing.InCubic
        }
        
        onFinished: {
            if (root.target && root.target.ListView && root.target.ListView.view) {
                root.target.ListView.view.model.remove(root.target.ListView.view.index)
            }
        }
    }
    
    // 组件加载时自动触发入场动画
    Component.onCompleted: {
        if (root.shouldAnimate && root.target) {
            root.target.opacity = 0
            root.target.x = -20
            enterAnimation.start()
        }
    }
    
    // 手动触发入场动画
    function animateIn() {
        if (root.shouldAnimate && root.target) {
            root.target.opacity = 0
            root.target.x = -20
            enterAnimation.start()
        } else if (root.target) {
            root.target.opacity = 1
            root.target.x = 0
        }
    }
    
    // 手动触发退场动画
    function animateOut() {
        if (root.shouldAnimate) {
            exitAnimation.start()
        }
    }
    
    // 设置交错延迟
    function setStaggerDelay(index, baseDelay) {
        enterDelay = index * (baseDelay || 30)
        enterAnimation.animations[0].duration = root.enterDuration + enterDelay
    }
}