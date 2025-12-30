#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include "../../Core/SettingsManager.h"
#include "ThunderFileModel.h"

class ThunderService : public QObject
{
    Q_OBJECT

public:
    explicit ThunderService(SettingsManager* settings, QObject *parent = nullptr);
    ~ThunderService();

    void listFiles(const QString &parentId = "");
    void downloadFiles(const QStringList &fileIds, const QString &savePath);
    void deleteFiles(const QStringList &fileIds);

    // Explicit login trigger
    void forceLogin();

signals:
    void fileListUpdated(const std::vector<ThunderFile> &files);
    void linkResolved(QString url, QJsonObject options, QString savePath, QString filename);
    void errorOccurred(QString message);
    void authRequired();
    void verificationRequired(QString url);

private:
    SettingsManager *m_settings;
    QNetworkAccessManager *m_netManager;

    const QString APP_ID = "40";
    const QString APP_KEY = "34a062aaa22f906fca4fefe9fb3a3021";
    const QString CLIENT_ID = "Xp6vsxz_7IYVw2BB";
    const QString CLIENT_SECRET = "Xp6vsy4tN9toTVdMSpomVdXpRmES";
    const QString CLIENT_VERSION = "8.31.0.9726";
    const QString PACKAGE_NAME = "com.xunlei.downloadprovider";
    const QString API_URL = "https://api-pan.xunlei.com/drive/v1";
    const QString XLUSER_API = "https://xluser-ssl.xunlei.com";

    const QString DOWNLOAD_USER_AGENT = "Dalvik/2.1.0 (Linux; U; Android 12; M2004J7AC Build/SP1A.210812.016)";
    const QString GENERAL_USER_AGENT = "ANDROID-com.xunlei.downloadprovider/8.31.0.9726 netWorkType/5G appid/40 deviceName/Xiaomi_M2004j7ac deviceModel/M2004J7AC OSVersion/12 protocolVersion/301 platformVersion/10 sdkVersion/512000 Oauth2Client/0.9 (Linux 4_14_186-perf-gddfs8vbb238b) (JAVA 0)";

    void login();
    void fetchToken(const QString &sessionId);
    void fetchFileList(const QString &parentId);
    void fetchDlinks(const QStringList &fileIds, const QString &savePath);
    void executeDelete(const QStringList &fileIds);
    void refreshCaptchaToken(const QString &action, const QString &username);

    QNetworkRequest createRequest(const QString &url);
    QString generateDeviceSign(const QString &deviceId);
    QString generateCaptchaSign(const QString &timestamp);
};