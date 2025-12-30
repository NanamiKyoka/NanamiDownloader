#include "ThunderFileModel.h"

QString ThunderFile::sizeString() const {
    if (isDir()) return "-";
    if (size < 1024) return QString::number(size) + " B";
    if (size < 1024 * 1024) return QString::number(size / 1024.0, 'f', 2) + " KB";
    if (size < 1024 * 1024 * 1024) return QString::number(size / (1024.0 * 1024.0), 'f', 2) + " MB";
    return QString::number(size / (1024.0 * 1024.0 * 1024.0), 'f', 2) + " GB";
}

QString ThunderFile::timeString() const {
    return modified_time.toString("yyyy-MM-dd HH:mm");
}

ThunderFileModel::ThunderFileModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ThunderFileModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return static_cast<int>(m_files.size());
}

QVariant ThunderFileModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_files.size()) return QVariant();

    const auto &file = m_files[index.row()];

    switch (role) {
    case IdRole: return file.id;
    case NameRole: return file.name;
    case SizeRole: return file.size;
    case SizeStringRole: return file.sizeString();
    case IsDirRole: return file.isDir();
    case TimeRole: return file.modified_time;
    case TimeStringRole: return file.timeString();
    case HashRole: return file.hash;
    default: return QVariant();
    }
}

QHash<int, QByteArray> ThunderFileModel::roleNames() const
{
    return {
        {IdRole, "id"},
        {NameRole, "name"},
        {SizeRole, "size"},
        {SizeStringRole, "sizeString"},
        {IsDirRole, "isDir"},
        {TimeRole, "time"},
        {TimeStringRole, "timeString"},
        {HashRole, "hash"}
    };
}

void ThunderFileModel::updateData(const std::vector<ThunderFile>& files)
{
    beginResetModel();
    m_files = files;
    endResetModel();
}

void ThunderFileModel::clear()
{
    beginResetModel();
    m_files.clear();
    endResetModel();
}

QVariantMap ThunderFileModel::get(int row) const
{
    if (row < 0 || row >= m_files.size()) return QVariantMap();
    const auto &f = m_files[row];
    return {
        {"id", f.id},
        {"name", f.name},
        {"isDir", f.isDir()},
        {"path", f.id}
    };
}