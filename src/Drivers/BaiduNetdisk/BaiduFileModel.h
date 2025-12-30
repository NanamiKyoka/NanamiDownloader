#pragma once

#include <QAbstractListModel>
#include <vector>
#include <QDateTime>

struct BaiduFile {
    QString fs_id;
    QString server_filename;
    QString path;
    qint64 size;
    bool isdir;
    qint64 server_mtime;
    
    QString sizeString() const;
    QString timeString() const;
};

class BaiduFileModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        FsIdRole = Qt::UserRole + 1,
        NameRole,
        PathRole,
        SizeRole,
        SizeStringRole,
        IsDirRole,
        TimeRole,
        TimeStringRole
    };

    explicit BaiduFileModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateData(const std::vector<BaiduFile>& files);
    void clear();
    
    Q_INVOKABLE QVariantMap get(int row) const;

private:
    std::vector<BaiduFile> m_files;
};