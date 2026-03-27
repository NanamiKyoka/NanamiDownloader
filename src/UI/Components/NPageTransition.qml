// NPageTransition.qml - 页面切换动画组件
// 用于页面切换时的淡入淡出 + 滑动效果
import QtQuick
import Nanami.UI 1.0

Loader {
    id: root
    
    // 动画配置 - 使用硬编码默认值
    readonly property int _defaultDuration: 250
    property int transitionDuration: _defaultDuration
    property string transitionType: "fadeSlide"  // fade, slide, fadeSlide
    
    // 状态
    readonly property bool shouldAnimate: !Theme || Theme.animationsEnabled
    
    // 当前页面
    property var currentPage: null
    property var previousPage: null
    
    // 页面切换动画
    ParallelAnimation {
        id: enterAnimation
        running: false
        
        NumberAnimation {
            target: root.item
            property: "opacity"
            from: 0
            to: 1
            duration: root.shouldAnimate ? root.transitionDuration : 0
            easing.type: Easing.OutCubic
        }
        
        NumberAnimation {
            target: root.item
            property: "x"
            from: root.transitionType === "fade" ? 0 : 50
            to: 0
            duration: root.shouldAnimate && root.transitionType !== "fade" ? root.transitionDuration : 0
            easing.type: Easing.OutCubic
        }
    }
    
    // 加载页面
    function loadPage(pageComponent, properties) {
        if (root.item) {
            // 如果有动画，先执行退场动画
            if (root.shouldAnimate) {
                previousPage = root.item
                exitAnimation.start()
            } else {
                setSource(pageComponent, properties || {})
                playEnterAnimation()
            }
        } else {
            setSource(pageComponent, properties || {})
            playEnterAnimation()
        }
    }
    
    // 播放入场动画
    function playEnterAnimation() {
        if (root.shouldAnimate && root.item) {
            root.item.opacity = 0
            if (root.transitionType !== "fade") {
                root.item.x = 50
            }
            enterAnimation.start()
        }
    }
    
    // 退场动画
    ParallelAnimation {
        id: exitAnimation
        running: false
        
        NumberAnimation {
            target: root.item
            property: "opacity"
            from: 1
            to: 0
            duration: root.shouldAnimate ? root.transitionDuration : 0
            easing.type: Easing.InCubic
        }
        
        NumberAnimation {
            target: root.item
            property: "x"
            from: 0
            to: -50
            duration: root.shouldAnimate && root.transitionType !== "fade" ? root.transitionDuration : 0
            easing.type: Easing.InCubic
        }
        
        onFinished: {
            if (root.sourceComponent) {
                root.sourceComponent = null
            }
        }
    }
    
    // 监听 item 变化
    onItemChanged: {
        if (item && status === Loader.Ready) {
            playEnterAnimation()
        }
    }
}

// 使用示例：
// NPageTransition {
//     id: pageLoader
//     anchors.fill: parent
//     transitionType: "fadeSlide"  // 或 "fade" 或 "slide"
// }
//
// 切换页面：
// pageLoader.loadPage("SettingsView.qml", { someProperty: value })