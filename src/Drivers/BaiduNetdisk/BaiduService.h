#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantList>
#include <QJsonObject>
#include "../../Core/SettingsManager.h"
#include "BaiduFileModel.h"

class BaiduService : public QObject
{
    Q_OBJECT

public:
    explicit BaiduService(SettingsManager* settings, QObject *parent = nullptr);
    ~BaiduService();

    void listFiles(const QString &path = "/");
    void downloadFiles(const QStringList &fsIds, const QString &savePath);
    void deleteFiles(const QStringList &paths);

    signals:
        void fileListUpdated(const std::vector<BaiduFile> &files);
    void linkResolved(QString url, QJsonObject options, QString savePath, QString filename);
    void errorOccurred(QString message);
    void tokenExpired();

private:
    SettingsManager *m_settings;
    QNetworkAccessManager *m_netManager;

    const QString CLIENT_ID = "hq9yQ9w9kR4YHj1kyYafLygVocobh7Sf";
    const QString CLIENT_SECRET = "YH2VpZcFJHYNnV6vLfHQXDBhcE7ZChyE";

    void refreshToken();

    void fetchFileList(const QString &path);
    void fetchDlinks(const QStringList &fsIds, const QString &savePath);
    void executeDelete(const QStringList &paths);
};