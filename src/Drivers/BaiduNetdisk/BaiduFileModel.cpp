#include "BaiduFileModel.h"

QString BaiduFile::sizeString() const {
    if (isdir) return "-";
    if (size < 1024) return QString::number(size) + " B";
    if (size < 1024 * 1024) return QString::number(size / 1024.0, 'f', 2) + " KB";
    if (size < 1024 * 1024 * 1024) return QString::number(size / (1024.0 * 1024.0), 'f', 2) + " MB";
    return QString::number(size / (1024.0 * 1024.0 * 1024.0), 'f', 2) + " GB";
}

QString BaiduFile::timeString() const {
    return QDateTime::fromSecsSinceEpoch(server_mtime).toString("yyyy-MM-dd HH:mm");
}

BaiduFileModel::BaiduFileModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int BaiduFileModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return static_cast<int>(m_files.size());
}

QVariant BaiduFileModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_files.size()) return QVariant();

    const auto &file = m_files[index.row()];

    switch (role) {
    case FsIdRole: return file.fs_id;
    case NameRole: return file.server_filename;
    case PathRole: return file.path;
    case SizeRole: return file.size;
    case SizeStringRole: return file.sizeString();
    case IsDirRole: return file.isdir;
    case TimeRole: return file.server_mtime;
    case TimeStringRole: return file.timeString();
    default: return QVariant();
    }
}

QHash<int, QByteArray> BaiduFileModel::roleNames() const
{
    return {
        {FsIdRole, "fs_id"},
        {NameRole, "name"},
        {PathRole, "path"},
        {SizeRole, "size"},
        {SizeStringRole, "sizeString"},
        {IsDirRole, "isDir"},
        {TimeRole, "time"},
        {TimeStringRole, "timeString"}
    };
}

void BaiduFileModel::updateData(const std::vector<BaiduFile>& files)
{
    beginResetModel();
    m_files = files;
    endResetModel();
}

void BaiduFileModel::clear()
{
    beginResetModel();
    m_files.clear();
    endResetModel();
}

QVariantMap BaiduFileModel::get(int row) const
{
    if (row < 0 || row >= m_files.size()) return QVariantMap();
    const auto &f = m_files[row];
    return {
        {"fs_id", f.fs_id},
        {"name", f.server_filename},
        {"path", f.path},
        {"isDir", f.isdir}
    };
}