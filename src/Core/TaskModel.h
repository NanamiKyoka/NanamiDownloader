/**
 * @file TaskModel.h
 * @brief 任务数据模型，提供下载任务的 QML 列表模型
 * 
 * 包含：
 * - Task 结构体：存储单个下载任务的所有信息
 * - TaskModel 类：继承 QAbstractListModel，供 QML ListView 使用
 */

#pragma once

#include <QAbstractListModel>
#include <vector>
#include "../Utils/FormatUtils.h"

/**
 * @struct Task
 * @brief 下载任务数据结构
 * 
 * 存储单个下载任务的所有信息，包括：
 * - 任务标识（gid、名称、状态）
 * - 进度信息（总大小、已完成大小）
 * - 速度信息（下载速度、上传速度）
 * - 文件信息（保存路径、原始链接）
 */
struct Task {
    QString gid;              ///< 任务全局唯一标识符
    QString name;             ///< 任务名称（文件名）
    QString status;           ///< 任务状态（active/waiting/stopped/error/complete）
    qint64 totalLength = 0;       ///< 文件总大小（字节）
    qint64 completedLength = 0;   ///< 已完成大小（字节）
    qint64 downloadSpeed = 0;     ///< 下载速度（字节/秒）
    qint64 uploadSpeed = 0;       ///< 上传速度（字节/秒，BT 任务使用）
    int connections = 0;          ///< 连接数
    QString path;             ///< 保存路径
    QString url;              ///< 原始下载链接

    bool operator==(const Task& other) const {
        return gid == other.gid &&
               name == other.name &&
               status == other.status &&
               totalLength == other.totalLength &&
               completedLength == other.completedLength &&
               downloadSpeed == other.downloadSpeed &&
               uploadSpeed == other.uploadSpeed &&
               connections == other.connections &&
               path == other.path &&
               url == other.url;
    }

    /**
     * @brief 计算下载进度百分比
     * @return 0.0 ~ 1.0 之间的进度值
     */
    double progress() const {
        if (totalLength <= 0) return 0.0;
        return static_cast<double>(completedLength) / totalLength;
    }

    /**
     * @brief 获取格式化的下载速度字符串
     * @return 如 "1.5 MB/s"
     */
    QString downloadSpeedString() const {
        return FormatUtils::formatSpeed(downloadSpeed);
    }

    /**
     * @brief 获取格式化的上传速度字符串
     * @return 如 "500 KB/s"
     */
    QString uploadSpeedString() const {
        return FormatUtils::formatSpeed(uploadSpeed);
    }
    
    /**
     * @brief 获取格式化的文件大小字符串
     * @return 如 "1.5 GB"
     */
    QString totalSizeString() const {
        return FormatUtils::formatSize(totalLength);
    }
    
    /**
     * @brief 获取格式化的进度字符串
     * @return 如 "75.5%"
     */
    QString progressString() const {
        return FormatUtils::formatProgress(completedLength, totalLength);
    }
};

/**
 * @class TaskModel
 * @brief 任务列表模型，用于 QML ListView 展示
 * 
 * 继承 QAbstractListModel，提供：
 * - 任务列表的数据存储
 * - 角色映射供 QML 访问各字段
 * - 批量更新和清空操作
 */
class TaskModel : public QAbstractListModel
{
    Q_OBJECT

public:
    /**
     * @brief QML 可访问的角色枚举
     */
    enum Roles {
        GidRole = Qt::UserRole + 1,  ///< 任务 GID
        NameRole,                     ///< 任务名称
        StatusRole,                   ///< 任务状态
        TotalLengthRole,              ///< 文件总大小
        CompletedLengthRole,          ///< 已完成大小
        DownloadSpeedRole,            ///< 下载速度
        UploadSpeedRole,              ///< 上传速度
        ConnectionsRole,              ///< 连接数
        ProgressRole,                 ///< 进度（0.0~1.0）
        PathRole,                     ///< 保存路径
        UrlRole,                      ///< 原始链接
        DownloadSpeedStringRole       ///< 格式化的下载速度
    };

    explicit TaskModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    /**
     * @brief 批量更新任务列表
     * @param newTasks 新的任务列表
     */
    void updateTasks(const std::vector<Task>& newTasks);
    
    /**
     * @brief 清空所有任务
     */
    void clear();

private:
    std::vector<Task> m_tasks;  ///< 任务列表
};