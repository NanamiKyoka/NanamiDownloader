#pragma once

#include <QObject>
#include <QTimer>
#include <QMap>
#include <QVariantList>
#include <vector>
#include <memory>
#include <mutex>
#include <QJsonObject>

#ifdef _MSC_VER
#pragma warning(push, 0)
#endif
#include <libtorrent/session.hpp>
#include <libtorrent/torrent_handle.hpp>
#include <libtorrent/torrent_status.hpp>
#ifdef _MSC_VER
#pragma warning(pop)
#endif

#include "TaskModel.h"
#include "SettingsManager.h"

class TorrentService : public QObject
{
    Q_OBJECT

public:
    explicit TorrentService(SettingsManager* settings, QObject *parent = nullptr);
    ~TorrentService();

    void startService();
    void shutdownService();

    QString fetchMagnetMetadata(const QString &magnetLink);
    void fetchTorrentFileMetadata(const QString &filePath);

    void confirmDownload(const QString &gid, const QString &savePath, const QList<int> &selectedFilesIndex);
    void cancelDownload(const QString &gid, bool deleteFiles);
    void reconfigureTask(const QString &gid);

    void setFilePriority(const QString &gid, int fileIndex, bool enabled);

    void pause(const QString &gid);
    void resume(const QString &gid);
    void remove(const QString &gid, bool deleteFiles);
    void pauseAll();
    void resumeAll();

    void applySettings();

    std::vector<Task> getActiveTasks() const;
    std::vector<Task> getSeedingTasks() const;
    std::vector<Task> getWaitingTasks() const;
    std::vector<Task> getStoppedTasks() const;

    QJsonObject getTorrentDetails(const QString &gid);

signals:
    void tasksUpdated();
    void metadataLoaded(QString gid, QString name, QString size, QVariantList files);
    void taskExists(QString gid, QString name);

private slots:
    void onAlertTimer();
    void saveResumeData();

private:
    SettingsManager* m_settings;
    std::unique_ptr<libtorrent::session> m_session;
    QTimer m_alertTimer;
    QTimer m_saveResumeTimer;

    struct TorrentInfo {
        QString gid;
        QString name;
        libtorrent::torrent_handle handle;
        bool isMetaDataPending = false;
    };

    QMap<QString, TorrentInfo> m_torrents;
    std::mutex m_mutex;

    void handleAlerts();
    Task createTaskFromStatus(const libtorrent::torrent_status& status, const QString& gidOverride = "");
    QString getGid(const libtorrent::torrent_handle& h) const;
    QString formatSize(qint64 bytes);

    void loadResumeData();
    void writeResumeData(const libtorrent::add_torrent_params& atp);
    void addDefaultTrackers(libtorrent::add_torrent_params& p);
};