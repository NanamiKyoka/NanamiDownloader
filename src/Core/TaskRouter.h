/**
 * @file TaskRouter.h
 * @brief 任务路由器，根据任务 GID 前缀识别服务类型
 * 
 * 该类负责：
 * - 识别任务所属的下载服务
 * - 提供统一的服务类型判断接口
 * - 消除 DownloadManager 中的重复判断逻辑
 */

#pragma once

#include <QString>

/**
 * @enum ServiceType
 * @brief 下载服务类型枚举
 */
enum class ServiceType {
    Aria2,      ///< HTTP/FTP 下载服务
    Torrent,    ///< BT 种子下载服务
    M3u8        ///< M3U8 流媒体下载服务
};

/**
 * @class TaskRouter
 * @brief 任务路由器
 * 
 * 根据任务 GID 的前缀判断任务所属的服务类型：
 * - "m3u8_" 前缀 -> M3U8 服务
 * - "bt_" 前缀 -> Torrent 服务
 * - 无前缀 -> Aria2 服务
 */
class TaskRouter
{
public:
    /**
     * @brief 根据任务 GID 识别服务类型
     * @param gid 任务全局唯一标识符
     * @return 服务类型
     */
    static ServiceType identifyService(const QString &gid);
    
    /**
     * @brief 检查是否为 M3U8 任务
     * @param gid 任务 GID
     * @return 是否为 M3U8 任务
     */
    static bool isM3u8Task(const QString &gid);
    
    /**
     * @brief 检查是否为 Torrent 任务
     * @param gid 任务 GID
     * @return 是否为 Torrent 任务
     */
    static bool isTorrentTask(const QString &gid);
    
    /**
     * @brief 检查是否为 Aria2 任务
     * @param gid 任务 GID
     * @return 是否为 Aria2 任务
     */
    static bool isAria2Task(const QString &gid);
    
    /**
     * @brief 获取服务类型名称
     * @param type 服务类型
     * @return 类型名称字符串
     */
    static QString serviceTypeName(ServiceType type);
};
