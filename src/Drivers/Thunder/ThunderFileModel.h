/**
 * @file ThunderFileModel.h
 * @brief 迅雷云盘文件数据模型，提供文件列表的 QML 列表模型
 */

#pragma once

#include <QAbstractListModel>
#include <vector>
#include <QDateTime>

/**
 * @struct ThunderFile
 * @brief 迅雷云盘文件信息结构体
 */
struct ThunderFile {
    QString id;              ///< 文件唯一标识
    QString name;            ///< 文件名
    QString kind;            ///< 文件类型（drive#file 或 drive#folder）
    QString parent_id;       ///< 父目录 ID
    qint64 size;             ///< 文件大小（字节）
    QString thumbnail;       ///< 缩略图 URL
    QString mime_type;       ///< MIME 类型
    QDateTime created_time;  ///< 创建时间
    QDateTime modified_time; ///< 修改时间
    QString hash;            ///< 文件哈希值

    bool isDir() const { return kind == "drive#folder"; }
    QString sizeString() const;  ///< 格式化的文件大小
    QString timeString() const;  ///< 格式化的修改时间
};

/**
 * @class ThunderFileModel
 * @brief 迅雷云盘文件列表模型，用于 QML ListView 展示
 */
class ThunderFileModel : public QAbstractListModel
{
    Q_OBJECT

public:
    /**
     * @brief QML 可访问的角色枚举
     */
    enum Roles {
        IdRole = Qt::UserRole + 1,  ///< 文件 ID
        NameRole,                    ///< 文件名
        SizeRole,                    ///< 文件大小
        SizeStringRole,              ///< 格式化大小
        IsDirRole,                   ///< 是否为目录
        TimeRole,                    ///< 修改时间戳
        TimeStringRole,              ///< 格式化时间
        HashRole                     ///< 文件哈希
    };

    explicit ThunderFileModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateData(const std::vector<ThunderFile>& files);
    void clear();
    
    /**
     * @brief 获取指定行的完整数据
     * @param row 行号
     * @return 包含所有字段的 QVariantMap
     */
    Q_INVOKABLE QVariantMap get(int row) const;

private:
    std::vector<ThunderFile> m_files;  ///< 文件列表
};