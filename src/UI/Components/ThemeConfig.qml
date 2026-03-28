// ThemeConfig.qml - 兼容层，连接 C++ ThemeController 和 QML Theme 单例
import QtQuick 2.15
import Nanami.UI 1.0

// 此文件作为桥接层存在
// Theme.qml 通过 Nanami.UI 1.0 导入 ThemeController
// ThemeController 在 main.cpp 中注册为 "Theme"

// 所有颜色属性通过 Theme.* 直接访问
// 例如：Theme.primary, Theme.textPrimary, Theme.isDark 等
QtObject {}
