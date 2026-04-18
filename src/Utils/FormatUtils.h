#pragma once

#include <QString>

namespace FormatUtils {

QString formatSpeed(qint64 bytesPerSecond);

QString formatSize(qint64 bytes);

QString formatTime(qint64 seconds);

QString formatProgress(qint64 completed, qint64 total);

}
