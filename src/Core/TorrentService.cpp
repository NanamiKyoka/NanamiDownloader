#include "TorrentService.h"
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QCoreApplication>
#include <cmath>
#include <fstream>
#include <QDateTime>
#include <QJsonArray>
#include <QtConcurrentRun>

#ifdef _MSC_VER
#pragma warning(push, 0)
#endif
#include <libtorrent/session_params.hpp>
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/magnet_uri.hpp>
#include <libtorrent/alert_types.hpp>
#include <libtorrent/torrent_info.hpp>
#include <libtorrent/download_priority.hpp>
#include <libtorrent/write_resume_data.hpp>
#include <libtorrent/read_resume_data.hpp>
#include <libtorrent/peer_info.hpp>
#include <libtorrent/announce_entry.hpp>
#ifdef _MSC_VER
#pragma warning(pop)
#endif

namespace lt = libtorrent;

TorrentService::TorrentService(SettingsManager* settings, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
{
    connect(&m_alertTimer, &QTimer::timeout, this, &TorrentService::onAlertTimer);

    m_saveResumeTimer.setInterval(60000);
    connect(&m_saveResumeTimer, &QTimer::timeout, this, &TorrentService::saveResumeData);
}

TorrentService::~TorrentService()
{
    shutdownService();
}

void TorrentService::startService()
{
    if (m_session) return;

    qInfo() << "Starting Libtorrent Service...";

    lt::settings_pack pack;

    pack.set_int(lt::settings_pack::aio_threads, 4);

    pack.set_int(lt::settings_pack::alert_mask,
        lt::alert::status_notification |
        lt::alert::storage_notification |
        lt::alert::error_notification
    );

    pack.set_str(lt::settings_pack::user_agent, m_settings->userAgent().toStdString());

    pack.set_int(lt::settings_pack::active_downloads, m_settings->maxConcurrentDownloads());
    pack.set_int(lt::settings_pack::active_seeds, 100);
    pack.set_int(lt::settings_pack::active_limit, 200);

    pack.set_int(lt::settings_pack::connections_limit, m_settings->maxConnectionPerServer() * 10);

    pack.set_int(lt::settings_pack::send_buffer_watermark, 3 * 1024 * 1024);

    pack.set_bool(lt::settings_pack::enable_dht, m_settings->enableDht());
    pack.set_str(lt::settings_pack::dht_bootstrap_nodes, "router.bittorrent.com:6881,router.utorrent.com:6881,dht.transmissionbt.com:6881");

    if (m_settings->btProxyEnabled() && !m_settings->btProxyUrl().isEmpty()) {
        QUrl proxyUrl(m_settings->btProxyUrl());
        if (proxyUrl.isValid()) {
            lt::settings_pack::proxy_type_t proxyType = lt::settings_pack::http;
            if (proxyUrl.scheme() == "socks5") {
                proxyType = lt::settings_pack::socks5;
            } else if (proxyUrl.scheme() == "socks5_pw") {
                proxyType = lt::settings_pack::socks5_pw;
            } else if (proxyUrl.scheme() == "http") {
                proxyType = lt::settings_pack::http;
            }

            pack.set_int(lt::settings_pack::proxy_type, proxyType);
            pack.set_str(lt::settings_pack::proxy_hostname, proxyUrl.host().toStdString());
            pack.set_int(lt::settings_pack::proxy_port, proxyUrl.port());

            if (!proxyUrl.userName().isEmpty()) {
                pack.set_str(lt::settings_pack::proxy_username, proxyUrl.userName().toStdString());
            }
            if (!proxyUrl.password().isEmpty()) {
                pack.set_str(lt::settings_pack::proxy_password, proxyUrl.password().toStdString());
            }
        }
    } else {
        pack.set_int(lt::settings_pack::proxy_type, lt::settings_pack::none);
    }

    m_session = std::make_unique<lt::session>(pack);

    loadResumeData();

    applySettings();
    m_alertTimer.start(500);
    m_saveResumeTimer.start();
}

void TorrentService::shutdownService()
{
    m_alertTimer.stop();
    m_saveResumeTimer.stop();

    if (m_session) {
        saveResumeData();
        handleAlerts();

        m_session->pause();
        m_session.reset();
    }
    m_torrents.clear();
}

void TorrentService::loadResumeData() {
    QString resumeDir = QCoreApplication::applicationDirPath() + "/torrents";
    QDir dir(resumeDir);
    if (!dir.exists()) return;

    QStringList filters;
    filters << "*.resume";
    dir.setNameFilters(filters);
    QFileInfoList list = dir.entryInfoList();

    for (const auto& fileInfo : list) {
        std::ifstream ifs(fileInfo.absoluteFilePath().toStdString(), std::ios::binary);
        if (!ifs.good()) continue;

        std::vector<char> buf;
        ifs.seekg(0, std::ios::end);
        size_t size = ifs.tellg();
        if (size == 0) continue;

        buf.resize(size);
        ifs.seekg(0, std::ios::beg);
        ifs.read(buf.data(), size);

        try {
            lt::add_torrent_params atp = lt::read_resume_data(buf);
            m_session->async_add_torrent(atp);
        } catch (std::exception const&) {
            qWarning() << "Failed to read resume data:" << fileInfo.fileName();
        }
    }
}

void TorrentService::saveResumeData() {
    if (!m_session) return;

    m_session->post_torrent_updates();

    std::vector<lt::torrent_handle> handles = m_session->get_torrents();
    for (auto& h : handles) {
        if (!h.is_valid()) continue;
        if (h.need_save_resume_data()) {
            h.save_resume_data(lt::torrent_handle::save_info_dict);
        }
    }
}

void TorrentService::writeResumeData(const lt::add_torrent_params& atp) {
    (void)QtConcurrent::run([atp](){
        std::vector<char> buf = lt::write_resume_data_buf(atp);

        QString resumeDir = QCoreApplication::applicationDirPath() + "/torrents";
        QDir dir(resumeDir);
        if (!dir.exists()) dir.mkpath(".");

        std::stringstream ss;
        ss << atp.info_hashes.v1;
        QString hash = QString::fromStdString(ss.str());
        QString filePath = resumeDir + "/" + hash + ".resume";

        std::ofstream ofs(filePath.toStdString(), std::ios::binary | std::ios::trunc);
        ofs.write(buf.data(), buf.size());
    });
}

void TorrentService::addDefaultTrackers(libtorrent::add_torrent_params& p)
{
    QString trackerList = m_settings->btTrackers();
    if (trackerList.isEmpty()) return;

    QStringList trackers = trackerList.split(",", Qt::SkipEmptyParts);
    for (const QString& tr : trackers) {
        p.trackers.push_back(tr.trimmed().toStdString());
    }
}

QString TorrentService::fetchMagnetMetadata(const QString &magnetLink)
{
    if (!m_session) startService();

    try {
        lt::add_torrent_params p = lt::parse_magnet_uri(magnetLink.toStdString());
        p.save_path = m_settings->downloadPath().toStdString();

        p.flags |= lt::torrent_flags::upload_mode;
        p.flags &= ~lt::torrent_flags::paused;
        p.flags |= lt::torrent_flags::auto_managed;

        addDefaultTrackers(p);

        std::stringstream ss;
        ss << p.info_hashes.v1;
        QString gid = "bt_" + QString::fromStdString(ss.str());

        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_torrents.contains(gid)) {
            emit taskExists(gid, m_torrents[gid].name);
            return "";
        }

        m_session->async_add_torrent(p);
        qInfo() << "Magnet link added. GID:" << gid;
        return gid;
    } catch (const std::exception& e) {
        qWarning() << "Error parsing magnet:" << e.what();
        return "";
    }
}

void TorrentService::fetchTorrentFileMetadata(const QString &filePath)
{
    if (!m_session) startService();

    QString localPath = filePath;
    if (localPath.startsWith("file:///")) localPath = localPath.mid(8);

    try {
        auto ti = std::make_shared<lt::torrent_info>(localPath.toStdString());
        lt::add_torrent_params p;
        p.ti = ti;
        p.save_path = m_settings->downloadPath().toStdString();

        p.flags |= lt::torrent_flags::paused;
        p.flags |= lt::torrent_flags::upload_mode;

        addDefaultTrackers(p);

        std::stringstream ss;
        ss << p.info_hashes.v1;
        QString gid = "bt_" + QString::fromStdString(ss.str());

        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_torrents.contains(gid)) {
             emit taskExists(gid, m_torrents[gid].name);
             return;
        }

        m_session->async_add_torrent(p);
        qInfo() << "Torrent file added. GID:" << gid;
    } catch (const std::exception& e) {
        qWarning() << "Error adding torrent file:" << e.what();
    }
}

void TorrentService::reconfigureTask(const QString &gid)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_torrents.contains(gid)) return;

    lt::torrent_handle h = m_torrents[gid].handle;
    if (!h.is_valid()) return;

    h.set_flags(lt::torrent_flags::upload_mode);
    h.unset_flags(lt::torrent_flags::auto_managed);
    h.pause();

    m_torrents[gid].isMetaDataPending = true;

    QVariantList files;
    auto torrent_file = h.torrent_file();
    if (torrent_file) {
        int num_files = torrent_file->num_files();
        for (int i = 0; i < num_files; ++i) {
            lt::file_index_t idx(i);
            QVariantMap fileMap;
            fileMap["index"] = i;
            fileMap["path"] = QString::fromStdString(torrent_file->files().file_path(idx));
            fileMap["size"] = static_cast<qint64>(torrent_file->files().file_size(idx));
            fileMap["sizeStr"] = formatSize(fileMap["size"].toLongLong());
            files.append(fileMap);
        }
        QString totalSize = formatSize(torrent_file->total_size());
        emit metadataLoaded(gid, m_torrents[gid].name, totalSize, files);
    }
}

void TorrentService::confirmDownload(const QString &gid, const QString &savePath, const QList<int> &selectedFilesIndex)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_torrents.contains(gid)) return;

    lt::torrent_handle h = m_torrents[gid].handle;
    if (!h.is_valid()) return;

    QString cleanPath = savePath;
    if (cleanPath.startsWith("file:///")) cleanPath = cleanPath.mid(8);
    h.move_storage(cleanPath.toStdString());

    std::vector<lt::download_priority_t> file_priorities;
    if (h.torrent_file()) {
        int num_files = h.torrent_file()->num_files();
        file_priorities.resize(num_files, lt::dont_download);

        for (int idx : selectedFilesIndex) {
            if (idx >= 0 && idx < num_files) {
                file_priorities[idx] = lt::default_priority;
            }
        }
        h.prioritize_files(file_priorities);
    }

    h.unset_flags(lt::torrent_flags::upload_mode);
    h.unset_flags(lt::torrent_flags::paused);
    h.set_flags(lt::torrent_flags::auto_managed);
    h.resume();

    m_torrents[gid].isMetaDataPending = false;
    h.save_resume_data(lt::torrent_handle::save_info_dict);
    qInfo() << "Torrent confirmed and started. GID:" << gid;
    emit tasksUpdated();
}

void TorrentService::cancelDownload(const QString &gid, bool deleteFiles)
{
    remove(gid, deleteFiles);
}

void TorrentService::setFilePriority(const QString &gid, int fileIndex, bool enabled)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_torrents.contains(gid)) return;

    lt::torrent_handle h = m_torrents[gid].handle;
    if (!h.is_valid()) return;

    h.file_priority(lt::file_index_t(fileIndex), enabled ? lt::default_priority : lt::dont_download);
}

void TorrentService::pause(const QString &gid)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_torrents.contains(gid)) {
        m_torrents[gid].handle.pause();
        m_torrents[gid].handle.unset_flags(lt::torrent_flags::auto_managed);
        m_torrents[gid].handle.save_resume_data(lt::torrent_handle::save_info_dict);
        qInfo() << "Torrent paused. GID:" << gid;
    }
}

void TorrentService::resume(const QString &gid)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_torrents.contains(gid)) {
        m_torrents[gid].handle.resume();
        m_torrents[gid].handle.set_flags(lt::torrent_flags::auto_managed);
        qInfo() << "Torrent resumed. GID:" << gid;
    }
}

void TorrentService::remove(const QString &gid, bool deleteFiles)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_torrents.contains(gid)) {
        lt::torrent_handle h = m_torrents[gid].handle;

        std::stringstream ss;
        ss << h.info_hashes().v1;
        QString hash = QString::fromStdString(ss.str());
        QString resumePath = QCoreApplication::applicationDirPath() + "/torrents/" + hash + ".resume";
        QFile::remove(resumePath);

        lt::remove_flags_t flags = {};
        if (deleteFiles) flags |= lt::session_handle::delete_files;
        m_session->remove_torrent(h, flags);
        m_torrents.remove(gid);
        qInfo() << "Torrent removed. GID:" << gid << "Delete files:" << deleteFiles;
        emit tasksUpdated();
    }
}

void TorrentService::pauseAll()
{
    if (!m_session) return;
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto& info : m_torrents) {
        if (info.handle.is_valid()) {
            info.handle.pause();
            info.handle.unset_flags(lt::torrent_flags::auto_managed);
        }
    }
    saveResumeData();
    qInfo() << "All torrents paused.";
}

void TorrentService::resumeAll()
{
    if (!m_session) return;
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto& info : m_torrents) {
        if (info.handle.is_valid()) {
            info.handle.resume();
            info.handle.set_flags(lt::torrent_flags::auto_managed);
        }
    }
    qInfo() << "All torrents resumed.";
}

void TorrentService::applySettings()
{
    if (!m_session) return;

    lt::settings_pack pack;
    int dlLimit = m_settings->globalMaxDownloadSpeed() * 1024;
    int ulLimit = m_settings->globalMaxUploadSpeed() * 1024;

    pack.set_int(lt::settings_pack::download_rate_limit, dlLimit > 0 ? dlLimit : 0);
    pack.set_int(lt::settings_pack::upload_rate_limit, ulLimit > 0 ? ulLimit : 0);
    pack.set_int(lt::settings_pack::active_downloads, m_settings->maxConcurrentDownloads());

    if (m_settings->btProxyEnabled() && !m_settings->btProxyUrl().isEmpty()) {
        QUrl proxyUrl(m_settings->btProxyUrl());
        if (proxyUrl.isValid()) {
            lt::settings_pack::proxy_type_t proxyType = lt::settings_pack::http;
            if (proxyUrl.scheme() == "socks5") {
                proxyType = lt::settings_pack::socks5;
            } else if (proxyUrl.scheme() == "socks5_pw") {
                proxyType = lt::settings_pack::socks5_pw;
            } else if (proxyUrl.scheme() == "http") {
                proxyType = lt::settings_pack::http;
            }

            pack.set_int(lt::settings_pack::proxy_type, proxyType);
            pack.set_str(lt::settings_pack::proxy_hostname, proxyUrl.host().toStdString());
            pack.set_int(lt::settings_pack::proxy_port, proxyUrl.port());

            if (!proxyUrl.userName().isEmpty()) {
                pack.set_str(lt::settings_pack::proxy_username, proxyUrl.userName().toStdString());
            }
            if (!proxyUrl.password().isEmpty()) {
                pack.set_str(lt::settings_pack::proxy_password, proxyUrl.password().toStdString());
            }
        }
    } else {
        pack.set_int(lt::settings_pack::proxy_type, lt::settings_pack::none);
    }

    m_session->apply_settings(pack);
    qInfo() << "Torrent settings applied.";
}

void TorrentService::onAlertTimer()
{
    if (!m_session) return;
    handleAlerts();
    emit tasksUpdated();
}

void TorrentService::handleAlerts()
{
    std::vector<lt::alert*> alerts;
    m_session->pop_alerts(&alerts);

    std::lock_guard<std::mutex> lock(m_mutex);

    for (lt::alert* a : alerts) {
        if (auto at = lt::alert_cast<lt::add_torrent_alert>(a)) {
            if (at->error) {
                qCritical() << "Failed to add torrent:" << at->error.message().c_str();
            } else {
                lt::torrent_handle h = at->handle;
                QString gid = getGid(h);
                TorrentInfo info;
                info.gid = gid;
                info.handle = h;
                info.name = QString::fromStdString(h.status().name);

                bool isResume = (at->params.flags & lt::torrent_flags::upload_mode) == lt::torrent_flags_t{};

                if (!isResume && h.status().state != lt::torrent_status::seeding && (h.flags() & lt::torrent_flags::upload_mode)) {
                     info.isMetaDataPending = true;
                }

                m_torrents[gid] = info;
                qInfo() << "Torrent added successfully. GID:" << gid << "Name:" << info.name;
            }
        }
        else if (auto mr = lt::alert_cast<lt::metadata_received_alert>(a)) {
             QString gid = getGid(mr->handle);
             if (m_torrents.contains(gid)) {
                 auto handle = mr->handle;
                 m_torrents[gid].name = QString::fromStdString(handle.status().name);

                 if (m_torrents[gid].isMetaDataPending) {
                     handle.pause();

                     QVariantList files;
                     auto torrent_file = handle.torrent_file();
                     if (torrent_file) {
                         int num_files = torrent_file->num_files();
                         for (int i = 0; i < num_files; ++i) {
                             lt::file_index_t idx(i);
                             QVariantMap fileMap;
                             fileMap["index"] = i;
                             fileMap["path"] = QString::fromStdString(torrent_file->files().file_path(idx));
                             fileMap["size"] = static_cast<qint64>(torrent_file->files().file_size(idx));
                             fileMap["sizeStr"] = formatSize(fileMap["size"].toLongLong());
                             files.append(fileMap);
                         }

                         QString totalSize = formatSize(torrent_file->total_size());
                         emit metadataLoaded(gid, m_torrents[gid].name, totalSize, files);
                     }
                 }
                 handle.save_resume_data(lt::torrent_handle::save_info_dict);
                 qInfo() << "Metadata received for GID:" << gid;
             }
        }
        else if (auto rd = lt::alert_cast<lt::save_resume_data_alert>(a)) {
            writeResumeData(rd->params);
        }
        else if (auto fd = lt::alert_cast<lt::save_resume_data_failed_alert>(a)) {
            qWarning() << "Save resume data failed:" << fd->error.message().c_str();
        }
        else if (auto err = lt::alert_cast<lt::torrent_error_alert>(a)) {
            qWarning() << "Torrent error:" << err->error.message().c_str() << "File:" << err->filename();
        }
    }

    for(auto& t : m_torrents) {
        if (t.isMetaDataPending && t.handle.is_valid() && t.handle.torrent_file()) {
             auto h = t.handle;
             if (h.flags() & lt::torrent_flags::upload_mode) {
                 t.isMetaDataPending = false;
                 QVariantList files;
                 auto torrent_file = h.torrent_file();
                 int num_files = torrent_file->num_files();
                 for (int i = 0; i < num_files; ++i) {
                     lt::file_index_t idx(i);
                     QVariantMap fileMap;
                     fileMap["index"] = i;
                     fileMap["path"] = QString::fromStdString(torrent_file->files().file_path(idx));
                     fileMap["size"] = static_cast<qint64>(torrent_file->files().file_size(idx));
                     fileMap["sizeStr"] = formatSize(fileMap["size"].toLongLong());
                     files.append(fileMap);
                 }
                 QString totalSize = formatSize(torrent_file->total_size());
                 emit metadataLoaded(t.gid, t.name, totalSize, files);
             }
        }
    }
}

QString TorrentService::getGid(const lt::torrent_handle& h) const {
    std::stringstream ss;
    ss << h.info_hashes().v1;
    return "bt_" + QString::fromStdString(ss.str());
}

QString TorrentService::formatSize(qint64 bytes) {
    if (bytes == 0) return "0 B";
    const char* sizes[] = { "B", "KB", "MB", "GB", "TB" };
    int i = 0;
    double dblByte = bytes;
    while (dblByte >= 1024 && i < 4) {
        dblByte /= 1024;
        i++;
    }
    return QString::number(dblByte, 'f', 2) + " " + sizes[i];
}

Task TorrentService::createTaskFromStatus(const lt::torrent_status& status, const QString& gidOverride)
{
    Task t;
    t.gid = gidOverride.isEmpty() ? getGid(status.handle) : gidOverride;
    t.url = "magnet:?xt=urn:btih:" + t.gid.mid(3);

    if (m_torrents.contains(t.gid)) {
        t.name = m_torrents[t.gid].name;
    } else {
        t.name = QString::fromStdString(status.name);
    }

    if (t.name.isEmpty() || t.name == "Unknown") {
        t.name = "Fetching Metadata...";
    }

    t.totalLength = status.total_wanted;
    t.completedLength = status.total_wanted_done;
    t.downloadSpeed = status.download_payload_rate;
    t.uploadSpeed = status.upload_payload_rate;
    t.connections = status.num_peers;

    if (status.state == lt::torrent_status::checking_files || status.state == lt::torrent_status::downloading_metadata) {
        t.status = "waiting";
        if (status.state == lt::torrent_status::checking_files) {
             t.name = "[Checking] " + t.name;
        }
    } else if (status.state == lt::torrent_status::downloading) {
        t.status = "active";
    } else if (status.state == lt::torrent_status::finished) {
        t.status = "seeding";
    } else if (status.state == lt::torrent_status::seeding) {
        t.status = "seeding";
    } else if (status.state == lt::torrent_status::checking_resume_data) {
        t.status = "waiting";
    } else {
        t.status = "paused";
    }

    if ((status.flags & lt::torrent_flags::paused) && (status.state == lt::torrent_status::finished || status.state == lt::torrent_status::seeding)) {
        t.status = "complete";
    } else if (status.flags & lt::torrent_flags::paused) {
        t.status = "paused";
    }

    if (status.flags & lt::torrent_flags::upload_mode) {
        t.status = "waiting";
        t.name = "Fetching Metadata...";
    }

    if (status.errc) {
        t.status = "error";
    }

    t.path = QString::fromStdString(status.save_path);
    return t;
}

std::vector<Task> TorrentService::getActiveTasks() const
{
    std::vector<Task> result;
    if (!m_session) return result;

    std::vector<lt::torrent_handle> handles = m_session->get_torrents();
    for (const auto& h : handles) {
        QString gid = getGid(h);
        if(m_torrents.contains(gid) && m_torrents[gid].isMetaDataPending) continue;

        auto st = h.status();
        Task t = const_cast<TorrentService*>(this)->createTaskFromStatus(st);
        if (t.status == "active") result.push_back(t);
    }
    return result;
}

std::vector<Task> TorrentService::getSeedingTasks() const
{
    std::vector<Task> result;
    if (!m_session) return result;

    std::vector<lt::torrent_handle> handles = m_session->get_torrents();
    for (const auto& h : handles) {
        QString gid = getGid(h);
        if(m_torrents.contains(gid) && m_torrents[gid].isMetaDataPending) continue;

        auto st = h.status();
        Task t = const_cast<TorrentService*>(this)->createTaskFromStatus(st);
        if (t.status == "seeding") result.push_back(t);
    }
    return result;
}

std::vector<Task> TorrentService::getWaitingTasks() const
{
    std::vector<Task> result;
    if (!m_session) return result;

    std::vector<lt::torrent_handle> handles = m_session->get_torrents();
    for (const auto& h : handles) {
        QString gid = getGid(h);
        if(m_torrents.contains(gid) && m_torrents[gid].isMetaDataPending) continue;

        auto st = h.status();
        Task t = const_cast<TorrentService*>(this)->createTaskFromStatus(st);
        if (t.status == "waiting") result.push_back(t);
    }
    return result;
}

std::vector<Task> TorrentService::getStoppedTasks() const
{
    std::vector<Task> result;
    if (!m_session) return result;

    std::vector<lt::torrent_handle> handles = m_session->get_torrents();
    for (const auto& h : handles) {
        QString gid = getGid(h);
        if(m_torrents.contains(gid) && m_torrents[gid].isMetaDataPending) continue;

        auto st = h.status();
        Task t = const_cast<TorrentService*>(this)->createTaskFromStatus(st);
        if (t.status == "paused" || t.status == "complete" || t.status == "error") result.push_back(t);
    }
    return result;
}

QString getPeerFlags(const lt::peer_info& p) {
    QString res;
    if (p.flags & lt::peer_info::interesting) res += "I";
    if (p.flags & lt::peer_info::choked) res += "C";
    if (p.flags & lt::peer_info::remote_interested) res += "i";
    if (p.flags & lt::peer_info::remote_choked) res += "c";
    if (p.flags & lt::peer_info::supports_extensions) res += "E";
    if (p.flags & lt::peer_info::local_connection) res += "l";
    if (p.flags & lt::peer_info::handshake) res += "h";
    if (p.flags & lt::peer_info::connecting) res += "C";
    if (p.flags & lt::peer_info::on_parole) res += "P";
    if (p.flags & lt::peer_info::seed) res += "S";
    if (p.flags & lt::peer_info::optimistic_unchoke) res += "O";
    if (p.flags & lt::peer_info::snubbed) res += "s";
    if (p.flags & lt::peer_info::upload_only) res += "U";
    return res;
}

QJsonObject TorrentService::getTorrentDetails(const QString &gid) {
    QJsonObject details;
    if (!m_torrents.contains(gid)) return details;

    lt::torrent_handle h = m_torrents[gid].handle;
    if (!h.is_valid()) return details;

    lt::torrent_status st = h.status();

    QJsonObject general;
    general["totalSize"] = formatSize(st.total_wanted);
    general["addedOn"] = QDateTime::fromSecsSinceEpoch(st.added_time).toString("yyyy/MM/dd HH:mm");

    QString completedOn = "N/A";
    if (st.completed_time > 0) completedOn = QDateTime::fromSecsSinceEpoch(st.completed_time).toString("yyyy/MM/dd HH:mm");
    general["completedOn"] = completedOn;

    std::stringstream ss;
    ss << st.info_hashes.v1;
    general["hash"] = QString::fromStdString(ss.str());
    general["savePath"] = QString::fromStdString(st.save_path);
    general["downloaded"] = formatSize(st.total_done);
    general["uploaded"] = formatSize(st.all_time_upload);
    general["downloadSpeed"] = formatSize(st.download_rate) + "/s";
    general["uploadSpeed"] = formatSize(st.upload_rate) + "/s";
    general["connections"] = QString::number(st.num_connections);
    general["seeds"] = QString::number(st.num_seeds);
    general["peers"] = QString::number(st.num_peers);
    general["shareRatio"] = QString::number(st.all_time_upload > 0 && st.all_time_download > 0 ? (double)st.all_time_upload / st.all_time_download : 0.0, 'f', 2);

    QString progress = QString::number(st.progress_ppm / 10000.0, 'f', 1) + "%";
    general["progress"] = progress;

    if (h.torrent_file()) {
        general["pieces"] = QString::number(h.torrent_file()->num_pieces()) + " x " + formatSize(h.torrent_file()->piece_length());
        general["completedPieces"] = QString::number(st.pieces.count());
    }

    details["general"] = general;

    QJsonArray trackers;
    std::vector<lt::announce_entry> trs = h.trackers();
    for (const auto& t : trs) {
        QJsonObject trObj;
        trObj["url"] = QString::fromStdString(t.url);
        trObj["status"] = "Updating...";
        trObj["message"] = "";
        trObj["seeds"] = 0;
        trObj["peers"] = 0;
        trObj["downloaded"] = 0;

        bool working = false;
        for (const auto& ep : t.endpoints) {
            auto const& info_hash = ep.info_hashes[lt::protocol_version::V1];

            if (info_hash.scrape_complete > 0 || info_hash.scrape_incomplete > 0) {
                trObj["seeds"] = info_hash.scrape_complete;
                trObj["peers"] = info_hash.scrape_incomplete;
                trObj["downloaded"] = info_hash.scrape_downloaded;
            }

            if (!info_hash.message.empty()) {
                trObj["message"] = QString::fromStdString(info_hash.message);
            }

            if (!info_hash.last_error) {
                working = true;
            } else {
                trObj["message"] = QString::fromStdString(info_hash.last_error.message());
            }
        }

        if (working) trObj["status"] = "Working";
        else if (!t.endpoints.empty()) trObj["status"] = "Not Working";

        trackers.append(trObj);
    }
    details["trackers"] = trackers;

    QJsonArray peers;
    std::vector<lt::peer_info> pis;
    h.get_peer_info(pis);
    for (const auto& p : pis) {
        QJsonObject pObj;
        pObj["ip"] = QString::fromStdString(p.ip.address().to_string());
        pObj["client"] = QString::fromStdString(p.client);
        pObj["flags"] = getPeerFlags(p);
        pObj["progress"] = QString::number(p.progress_ppm / 10000.0, 'f', 1) + "%";
        pObj["downSpeed"] = formatSize(p.down_speed) + "/s";
        pObj["upSpeed"] = formatSize(p.up_speed) + "/s";
        peers.append(pObj);
    }
    details["peers"] = peers;

    QJsonArray fileList;
    if (h.torrent_file()) {
        auto tf = h.torrent_file();
        std::vector<std::int64_t> file_progress;
        h.file_progress(file_progress);
        std::vector<lt::download_priority_t> priorities = h.get_file_priorities();

        for (int i = 0; i < tf->num_files(); ++i) {
            QJsonObject fObj;
            fObj["index"] = i;
            fObj["name"] = QString::fromStdString(tf->files().file_path(lt::file_index_t(i)));
            fObj["size"] = formatSize(tf->files().file_size(lt::file_index_t(i)));
            double prog = file_progress[i] > 0 ? (double)file_progress[i] / tf->files().file_size(lt::file_index_t(i)) * 100.0 : 0.0;
            fObj["progress"] = QString::number(prog, 'f', 1) + "%";

            bool isDownloading = (i < priorities.size() && priorities[i] != lt::dont_download);
            fObj["priority"] = isDownloading ? "Normal" : "Ignored";
            fObj["checked"] = isDownloading;

            fileList.append(fObj);
        }
    }
    details["files"] = fileList;

    return details;
}