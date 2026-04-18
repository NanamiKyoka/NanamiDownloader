/**
 * @file TaskRouter.cpp
 * @brief 任务路由器实现
 */

#include "TaskRouter.h"

ServiceType TaskRouter::identifyService(const QString &gid)
{
    if (gid.startsWith("m3u8_")) {
        return ServiceType::M3u8;
    }
    if (gid.startsWith("bt_")) {
        return ServiceType::Torrent;
    }
    return ServiceType::Aria2;
}

bool TaskRouter::isM3u8Task(const QString &gid)
{
    return gid.startsWith("m3u8_");
}

bool TaskRouter::isTorrentTask(const QString &gid)
{
    return gid.startsWith("bt_");
}

bool TaskRouter::isAria2Task(const QString &gid)
{
    return !gid.startsWith("m3u8_") && !gid.startsWith("bt_");
}

QString TaskRouter::serviceTypeName(ServiceType type)
{
    switch (type) {
    case ServiceType::Aria2:
        return "Aria2";
    case ServiceType::Torrent:
        return "Torrent";
    case ServiceType::M3u8:
        return "M3U8";
    default:
        return "Unknown";
    }
}
