#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QQuickStyle>
#include <QTranslator>
#include "Core/DownloadManager.h"
#include "UI/ThemeController.h"
#include "Core/SettingsManager.h"
#include "Core/ClipboardHelper.h"
#include "Core/AutoStartManager.h"
#include "Utils/CursorPosProvider.h"
#include "Utils/SingleInstanceManager.h"
#include "Utils/Logger.h"
#include "Drivers/BaiduNetdisk/BaiduFileModel.h"
#include "Drivers/Thunder/ThunderFileModel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    Logger::instance()->init();
    qInstallMessageHandler(Logger::messageOutput);

    qInfo() << "App Started. Version: 1.1.0";
    qInfo() << "App Directory:" << QCoreApplication::applicationDirPath();
    qInfo() << "OS:" << QSysInfo::prettyProductName() << QSysInfo::currentCpuArchitecture();

    app.setWindowIcon(QIcon(":/src/Icons/icon.svg"));
    app.setOrganizationName("NanamiDownloader");
    app.setOrganizationDomain("nanami.app");

    SingleInstanceManager singleInstance("NanamiDownloader_Unique_Lock_Key");
    if (!singleInstance.checkAndListen()) {
        return 0;
    }

    QQuickStyle::setStyle("Basic");

    qmlRegisterType<DownloadManager>("Nanami.Core", 1, 0, "DownloadManager");
    qmlRegisterType<ThemeController>("Nanami.UI", 1, 0, "ThemeController");
    qmlRegisterType<SettingsManager>("Nanami.Core", 1, 0, "SettingsManager");
    qmlRegisterType<ClipboardHelper>("Nanami.Core", 1, 0, "ClipboardHelper");
    qmlRegisterType<BaiduFileModel>("Nanami.Core", 1, 0, "BaiduFileModel");
    qmlRegisterType<ThunderFileModel>("Nanami.Core", 1, 0, "ThunderFileModel");
    qmlRegisterType<Logger>("Nanami.Utils", 1, 0, "Logger");

    SettingsManager settingsManager;
    DownloadManager downloadManager(&settingsManager);
    ThemeController themeController;
    ClipboardHelper clipboardHelper;
    AutoStartManager autoStartManager;
    CursorPosProvider cursorPosProvider;

    QTranslator translator;
    auto loadLanguage = [&](const QString &lang) {
        if (translator.load(lang, ":/translations")) {
            app.installTranslator(&translator);
        } else {
            app.removeTranslator(&translator);
        }
    };

    loadLanguage(settingsManager.language());

    themeController.setIsDark(themeController.isDark());

    QQmlApplicationEngine engine;

    QObject::connect(&settingsManager, &SettingsManager::languageChanged, [&]() {
        loadLanguage(settingsManager.language());
        engine.retranslate();
    });

    engine.rootContext()->setContextProperty("Settings", &settingsManager);
    engine.rootContext()->setContextProperty("Downloader", &downloadManager);
    engine.rootContext()->setContextProperty("Theme", &themeController);
    engine.rootContext()->setContextProperty("Clipboard", &clipboardHelper);
    engine.rootContext()->setContextProperty("CursorPosProvider", &cursorPosProvider);
    engine.rootContext()->setContextProperty("SingleInstance", &singleInstance);
    engine.rootContext()->setContextProperty("AppLogger", Logger::instance());

    if (settingsManager.autoStart()) {
        autoStartManager.setAutoStart(true);
    } else {
        autoStartManager.setAutoStart(false);
    }

    QObject::connect(&app, &QGuiApplication::aboutToQuit, [&downloadManager](){
        downloadManager.shutdown();
    });

    const QUrl url(QStringLiteral("qrc:/src/UI/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}