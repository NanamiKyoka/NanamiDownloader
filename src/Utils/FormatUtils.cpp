#include "FormatUtils.h"

namespace FormatUtils {

QString formatSpeed(qint64 bytesPerSecond)
{
    if (bytesPerSecond <= 0)
        return "0 B/s";
    if (bytesPerSecond >= 1024LL * 1024 * 1024) {
        return QString::number(static_cast<double>(bytesPerSecond) / (1024 * 1024 * 1024), 'f', 2) + " GB/s";
    } else if (bytesPerSecond >= 1024 * 1024) {
        return QString::number(static_cast<double>(bytesPerSecond) / (1024 * 1024), 'f', 1) + " MB/s";
    } else if (bytesPerSecond >= 1024) {
        return QString::number(static_cast<double>(bytesPerSecond) / 1024, 'f', 0) + " KB/s";
    } else {
        return QString::number(bytesPerSecond) + " B/s";
    }
}

QString formatSize(qint64 bytes)
{
    if (bytes == 0)
        return "0 B";
    
    const char* units[] = { "B", "KB", "MB", "GB", "TB", "PB" };
    int unitIndex = 0;
    double size = static_cast<double>(bytes);
    
    while (size >= 1024.0 && unitIndex < 5) {
        size /= 1024.0;
        unitIndex++;
    }
    
    if (unitIndex == 0) {
        return QString::number(bytes) + " " + units[unitIndex];
    } else {
        return QString::number(size, 'f', 2) + " " + units[unitIndex];
    }
}

QString formatTime(qint64 seconds)
{
    if (seconds < 0)
        return "--:--";
    if (seconds < 60) {
        return QString("%1s").arg(seconds);
    } else if (seconds < 3600) {
        int mins = static_cast<int>(seconds / 60);
        int secs = static_cast<int>(seconds % 60);
        return QString("%1:%2").arg(mins, 2, 10, QChar('0')).arg(secs, 2, 10, QChar('0'));
    } else if (seconds < 86400) {
        int hours = static_cast<int>(seconds / 3600);
        int mins = static_cast<int>((seconds % 3600) / 60);
        int secs = static_cast<int>(seconds % 60);
        return QString("%1:%2:%3")
            .arg(hours, 2, 10, QChar('0'))
            .arg(mins, 2, 10, QChar('0'))
            .arg(secs, 2, 10, QChar('0'));
    } else {
        int days = static_cast<int>(seconds / 86400);
        int hours = static_cast<int>((seconds % 86400) / 3600);
        int mins = static_cast<int>((seconds % 3600) / 60);
        return QString("%1d %2:%3")
            .arg(days)
            .arg(hours, 2, 10, QChar('0'))
            .arg(mins, 2, 10, QChar('0'));
    }
}

QString formatProgress(qint64 completed, qint64 total)
{
    if (total <= 0)
        return "0%";
    
    double percent = static_cast<double>(completed) / total * 100.0;
    return QString::number(percent, 'f', 1) + "%";
}

}
