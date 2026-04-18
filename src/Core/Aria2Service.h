/**
 * @file Aria2Service.h
 * @brief aria2 RPC 服务封装，管理 aria2 进程和 WebSocket 通信
 * 
 * 该类负责：
 * - 启动和管理 aria2 子进程
 * - 通过 WebSocket 与 aria2 JSON-RPC 通信
 * - 定时获取任务状态并缓存
 * - 提供 aria2 支持的所有下载操作
 */

#pragma once

#include <QJsonObject>
#include <QObject>
#include <QProcess>
#include <QWebSocket>
#include <QTimer>
#include <vector>
#include <QQueue>
#include <mutex>
#include "TaskModel.h"
#include "SettingsManager.h"

/**
 * @class Aria2Service
 * @brief aria2 下载服务，通过 WebSocket JSON-RPC 控制 aria2 进程
 */
class Aria2Service : public QObject
{
    Q_OBJECT

public:
    explicit Aria2Service(SettingsManager* settings, QObject *parent = nullptr);
    ~Aria2Service();

    bool isConnected() const;

    // ==================== 生命周期管理 ====================
    /**
     * @brief 启动 aria2 进程并连接 WebSocket
     */
    void startService();
    
    /**
     * @brief 安全关闭 aria2 进程
     */
    void shutdownService();

    // ==================== 添加下载任务 ====================
    /**
     * @brief 添加 HTTP/FTP/磁力链接下载任务
     * @param uri 下载链接
     * @param options aria2 选项
     */
    void addUri(const QString &uri, const QJsonObject &options = QJsonObject());
    
    /**
     * @brief 添加种子文件下载任务
     * @param filePath 种子文件路径
     * @param options aria2 选项
     */
    void addTorrent(const QString &filePath, const QJsonObject &options = QJsonObject());

    // ==================== 任务控制 ====================
    void pause(const QString &gid);
    void unpause(const QString &gid);
    void remove(const QString &gid);
    void removeDownloadResult(const QString &gid);
    void pauseAll();
    void unpauseAll();
    void purgeDownloadResult();

    // ==================== 设置相关 ====================
    /**
     * @brief 应用全局设置到 aria2
     * @note 调用 aria2 的 changeGlobalOption 方法
     */
    void applyGlobalSettings();

    // ==================== 任务查询 ====================
    std::vector<Task> getActiveTasks() const;
    std::vector<Task> getWaitingTasks() const;
    std::vector<Task> getStoppedTasks() const;

signals:
    void connectionStatusChanged();
    void logReceived(QString log);
    void tasksUpdated();

private slots:
    void onSocketConnected();
    void onSocketDisconnected();
    void onSocketTextMessageReceived(const QString &message);
    void onStatusTimerTimeout();

private:
    QProcess *m_process;          ///< aria2 子进程
    QWebSocket *m_webSocket;      ///< WebSocket 连接
    QTimer m_reconnectTimer;      ///< 重连定时器
    QTimer m_statusTimer;         ///< 状态刷新定时器
    bool m_isConnected;           ///< 连接状态
    SettingsManager *m_settings;  ///< 设置管理器

    std::vector<Task> m_activeTasks;   ///< 活动任务缓存
    std::vector<Task> m_waitingTasks;  ///< 等待任务缓存
    std::vector<Task> m_stoppedTasks;  ///< 已停止任务缓存
    mutable std::mutex m_tasksMutex;   ///< 任务缓存线程安全锁

    void connectToSocket();
    void sendJsonRpc(const QString &method, const QVariant &params = QVariant(), const QString &id = "");
    Task parseTaskJson(const QJsonObject &json);
};