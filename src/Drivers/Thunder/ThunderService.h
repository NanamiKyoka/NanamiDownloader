/**
 * @file ThunderService.h
 * @brief 迅雷云盘服务，提供文件浏览和下载功能
 * 
 * 该类负责：
 * - 迅雷云盘用户认证（用户名密码登录）
 * - 文件列表获取
 * - 文件下载链接解析
 * - 文件删除操作
 * 
 * 认证流程可能需要验证码，通过 verificationRequired 信号通知 UI。
 */

#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include "../../Core/SettingsManager.h"
#include "ThunderFileModel.h"

/**
 * @class ThunderService
 * @brief 迅雷云盘 API 封装
 * 
 * 模拟迅雷 Android 客户端 API，需要用户名密码登录。
 * 认证信息存储在 SettingsManager 中。
 */
class ThunderService : public QObject
{
    Q_OBJECT

public:
    explicit ThunderService(SettingsManager* settings, QObject *parent = nullptr);
    ~ThunderService();

    // ==================== 文件操作 ====================
    /**
     * @brief 获取指定目录下的文件列表
     * @param parentId 父目录 ID，空字符串表示根目录
     */
    void listFiles(const QString &parentId = "");
    
    /**
     * @brief 下载指定文件
     * @param fileIds 文件 ID 列表
     * @param savePath 保存路径
     */
    void downloadFiles(const QStringList &fileIds, const QString &savePath);
    
    /**
     * @brief 删除指定文件
     * @param fileIds 文件 ID 列表
     */
    void deleteFiles(const QStringList &fileIds);

    // ==================== 认证 ====================
    /**
     * @brief 强制重新登录
     * @note 通常在认证失败时调用
     */
    void forceLogin();

signals:
    /**
     * @brief 文件列表获取完成
     * @param files 文件列表
     */
    void fileListUpdated(const std::vector<ThunderFile> &files);
    
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
     * @brief 需要用户认证（未登录或 Token 过期）
     */
    void authRequired();
    
    /**
     * @brief 需要验证码验证
     * @param url 验证码图片 URL
     */
    void verificationRequired(QString url);

private:
    SettingsManager *m_settings;        ///< 设置管理器
    QNetworkAccessManager *m_netManager; ///< 网络请求管理器

    // API 配置常量
    const QString APP_ID = "40";
    const QString APP_KEY = "34a062aaa22f906fca4fefe9fb3a3021";
    const QString CLIENT_ID = "Xp6vsxz_7IYVw2BB";
    const QString CLIENT_SECRET = "Xp6vsy4tN9toTVdMSpomVdXpRmES";
    const QString CLIENT_VERSION = "8.31.0.9726";
    const QString PACKAGE_NAME = "com.xunlei.downloadprovider";
    const QString API_URL = "https://api-pan.xunlei.com/drive/v1";
    const QString XLUSER_API = "https://xluser-ssl.xunlei.com";

    // User-Agent 字符串
    const QString DOWNLOAD_USER_AGENT = "Dalvik/2.1.0 (Linux; U; Android 12; M2004J7AC Build/SP1A.210812.016)";
    const QString GENERAL_USER_AGENT = "ANDROID-com.xunlei.downloadprovider/8.31.0.9726 netWorkType/5G appid/40 deviceName/Xiaomi_M2004j7ac deviceModel/M2004J7AC OSVersion/12 protocolVersion/301 platformVersion/10 sdkVersion/512000 Oauth2Client/0.9 (Linux 4_14_186-perf-gddfs8vbb238b) (JAVA 0)";

    void login();
    void fetchToken(const QString &sessionId);
    void fetchFileList(const QString &parentId);
    void fetchDlinks(const QStringList &fileIds, const QString &savePath);
    void executeDelete(const QStringList &fileIds);
    void refreshCaptchaToken(const QString &action, const QString &username);

    QNetworkRequest createRequest(const QString &url);
    QString generateDeviceSign(const QString &deviceId);
    QString generateCaptchaSign(const QString &timestamp);
};