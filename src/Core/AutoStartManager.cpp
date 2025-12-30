#include "AutoStartManager.h"
#include <QSettings>
#include <QCoreApplication>
#include <QDir>
#include "AutoStartManager.h"
#include <QSettings>
#include <QCoreApplication>
#include <QDir>

AutoStartManager::AutoStartManager(QObject *parent)
    : QObject(parent)
{
}

bool AutoStartManager::isAutoStart() const
{
#ifdef Q_OS_WIN
    QSettings settings("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", QSettings::NativeFormat);
    QString appName = QCoreApplication::applicationName();
    return settings.value(appName).isValid();
#else
    return false;
#endif
}

void AutoStartManager::setAutoStart(bool enable)
{
#ifdef Q_OS_WIN
    QSettings settings("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", QSettings::NativeFormat);
    QString appName = QCoreApplication::applicationName();
    if (enable) {
        QString appPath = QDir::toNativeSeparators(QCoreApplication::applicationFilePath());
        settings.setValue(appName, appPath);
    } else {
        settings.remove(appName);
    }
#endif
}