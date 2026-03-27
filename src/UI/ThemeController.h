#pragma once

#include <QObject>
#include <QColor>
#include <QSettings>

class ThemeController : public QObject
{
    Q_OBJECT

    // 主题模式
    Q_PROPERTY(bool isDark READ isDark WRITE setIsDark NOTIFY isDarkChanged)

    // 基础色板 (Ant Design 色系)
    Q_PROPERTY(QColor primary READ primary NOTIFY themeChanged)
    Q_PROPERTY(QColor success READ success NOTIFY themeChanged)
    Q_PROPERTY(QColor warning READ warning NOTIFY themeChanged)
    Q_PROPERTY(QColor error READ error NOTIFY themeChanged)
    Q_PROPERTY(QColor info READ info NOTIFY themeChanged)

    // 文字色
    Q_PROPERTY(QColor textPrimary READ textPrimary NOTIFY themeChanged)
    Q_PROPERTY(QColor textSecondary READ textSecondary NOTIFY themeChanged)
    Q_PROPERTY(QColor textDisabled READ textDisabled NOTIFY themeChanged)
    Q_PROPERTY(QColor textHint READ textHint NOTIFY themeChanged)

    // 背景色
    Q_PROPERTY(QColor background READ background NOTIFY themeChanged)
    Q_PROPERTY(QColor surface READ surface NOTIFY themeChanged)
    Q_PROPERTY(QColor surfaceVariant READ surfaceVariant NOTIFY themeChanged)
    Q_PROPERTY(QColor elevated READ elevated NOTIFY themeChanged)

    // 边框色
    Q_PROPERTY(QColor divider READ divider NOTIFY themeChanged)
    Q_PROPERTY(QColor border READ border NOTIFY themeChanged)
    Q_PROPERTY(QColor borderFocus READ borderFocus NOTIFY themeChanged)

    // 特殊色
    Q_PROPERTY(QColor sidebar READ sidebar NOTIFY themeChanged)
    Q_PROPERTY(QColor hover READ hover NOTIFY themeChanged)
    Q_PROPERTY(QColor pressed READ pressed NOTIFY themeChanged)
    Q_PROPERTY(QColor disabled READ disabled NOTIFY themeChanged)
    Q_PROPERTY(QColor disabledText READ disabledText NOTIFY themeChanged)

    // 兼容旧 API (别名)
    Q_PROPERTY(QColor accent READ primary NOTIFY themeChanged)

    // 设计 Token - 尺寸
    Q_PROPERTY(int inputHeightSM READ inputHeightSM NOTIFY themeChanged)
    Q_PROPERTY(int inputHeight READ inputHeight NOTIFY themeChanged)
    Q_PROPERTY(int inputHeightLG READ inputHeightLG NOTIFY themeChanged)

    // 设计 Token - 字体大小
    Q_PROPERTY(int fontSM READ fontSM NOTIFY themeChanged)
    Q_PROPERTY(int fontMD READ fontMD NOTIFY themeChanged)
    Q_PROPERTY(int fontLG READ fontLG NOTIFY themeChanged)

    // 设计 Token - 图标大小
    Q_PROPERTY(int iconSizeSM READ iconSizeSM NOTIFY themeChanged)
    Q_PROPERTY(int iconSize READ iconSize NOTIFY themeChanged)
    Q_PROPERTY(int iconSizeLG READ iconSizeLG NOTIFY themeChanged)

    // 设计 Token - 间距
    Q_PROPERTY(int spacingXS READ spacingXS NOTIFY themeChanged)
    Q_PROPERTY(int spacingSM READ spacingSM NOTIFY themeChanged)
    Q_PROPERTY(int spacingMD READ spacingMD NOTIFY themeChanged)

    // 设计 Token - 圆角
    Q_PROPERTY(int borderRadiusSmall READ borderRadiusSmall NOTIFY themeChanged)
    Q_PROPERTY(int borderRadiusMedium READ borderRadiusMedium NOTIFY themeChanged)

    // 设计 Token - 动画时长
    Q_PROPERTY(int durationFast READ durationFast NOTIFY themeChanged)
    Q_PROPERTY(int durationNormal READ durationNormal NOTIFY themeChanged)
    Q_PROPERTY(int durationSlow READ durationSlow NOTIFY themeChanged)

    // 动画开关
    Q_PROPERTY(bool animationsEnabled READ animationsEnabled WRITE setAnimationsEnabled NOTIFY animationsEnabledChanged)

public:
    explicit ThemeController(QObject *parent = nullptr);

    // 主题模式
    bool isDark() const;
    void setIsDark(bool isDark);

    // 基础色板
    QColor primary() const;
    QColor success() const;
    QColor warning() const;
    QColor error() const;
    QColor info() const;

    // 文字色
    QColor textPrimary() const;
    QColor textSecondary() const;
    QColor textDisabled() const;
    QColor textHint() const;

    // 背景色
    QColor background() const;
    QColor surface() const;
    QColor surfaceVariant() const;
    QColor elevated() const;

    // 边框色
    QColor divider() const;
    QColor border() const;
    QColor borderFocus() const;

    // 特殊色
    QColor sidebar() const;
    QColor hover() const;
    QColor pressed() const;
    QColor disabled() const;
    QColor disabledText() const;

    // 设计 Token - 尺寸
    int inputHeightSM() const;
    int inputHeight() const;
    int inputHeightLG() const;

    // 设计 Token - 字体大小
    int fontSM() const;
    int fontMD() const;
    int fontLG() const;

    // 设计 Token - 图标大小
    int iconSizeSM() const;
    int iconSize() const;
    int iconSizeLG() const;

    // 设计 Token - 间距
    int spacingXS() const;
    int spacingSM() const;
    int spacingMD() const;

    // 设计 Token - 圆角
    int borderRadiusSmall() const;
    int borderRadiusMedium() const;

    // 设计 Token - 动画时长
    int durationFast() const;
    int durationNormal() const;
    int durationSlow() const;

    // 动画开关
    bool animationsEnabled() const;
    void setAnimationsEnabled(bool enabled);

signals:
    void isDarkChanged();
    void themeChanged();
    void animationsEnabledChanged();

private:
    bool m_isDark;
    bool m_animationsEnabled;
    QSettings m_settings;
};