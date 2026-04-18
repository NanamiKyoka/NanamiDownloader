/**
 * @file TorrentService.h
 * @brief BitTorrent 下载服务，基于 libtorrent 库实现
 * 
 * 该类负责：
 * - 管理 BitTorrent 会话和种子任务
 * - 支持磁力链接和种子文件
 * - 处理元数据获取、文件选择、做种等
 * - 使用 resume data 持久化任务状态
 */

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

/**
 * @class TorrentService
 * @brief BitTorrent 下载服务
 * 
 * 使用 libtorrent 库实现完整的 BT 下载功能，
 * 任务 ID 以 "bt_" 前缀标识。
 * 
 * 工作流程：
 * 1. 添加磁力链接或种子文件
 * 2. 等待元数据下载完成（仅磁力链接）
 * 3. 用户选择要下载的文件
 * 4. 确认开始下载
 */
class TorrentService : public QObject
{
    Q_OBJECT

public:
    explicit TorrentService(SettingsManager* settings, QObject *parent = nullptr);
    ~TorrentService();

    // ==================== 生命周期管理 ====================
    void startService();
    void shutdownService();

    // ==================== 添加任务 ====================
    /**
     * @brief 获取磁力链接的元数据（不开始下载）
     * @param magnetLink 磁力链接
     * @return 任务 GID
     */
    QString fetchMagnetMetadata(const QString &magnetLink);
    
    /**
     * @brief 获取种子文件的元数据
     * @param filePath 种子文件路径
     */
    void fetchTorrentFileMetadata(const QString &filePath);

    // ==================== 确认下载 ====================
    /**
     * @brief 确认开始下载，选择要下载的文件
     * @param gid 任务 GID
     * @param savePath 保存路径
     * @param selectedFilesIndex 选中文件的索引列表
     */
    void confirmDownload(const QString &gid, const QString &savePath, const QList<int> &selectedFilesIndex);
    void cancelDownload(const QString &gid, bool deleteFiles);
    void reconfigureTask(const QString &gid);

    // ==================== 文件选择 ====================
    /**
     * @brief 设置种子内某文件的下载优先级
     * @param gid 任务 GID
     * @param fileIndex 文件索引
     * @param enabled 是否下载
     */
    void setFilePriority(const QString &gid, int fileIndex, bool enabled);

    // ==================== 任务控制 ====================
    void pause(const QString &gid);
    void resume(const QString &gid);
    void remove(const QString &gid, bool deleteFiles);
    void pauseAll();
    void resumeAll();
    
    /**
     * @brief 移除所有已完成/错误的任务
     * @return 移除的任务数量
     */
    int removeCompletedTasks();

    // ==================== 设置 ====================
    void applySettings();

    // ==================== 任务查询 ====================
    std::vector<Task> getActiveTasks() const;
    std::vector<Task> getSeedingTasks() const;
    std::vector<Task> getWaitingTasks() const;
    std::vector<Task> getStoppedTasks() const;

    /**
     * @brief 获取种子任务的详细信息
     * @param gid 任务 GID
     * @return 包含文件列表、做种信息等的 JSON 对象
     */
    QJsonObject getTorrentDetails(const QString &gid);

signals:
    void tasksUpdated();
    
    /**
     * @brief 元数据获取完成（仅磁力链接）
     * @param gid 任务 GID
     * @param name 种子名称
     * @param size 总大小字符串
     * @param files 文件列表（QVariantList）
     */
    void metadataLoaded(QString gid, QString name, QString size, QVariantList files);
    void taskExists(QString gid, QString name);

private slots:
    void onAlertTimer();
    void saveResumeData();

private:
    SettingsManager* m_settings;                    ///< 设置管理器
    std::unique_ptr<libtorrent::session> m_session; ///< libtorrent 会话
    QTimer m_alertTimer;                            ///< 告警处理定时器
    QTimer m_saveResumeTimer;                       ///< resume data 保存定时器

    /**
     * @struct TorrentInfo
     * @brief 种子任务信息
     */
    struct TorrentInfo {
        QString gid;                          ///< 任务 GID
        QString name;                         ///< 种子名称
        libtorrent::torrent_handle handle;    ///< libtorrent 句柄
        bool isMetaDataPending = false;       ///< 是否正在等待元数据
    };

    QMap<QString, TorrentInfo> m_torrents;  ///< 任务映射（gid -> TorrentInfo）
    std::mutex m_mutex;                      ///< 线程安全锁

    void handleAlerts();
    Task createTaskFromStatus(const libtorrent::torrent_status& status, const QString& gidOverride = "");
    QString getGid(const libtorrent::torrent_handle& h) const;

    void loadResumeData();
    void writeResumeData(const libtorrent::add_torrent_params& atp);
    void addDefaultTrackers(libtorrent::add_torrent_params& p);
};