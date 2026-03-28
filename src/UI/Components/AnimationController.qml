// AnimationController.qml - 动画控制器单例
// 提供标准化的动画配置，响应 Theme.animationsEnabled 状态
pragma Singleton
import QtQuick 2.15
import Nanami.UI 1.0

QtObject {
    // 默认值（后备）
    readonly property int _defaultDurationFast: 150
    readonly property int _defaultDurationNormal: 250
    readonly property int _defaultDurationSlow: 400
    readonly property bool _defaultAnimationsEnabled: true

    // 动画时长配置（从 Theme 读取，带默认值后备）
    readonly property int durationFast: Theme ? Theme.durationFast : _defaultDurationFast
    readonly property int durationNormal: Theme ? Theme.durationNormal : _defaultDurationNormal
    readonly property int durationSlow: Theme ? Theme.durationSlow : _defaultDurationSlow
    
    // 缓动曲线类型（直接使用数值，Easing.Type 枚举值）
    readonly property int easingEaseOut: 4           // Easing.OutCubic
    readonly property int easingEaseIn: 1            // Easing.InCubic
    readonly property int easingEaseInOut: 2         // Easing.InOutCubic
    readonly property int easingEaseOutBack: 16      // Easing.OutBack
    readonly property int easingEaseOutElastic: 14   // Easing.OutElastic
    readonly property int easingEaseOutBounce: 6     // Easing.OutBounce
    readonly property int easingLinear: 0            // Easing.Linear
    
    // 标准动画时长（语义化命名）
    readonly property int buttonDuration: durationFast          // 按钮动画
    readonly property int hoverDuration: durationFast           // 悬停动画
    readonly property int pressDuration: durationFast           // 按压动画
    readonly property int dialogDuration: durationNormal        // 对话框动画
    readonly property int pageDuration: durationNormal          // 页面切换
    readonly property int listDuration: durationNormal          // 列表动画
    readonly property int progressDuration: durationNormal      // 进度条动画
    readonly property int fadeDuration: durationFast            // 淡入淡出
    
    // 缩放配置
    readonly property real hoverScale: 1.02        // 悬停缩放比例
    readonly property real pressScale: 0.98        // 按压缩小比例
    readonly property real dialogEnterScale: 0.95  // 对话框入场缩放
    readonly property real dialogExitScale: 1.05   // 对话框退场缩放
    
    // 辅助方法：获取动画时长（禁用时返回 0）
    function getDuration(duration) {
        var enabled = _defaultAnimationsEnabled
        if (Theme) {
            enabled = Theme.animationsEnabled
        }
        return enabled ? duration : 0
    }
    
    // 辅助方法：判断是否启用动画
    function isEnabled() {
        if (Theme) {
            return Theme.animationsEnabled
        }
        return _defaultAnimationsEnabled
    }
}

// 使用示例：
// 1. 在组件中使用：
//    Behavior on scale {
//        enabled: Theme.animationsEnabled
//        NumberAnimation { 
//            duration: AnimationController.hoverDuration
//            easing.type: AnimationController.easingEaseOut
//        }
//    }
//
// 2. 使用辅助方法：
//    Behavior on opacity {
//        enabled: Theme.animationsEnabled
//        NumberAnimation { duration: AnimationController.getDuration(AnimationController.fadeDuration) }
//    }