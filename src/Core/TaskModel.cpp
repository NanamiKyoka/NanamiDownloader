#include "TaskModel.h"
#include <map>
#include <algorithm>

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
    if (newTasks.empty() && m_tasks.empty()) {
        return;
    }

    if (newTasks.empty()) {
        beginResetModel();
        m_tasks.clear();
        endResetModel();
        return;
    }

    if (m_tasks.empty()) {
        beginInsertRows(QModelIndex(), 0, static_cast<int>(newTasks.size()) - 1);
        m_tasks = newTasks;
        endInsertRows();
        return;
    }

    std::map<QString, size_t> oldIndexMap;
    for (size_t i = 0; i < m_tasks.size(); ++i) {
        oldIndexMap[m_tasks[i].gid] = i;
    }

    std::map<QString, size_t> newIndexMap;
    for (size_t i = 0; i < newTasks.size(); ++i) {
        newIndexMap[newTasks[i].gid] = i;
    }

    std::vector<int> toRemove;
    for (size_t i = 0; i < m_tasks.size(); ++i) {
        if (newIndexMap.find(m_tasks[i].gid) == newIndexMap.end()) {
            toRemove.push_back(static_cast<int>(i));
        }
    }

    std::vector<std::pair<size_t, Task>> toInsert;
    for (size_t i = 0; i < newTasks.size(); ++i) {
        if (oldIndexMap.find(newTasks[i].gid) == oldIndexMap.end()) {
            toInsert.emplace_back(i, newTasks[i]);
        }
    }

    if (toRemove.size() > m_tasks.size() / 2 || toInsert.size() > newTasks.size() / 2) {
        beginResetModel();
        m_tasks = newTasks;
        endResetModel();
        return;
    }

    for (auto it = toRemove.rbegin(); it != toRemove.rend(); ++it) {
        beginRemoveRows(QModelIndex(), *it, *it);
        m_tasks.erase(m_tasks.begin() + *it);
        endRemoveRows();
    }

    for (const auto &pair : toInsert) {
        size_t pos = pair.first;
        if (pos <= m_tasks.size()) {
            beginInsertRows(QModelIndex(), static_cast<int>(pos), static_cast<int>(pos));
            m_tasks.insert(m_tasks.begin() + pos, pair.second);
            endInsertRows();
        }
    }

    oldIndexMap.clear();
    for (size_t i = 0; i < m_tasks.size(); ++i) {
        oldIndexMap[m_tasks[i].gid] = i;
    }

    for (size_t i = 0; i < newTasks.size(); ++i) {
        auto it = oldIndexMap.find(newTasks[i].gid);
        if (it != oldIndexMap.end()) {
            size_t oldIdx = it->second;
            if (!(m_tasks[oldIdx] == newTasks[i])) {
                m_tasks[oldIdx] = newTasks[i];
                emit dataChanged(index(static_cast<int>(oldIdx), 0), 
                                index(static_cast<int>(oldIdx), 0));
            }
        }
    }
}

void TaskModel::clear()
{
    if (m_tasks.empty()) {
        return;
    }
    beginResetModel();
    m_tasks.clear();
    endResetModel();
}