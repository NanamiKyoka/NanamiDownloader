#pragma once

#include <QObject>
#include <QColor>
#include <QSettings>

class ThemeController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isDark READ isDark WRITE setIsDark NOTIFY isDarkChanged)
    Q_PROPERTY(QColor background READ background NOTIFY themeChanged)
    Q_PROPERTY(QColor surface READ surface NOTIFY themeChanged)
    Q_PROPERTY(QColor textPrimary READ textPrimary NOTIFY themeChanged)
    Q_PROPERTY(QColor textSecondary READ textSecondary NOTIFY themeChanged)
    Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
    Q_PROPERTY(QColor divider READ divider NOTIFY themeChanged)
    Q_PROPERTY(QColor sidebar READ sidebar NOTIFY themeChanged)

public:
    explicit ThemeController(QObject *parent = nullptr);

    bool isDark() const;
    void setIsDark(bool isDark);

    QColor background() const;
    QColor surface() const;
    QColor textPrimary() const;
    QColor textSecondary() const;
    QColor accent() const;
    QColor divider() const;
    QColor sidebar() const;

    signals:
        void isDarkChanged();
    void themeChanged();

private:
    bool m_isDark;
    QSettings m_settings;
};