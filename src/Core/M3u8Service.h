/**
 * @file M3u8Service.h
 * @brief M3U8 视频流下载服务，使用 FFmpeg 下载 HLS 流
 * 
 * 该类负责：
 * - 管理 M3U8 视频下载任务
 * - 为每个任务启动独立的 FFmpeg 进程
 * - 解析 FFmpeg 输出获取下载进度
 * - 持久化任务状态以便恢复
 */

#pragma once

#include <QObject>
#include <QProcess>
#include <QMap>
#include <QJsonObject>
#include <vector>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include "TaskModel.h"
#include "SettingsManager.h"

/**
 * @class M3u8Service
 * @brief M3U8/HLS 视频下载服务
 * 
 * 每个下载任务由独立的 FFmpeg 进程处理，
 * 任务 ID 以 "m3u8_" 前缀标识。
 */
class M3u8Service : public QObject
{
    Q_OBJECT

public:
    explicit M3u8Service(SettingsManager* settings, QObject *parent = nullptr);
    ~M3u8Service();

    /**
     * @brief 从磁盘加载之前保存的任务
     */
    void loadTasks();

    // ==================== 任务操作 ====================
    /**
     * @brief 开始新的 M3U8 下载任务
     * @param url M3U8 链接
     * @param saveName 保存文件名
     * @param saveDir 保存目录
     * @param options 额外选项（如代理设置）
     */
    void startTask(const QString &url, const QString &saveName, const QString &saveDir, const QJsonObject &options);
    void resumeTask(const QString &gid);
    void restartTask(const QString &gid);
    void cancelTask(const QString &gid);
    void deleteTask(const QString &gid, bool deleteFile);
    void stopTask(const QString &gid);
    void removeTask(const QString &gid);
    void openTaskFolder(const QString &gid);

    // ==================== 批量操作 ====================
    void pauseAll();
    void resumeAll();

    // ==================== 任务查询 ====================
    std::vector<Task> getActiveTasks() const;
    std::vector<Task> getWaitingTasks() const;
    std::vector<Task> getStoppedTasks() const;

signals:
    void tasksUpdated();
    void errorOccurred(QString message);

private slots:
    void onProcessReadyReadStandardOutput();
    void onProcessReadyReadStandardError();
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessError(QProcess::ProcessError error);

private:
    /**
     * @struct M3u8Job
     * @brief M3U8 下载任务信息
     */
    struct M3u8Job {
        QProcess *process = nullptr;  ///< FFmpeg 进程
        Task task;                     ///< 任务数据
        QJsonObject options;           ///< 下载选项
        QString saveDir;               ///< 保存目录
    };

    QMap<QString, M3u8Job> m_jobs;  ///< 任务映射（gid -> M3u8Job）
    SettingsManager *m_settings;    ///< 设置管理器

    QString generateGid();
    void saveTasksToDisk();
    void processOutput(const QString &output, const QString &gid);
    void startProcessInternal(const QString &gid);
    qint64 parseSizeString(const QString &sizeStr, const QString &unit);
};