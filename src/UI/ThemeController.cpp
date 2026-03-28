#include "ThemeController.h"

ThemeController::ThemeController(QObject *parent)
    : QObject(parent), m_settings("NanamiDownloader", "Config")
{
    m_isDark = m_settings.value("isDark", false).toBool();
    m_animationsEnabled = m_settings.value("animationsEnabled", true).toBool();
}

// 主题模式
bool ThemeController::isDark() const
{
    return m_isDark;
}

void ThemeController::setIsDark(bool isDark)
{
    if (m_isDark != isDark)
    {
        m_isDark = isDark;
        m_settings.setValue("isDark", isDark);
        emit isDarkChanged();
        emit themeChanged();
    }
}

// 基础色板 (Ant Design 色系)
QColor ThemeController::primary() const
{
    return QColor("#1890ff");
}

QColor ThemeController::success() const
{
    return QColor("#52c41a");
}

QColor ThemeController::warning() const
{
    return QColor("#faad14");
}

QColor ThemeController::error() const
{
    return QColor("#ff4d4f");
}

QColor ThemeController::info() const
{
    return QColor("#1890ff");
}

// 文字色
QColor ThemeController::textPrimary() const
{
    return m_isDark ? QColor("#ffffff") : QColor("#333333");
}

QColor ThemeController::textSecondary() const
{
    return m_isDark ? QColor("#aaaaaa") : QColor("#666666");
}

QColor ThemeController::textDisabled() const
{
    return m_isDark ? QColor("#666666") : QColor("#bbbbbb");
}

QColor ThemeController::textHint() const
{
    return m_isDark ? QColor("#888888") : QColor("#999999");
}

// 背景色
QColor ThemeController::background() const
{
    return m_isDark ? QColor("#1e1e1e") : QColor("#f5f5f7");
}

QColor ThemeController::surface() const
{
    return m_isDark ? QColor("#2d2d2d") : QColor("#ffffff");
}

QColor ThemeController::surfaceVariant() const
{
    return m_isDark ? QColor("#2b2b2b") : QColor("#f5f5f5");
}

QColor ThemeController::elevated() const
{
    return m_isDark ? QColor("#383838") : QColor("#ffffff");
}

// 边框色
QColor ThemeController::divider() const
{
    return m_isDark ? QColor("#3e3e3e") : QColor("#e0e0e0");
}

QColor ThemeController::border() const
{
    return m_isDark ? QColor("#4a4a4a") : QColor("#d9d9d9");
}

QColor ThemeController::borderFocus() const
{
    return primary();
}

// 特殊色
QColor ThemeController::sidebar() const
{
    return m_isDark ? QColor("#222222") : QColor("#ffffff");
}

QColor ThemeController::hover() const
{
    return m_isDark ? QColor("#444444") : QColor("#eeeeee");
}

QColor ThemeController::pressed() const
{
    return m_isDark ? QColor("#555555") : QColor("#dddddd");
}

QColor ThemeController::disabled() const
{
    return m_isDark ? QColor("#3a3a3a") : QColor("#f5f5f5");
}

QColor ThemeController::disabledText() const
{
    return m_isDark ? QColor("#666666") : QColor("#bbbbbb");
}

// 设计 Token - 尺寸
int ThemeController::inputHeightSM() const { return 24; }
int ThemeController::inputHeight() const { return 32; }
int ThemeController::inputHeightLG() const { return 40; }

// 设计 Token - 字体大小
int ThemeController::fontSM() const { return 12; }
int ThemeController::fontMD() const { return 14; }
int ThemeController::fontLG() const { return 16; }

// 设计 Token - 图标大小
int ThemeController::iconSizeSM() const { return 14; }
int ThemeController::iconSize() const { return 16; }
int ThemeController::iconSizeLG() const { return 20; }

// 设计 Token - 间距
int ThemeController::spacingXS() const { return 4; }
int ThemeController::spacingSM() const { return 8; }
int ThemeController::spacingMD() const { return 16; }

// 设计 Token - 圆角
int ThemeController::borderRadiusSmall() const { return 2; }
int ThemeController::borderRadiusMedium() const { return 4; }

// 设计 Token - 动画时长
int ThemeController::durationFast() const { return 150; }
int ThemeController::durationNormal() const { return 250; }
int ThemeController::durationSlow() const { return 400; }

// 动画开关
bool ThemeController::animationsEnabled() const
{
    return m_animationsEnabled;
}

void ThemeController::setAnimationsEnabled(bool enabled)
{
    if (m_animationsEnabled != enabled)
    {
        m_animationsEnabled = enabled;
        m_settings.setValue("animationsEnabled", enabled);
        emit animationsEnabledChanged();
    }
}