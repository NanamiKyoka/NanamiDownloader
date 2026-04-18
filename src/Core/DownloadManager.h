/**
 * @file DownloadManager.h
 * @brief 下载管理器，协调多种下载服务（aria2、M3U8、BT、网盘）的核心组件
 * 
 * 该类是整个下载系统的核心，负责：
 * - 管理 aria2、M3U8、BitTorrent 三种下载引擎
 * - 协调百度网盘、迅雷云盘的文件浏览和下载
 * - 提供任务列表模型供 UI 展示
 * - 处理任务的增删改查和状态刷新
 */

#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSet>
#include <optional>
#include "Aria2Service.h"
#include "M3u8Service.h"
#include "TorrentService.h"
#include "../Drivers/BaiduNetdisk/BaiduService.h"
#include "../Drivers/BaiduNetdisk/BaiduFileModel.h"
#include "../Drivers/Thunder/ThunderService.h"
#include "../Drivers/Thunder/ThunderFileModel.h"
#include "TaskModel.h"
#include "SettingsManager.h"

/**
 * @class DownloadManager
 * @brief 下载管理器，统一管理所有下载任务和服务
 * 
 * 使用时需先调用 startServices() 启动底层服务，
 * 程序退出时调用 shutdown() 安全关闭。
 */
class DownloadManager : public QObject
{
    Q_OBJECT

    // ==================== 任务列表模型 ====================
    Q_PROPERTY(TaskModel* allModel READ allModel CONSTANT)
    Q_PROPERTY(TaskModel* activeModel READ activeModel CONSTANT)
    Q_PROPERTY(TaskModel* waitingModel READ waitingModel CONSTANT)
    Q_PROPERTY(TaskModel* stoppedModel READ stoppedModel CONSTANT)
    Q_PROPERTY(TaskModel* seedingModel READ seedingModel CONSTANT)

    // ==================== 网盘文件模型 ====================
    Q_PROPERTY(BaiduFileModel* baiduModel READ baiduModel CONSTANT)
    Q_PROPERTY(ThunderFileModel* thunderModel READ thunderModel CONSTANT)

    // ==================== 全局状态 ====================
    Q_PROPERTY(QString totalDownloadSpeedString READ totalDownloadSpeedString NOTIFY totalDownloadSpeedChanged)

public:
    explicit DownloadManager(SettingsManager* settings, QObject *parent = nullptr);
    ~DownloadManager();

    // ==================== 属性访问器 ====================
    TaskModel* allModel() const { return m_allModel; }
    TaskModel* activeModel() const { return m_activeModel; }
    TaskModel* waitingModel() const { return m_waitingModel; }
    TaskModel* stoppedModel() const { return m_stoppedModel; }
    TaskModel* seedingModel() const { return m_seedingModel; }
    BaiduFileModel* baiduModel() const { return m_baiduModel; }
    ThunderFileModel* thunderModel() const { return m_thunderModel; }
    QString totalDownloadSpeedString() const { return m_totalDownloadSpeedString; }

    // ==================== 生命周期管理 ====================
    /**
     * @brief 启动所有下载服务（aria2、M3U8、BT）
     * @note 必须在使用其他功能前调用
     */
    Q_INVOKABLE void startServices();
    
    /**
     * @brief 安全关闭所有服务
     */
    void shutdown();

    // ==================== 添加下载任务 ====================
    /**
     * @brief 添加 HTTP/FTP 下载任务
     * @param uri 下载链接
     * @param options aria2 选项，如 {"dir": "/path", "out": "filename"}
     */
    Q_INVOKABLE void addUri(const QString &uri, const QJsonObject &options = QJsonObject());
    
    /**
     * @brief 添加种子文件下载任务
     * @param filePath 种子文件路径
     * @param options aria2 选项
     */
    Q_INVOKABLE void addTorrent(const QString &filePath, const QJsonObject &options = QJsonObject());
    
    /**
     * @brief 下载 M3U8 视频流
     * @param url M3U8 链接
     * @param saveName 保存文件名
     * @param saveDir 保存目录
     * @param options 额外选项
     */
    Q_INVOKABLE void downloadM3u8(const QString &url, const QString &saveName, const QString &saveDir, const QJsonObject &options);

    // ==================== 种子任务管理 ====================
    /**
     * @brief 确认种子任务，选择要下载的文件
     * @param gid 任务 GID
     * @param savePath 保存路径
     * @param selectedFiles 选中文件的索引列表
     */
    Q_INVOKABLE void confirmTorrent(const QString &gid, const QString &savePath, const QList<int> &selectedFiles);
    Q_INVOKABLE void cancelTorrent(const QString &gid);
    Q_INVOKABLE void overwriteTorrent(const QString &gid);
    Q_INVOKABLE void continueTorrent(const QString &gid);
    
    /**
     * @brief 设置种子内某文件的下载优先级
     * @param gid 任务 GID
     * @param fileIndex 文件索引
     * @param enabled 是否下载该文件
     */
    Q_INVOKABLE void setFilePriority(const QString &gid, int fileIndex, bool enabled);

    // ==================== 任务控制 ====================
    Q_INVOKABLE void pause(const QString &gid);
    Q_INVOKABLE void unpause(const QString &gid);
    Q_INVOKABLE void remove(const QString &gid);
    
    /**
     * @brief 删除任务，可选择同时删除文件
     * @param gid 任务 GID，前缀标识任务类型（m3u8_、bt_、无前缀为 aria2）
     * @param deleteFile 是否同时删除已下载的文件
     */
    Q_INVOKABLE void handleDelete(const QString &gid, bool deleteFile);
    
    Q_INVOKABLE void pauseAll();
    Q_INVOKABLE void unpauseAll();
    Q_INVOKABLE void purgeDownloadResult();
    
    /**
     * @brief 移除已完成的任务
     * @return 移除的任务数量
     */
    Q_INVOKABLE int removeCompletedTasks();
    
    // ==================== 文件操作 ====================
    Q_INVOKABLE void openFolder(const QString &path);
    Q_INVOKABLE void openFile(const QString &path);
    Q_INVOKABLE void restartTask(const QString &gid);

    // ==================== 任务信息 ====================
    /**
     * @brief 获取任务详细信息
     * @param gid 任务 GID
     * @return 包含任务详情的 JSON 对象
     */
    Q_INVOKABLE QJsonObject getTaskDetails(const QString &gid);
    
    // ==================== 设置相关 ====================
    Q_INVOKABLE void applyGlobalSettings();
    Q_INVOKABLE void fetchTrackers();

    // ==================== 百度网盘操作 ====================
    Q_INVOKABLE void loadBaiduPath(const QString &path);
    Q_INVOKABLE void downloadBaiduFiles(const QList<int> &indexes);
    Q_INVOKABLE void deleteBaiduFiles(const QList<int> &indexes);

    // ==================== 迅雷云盘操作 ====================
    Q_INVOKABLE void loadThunderPath(const QString &parentId);
    Q_INVOKABLE void downloadThunderFiles(const QList<int> &indexes);
    Q_INVOKABLE void deleteThunderFiles(const QList<int> &indexes);
    Q_INVOKABLE void loginThunder();

signals:
    // ==================== 种子任务信号 ====================
    void torrentMetadataLoaded(QString gid, QString name, QString size, QVariantList files);
    void magnetLinkAdded(QString gid);
    
    // ==================== 任务状态信号 ====================
    void taskExists(QString gid, QString name);
    void errorOccurred(QString message);
    
    // ==================== 网盘操作信号 ====================
    void baiduFilesLoaded();
    void thunderFilesLoaded();
    void authRequired();
    void thunderVerificationRequired(QString url);
    
    // ==================== 全局状态信号 ====================
    void totalDownloadSpeedChanged();

private slots:
    /**
     * @brief 定时刷新所有任务状态
     * @note 由定时器触发，合并各服务的任务列表并更新模型
     */
    void refreshTasks();

private:
    // ==================== 下载服务实例 ====================
    Aria2Service *m_aria2;      ///< aria2 RPC 服务
    M3u8Service *m_m3u8;        ///< M3U8 视频下载服务
    TorrentService *m_torrent;  ///< BitTorrent 下载服务
    BaiduService *m_baidu;      ///< 百度网盘服务
    ThunderService *m_thunder;  ///< 迅雷云盘服务

    // ==================== 任务模型 ====================
    TaskModel *m_allModel;      ///< 所有任务
    TaskModel *m_activeModel;   ///< 活动任务
    TaskModel *m_waitingModel;  ///< 等待中任务
    TaskModel *m_stoppedModel;  ///< 已停止任务
    TaskModel *m_seedingModel;  ///< 做种中任务
    BaiduFileModel *m_baiduModel;     ///< 百度网盘文件列表
    ThunderFileModel *m_thunderModel; ///< 迅雷云盘文件列表

    // ==================== 其他成员 ====================
    SettingsManager *m_settings;         ///< 设置管理器
    QNetworkAccessManager *m_netManager; ///< 网络请求管理器

    bool m_wasDownloading = false;       ///< 上次刷新时是否有下载中的任务
    void checkDownloadCompleteAction();  ///< 检查并执行下载完成后的动作
    void performShutdown();              ///< 执行关机
    void performPlaySound();             ///< 播放提示音

    QMap<QString, int> m_retryState;          ///< 重试状态记录
    QSet<QString> m_handledErrorGids;         ///< 已处理的错误任务 GID
    QSet<QString> m_previousActiveGids;       ///< 上一次活动任务 GID 集合
    QString m_totalDownloadSpeedString = "0 B/s"; ///< 格式化的总下载速度

    std::optional<Task> findTaskByGid(const QString &gid) const;
};