#include "ThemeController.h"

ThemeController::ThemeController(QObject *parent)
    : QObject(parent)
    , m_settings("NanamiDownloader", "Config")
{
    m_isDark = m_settings.value("isDark", false).toBool();
}

bool ThemeController::isDark() const
{
    return m_isDark;
}

void ThemeController::setIsDark(bool isDark)
{
    if (m_isDark != isDark) {
        m_isDark = isDark;
        m_settings.setValue("isDark", isDark);
        emit isDarkChanged();
        emit themeChanged();
    }
}

QColor ThemeController::background() const
{
    return m_isDark ? QColor("#1e1e1e") : QColor("#f5f5f7");
}

QColor ThemeController::surface() const
{
    return m_isDark ? QColor("#2d2d2d") : QColor("#ffffff");
}

QColor ThemeController::textPrimary() const
{
    return m_isDark ? QColor("#ffffff") : QColor("#333333");
}

QColor ThemeController::textSecondary() const
{
    return m_isDark ? QColor("#aaaaaa") : QColor("#666666");
}

QColor ThemeController::accent() const
{
    return QColor("#007bff");
}

QColor ThemeController::divider() const
{
    return m_isDark ? QColor("#3e3e3e") : QColor("#e0e0e0");
}

QColor ThemeController::sidebar() const
{
    return QColor("#222222");
}