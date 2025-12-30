#include "DownloadManager.h"
#include <QDesktopServices>
#include <QUrl>
#include <QFileInfo>
#include <QProcess>
#include <QDebug>
#include <QTimer>
#include <QFile>
#include <QStandardPaths>
#include <QUuid>
#include <QApplication>

DownloadManager::DownloadManager(SettingsManager* settings, QObject *parent)
    : QObject(parent)
    , m_aria2(new Aria2Service(settings, this))
    , m_m3u8(new M3u8Service(settings, this))
    , m_torrent(new TorrentService(settings, this))
    , m_baidu(new BaiduService(settings, this))
    , m_thunder(new ThunderService(settings, this))
    , m_allModel(new TaskModel(this))
    , m_activeModel(new TaskModel(this))
    , m_waitingModel(new TaskModel(this))
    , m_stoppedModel(new TaskModel(this))
    , m_seedingModel(new TaskModel(this))
    , m_baiduModel(new BaiduFileModel(this))
    , m_thunderModel(new ThunderFileModel(this))
    , m_settings(settings)
    , m_netManager(new QNetworkAccessManager(this))
{
    connect(m_aria2, &Aria2Service::tasksUpdated, this, &DownloadManager::refreshTasks);
    connect(m_m3u8, &M3u8Service::tasksUpdated, this, &DownloadManager::refreshTasks);
    connect(m_torrent, &TorrentService::tasksUpdated, this, &DownloadManager::refreshTasks);

    connect(m_torrent, &TorrentService::metadataLoaded, this, &DownloadManager::torrentMetadataLoaded);
    connect(m_torrent, &TorrentService::taskExists, this, &DownloadManager::taskExists);

    connect(m_m3u8, &M3u8Service::errorOccurred, this, [this](QString msg){
        emit errorOccurred("M3U8 Error: " + msg);
    });

    connect(m_baidu, &BaiduService::fileListUpdated, this, [this](const std::vector<BaiduFile> &files){
        m_baiduModel->updateData(files);
        emit baiduFilesLoaded();
    });
    connect(m_baidu, &BaiduService::linkResolved, this, [this](QString url, QJsonObject options, QString savePath, QString filename){
        QJsonObject finalOptions = options;
        if (!finalOptions.contains("out") && !filename.isEmpty()) {
            finalOptions["out"] = filename;
        }
        addUri(url, finalOptions);
        qInfo() << "Baidu download started:" << filename;
    });
    connect(m_baidu, &BaiduService::errorOccurred, this, [this](QString msg){
        emit errorOccurred("Baidu Error: " + msg);
    });

    connect(m_thunder, &ThunderService::fileListUpdated, this, [this](const std::vector<ThunderFile> &files){
        m_thunderModel->updateData(files);
        emit thunderFilesLoaded();
    });
    connect(m_thunder, &ThunderService::linkResolved, this, [this](QString url, QJsonObject options, QString savePath, QString filename){
        addUri(url, options);
        qInfo() << "Thunder download started:" << filename;
    });
    connect(m_thunder, &ThunderService::errorOccurred, this, [this](QString msg){
        emit errorOccurred("Thunder Error: " + msg);
    });
    connect(m_thunder, &ThunderService::authRequired, this, &DownloadManager::authRequired);
    connect(m_thunder, &ThunderService::verificationRequired, this, &DownloadManager::thunderVerificationRequired);

    refreshTasks();
}

DownloadManager::~DownloadManager()
{
    shutdown();
}

void DownloadManager::startServices()
{
    m_aria2->startService();
}

void DownloadManager::shutdown()
{
    if (m_aria2) m_aria2->shutdownService();
    if (m_torrent) m_torrent->shutdownService();
}

void DownloadManager::addUri(const QString &uri, const QJsonObject &options)
{
    QString cleanUri = uri.trimmed();

    if (cleanUri.startsWith("magnet:?")) {
        QString gid = m_torrent->fetchMagnetMetadata(cleanUri);
        if (!gid.isEmpty()) {
            emit magnetLinkAdded(gid);
        }
    } else if (cleanUri.endsWith(".torrent", Qt::CaseInsensitive)) {
        QNetworkRequest req((QUrl(cleanUri)));

        if (options.contains("header")) {
            QJsonArray headers = options["header"].toArray();
            for (const auto& h : headers) {
                QString headerStr = h.toString();
                int idx = headerStr.indexOf(":");
                if (idx != -1) {
                    req.setRawHeader(headerStr.left(idx).trimmed().toUtf8(), headerStr.mid(idx + 1).trimmed().toUtf8());
                }
            }
        }

        QNetworkReply *reply = m_netManager->get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply, options](){
            reply->deleteLater();
            if (reply->error() == QNetworkReply::NoError) {
                QByteArray data = reply->readAll();
                QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
                QString tempPath = tempDir + "/" + QUuid::createUuid().toString(QUuid::WithoutBraces) + ".torrent";

                QFile f(tempPath);
                if (f.open(QIODevice::WriteOnly)) {
                    f.write(data);
                    f.close();
                    addTorrent(tempPath, options);
                } else {
                    qWarning() << "Failed to write temp torrent file:" << f.errorString();
                }
            } else {
                qWarning() << "Failed to download .torrent file:" << reply->errorString();
            }
        });
    } else {
        m_aria2->addUri(cleanUri, options);
    }
}

void DownloadManager::addTorrent(const QString &filePath, const QJsonObject &options)
{
    m_torrent->startService();
    m_torrent->fetchTorrentFileMetadata(filePath);
}

void DownloadManager::downloadM3u8(const QString &url, const QString &saveName, const QString &saveDir, const QJsonObject &options)
{
    m_m3u8->startTask(url, saveName, saveDir, options);
}

void DownloadManager::confirmTorrent(const QString &gid, const QString &savePath, const QList<int> &selectedFiles)
{
    m_torrent->confirmDownload(gid, savePath, selectedFiles);
}

void DownloadManager::cancelTorrent(const QString &gid)
{
    m_torrent->cancelDownload(gid, true);
}

void DownloadManager::overwriteTorrent(const QString &gid)
{
    m_torrent->reconfigureTask(gid);
}

void DownloadManager::continueTorrent(const QString &gid)
{
    m_torrent->resume(gid);
}

void DownloadManager::setFilePriority(const QString &gid, int fileIndex, bool enabled)
{
    if (gid.startsWith("bt_")) {
        m_torrent->setFilePriority(gid, fileIndex, enabled);
    }
}

void DownloadManager::pause(const QString &gid)
{
    if (gid.startsWith("m3u8_")) m_m3u8->stopTask(gid);
    else if (gid.startsWith("bt_")) m_torrent->pause(gid);
    else m_aria2->pause(gid);
}

void DownloadManager::unpause(const QString &gid)
{
    if (gid.startsWith("m3u8_")) m_m3u8->resumeTask(gid);
    else if (gid.startsWith("bt_")) m_torrent->resume(gid);
    else m_aria2->unpause(gid);
}

void DownloadManager::remove(const QString &gid)
{
    handleDelete(gid, false);
}

void DownloadManager::handleDelete(const QString &gid, bool deleteFile)
{
    qInfo() << "Deleting task:" << gid << "Delete files:" << deleteFile;
    if (gid.startsWith("m3u8_")) {
        bool isActive = false;
        auto activeTasks = m_m3u8->getActiveTasks();
        for(const auto& t : activeTasks) if(t.gid == gid) isActive = true;

        if (isActive) {
            m_m3u8->cancelTask(gid);
        } else {
            m_m3u8->deleteTask(gid, deleteFile);
        }
    } else if (gid.startsWith("bt_")) {
        m_torrent->remove(gid, deleteFile);
    } else {
        bool isActive = false;
        auto activeTasks = m_aria2->getActiveTasks();
        for(const auto& t : activeTasks) if(t.gid == gid) isActive = true;

        if(!isActive) {
            auto waitingTasks = m_aria2->getWaitingTasks();
            for(const auto& t : waitingTasks) if(t.gid == gid) isActive = true;
        }

        if (isActive) {
            m_aria2->remove(gid);
        } else {
            QString path;
            auto stoppedTasks = m_aria2->getStoppedTasks();
            for(const auto& t : stoppedTasks) {
                if(t.gid == gid) {
                    path = t.path;
                    break;
                }
            }

            if (deleteFile && !path.isEmpty()) {
                QFile::remove(path);
                QFile::remove(path + ".aria2");
            }
            m_aria2->removeDownloadResult(gid);
        }
    }
}

void DownloadManager::pauseAll()
{
    m_aria2->pauseAll();
    m_torrent->pauseAll();
    m_m3u8->pauseAll();
}

void DownloadManager::unpauseAll()
{
    m_aria2->unpauseAll();
    m_torrent->resumeAll();
    m_m3u8->resumeAll();
}

void DownloadManager::purgeDownloadResult()
{
    m_aria2->purgeDownloadResult();
}

void DownloadManager::openFolder(const QString &path)
{
    if (path.isEmpty()) return;
    QFileInfo fi(path);
    QString folderPath = fi.isDir() ? fi.absoluteFilePath() : fi.absolutePath();
    QDesktopServices::openUrl(QUrl::fromLocalFile(folderPath));
}

void DownloadManager::openFile(const QString &path)
{
    if (path.isEmpty()) return;
    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

void DownloadManager::restartTask(const QString &gid)
{
    if (gid.startsWith("m3u8_")) {
        m_m3u8->restartTask(gid);
    } else if (gid.startsWith("bt_")) {
        m_torrent->resume(gid);
    } else {
        std::vector<Task> stopped = m_aria2->getStoppedTasks();
        QString url;
        bool found = false;
        for (const auto &t : stopped) {
            if (t.gid == gid) {
                url = t.url;
                found = true;
                break;
            }
        }
        if (!found) {
             std::vector<Task> active = m_aria2->getActiveTasks();
             for (const auto &t : active) { if(t.gid == gid) { url = t.url; found = true; break; } }
        }
        if (!found) {
             std::vector<Task> waiting = m_aria2->getWaitingTasks();
             for (const auto &t : waiting) { if(t.gid == gid) { url = t.url; found = true; break; } }
        }

        if (found && !url.isEmpty()) {
            handleDelete(gid, false);
            addUri(url);
        }
    }
}

QJsonObject DownloadManager::getTaskDetails(const QString &gid) {
    if (gid.startsWith("bt_")) {
        return m_torrent->getTorrentDetails(gid);
    }
    return QJsonObject();
}

void DownloadManager::applyGlobalSettings()
{
    m_aria2->applyGlobalSettings();
    m_torrent->applySettings();
}

void DownloadManager::refreshTasks()
{
    std::vector<Task> active = m_aria2->getActiveTasks();
    std::vector<Task> m3u8Active = m_m3u8->getActiveTasks();
    std::vector<Task> btActive = m_torrent->getActiveTasks();

    active.insert(active.end(), m3u8Active.begin(), m3u8Active.end());
    active.insert(active.end(), btActive.begin(), btActive.end());
    m_activeModel->updateTasks(active);

    qint64 totalSpeed = 0;
    for(const auto& t : active) {
        totalSpeed += t.downloadSpeed;
    }

    QString speedStr = formatSpeed(totalSpeed);
    if (speedStr != m_totalDownloadSpeedString) {
        m_totalDownloadSpeedString = speedStr;
        emit totalDownloadSpeedChanged();
    }

    std::vector<Task> waiting = m_aria2->getWaitingTasks();
    std::vector<Task> m3u8Waiting = m_m3u8->getWaitingTasks();
    std::vector<Task> btWaiting = m_torrent->getWaitingTasks();

    waiting.insert(waiting.end(), m3u8Waiting.begin(), m3u8Waiting.end());
    waiting.insert(waiting.end(), btWaiting.begin(), btWaiting.end());
    m_waitingModel->updateTasks(waiting);

    std::vector<Task> stopped = m_aria2->getStoppedTasks();
    std::vector<Task> m3u8Stopped = m_m3u8->getStoppedTasks();
    std::vector<Task> btStopped = m_torrent->getStoppedTasks();

    stopped.insert(stopped.end(), m3u8Stopped.begin(), m3u8Stopped.end());
    stopped.insert(stopped.end(), btStopped.begin(), btStopped.end());
    m_stoppedModel->updateTasks(stopped);

    std::vector<Task> seeding = m_torrent->getSeedingTasks();
    m_seedingModel->updateTasks(seeding);

    std::vector<Task> all;
    all.reserve(active.size() + waiting.size() + stopped.size() + seeding.size());
    all.insert(all.end(), active.begin(), active.end());
    all.insert(all.end(), waiting.begin(), waiting.end());
    all.insert(all.end(), stopped.begin(), stopped.end());
    all.insert(all.end(), seeding.begin(), seeding.end());
    m_allModel->updateTasks(all);

    for (const auto& task : stopped) {
        if (task.status == "error") {
            if (!m_handledErrorGids.contains(task.gid)) {
                m_handledErrorGids.insert(task.gid);

                if (m_settings->onDownloadFailure() == 1) {
                    QString key = task.url.isEmpty() ? task.gid : task.url;
                    int currentRetries = m_retryState.value(key, 0);

                    if (currentRetries < m_settings->maxTries()) {
                        m_retryState[key] = currentRetries + 1;

                        int waitTime = m_settings->retryWait() * 1000;
                        if (waitTime < 1000) waitTime = 1000;

                        qInfo() << QString("Task failed. Retrying in %1s (%2/%3)...").arg(waitTime/1000).arg(m_retryState[key]).arg(m_settings->maxTries());

                        QTimer::singleShot(waitTime, this, [this, gidStr=task.gid](){
                            restartTask(gidStr);
                        });
                    } else {
                        qWarning() << "Task failed. Max retries reached.";
                        m_retryState.remove(key);
                    }
                }
            }
        } else if (task.status == "complete") {
            QString key = task.url.isEmpty() ? task.gid : task.url;
            if (m_retryState.contains(key)) {
                m_retryState.remove(key);
            }
        }
    }

    QSet<QString> currentActiveGids;
    QMap<QString, QString> currentStatusMap;

    auto addToMap = [&](const std::vector<Task>& vec) {
        for (const auto& t : vec) currentStatusMap[t.gid] = t.status;
    };
    addToMap(active);
    addToMap(waiting);
    addToMap(stopped);
    addToMap(seeding);

    for (const auto& t : active) {
        currentActiveGids.insert(t.gid);
    }

    if (currentActiveGids.isEmpty() && !m_previousActiveGids.isEmpty()) {
        bool naturalFinish = true;
        for (const QString& gid : m_previousActiveGids) {
            if (!currentStatusMap.contains(gid)) {
                naturalFinish = false;
                break;
            }
            QString s = currentStatusMap[gid];
            if (s == "paused" || s == "waiting" || s == "removed" || s == "error") {
                naturalFinish = false;
                break;
            }
        }

        if (naturalFinish) {
            checkDownloadCompleteAction();
        }
    }
    m_previousActiveGids = currentActiveGids;
}

QString DownloadManager::formatSpeed(qint64 bytes) {
    if (bytes <= 0) return "0 B/s";
    if (bytes >= 1024 * 1024 * 1024) {
        return QString::number(static_cast<double>(bytes) / (1024 * 1024 * 1024), 'f', 2) + " GB/s";
    } else if (bytes >= 1024 * 1024) {
        return QString::number(static_cast<double>(bytes) / (1024 * 1024), 'f', 1) + " MB/s";
    } else if (bytes >= 1024) {
        return QString::number(static_cast<double>(bytes) / 1024, 'f', 0) + " KB/s";
    } else {
        return QString::number(bytes) + " B/s";
    }
}

void DownloadManager::checkDownloadCompleteAction()
{
    int action = m_settings->onDownloadComplete();

    if (action == 1) {
        performPlaySound();
    } else if (action == 2) {
        m_settings->setOnDownloadComplete(0);
        performShutdown();
    }
}

void DownloadManager::performShutdown()
{
#ifdef Q_OS_WIN
    QProcess::startDetached("shutdown", {"/s", "/t", "30"});
#elif defined(Q_OS_LINUX) || defined(Q_OS_MAC)
    QProcess::startDetached("shutdown", {"-h", "+1"});
#endif
    qInfo() << "System will shut down in 30-60 seconds.";
}

void DownloadManager::performPlaySound()
{
    QApplication::beep();
    qInfo() << "Downloads complete. Beep!";
}

void DownloadManager::fetchTrackers()
{
    QMap<QString, QString> urls;
    urls["ngosang-best-link"] = "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt";
    urls["ngosang-best-mirror"] = "https://ngosang.github.io/trackerslist/trackers_best.txt";
    urls["ngosang-best-cdn"] = "https://cdn.jsdelivr.net/gh/ngosang/trackerslist@master/trackers_best.txt";
    urls["ngosang-all-link"] = "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt";
    urls["ngosang-all-mirror"] = "https://ngosang.github.io/trackerslist/trackers_all.txt";
    urls["ngosang-all-cdn"] = "https://cdn.jsdelivr.net/gh/ngosang/trackerslist@master/trackers_all.txt";
    urls["ngosang-all_udp-link"] = "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_udp.txt";
    urls["ngosang-all_udp-mirror"] = "https://ngosang.github.io/trackerslist/trackers_all_udp.txt";
    urls["ngosang-all_udp-cdn"] = "https://cdn.jsdelivr.net/gh/ngosang/trackerslist@master/trackers_all_udp.txt";
    urls["ngosang-all_http-link"] = "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_http.txt";
    urls["ngosang-all_http-mirror"] = "https://ngosang.github.io/trackerslist/trackers_all_http.txt";
    urls["ngosang-all_http-cdn"] = "https://cdn.jsdelivr.net/gh/ngosang/trackerslist@master/trackers_all_http.txt";
    urls["ngosang-all_https-link"] = "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_https.txt";
    urls["ngosang-all_https-mirror"] = "https://ngosang.github.io/trackerslist/trackers_all_https.txt";
    urls["ngosang-all_https-cdn"] = "https://cdn.jsdelivr.net/gh/ngosang/trackerslist@master/trackers_all_https.txt";
    urls["XIU2-best-link"] = "https://cf.trackerslist.com/best.txt";
    urls["XIU2-best-cdn"] = "https://jsd.onmicrosoft.cn/gh/XIU2/TrackersListCollection/best.txt";
    urls["XIU2-all-link"] = "https://cf.trackerslist.com/all.txt";
    urls["XIU2-all-cdn"] = "https://jsd.onmicrosoft.cn/gh/XIU2/TrackersListCollection/all.txt";
    urls["XIU2-http-link"] = "https://cf.trackerslist.com/http.txt";
    urls["XIU2-http-cdn"] = "https://jsd.onmicrosoft.cn/gh/XIU2/TrackersListCollection/http.txt";
    urls["XIU2-nohttp-link"] = "https://cf.trackerslist.com/nohttp.txt";
    urls["XIU2-nohttp-cdn"] = "https://jsd.onmicrosoft.cn/gh/XIU2/TrackersListCollection/nohttp.txt";

    QStringList enabled = m_settings->enabledTrackerSources();
    if (enabled.isEmpty()) return;

    auto accumulated = std::make_shared<QSet<QString>>();
    auto pendingCount = std::make_shared<int>(0);

    for (const QString &key : enabled) {
        if (urls.contains(key)) {
            (*pendingCount)++;

            QNetworkRequest req;
            req.setUrl(QUrl(urls[key]));
            QNetworkReply *reply = m_netManager->get(req);

            connect(reply, &QNetworkReply::finished, this, [this, reply, accumulated, pendingCount]() {
                if (reply->error() == QNetworkReply::NoError) {
                    QString data = QString::fromUtf8(reply->readAll());
                    QStringList lines = data.split('\n');
                    for (const QString &line : lines) {
                        QString clean = line.trimmed();
                        if (!clean.isEmpty() && !clean.startsWith("#")) {
                            accumulated->insert(clean);
                        }
                    }
                }
                reply->deleteLater();
                (*pendingCount)--;

                if (*pendingCount == 0) {
                    QStringList resultList(accumulated->begin(), accumulated->end());
                    QString finalStr = resultList.join(",");
                    if (!finalStr.isEmpty()) {
                        m_settings->setBtTrackers(finalStr);
                        applyGlobalSettings();
                    }
                }
            });
        }
    }
}

void DownloadManager::loadBaiduPath(const QString &path)
{
    m_baidu->listFiles(path);
}

void DownloadManager::downloadBaiduFiles(const QList<int> &indexes)
{
    QStringList fsIds;
    for (int row : indexes) {
        QVariantMap data = m_baiduModel->get(row);
        if (!data.isEmpty() && !data["isDir"].toBool()) {
            fsIds << data["fs_id"].toString();
        }
    }
    if (!fsIds.isEmpty()) {
        m_baidu->downloadFiles(fsIds, m_settings->downloadPath());
    }
}

void DownloadManager::deleteBaiduFiles(const QList<int> &indexes)
{
    QStringList paths;
    for (int row : indexes) {
        QVariantMap data = m_baiduModel->get(row);
        if (!data.isEmpty()) {
            paths << data["path"].toString();
        }
    }
    if (!paths.isEmpty()) {
        m_baidu->deleteFiles(paths);
        QTimer::singleShot(1000, this, [this](){
            emit baiduFilesLoaded();
        });
    }
}

void DownloadManager::loadThunderPath(const QString &parentId)
{
    m_thunder->listFiles(parentId);
}

void DownloadManager::downloadThunderFiles(const QList<int> &indexes)
{
    QStringList fileIds;
    for (int row : indexes) {
        QVariantMap data = m_thunderModel->get(row);
        if (!data.isEmpty() && !data["isDir"].toBool()) {
            fileIds << data["id"].toString();
        }
    }
    if (!fileIds.isEmpty()) {
        m_thunder->downloadFiles(fileIds, m_settings->downloadPath());
    }
}

void DownloadManager::deleteThunderFiles(const QList<int> &indexes)
{
    QStringList fileIds;
    for (int row : indexes) {
        QVariantMap data = m_thunderModel->get(row);
        if (!data.isEmpty()) {
            fileIds << data["id"].toString();
        }
    }
    if (!fileIds.isEmpty()) {
        m_thunder->deleteFiles(fileIds);
        QTimer::singleShot(1000, this, [this](){
             emit thunderFilesLoaded();
        });
    }
}

void DownloadManager::loginThunder()
{
    m_thunder->forceLogin();
}