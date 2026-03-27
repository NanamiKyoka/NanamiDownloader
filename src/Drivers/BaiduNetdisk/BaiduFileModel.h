/**
 * @file BaiduFileModel.h
 * @brief 百度网盘文件数据模型，提供文件列表的 QML 列表模型
 */

#pragma once

#include <QAbstractListModel>
#include <vector>
#include <QDateTime>

/**
 * @struct BaiduFile
 * @brief 百度网盘文件信息结构体
 */
struct BaiduFile {
    QString fs_id;           ///< 文件唯一标识
    QString server_filename; ///< 文件名
    QString path;            ///< 文件路径
    qint64 size;             ///< 文件大小（字节）
    bool isdir;              ///< 是否为目录
    qint64 server_mtime;     ///< 服务器修改时间戳
    
    QString sizeString() const;  ///< 格式化的文件大小
    QString timeString() const;  ///< 格式化的修改时间
};

/**
 * @class BaiduFileModel
 * @brief 百度网盘文件列表模型，用于 QML ListView 展示
 */
class BaiduFileModel : public QAbstractListModel
{
    Q_OBJECT

public:
    /**
     * @brief QML 可访问的角色枚举
     */
    enum Roles {
        FsIdRole = Qt::UserRole + 1,  ///< 文件 ID
        NameRole,                      ///< 文件名
        PathRole,                      ///< 文件路径
        SizeRole,                      ///< 文件大小
        SizeStringRole,                ///< 格式化大小
        IsDirRole,                     ///< 是否为目录
        TimeRole,                      ///< 修改时间戳
        TimeStringRole                 ///< 格式化时间
    };

    explicit BaiduFileModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateData(const std::vector<BaiduFile>& files);
    void clear();
    
    /**
     * @brief 获取指定行的完整数据
     * @param row 行号
     * @return 包含所有字段的 QVariantMap
     */
    Q_INVOKABLE QVariantMap get(int row) const;

private:
    std::vector<BaiduFile> m_files;  ///< 文件列表
};