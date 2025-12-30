#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSet>
#include "Aria2Service.h"
#include "M3u8Service.h"
#include "TorrentService.h"
#include "../Drivers/BaiduNetdisk/BaiduService.h"
#include "../Drivers/BaiduNetdisk/BaiduFileModel.h"
#include "../Drivers/Thunder/ThunderService.h"
#include "../Drivers/Thunder/ThunderFileModel.h"
#include "TaskModel.h"
#include "SettingsManager.h"

class DownloadManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(TaskModel* allModel READ allModel CONSTANT)
    Q_PROPERTY(TaskModel* activeModel READ activeModel CONSTANT)
    Q_PROPERTY(TaskModel* waitingModel READ waitingModel CONSTANT)
    Q_PROPERTY(TaskModel* stoppedModel READ stoppedModel CONSTANT)
    Q_PROPERTY(TaskModel* seedingModel READ seedingModel CONSTANT)
    Q_PROPERTY(BaiduFileModel* baiduModel READ baiduModel CONSTANT)
    Q_PROPERTY(ThunderFileModel* thunderModel READ thunderModel CONSTANT)
    Q_PROPERTY(QString totalDownloadSpeedString READ totalDownloadSpeedString NOTIFY totalDownloadSpeedChanged)

public:
    explicit DownloadManager(SettingsManager* settings, QObject *parent = nullptr);
    ~DownloadManager();

    TaskModel* allModel() const { return m_allModel; }
    TaskModel* activeModel() const { return m_activeModel; }
    TaskModel* waitingModel() const { return m_waitingModel; }
    TaskModel* stoppedModel() const { return m_stoppedModel; }
    TaskModel* seedingModel() const { return m_seedingModel; }
    BaiduFileModel* baiduModel() const { return m_baiduModel; }
    ThunderFileModel* thunderModel() const { return m_thunderModel; }
    QString totalDownloadSpeedString() const { return m_totalDownloadSpeedString; }

    Q_INVOKABLE void startServices();
    void shutdown();

    Q_INVOKABLE void addUri(const QString &uri, const QJsonObject &options = QJsonObject());
    Q_INVOKABLE void addTorrent(const QString &filePath, const QJsonObject &options = QJsonObject());
    Q_INVOKABLE void downloadM3u8(const QString &url, const QString &saveName, const QString &saveDir, const QJsonObject &options);

    Q_INVOKABLE void confirmTorrent(const QString &gid, const QString &savePath, const QList<int> &selectedFiles);
    Q_INVOKABLE void cancelTorrent(const QString &gid);
    Q_INVOKABLE void overwriteTorrent(const QString &gid);
    Q_INVOKABLE void continueTorrent(const QString &gid);
    Q_INVOKABLE void setFilePriority(const QString &gid, int fileIndex, bool enabled);

    Q_INVOKABLE void pause(const QString &gid);
    Q_INVOKABLE void unpause(const QString &gid);
    Q_INVOKABLE void remove(const QString &gid);
    Q_INVOKABLE void handleDelete(const QString &gid, bool deleteFile);
    Q_INVOKABLE void pauseAll();
    Q_INVOKABLE void unpauseAll();
    Q_INVOKABLE void purgeDownloadResult();
    Q_INVOKABLE void openFolder(const QString &path);
    Q_INVOKABLE void openFile(const QString &path);
    Q_INVOKABLE void restartTask(const QString &gid);

    Q_INVOKABLE QJsonObject getTaskDetails(const QString &gid);
    Q_INVOKABLE void applyGlobalSettings();
    Q_INVOKABLE void fetchTrackers();

    Q_INVOKABLE void loadBaiduPath(const QString &path);
    Q_INVOKABLE void downloadBaiduFiles(const QList<int> &indexes);
    Q_INVOKABLE void deleteBaiduFiles(const QList<int> &indexes);

    Q_INVOKABLE void loadThunderPath(const QString &parentId);
    Q_INVOKABLE void downloadThunderFiles(const QList<int> &indexes);
    Q_INVOKABLE void deleteThunderFiles(const QList<int> &indexes);
    Q_INVOKABLE void loginThunder();

signals:
    void torrentMetadataLoaded(QString gid, QString name, QString size, QVariantList files);
    void magnetLinkAdded(QString gid);
    void taskExists(QString gid, QString name);
    void errorOccurred(QString message);
    void baiduFilesLoaded();
    void thunderFilesLoaded();
    void authRequired();
    void thunderVerificationRequired(QString url);
    void totalDownloadSpeedChanged();

private slots:
    void refreshTasks();

private:
    Aria2Service *m_aria2;
    M3u8Service *m_m3u8;
    TorrentService *m_torrent;
    BaiduService *m_baidu;
    ThunderService *m_thunder;

    TaskModel *m_allModel;
    TaskModel *m_activeModel;
    TaskModel *m_waitingModel;
    TaskModel *m_stoppedModel;
    TaskModel *m_seedingModel;
    BaiduFileModel *m_baiduModel;
    ThunderFileModel *m_thunderModel;

    SettingsManager *m_settings;
    QNetworkAccessManager *m_netManager;

    bool m_wasDownloading = false;
    void checkDownloadCompleteAction();
    void performShutdown();
    void performPlaySound();

    QMap<QString, int> m_retryState;
    QSet<QString> m_handledErrorGids;
    QSet<QString> m_previousActiveGids;
    QString m_totalDownloadSpeedString = "0 B/s";

    QString formatSpeed(qint64 bytes);
};