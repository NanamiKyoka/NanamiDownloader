#include "TaskModel.h"

TaskModel::TaskModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int TaskModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return static_cast<int>(m_tasks.size());
}

QVariant TaskModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_tasks.size())
        return QVariant();

    const auto &task = m_tasks[index.row()];

    switch (role) {
    case GidRole: return task.gid;
    case NameRole: return task.name;
    case StatusRole: return task.status;
    case TotalLengthRole: return task.totalLength;
    case CompletedLengthRole: return task.completedLength;
    case DownloadSpeedRole: return task.downloadSpeed;
    case UploadSpeedRole: return task.uploadSpeed;
    case DownloadSpeedStringRole: return task.downloadSpeedString();
    case ConnectionsRole: return task.connections;
    case ProgressRole: return task.progress();
    case PathRole: return task.path;
    case UrlRole: return task.url;
    default: return QVariant();
    }
}

QHash<int, QByteArray> TaskModel::roleNames() const
{
    return {
        {GidRole, "gid"},
        {NameRole, "name"},
        {StatusRole, "status"},
        {TotalLengthRole, "totalLength"},
        {CompletedLengthRole, "completedLength"},
        {DownloadSpeedRole, "downloadSpeed"},
        {UploadSpeedRole, "uploadSpeed"},
        {DownloadSpeedStringRole, "downloadSpeedString"},
        {ConnectionsRole, "connections"},
        {ProgressRole, "progress"},
        {PathRole, "path"},
        {UrlRole, "url"}
    };
}

void TaskModel::updateTasks(const std::vector<Task>& newTasks)
{
    if (m_tasks.size() != newTasks.size()) {
        beginResetModel();
        m_tasks = newTasks;
        endResetModel();
        return;
    }

    for (size_t i = 0; i < m_tasks.size(); ++i) {
        if (!(m_tasks[i] == newTasks[i])) {
            m_tasks[i] = newTasks[i];
            emit dataChanged(index(static_cast<int>(i), 0), index(static_cast<int>(i), 0));
        }
    }
}

void TaskModel::clear()
{
    beginResetModel();
    m_tasks.clear();
    endResetModel();
}