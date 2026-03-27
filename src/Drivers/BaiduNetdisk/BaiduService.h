/**
 * @file BaiduService.h
 * @brief 百度网盘服务，提供文件浏览和下载功能
 * 
 * 该类负责：
 * - 百度网盘 OAuth 认证（基于 refresh token）
 * - 文件列表获取
 * - 文件下载链接解析
 * - 文件删除操作
 */

#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantList>
#include <QJsonObject>
#include "../../Core/SettingsManager.h"
#include "BaiduFileModel.h"

/**
 * @class BaiduService
 * @brief 百度网盘 API 封装
 * 
 * 使用 OAuth 2.0 认证，需要用户在浏览器中授权后获取 refresh token。
 * 认证信息存储在 SettingsManager 中。
 */
class BaiduService : public QObject
{
    Q_OBJECT

public:
    explicit BaiduService(SettingsManager* settings, QObject *parent = nullptr);
    ~BaiduService();

    // ==================== 文件操作 ====================
    /**
     * @brief 获取指定目录下的文件列表
     * @param path 目录路径，默认为根目录 "/"
     */
    void listFiles(const QString &path = "/");
    
    /**
     * @brief 下载指定文件
     * @param fsIds 文件 ID 列表
     * @param savePath 保存路径
     */
    void downloadFiles(const QStringList &fsIds, const QString &savePath);
    
    /**
     * @brief 删除指定文件
     * @param paths 文件路径列表
     */
    void deleteFiles(const QStringList &paths);

signals:
    /**
     * @brief 文件列表获取完成
     * @param files 文件列表
     */
    void fileListUpdated(const std::vector<BaiduFile> &files);
    
    /**
     * @brief 下载链接解析完成
     * @param url 下载链接
     * @param options aria2 选项
     * @param savePath 保存路径
     * @param filename 文件名
     */
    void linkResolved(QString url, QJsonObject options, QString savePath, QString filename);
    void errorOccurred(QString message);
    
    /**
     * @brief Token 过期，需要重新授权
     */
    void tokenExpired();

private:
    SettingsManager *m_settings;        ///< 设置管理器
    QNetworkAccessManager *m_netManager; ///< 网络请求管理器

    // OAuth 应用凭证
    const QString CLIENT_ID = "hq9yQ9w9kR4YHj1kyYafLygVocobh7Sf";
    const QString CLIENT_SECRET = "YH2VpZcFJHYNnV6vLfHQXDBhcE7ZChyE";

    void refreshToken();

    void fetchFileList(const QString &path);
    void fetchDlinks(const QStringList &fsIds, const QString &savePath);
    void executeDelete(const QStringList &paths);
};