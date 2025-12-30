#pragma once

#include <QAbstractListModel>
#include <vector>

struct Task {
    QString gid;
    QString name;
    QString status;
    qint64 totalLength = 0;
    qint64 completedLength = 0;
    qint64 downloadSpeed = 0;
    qint64 uploadSpeed = 0;
    int connections = 0;
    QString path;
    QString url;

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

    double progress() const {
        if (totalLength <= 0) return 0.0;
        return static_cast<double>(completedLength) / totalLength;
    }

    QString downloadSpeedString() const {
        return formatSpeed(downloadSpeed);
    }

    QString uploadSpeedString() const {
        return formatSpeed(uploadSpeed);
    }

    static QString formatSpeed(qint64 bytes) {
        if (bytes <= 0) return "0 B/s";
        if (bytes >= 1024 * 1024) {
            return QString::number(static_cast<double>(bytes) / (1024 * 1024), 'f', 1) + " MB/s";
        } else if (bytes >= 1024) {
            return QString::number(static_cast<double>(bytes) / 1024, 'f', 0) + " KB/s";
        } else {
            return QString::number(bytes) + " B/s";
        }
    }
};

class TaskModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        GidRole = Qt::UserRole + 1,
        NameRole,
        StatusRole,
        TotalLengthRole,
        CompletedLengthRole,
        DownloadSpeedRole,
        UploadSpeedRole,
        ConnectionsRole,
        ProgressRole,
        PathRole,
        UrlRole,
        DownloadSpeedStringRole
    };

    explicit TaskModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateTasks(const std::vector<Task>& newTasks);
    void clear();

private:
    std::vector<Task> m_tasks;
};