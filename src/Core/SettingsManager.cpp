#include "SettingsManager.h"
#include <QRegularExpression>
#include <QUuid>

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
    , m_settings("NanamiDownloader", "Config")
{
}

QString SettingsManager::language() const { return m_settings.value("language", "zh_CN").toString(); }
void SettingsManager::setLanguage(const QString &lang) { m_settings.setValue("language", lang); emit languageChanged(); }

QString SettingsManager::downloadPath() const {
    QString defaultPath = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    return m_settings.value("downloadPath", defaultPath).toString();
}
void SettingsManager::setDownloadPath(const QString &path) {
    QString cleanPath = path;
    if (cleanPath.startsWith("file:///")) cleanPath = cleanPath.mid(8);
    m_settings.setValue("downloadPath", cleanPath);
    emit downloadPathChanged();
}

bool SettingsManager::monitorClipboard() const { return m_settings.value("monitorClipboard", true).toBool(); }
void SettingsManager::setMonitorClipboard(bool monitor) { m_settings.setValue("monitorClipboard", monitor); emit monitorClipboardChanged(); }

bool SettingsManager::resumeTasks() const { return m_settings.value("resumeTasks", true).toBool(); }
void SettingsManager::setResumeTasks(bool resume) { m_settings.setValue("resumeTasks", resume); emit resumeTasksChanged(); }

bool SettingsManager::confirmExit() const { return m_settings.value("confirmExit", true).toBool(); }
void SettingsManager::setConfirmExit(bool confirm) { m_settings.setValue("confirmExit", confirm); emit confirmExitChanged(); }

bool SettingsManager::rememberWindowPosition() const { return m_settings.value("rememberWindowPosition", true).toBool(); }
void SettingsManager::setRememberWindowPosition(bool remember) { m_settings.setValue("rememberWindowPosition", remember); emit rememberWindowPositionChanged(); }

int SettingsManager::closeAction() const { return m_settings.value("closeAction", 0).toInt(); }
void SettingsManager::setCloseAction(int action) { m_settings.setValue("closeAction", action); emit closeActionChanged(); }

int SettingsManager::windowWidth() const { return m_settings.value("windowWidth", 1100).toInt(); }
void SettingsManager::setWindowWidth(int width) { m_settings.setValue("windowWidth", width); emit windowWidthChanged(); }

int SettingsManager::windowHeight() const { return m_settings.value("windowHeight", 700).toInt(); }
void SettingsManager::setWindowHeight(int height) { m_settings.setValue("windowHeight", height); emit windowHeightChanged(); }

int SettingsManager::windowX() const { return m_settings.value("windowX", -1).toInt(); }
void SettingsManager::setWindowX(int x) { m_settings.setValue("windowX", x); emit windowXChanged(); }

int SettingsManager::windowY() const { return m_settings.value("windowY", -1).toInt(); }
void SettingsManager::setWindowY(int y) { m_settings.setValue("windowY", y); emit windowYChanged(); }

QString SettingsManager::aria2ProxyUrl() const { return m_settings.value("aria2ProxyUrl", "").toString(); }
void SettingsManager::setAria2ProxyUrl(const QString &url) { m_settings.setValue("aria2ProxyUrl", url); emit aria2ProxyUrlChanged(); }

bool SettingsManager::aria2ProxyEnabled() const { return m_settings.value("aria2ProxyEnabled", false).toBool(); }
void SettingsManager::setAria2ProxyEnabled(bool enabled) { m_settings.setValue("aria2ProxyEnabled", enabled); emit aria2ProxyEnabledChanged(); }

QString SettingsManager::m3u8ProxyUrl() const { return m_settings.value("m3u8ProxyUrl", "").toString(); }
void SettingsManager::setM3u8ProxyUrl(const QString &url) { m_settings.setValue("m3u8ProxyUrl", url); emit m3u8ProxyUrlChanged(); }

bool SettingsManager::m3u8ProxyEnabled() const { return m_settings.value("m3u8ProxyEnabled", false).toBool(); }
void SettingsManager::setM3u8ProxyEnabled(bool enabled) { m_settings.setValue("m3u8ProxyEnabled", enabled); emit m3u8ProxyEnabledChanged(); }

QString SettingsManager::btProxyUrl() const { return m_settings.value("btProxyUrl", "").toString(); }
void SettingsManager::setBtProxyUrl(const QString &url) { m_settings.setValue("btProxyUrl", url); emit btProxyUrlChanged(); }

bool SettingsManager::btProxyEnabled() const { return m_settings.value("btProxyEnabled", false).toBool(); }
void SettingsManager::setBtProxyEnabled(bool enabled) { m_settings.setValue("btProxyEnabled", enabled); emit btProxyEnabledChanged(); }

QString SettingsManager::proxyRules() const { return m_settings.value("proxyRules", "").toString(); }
void SettingsManager::setProxyRules(const QString &rules) { m_settings.setValue("proxyRules", rules); emit proxyRulesChanged(); }

int SettingsManager::globalMaxDownloadSpeed() const { return m_settings.value("globalMaxDownloadSpeed", 0).toInt(); }
void SettingsManager::setGlobalMaxDownloadSpeed(int speed) { m_settings.setValue("globalMaxDownloadSpeed", speed); emit globalMaxDownloadSpeedChanged(); }

int SettingsManager::globalMaxUploadSpeed() const { return m_settings.value("globalMaxUploadSpeed", 0).toInt(); }
void SettingsManager::setGlobalMaxUploadSpeed(int speed) { m_settings.setValue("globalMaxUploadSpeed", speed); emit globalMaxUploadSpeedChanged(); }

int SettingsManager::minSpeedLimit() const { return m_settings.value("minSpeedLimit", 0).toInt(); }
void SettingsManager::setMinSpeedLimit(int speed) { m_settings.setValue("minSpeedLimit", speed); emit minSpeedLimitChanged(); }

int SettingsManager::maxConcurrentDownloads() const { return m_settings.value("maxConcurrentDownloads", 16).toInt(); }
void SettingsManager::setMaxConcurrentDownloads(int num) { m_settings.setValue("maxConcurrentDownloads", num); emit maxConcurrentDownloadsChanged(); }

int SettingsManager::maxConnectionPerServer() const { return m_settings.value("maxConnectionPerServer", 16).toInt(); }
void SettingsManager::setMaxConnectionPerServer(int num) { m_settings.setValue("maxConnectionPerServer", num); emit maxConnectionPerServerChanged(); }

int SettingsManager::split() const { return m_settings.value("split", 16).toInt(); }
void SettingsManager::setSplit(int num) { m_settings.setValue("split", num); emit splitChanged(); }

QString SettingsManager::minSplitSize() const { return m_settings.value("minSplitSize", "20M").toString(); }
void SettingsManager::setMinSplitSize(const QString &size) { m_settings.setValue("minSplitSize", size); emit minSplitSizeChanged(); }

int SettingsManager::timeout() const { return m_settings.value("timeout", 60).toInt(); }
void SettingsManager::setTimeout(int seconds) { m_settings.setValue("timeout", seconds); emit timeoutChanged(); }

int SettingsManager::connectTimeout() const { return m_settings.value("connectTimeout", 60).toInt(); }
void SettingsManager::setConnectTimeout(int seconds) { m_settings.setValue("connectTimeout", seconds); emit connectTimeoutChanged(); }

int SettingsManager::maxTries() const { return m_settings.value("maxTries", 5).toInt(); }
void SettingsManager::setMaxTries(int num) { m_settings.setValue("maxTries", num); emit maxTriesChanged(); }

int SettingsManager::retryWait() const { return m_settings.value("retryWait", 0).toInt(); }
void SettingsManager::setRetryWait(int seconds) { m_settings.setValue("retryWait", seconds); emit retryWaitChanged(); }

bool SettingsManager::enableDht() const { return m_settings.value("enableDht", true).toBool(); }
void SettingsManager::setEnableDht(bool enable) { m_settings.setValue("enableDht", enable); emit enableDhtChanged(); }

int SettingsManager::btMaxPeers() const { return m_settings.value("btMaxPeers", 55).toInt(); }
void SettingsManager::setBtMaxPeers(int num) { m_settings.setValue("btMaxPeers", num); emit btMaxPeersChanged(); }

bool SettingsManager::btRequireCrypto() const { return m_settings.value("btRequireCrypto", false).toBool(); }
void SettingsManager::setBtRequireCrypto(bool require) { m_settings.setValue("btRequireCrypto", require); emit btRequireCryptoChanged(); }

QString SettingsManager::btTrackers() const { return m_settings.value("btTrackers", "").toString(); }
void SettingsManager::setBtTrackers(const QString &trackers) { m_settings.setValue("btTrackers", trackers); emit btTrackersChanged(); }

QStringList SettingsManager::enabledTrackerSources() const { return m_settings.value("enabledTrackerSources").toStringList(); }
void SettingsManager::setEnabledTrackerSources(const QStringList &sources) { m_settings.setValue("enabledTrackerSources", sources); emit enabledTrackerSourcesChanged(); }

bool SettingsManager::autoUpdateTrackers() const { return m_settings.value("autoUpdateTrackers", true).toBool(); }
void SettingsManager::setAutoUpdateTrackers(bool enable) { m_settings.setValue("autoUpdateTrackers", enable); emit autoUpdateTrackersChanged(); }

void SettingsManager::addTrackerSource(const QString &source) {
    QStringList list = enabledTrackerSources();
    if (!list.contains(source)) {
        list.append(source);
        setEnabledTrackerSources(list);
    }
}

void SettingsManager::removeTrackerSource(const QString &source) {
    QStringList list = enabledTrackerSources();
    if (list.contains(source)) {
        list.removeAll(source);
        setEnabledTrackerSources(list);
    }
}

bool SettingsManager::hasTrackerSource(const QString &source) const {
    return enabledTrackerSources().contains(source);
}

QString SettingsManager::userAgent() const { return m_settings.value("userAgent", "NanamiDownloader/1.0").toString(); }
int SettingsManager::userAgentIndex() const { return m_settings.value("userAgentIndex", 0).toInt(); }
void SettingsManager::setUserAgent(const QString &ua) { m_settings.setValue("userAgent", ua); emit userAgentChanged(); }
void SettingsManager::setUserAgentIndex(int index) { m_settings.setValue("userAgentIndex", index); emit userAgentIndexChanged(); }

int SettingsManager::rpcPort() const { return m_settings.value("rpcPort", 16888).toInt(); }
void SettingsManager::setRpcPort(int port) { m_settings.setValue("rpcPort", port); emit rpcPortChanged(); }

QString SettingsManager::rpcSecret() const { return m_settings.value("rpcSecret", "").toString(); }
void SettingsManager::setRpcSecret(const QString &secret) { m_settings.setValue("rpcSecret", secret); emit rpcSecretChanged(); }

int SettingsManager::onDownloadComplete() const { return m_settings.value("onDownloadComplete", 0).toInt(); }
void SettingsManager::setOnDownloadComplete(int action) { m_settings.setValue("onDownloadComplete", action); emit onDownloadCompleteChanged(); }

int SettingsManager::onDownloadFailure() const { return m_settings.value("onDownloadFailure", 0).toInt(); }
void SettingsManager::setOnDownloadFailure(int action) { m_settings.setValue("onDownloadFailure", action); emit onDownloadFailureChanged(); }

bool SettingsManager::autoStart() const { return m_settings.value("autoStart", false).toBool(); }
void SettingsManager::setAutoStart(bool autoStart) { m_settings.setValue("autoStart", autoStart); emit autoStartChanged(); }

bool SettingsManager::enableCloudMount() const { return m_settings.value("enableCloudMount", false).toBool(); }
void SettingsManager::setEnableCloudMount(bool enable) { m_settings.setValue("enableCloudMount", enable); emit enableCloudMountChanged(); }

bool SettingsManager::enableBaiduMount() const { return m_settings.value("enableBaiduMount", false).toBool(); }
void SettingsManager::setEnableBaiduMount(bool enable) { m_settings.setValue("enableBaiduMount", enable); emit enableBaiduMountChanged(); }

bool SettingsManager::enableThunderMount() const { return m_settings.value("enableThunderMount", false).toBool(); }
void SettingsManager::setEnableThunderMount(bool enable) { m_settings.setValue("enableThunderMount", enable); emit enableThunderMountChanged(); }

QString SettingsManager::baiduRefreshToken() const { return m_settings.value("baiduRefreshToken", "").toString(); }
void SettingsManager::setBaiduRefreshToken(const QString &token) { m_settings.setValue("baiduRefreshToken", token); emit baiduRefreshTokenChanged(); }

QString SettingsManager::baiduAccessToken() const { return m_settings.value("baiduAccessToken", "").toString(); }
void SettingsManager::setBaiduAccessToken(const QString &token) { m_settings.setValue("baiduAccessToken", token); emit baiduAccessTokenChanged(); }

QString SettingsManager::baiduUserAgent() const { return m_settings.value("baiduUserAgent", "pan.baidu.com").toString(); }
void SettingsManager::setBaiduUserAgent(const QString &ua) { m_settings.setValue("baiduUserAgent", ua); emit baiduUserAgentChanged(); }

QString SettingsManager::thunderUsername() const { return m_settings.value("thunderUsername", "").toString(); }
void SettingsManager::setThunderUsername(const QString &v) {
    if (v != thunderUsername()) {
        m_settings.setValue("thunderUsername", v);
        setThunderAccessToken("");
        emit thunderUsernameChanged();
    }
}

QString SettingsManager::thunderPassword() const { return m_settings.value("thunderPassword", "").toString(); }
void SettingsManager::setThunderPassword(const QString &v) {
    if (v != thunderPassword()) {
        m_settings.setValue("thunderPassword", v);
        setThunderAccessToken("");
        emit thunderPasswordChanged();
    }
}

QString SettingsManager::thunderCaptchaToken() const { return m_settings.value("thunderCaptchaToken", "").toString(); }
void SettingsManager::setThunderCaptchaToken(const QString &v) { m_settings.setValue("thunderCaptchaToken", v); emit thunderCaptchaTokenChanged(); }

QString SettingsManager::thunderCreditKey() const { return m_settings.value("thunderCreditKey", "").toString(); }
void SettingsManager::setThunderCreditKey(const QString &v) { m_settings.setValue("thunderCreditKey", v); emit thunderCreditKeyChanged(); }

QString SettingsManager::thunderMountPathId() const { return m_settings.value("thunderMountPathId", "").toString(); }
void SettingsManager::setThunderMountPathId(const QString &v) { m_settings.setValue("thunderMountPathId", v); emit thunderMountPathIdChanged(); }

QString SettingsManager::thunderDeviceId() const {
    QString id = m_settings.value("thunderDeviceId", "").toString();
    if (id.isEmpty()) {
        id = QUuid::createUuid().toString(QUuid::WithoutBraces).replace("-", "").mid(0, 32);
        const_cast<SettingsManager*>(this)->setThunderDeviceId(id);
    }
    return id;
}
void SettingsManager::setThunderDeviceId(const QString &v) { m_settings.setValue("thunderDeviceId", v); emit thunderDeviceIdChanged(); }

QString SettingsManager::thunderAccessToken() const { return m_settings.value("thunderAccessToken", "").toString(); }
void SettingsManager::setThunderAccessToken(const QString &v) { m_settings.setValue("thunderAccessToken", v); emit thunderAccessTokenChanged(); }

QString SettingsManager::thunderRefreshToken() const { return m_settings.value("thunderRefreshToken", "").toString(); }
void SettingsManager::setThunderRefreshToken(const QString &v) { m_settings.setValue("thunderRefreshToken", v); emit thunderRefreshTokenChanged(); }

QString SettingsManager::matchProxy(const QString &url) {
    QString rules = proxyRules();
    if (rules.isEmpty()) return QString();

    QStringList lines = rules.split("\n");
    for(const QString &line : lines) {
        QString clean = line.trimmed();
        if(clean.isEmpty() || clean.startsWith("#")) continue;

        QStringList parts = clean.split("|");
        if(parts.size() >= 2) {
            QString pattern = parts[0].trimmed();
            QString proxy = parts[1].trimmed();

            QRegularExpression re(pattern);
            if (!re.isValid()) {
                if (url.contains(pattern, Qt::CaseInsensitive)) {
                    return proxy;
                }
            } else {
                 if (re.match(url).hasMatch()) {
                    return proxy;
                }
            }
        }
    }
    return QString();
}