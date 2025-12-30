#pragma once

#include <QAbstractListModel>
#include <vector>
#include <QDateTime>

struct ThunderFile {
    QString id;
    QString name;
    QString kind;
    QString parent_id;
    qint64 size;
    QString thumbnail;
    QString mime_type;
    QDateTime created_time;
    QDateTime modified_time;
    QString hash;

    bool isDir() const { return kind == "drive#folder"; }
    QString sizeString() const;
    QString timeString() const;
};

class ThunderFileModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        SizeRole,
        SizeStringRole,
        IsDirRole,
        TimeRole,
        TimeStringRole,
        HashRole
    };

    explicit ThunderFileModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateData(const std::vector<ThunderFile>& files);
    void clear();
    
    Q_INVOKABLE QVariantMap get(int row) const;

private:
    std::vector<ThunderFile> m_files;
};