/**
 * @file SettingsManager.h
 * @brief 设置管理器，负责应用程序所有配置项的持久化存储和访问
 * 
 * 使用 QSettings 实现配置的读写，所有配置项通过 Q_PROPERTY 暴露给 QML。
 * 配置文件存储在系统标准位置（如 Windows 注册表或 INI 文件）。
 */

#pragma once

#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QStringList>

/**
 * @class SettingsManager
 * @brief 应用程序设置管理器
 * 
 * 提供以下配置分类：
 * - 基础设置：下载路径、剪贴板监控、界面语言等
 * - 代理设置：aria2/M3U8/BT 的代理配置
 * - 速度限制：全局上下行速度限制
 * - 连接设置：并发数、分片数、超时等
 * - BT 设置：DHT、Tracker、加密等
 * - 网盘设置：百度网盘、迅雷云盘的认证信息
 */
class SettingsManager : public QObject
{
    Q_OBJECT

    // ==================== 基础设置 ====================
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString downloadPath READ downloadPath WRITE setDownloadPath NOTIFY downloadPathChanged)
    Q_PROPERTY(bool monitorClipboard READ monitorClipboard WRITE setMonitorClipboard NOTIFY monitorClipboardChanged)
    Q_PROPERTY(bool resumeTasks READ resumeTasks WRITE setResumeTasks NOTIFY resumeTasksChanged)
    Q_PROPERTY(bool confirmExit READ confirmExit WRITE setConfirmExit NOTIFY confirmExitChanged)
    Q_PROPERTY(bool confirmDelete READ confirmDelete WRITE setConfirmDelete NOTIFY confirmDeleteChanged)
    Q_PROPERTY(bool deleteWithFile READ deleteWithFile WRITE setDeleteWithFile NOTIFY deleteWithFileChanged)
    Q_PROPERTY(bool rememberWindowPosition READ rememberWindowPosition WRITE setRememberWindowPosition NOTIFY rememberWindowPositionChanged)
    Q_PROPERTY(int closeAction READ closeAction WRITE setCloseAction NOTIFY closeActionChanged)

    // ==================== 代理设置 ====================
    Q_PROPERTY(QString aria2ProxyUrl READ aria2ProxyUrl WRITE setAria2ProxyUrl NOTIFY aria2ProxyUrlChanged)
    Q_PROPERTY(bool aria2ProxyEnabled READ aria2ProxyEnabled WRITE setAria2ProxyEnabled NOTIFY aria2ProxyEnabledChanged)
    Q_PROPERTY(QString m3u8ProxyUrl READ m3u8ProxyUrl WRITE setM3u8ProxyUrl NOTIFY m3u8ProxyUrlChanged)
    Q_PROPERTY(bool m3u8ProxyEnabled READ m3u8ProxyEnabled WRITE setM3u8ProxyEnabled NOTIFY m3u8ProxyEnabledChanged)
    Q_PROPERTY(QString btProxyUrl READ btProxyUrl WRITE setBtProxyUrl NOTIFY btProxyUrlChanged)
    Q_PROPERTY(bool btProxyEnabled READ btProxyEnabled WRITE setBtProxyEnabled NOTIFY btProxyEnabledChanged)
    Q_PROPERTY(QString proxyRules READ proxyRules WRITE setProxyRules NOTIFY proxyRulesChanged)

    // ==================== 窗口设置 ====================
    Q_PROPERTY(int windowWidth READ windowWidth WRITE setWindowWidth NOTIFY windowWidthChanged)
    Q_PROPERTY(int windowHeight READ windowHeight WRITE setWindowHeight NOTIFY windowHeightChanged)
    Q_PROPERTY(int windowX READ windowX WRITE setWindowX NOTIFY windowXChanged)
    Q_PROPERTY(int windowY READ windowY WRITE setWindowY NOTIFY windowYChanged)

    // ==================== 速度限制 ====================
    Q_PROPERTY(int globalMaxDownloadSpeed READ globalMaxDownloadSpeed WRITE setGlobalMaxDownloadSpeed NOTIFY globalMaxDownloadSpeedChanged)
    Q_PROPERTY(int globalMaxUploadSpeed READ globalMaxUploadSpeed WRITE setGlobalMaxUploadSpeed NOTIFY globalMaxUploadSpeedChanged)
    Q_PROPERTY(int minSpeedLimit READ minSpeedLimit WRITE setMinSpeedLimit NOTIFY minSpeedLimitChanged)

    // ==================== 连接设置 ====================
    Q_PROPERTY(int maxConcurrentDownloads READ maxConcurrentDownloads WRITE setMaxConcurrentDownloads NOTIFY maxConcurrentDownloadsChanged)
    Q_PROPERTY(int maxConnectionPerServer READ maxConnectionPerServer WRITE setMaxConnectionPerServer NOTIFY maxConnectionPerServerChanged)
    Q_PROPERTY(int split READ split WRITE setSplit NOTIFY splitChanged)
    Q_PROPERTY(QString minSplitSize READ minSplitSize WRITE setMinSplitSize NOTIFY minSplitSizeChanged)

    // ==================== 超时与重试 ====================
    Q_PROPERTY(int timeout READ timeout WRITE setTimeout NOTIFY timeoutChanged)
    Q_PROPERTY(int connectTimeout READ connectTimeout WRITE setConnectTimeout NOTIFY connectTimeoutChanged)
    Q_PROPERTY(int maxTries READ maxTries WRITE setMaxTries NOTIFY maxTriesChanged)
    Q_PROPERTY(int retryWait READ retryWait WRITE setRetryWait NOTIFY retryWaitChanged)

    // ==================== BT 设置 ====================
    Q_PROPERTY(bool enableDht READ enableDht WRITE setEnableDht NOTIFY enableDhtChanged)
    Q_PROPERTY(int btMaxPeers READ btMaxPeers WRITE setBtMaxPeers NOTIFY btMaxPeersChanged)
    Q_PROPERTY(bool btRequireCrypto READ btRequireCrypto WRITE setBtRequireCrypto NOTIFY btRequireCryptoChanged)
    Q_PROPERTY(QString btTrackers READ btTrackers WRITE setBtTrackers NOTIFY btTrackersChanged)
    Q_PROPERTY(QStringList enabledTrackerSources READ enabledTrackerSources WRITE setEnabledTrackerSources NOTIFY enabledTrackerSourcesChanged)
    Q_PROPERTY(bool autoUpdateTrackers READ autoUpdateTrackers WRITE setAutoUpdateTrackers NOTIFY autoUpdateTrackersChanged)

    // ==================== User-Agent 设置 ====================
    Q_PROPERTY(QString userAgent READ userAgent WRITE setUserAgent NOTIFY userAgentChanged)
    Q_PROPERTY(int userAgentIndex READ userAgentIndex WRITE setUserAgentIndex NOTIFY userAgentIndexChanged)

    // ==================== RPC 设置 ====================
    Q_PROPERTY(int rpcPort READ rpcPort WRITE setRpcPort NOTIFY rpcPortChanged)
    Q_PROPERTY(QString rpcSecret READ rpcSecret WRITE setRpcSecret NOTIFY rpcSecretChanged)

    // ==================== 下载完成动作 ====================
    Q_PROPERTY(int onDownloadComplete READ onDownloadComplete WRITE setOnDownloadComplete NOTIFY onDownloadCompleteChanged)
    Q_PROPERTY(int onDownloadFailure READ onDownloadFailure WRITE setOnDownloadFailure NOTIFY onDownloadFailureChanged)

    // ==================== 开机启动 ====================
    Q_PROPERTY(bool autoStart READ autoStart WRITE setAutoStart NOTIFY autoStartChanged)

    // ==================== 云盘挂载设置 ====================
    Q_PROPERTY(bool enableCloudMount READ enableCloudMount WRITE setEnableCloudMount NOTIFY enableCloudMountChanged)
    Q_PROPERTY(bool enableBaiduMount READ enableBaiduMount WRITE setEnableBaiduMount NOTIFY enableBaiduMountChanged)
    Q_PROPERTY(bool enableThunderMount READ enableThunderMount WRITE setEnableThunderMount NOTIFY enableThunderMountChanged)

    // ==================== 百度网盘认证 ====================
    Q_PROPERTY(QString baiduRefreshToken READ baiduRefreshToken WRITE setBaiduRefreshToken NOTIFY baiduRefreshTokenChanged)
    Q_PROPERTY(QString baiduAccessToken READ baiduAccessToken WRITE setBaiduAccessToken NOTIFY baiduAccessTokenChanged)
    Q_PROPERTY(QString baiduUserAgent READ baiduUserAgent WRITE setBaiduUserAgent NOTIFY baiduUserAgentChanged)

    // ==================== 迅雷云盘认证 ====================
    Q_PROPERTY(QString thunderUsername READ thunderUsername WRITE setThunderUsername NOTIFY thunderUsernameChanged)
    Q_PROPERTY(QString thunderPassword READ thunderPassword WRITE setThunderPassword NOTIFY thunderPasswordChanged)
    Q_PROPERTY(QString thunderCaptchaToken READ thunderCaptchaToken WRITE setThunderCaptchaToken NOTIFY thunderCaptchaTokenChanged)
    Q_PROPERTY(QString thunderCreditKey READ thunderCreditKey WRITE setThunderCreditKey NOTIFY thunderCreditKeyChanged)
    Q_PROPERTY(QString thunderMountPathId READ thunderMountPathId WRITE setThunderMountPathId NOTIFY thunderMountPathIdChanged)
    Q_PROPERTY(QString thunderDeviceId READ thunderDeviceId WRITE setThunderDeviceId NOTIFY thunderDeviceIdChanged)
    Q_PROPERTY(QString thunderAccessToken READ thunderAccessToken WRITE setThunderAccessToken NOTIFY thunderAccessTokenChanged)
    Q_PROPERTY(QString thunderRefreshToken READ thunderRefreshToken WRITE setThunderRefreshToken NOTIFY thunderRefreshTokenChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);

    // ==================== 基础设置访问器 ====================
    QString language() const;
    QString downloadPath() const;
    bool monitorClipboard() const;
    bool resumeTasks() const;
    bool confirmExit() const;
    bool confirmDelete() const;
    bool deleteWithFile() const;
    bool rememberWindowPosition() const;
    int closeAction() const;
    int windowWidth() const;
    int windowHeight() const;
    int windowX() const;
    int windowY() const;

    // ==================== 代理设置访问器 ====================
    QString aria2ProxyUrl() const;
    bool aria2ProxyEnabled() const;
    QString m3u8ProxyUrl() const;
    bool m3u8ProxyEnabled() const;
    QString btProxyUrl() const;
    bool btProxyEnabled() const;
    QString proxyRules() const;

    // ==================== 速度限制访问器 ====================
    int globalMaxDownloadSpeed() const;
    int globalMaxUploadSpeed() const;
    int minSpeedLimit() const;

    // ==================== 连接设置访问器 ====================
    int maxConcurrentDownloads() const;
    int maxConnectionPerServer() const;
    int split() const;
    QString minSplitSize() const;

    // ==================== 超时与重试访问器 ====================
    int timeout() const;
    int connectTimeout() const;
    int maxTries() const;
    int retryWait() const;

    // ==================== BT 设置访问器 ====================
    bool enableDht() const;
    int btMaxPeers() const;
    bool btRequireCrypto() const;
    QString btTrackers() const;
    QStringList enabledTrackerSources() const;
    bool autoUpdateTrackers() const;

    // ==================== User-Agent 访问器 ====================
    QString userAgent() const;
    int userAgentIndex() const;

    // ==================== RPC 设置访问器 ====================
    int rpcPort() const;
    QString rpcSecret() const;

    // ==================== 下载完成动作访问器 ====================
    int onDownloadComplete() const;
    int onDownloadFailure() const;

    // ==================== 开机启动访问器 ====================
    bool autoStart() const;

    // ==================== 云盘挂载访问器 ====================
    bool enableCloudMount() const;
    bool enableBaiduMount() const;
    bool enableThunderMount() const;

    // ==================== 百度网盘认证访问器 ====================
    QString baiduRefreshToken() const;
    QString baiduAccessToken() const;
    QString baiduUserAgent() const;

    // ==================== 迅雷云盘认证访问器 ====================
    QString thunderUsername() const;
    QString thunderPassword() const;
    QString thunderCaptchaToken() const;
    QString thunderCreditKey() const;
    QString thunderMountPathId() const;
    QString thunderDeviceId() const;
    QString thunderAccessToken() const;
    QString thunderRefreshToken() const;

    // ==================== 工具方法 ====================
    /**
     * @brief 添加 Tracker 源地址
     * @param source Tracker 源 URL
     */
    Q_INVOKABLE void addTrackerSource(const QString &source);
    Q_INVOKABLE void removeTrackerSource(const QString &source);
    Q_INVOKABLE bool hasTrackerSource(const QString &source) const;
    Q_INVOKABLE void setUserAgentIndex(int index);

    /**
     * @brief 根据 URL 匹配代理规则
     * @param url 目标 URL
     * @return 匹配的代理地址，无匹配则返回空
     */
    Q_INVOKABLE QString matchProxy(const QString &url);

public slots:
    // ==================== 基础设置 ====================
    void setLanguage(const QString &lang);
    void setDownloadPath(const QString &path);
    void setMonitorClipboard(bool monitor);
    void setResumeTasks(bool resume);
    void setConfirmExit(bool confirm);
    void setConfirmDelete(bool confirm);
    void setDeleteWithFile(bool deleteFile);
    void setRememberWindowPosition(bool remember);
    void setCloseAction(int action);
    void setWindowWidth(int width);
    void setWindowHeight(int height);
    void setWindowX(int x);
    void setWindowY(int y);

    // ==================== 代理设置 ====================
    void setAria2ProxyUrl(const QString &url);
    void setAria2ProxyEnabled(bool enabled);
    void setM3u8ProxyUrl(const QString &url);
    void setM3u8ProxyEnabled(bool enabled);
    void setBtProxyUrl(const QString &url);
    void setBtProxyEnabled(bool enabled);
    void setProxyRules(const QString &rules);

    // ==================== 速度限制 ====================
    void setGlobalMaxDownloadSpeed(int speed);
    void setGlobalMaxUploadSpeed(int speed);
    void setMinSpeedLimit(int speed);

    // ==================== 连接设置 ====================
    void setMaxConcurrentDownloads(int num);
    void setMaxConnectionPerServer(int num);
    void setSplit(int num);
    void setMinSplitSize(const QString &size);

    // ==================== 超时与重试 ====================
    void setTimeout(int seconds);
    void setConnectTimeout(int seconds);
    void setMaxTries(int num);
    void setRetryWait(int seconds);

    // ==================== BT 设置 ====================
    void setEnableDht(bool enable);
    void setBtMaxPeers(int num);
    void setBtRequireCrypto(bool require);
    void setBtTrackers(const QString &trackers);
    void setEnabledTrackerSources(const QStringList &sources);
    void setAutoUpdateTrackers(bool enable);

    // ==================== User-Agent ====================
    void setUserAgent(const QString &ua);

    // ==================== RPC 设置 ====================
    void setRpcPort(int port);
    void setRpcSecret(const QString &secret);

    // ==================== 下载完成动作 ====================
    void setOnDownloadComplete(int action);
    void setOnDownloadFailure(int action);

    // ==================== 开机启动 ====================
    void setAutoStart(bool autoStart);

    // ==================== 云盘挂载 ====================
    void setEnableCloudMount(bool enable);
    void setEnableBaiduMount(bool enable);
    void setEnableThunderMount(bool enable);

    // ==================== 百度网盘认证 ====================
    void setBaiduRefreshToken(const QString &token);
    void setBaiduAccessToken(const QString &token);
    void setBaiduUserAgent(const QString &ua);

    // ==================== 迅雷云盘认证 ====================
    void setThunderUsername(const QString &v);
    void setThunderPassword(const QString &v);
    void setThunderCaptchaToken(const QString &v);
    void setThunderCreditKey(const QString &v);
    void setThunderMountPathId(const QString &v);
    void setThunderDeviceId(const QString &v);
    void setThunderAccessToken(const QString &v);
    void setThunderRefreshToken(const QString &v);

signals:
    // ==================== 基础设置变更信号 ====================
    void languageChanged();
    void downloadPathChanged();
    void monitorClipboardChanged();
    void resumeTasksChanged();
    void confirmExitChanged();
    void confirmDeleteChanged();
    void deleteWithFileChanged();
    void rememberWindowPositionChanged();
    void closeActionChanged();
    void windowWidthChanged();
    void windowHeightChanged();
    void windowXChanged();
    void windowYChanged();

    // ==================== 代理设置变更信号 ====================
    void aria2ProxyUrlChanged();
    void aria2ProxyEnabledChanged();
    void m3u8ProxyUrlChanged();
    void m3u8ProxyEnabledChanged();
    void btProxyUrlChanged();
    void btProxyEnabledChanged();
    void proxyRulesChanged();

    // ==================== 速度限制变更信号 ====================
    void globalMaxDownloadSpeedChanged();
    void globalMaxUploadSpeedChanged();
    void minSpeedLimitChanged();

    // ==================== 连接设置变更信号 ====================
    void maxConcurrentDownloadsChanged();
    void maxConnectionPerServerChanged();
    void splitChanged();
    void minSplitSizeChanged();

    // ==================== 超时与重试变更信号 ====================
    void timeoutChanged();
    void connectTimeoutChanged();
    void maxTriesChanged();
    void retryWaitChanged();

    // ==================== BT 设置变更信号 ====================
    void enableDhtChanged();
    void btMaxPeersChanged();
    void btRequireCryptoChanged();
    void btTrackersChanged();
    void enabledTrackerSourcesChanged();
    void autoUpdateTrackersChanged();

    // ==================== 其他设置变更信号 ====================
    void userAgentChanged();
    void userAgentIndexChanged();
    void rpcPortChanged();
    void rpcSecretChanged();
    void onDownloadCompleteChanged();
    void onDownloadFailureChanged();
    void autoStartChanged();

    // ==================== 云盘挂载变更信号 ====================
    void enableCloudMountChanged();
    void enableBaiduMountChanged();
    void enableThunderMountChanged();

    // ==================== 网盘认证变更信号 ====================
    void baiduRefreshTokenChanged();
    void baiduAccessTokenChanged();
    void baiduUserAgentChanged();

    void thunderUsernameChanged();
    void thunderPasswordChanged();
    void thunderCaptchaTokenChanged();
    void thunderCreditKeyChanged();
    void thunderMountPathIdChanged();
    void thunderDeviceIdChanged();
    void thunderAccessTokenChanged();
    void thunderRefreshTokenChanged();

private:
    QSettings m_settings;  ///< Qt 设置对象，用于持久化存储配置
};