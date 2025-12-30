#pragma once

#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QStringList>

class SettingsManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString downloadPath READ downloadPath WRITE setDownloadPath NOTIFY downloadPathChanged)
    Q_PROPERTY(bool monitorClipboard READ monitorClipboard WRITE setMonitorClipboard NOTIFY monitorClipboardChanged)
    Q_PROPERTY(bool resumeTasks READ resumeTasks WRITE setResumeTasks NOTIFY resumeTasksChanged)
    Q_PROPERTY(bool confirmExit READ confirmExit WRITE setConfirmExit NOTIFY confirmExitChanged)
    Q_PROPERTY(bool rememberWindowPosition READ rememberWindowPosition WRITE setRememberWindowPosition NOTIFY rememberWindowPositionChanged)
    Q_PROPERTY(int closeAction READ closeAction WRITE setCloseAction NOTIFY closeActionChanged)

    Q_PROPERTY(QString aria2ProxyUrl READ aria2ProxyUrl WRITE setAria2ProxyUrl NOTIFY aria2ProxyUrlChanged)
    Q_PROPERTY(bool aria2ProxyEnabled READ aria2ProxyEnabled WRITE setAria2ProxyEnabled NOTIFY aria2ProxyEnabledChanged)
    Q_PROPERTY(QString m3u8ProxyUrl READ m3u8ProxyUrl WRITE setM3u8ProxyUrl NOTIFY m3u8ProxyUrlChanged)
    Q_PROPERTY(bool m3u8ProxyEnabled READ m3u8ProxyEnabled WRITE setM3u8ProxyEnabled NOTIFY m3u8ProxyEnabledChanged)
    Q_PROPERTY(QString btProxyUrl READ btProxyUrl WRITE setBtProxyUrl NOTIFY btProxyUrlChanged)
    Q_PROPERTY(bool btProxyEnabled READ btProxyEnabled WRITE setBtProxyEnabled NOTIFY btProxyEnabledChanged)
    Q_PROPERTY(QString proxyRules READ proxyRules WRITE setProxyRules NOTIFY proxyRulesChanged)

    Q_PROPERTY(int windowWidth READ windowWidth WRITE setWindowWidth NOTIFY windowWidthChanged)
    Q_PROPERTY(int windowHeight READ windowHeight WRITE setWindowHeight NOTIFY windowHeightChanged)
    Q_PROPERTY(int windowX READ windowX WRITE setWindowX NOTIFY windowXChanged)
    Q_PROPERTY(int windowY READ windowY WRITE setWindowY NOTIFY windowYChanged)

    Q_PROPERTY(int globalMaxDownloadSpeed READ globalMaxDownloadSpeed WRITE setGlobalMaxDownloadSpeed NOTIFY globalMaxDownloadSpeedChanged)
    Q_PROPERTY(int globalMaxUploadSpeed READ globalMaxUploadSpeed WRITE setGlobalMaxUploadSpeed NOTIFY globalMaxUploadSpeedChanged)
    Q_PROPERTY(int minSpeedLimit READ minSpeedLimit WRITE setMinSpeedLimit NOTIFY minSpeedLimitChanged)

    Q_PROPERTY(int maxConcurrentDownloads READ maxConcurrentDownloads WRITE setMaxConcurrentDownloads NOTIFY maxConcurrentDownloadsChanged)
    Q_PROPERTY(int maxConnectionPerServer READ maxConnectionPerServer WRITE setMaxConnectionPerServer NOTIFY maxConnectionPerServerChanged)
    Q_PROPERTY(int split READ split WRITE setSplit NOTIFY splitChanged)
    Q_PROPERTY(QString minSplitSize READ minSplitSize WRITE setMinSplitSize NOTIFY minSplitSizeChanged)

    Q_PROPERTY(int timeout READ timeout WRITE setTimeout NOTIFY timeoutChanged)
    Q_PROPERTY(int connectTimeout READ connectTimeout WRITE setConnectTimeout NOTIFY connectTimeoutChanged)
    Q_PROPERTY(int maxTries READ maxTries WRITE setMaxTries NOTIFY maxTriesChanged)
    Q_PROPERTY(int retryWait READ retryWait WRITE setRetryWait NOTIFY retryWaitChanged)

    Q_PROPERTY(bool enableDht READ enableDht WRITE setEnableDht NOTIFY enableDhtChanged)
    Q_PROPERTY(int btMaxPeers READ btMaxPeers WRITE setBtMaxPeers NOTIFY btMaxPeersChanged)
    Q_PROPERTY(bool btRequireCrypto READ btRequireCrypto WRITE setBtRequireCrypto NOTIFY btRequireCryptoChanged)
    Q_PROPERTY(QString btTrackers READ btTrackers WRITE setBtTrackers NOTIFY btTrackersChanged)
    Q_PROPERTY(QStringList enabledTrackerSources READ enabledTrackerSources WRITE setEnabledTrackerSources NOTIFY enabledTrackerSourcesChanged)
    Q_PROPERTY(bool autoUpdateTrackers READ autoUpdateTrackers WRITE setAutoUpdateTrackers NOTIFY autoUpdateTrackersChanged)

    Q_PROPERTY(QString userAgent READ userAgent WRITE setUserAgent NOTIFY userAgentChanged)
    Q_PROPERTY(int userAgentIndex READ userAgentIndex WRITE setUserAgentIndex NOTIFY userAgentIndexChanged)

    Q_PROPERTY(int rpcPort READ rpcPort WRITE setRpcPort NOTIFY rpcPortChanged)
    Q_PROPERTY(QString rpcSecret READ rpcSecret WRITE setRpcSecret NOTIFY rpcSecretChanged)

    Q_PROPERTY(int onDownloadComplete READ onDownloadComplete WRITE setOnDownloadComplete NOTIFY onDownloadCompleteChanged)
    Q_PROPERTY(int onDownloadFailure READ onDownloadFailure WRITE setOnDownloadFailure NOTIFY onDownloadFailureChanged)

    Q_PROPERTY(bool autoStart READ autoStart WRITE setAutoStart NOTIFY autoStartChanged)

    Q_PROPERTY(bool enableCloudMount READ enableCloudMount WRITE setEnableCloudMount NOTIFY enableCloudMountChanged)
    Q_PROPERTY(bool enableBaiduMount READ enableBaiduMount WRITE setEnableBaiduMount NOTIFY enableBaiduMountChanged)
    Q_PROPERTY(bool enableThunderMount READ enableThunderMount WRITE setEnableThunderMount NOTIFY enableThunderMountChanged)

    Q_PROPERTY(QString baiduRefreshToken READ baiduRefreshToken WRITE setBaiduRefreshToken NOTIFY baiduRefreshTokenChanged)
    Q_PROPERTY(QString baiduAccessToken READ baiduAccessToken WRITE setBaiduAccessToken NOTIFY baiduAccessTokenChanged)
    Q_PROPERTY(QString baiduUserAgent READ baiduUserAgent WRITE setBaiduUserAgent NOTIFY baiduUserAgentChanged)

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

    QString language() const;

    QString downloadPath() const;
    bool monitorClipboard() const;
    bool resumeTasks() const;
    bool confirmExit() const;
    bool rememberWindowPosition() const;
    int closeAction() const;
    int windowWidth() const;
    int windowHeight() const;
    int windowX() const;
    int windowY() const;

    QString aria2ProxyUrl() const;
    bool aria2ProxyEnabled() const;
    QString m3u8ProxyUrl() const;
    bool m3u8ProxyEnabled() const;
    QString btProxyUrl() const;
    bool btProxyEnabled() const;
    QString proxyRules() const;

    int globalMaxDownloadSpeed() const;
    int globalMaxUploadSpeed() const;
    int minSpeedLimit() const;

    int maxConcurrentDownloads() const;
    int maxConnectionPerServer() const;
    int split() const;
    QString minSplitSize() const;

    int timeout() const;
    int connectTimeout() const;
    int maxTries() const;
    int retryWait() const;

    bool enableDht() const;
    int btMaxPeers() const;
    bool btRequireCrypto() const;
    QString btTrackers() const;
    QStringList enabledTrackerSources() const;
    bool autoUpdateTrackers() const;

    QString userAgent() const;
    int userAgentIndex() const;

    int rpcPort() const;
    QString rpcSecret() const;

    int onDownloadComplete() const;
    int onDownloadFailure() const;

    bool autoStart() const;

    bool enableCloudMount() const;
    bool enableBaiduMount() const;
    bool enableThunderMount() const;

    QString baiduRefreshToken() const;
    QString baiduAccessToken() const;
    QString baiduUserAgent() const;

    QString thunderUsername() const;
    QString thunderPassword() const;
    QString thunderCaptchaToken() const;
    QString thunderCreditKey() const;
    QString thunderMountPathId() const;
    QString thunderDeviceId() const;
    QString thunderAccessToken() const;
    QString thunderRefreshToken() const;

    Q_INVOKABLE void addTrackerSource(const QString &source);
    Q_INVOKABLE void removeTrackerSource(const QString &source);
    Q_INVOKABLE bool hasTrackerSource(const QString &source) const;
    Q_INVOKABLE void setUserAgentIndex(int index);

    Q_INVOKABLE QString matchProxy(const QString &url);

public slots:
    void setLanguage(const QString &lang);

    void setDownloadPath(const QString &path);
    void setMonitorClipboard(bool monitor);
    void setResumeTasks(bool resume);
    void setConfirmExit(bool confirm);
    void setRememberWindowPosition(bool remember);
    void setCloseAction(int action);
    void setWindowWidth(int width);
    void setWindowHeight(int height);
    void setWindowX(int x);
    void setWindowY(int y);

    void setAria2ProxyUrl(const QString &url);
    void setAria2ProxyEnabled(bool enabled);
    void setM3u8ProxyUrl(const QString &url);
    void setM3u8ProxyEnabled(bool enabled);
    void setBtProxyUrl(const QString &url);
    void setBtProxyEnabled(bool enabled);
    void setProxyRules(const QString &rules);

    void setGlobalMaxDownloadSpeed(int speed);
    void setGlobalMaxUploadSpeed(int speed);
    void setMinSpeedLimit(int speed);

    void setMaxConcurrentDownloads(int num);
    void setMaxConnectionPerServer(int num);
    void setSplit(int num);
    void setMinSplitSize(const QString &size);

    void setTimeout(int seconds);
    void setConnectTimeout(int seconds);
    void setMaxTries(int num);
    void setRetryWait(int seconds);

    void setEnableDht(bool enable);
    void setBtMaxPeers(int num);
    void setBtRequireCrypto(bool require);
    void setBtTrackers(const QString &trackers);
    void setEnabledTrackerSources(const QStringList &sources);
    void setAutoUpdateTrackers(bool enable);

    void setUserAgent(const QString &ua);

    void setRpcPort(int port);
    void setRpcSecret(const QString &secret);

    void setOnDownloadComplete(int action);
    void setOnDownloadFailure(int action);

    void setAutoStart(bool autoStart);

    void setEnableCloudMount(bool enable);
    void setEnableBaiduMount(bool enable);
    void setEnableThunderMount(bool enable);

    void setBaiduRefreshToken(const QString &token);
    void setBaiduAccessToken(const QString &token);
    void setBaiduUserAgent(const QString &ua);

    void setThunderUsername(const QString &v);
    void setThunderPassword(const QString &v);
    void setThunderCaptchaToken(const QString &v);
    void setThunderCreditKey(const QString &v);
    void setThunderMountPathId(const QString &v);
    void setThunderDeviceId(const QString &v);
    void setThunderAccessToken(const QString &v);
    void setThunderRefreshToken(const QString &v);

signals:
    void languageChanged();

    void downloadPathChanged();
    void monitorClipboardChanged();
    void resumeTasksChanged();
    void confirmExitChanged();
    void rememberWindowPositionChanged();
    void closeActionChanged();
    void windowWidthChanged();
    void windowHeightChanged();
    void windowXChanged();
    void windowYChanged();

    void aria2ProxyUrlChanged();
    void aria2ProxyEnabledChanged();
    void m3u8ProxyUrlChanged();
    void m3u8ProxyEnabledChanged();
    void btProxyUrlChanged();
    void btProxyEnabledChanged();
    void proxyRulesChanged();

    void globalMaxDownloadSpeedChanged();
    void globalMaxUploadSpeedChanged();
    void minSpeedLimitChanged();

    void maxConcurrentDownloadsChanged();
    void maxConnectionPerServerChanged();
    void splitChanged();
    void minSplitSizeChanged();

    void timeoutChanged();
    void connectTimeoutChanged();
    void maxTriesChanged();
    void retryWaitChanged();

    void enableDhtChanged();
    void btMaxPeersChanged();
    void btRequireCryptoChanged();
    void btTrackersChanged();
    void enabledTrackerSourcesChanged();
    void autoUpdateTrackersChanged();

    void userAgentChanged();
    void userAgentIndexChanged();
    void rpcPortChanged();
    void rpcSecretChanged();
    void onDownloadCompleteChanged();
    void onDownloadFailureChanged();
    void autoStartChanged();

    void enableCloudMountChanged();
    void enableBaiduMountChanged();
    void enableThunderMountChanged();

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
    QSettings m_settings;
};