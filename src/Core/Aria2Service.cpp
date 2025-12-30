#include "Aria2Service.h"
#include "LinkHelper.h"
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QRegularExpression>
#include <QTimer>

Aria2Service::Aria2Service(SettingsManager* settings, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
    , m_process(new QProcess(this))
    , m_webSocket(new QWebSocket(QString(), QWebSocketProtocol::VersionLatest, this))
    , m_isConnected(false)
{
    connect(m_webSocket, &QWebSocket::connected, this, &Aria2Service::onSocketConnected);
    connect(m_webSocket, &QWebSocket::disconnected, this, &Aria2Service::onSocketDisconnected);
    connect(m_webSocket, &QWebSocket::textMessageReceived, this, &Aria2Service::onSocketTextMessageReceived);

    connect(m_process, &QProcess::readyReadStandardOutput, this, [this](){
        QString output = m_process->readAllStandardOutput().trimmed();
        if(!output.isEmpty()) emit logReceived("Aria2: " + output);
    });
    connect(m_process, &QProcess::readyReadStandardError, this, [this](){
         QString output = m_process->readAllStandardError().trimmed();
         if(!output.isEmpty()) emit logReceived("Aria2 Err: " + output);
    });

    m_reconnectTimer.setInterval(2000);
    connect(&m_reconnectTimer, &QTimer::timeout, this, &Aria2Service::connectToSocket);

    m_statusTimer.setInterval(1000);
    connect(&m_statusTimer, &QTimer::timeout, this, &Aria2Service::onStatusTimerTimeout);
}

Aria2Service::~Aria2Service()
{
    shutdownService();
}

bool Aria2Service::isConnected() const
{
    return m_isConnected;
}

void Aria2Service::startService()
{
    if(m_process->state() != QProcess::NotRunning) return;

    QString program = QCoreApplication::applicationDirPath() + "/aria2c.exe";
    QStringList arguments;

    arguments << "--enable-rpc"
              << "--rpc-listen-port=" + QString::number(m_settings->rpcPort())
              << "--rpc-allow-origin-all"
              << "--rpc-listen-all=true"
              << "--continue=true"
              << "--bt-save-metadata=true"
              << "--bt-load-saved-metadata=true";

    if (!m_settings->rpcSecret().isEmpty()) {
        arguments << "--rpc-secret=" + m_settings->rpcSecret();
    }

    arguments << "--max-concurrent-downloads=" + QString::number(m_settings->maxConcurrentDownloads());

    QString sessionPath = QCoreApplication::applicationDirPath() + "/aria2.session";
    QFile sessionFile(sessionPath);
    if (!sessionFile.exists()) {
        qWarning() << "Aria2 session file not found, creating new one:" << sessionPath;
        if(sessionFile.open(QIODevice::WriteOnly)) {
            sessionFile.close();
        }
    }
    qInfo() << "Starting Aria2 Process:" << program;

    arguments << "--input-file=" + sessionPath
              << "--save-session=" + sessionPath
              << "--save-session-interval=30";

    m_process->start(program, arguments);

    QTimer::singleShot(1000, this, &Aria2Service::connectToSocket);
    m_reconnectTimer.start();
}

void Aria2Service::shutdownService()
{
    m_reconnectTimer.stop();
    m_statusTimer.stop();

    m_webSocket->disconnect();

    if (m_isConnected && m_webSocket->state() == QAbstractSocket::ConnectedState) {
        QJsonObject request;
        request["jsonrpc"] = "2.0";
        request["id"] = "SHUTDOWN_SAVE";
        request["method"] = "aria2.saveSession";
        QJsonDocument doc(request);
        m_webSocket->sendTextMessage(QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
        m_webSocket->flush();
        QCoreApplication::processEvents(QEventLoop::AllEvents, 100);
    }

    m_webSocket->close();
    m_isConnected = false;

    if (m_process->state() != QProcess::NotRunning) {
        m_process->terminate();
        if (!m_process->waitForFinished(1000)) {
            m_process->kill();
            m_process->waitForFinished(500);
        }
    }
}

void Aria2Service::addUri(const QString &uri, const QJsonObject &options)
{
    if(uri.isEmpty()) return;
    QString processedUri = LinkHelper::processLink(uri);
    QVariantList params;
    params << QStringList{processedUri};

    QJsonObject finalOptions = options;
    if (finalOptions.contains("dir")) {
        QString dir = finalOptions["dir"].toString();
        if (dir.startsWith("file:///")) finalOptions["dir"] = dir.mid(8);
    }

    QString ruleProxy = m_settings->matchProxy(processedUri);
    if (!ruleProxy.isEmpty()) {
        finalOptions["all-proxy"] = ruleProxy;
    }

    if (!finalOptions.isEmpty()) params << finalOptions;

    Task pending;
    pending.gid = "pending_" + QString::number(QDateTime::currentMSecsSinceEpoch());
    pending.name = processedUri;
    pending.status = "waiting";
    m_waitingTasks.insert(m_waitingTasks.begin(), pending);
    emit tasksUpdated();

    sendJsonRpc("aria2.addUri", params);
    QTimer::singleShot(200, this, &Aria2Service::onStatusTimerTimeout);
}

void Aria2Service::addTorrent(const QString &filePath, const QJsonObject &options)
{
    QString localPath = filePath;
    if (localPath.startsWith("file:///")) localPath = localPath.mid(8);

    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly)) return;
    QString base64 = file.readAll().toBase64();
    file.close();

    QVariantList params;
    params << base64 << QStringList();

    QJsonObject finalOptions = options;
    if (finalOptions.contains("dir")) {
        QString dir = finalOptions["dir"].toString();
        if (dir.startsWith("file:///")) finalOptions["dir"] = dir.mid(8);
    }
    if (!finalOptions.isEmpty()) params << finalOptions;

    Task pending;
    pending.gid = "pending_torrent";
    pending.name = QFileInfo(localPath).fileName();
    pending.status = "waiting";
    m_waitingTasks.insert(m_waitingTasks.begin(), pending);
    emit tasksUpdated();

    sendJsonRpc("aria2.addTorrent", params);
    QTimer::singleShot(200, this, &Aria2Service::onStatusTimerTimeout);
}

void Aria2Service::pause(const QString &gid) { sendJsonRpc("aria2.pause", QVariantList{gid}); }
void Aria2Service::unpause(const QString &gid) { sendJsonRpc("aria2.unpause", QVariantList{gid}); }
void Aria2Service::remove(const QString &gid) { sendJsonRpc("aria2.remove", QVariantList{gid}); }
void Aria2Service::removeDownloadResult(const QString &gid) { sendJsonRpc("aria2.removeDownloadResult", QVariantList{gid}); }
void Aria2Service::pauseAll() { sendJsonRpc("aria2.pauseAll"); }
void Aria2Service::unpauseAll() { sendJsonRpc("aria2.unpauseAll"); }
void Aria2Service::purgeDownloadResult() { sendJsonRpc("aria2.purgeDownloadResult"); }

void Aria2Service::applyGlobalSettings()
{
    QJsonObject options;

    if (m_settings->aria2ProxyEnabled() && !m_settings->aria2ProxyUrl().isEmpty()) {
        options["all-proxy"] = m_settings->aria2ProxyUrl();
    } else {
        options["all-proxy"] = "";
    }

    options["max-overall-download-limit"] = m_settings->globalMaxDownloadSpeed() > 0 ? QString::number(m_settings->globalMaxDownloadSpeed()) + "K" : "0";
    options["max-overall-upload-limit"] = m_settings->globalMaxUploadSpeed() > 0 ? QString::number(m_settings->globalMaxUploadSpeed()) + "K" : "0";
    options["lowest-speed-limit"] = m_settings->minSpeedLimit() > 0 ? QString::number(m_settings->minSpeedLimit()) + "K" : "0";

    options["max-concurrent-downloads"] = QString::number(m_settings->maxConcurrentDownloads());
    options["max-connection-per-server"] = QString::number(m_settings->maxConnectionPerServer());
    options["split"] = QString::number(m_settings->split());
    options["min-split-size"] = m_settings->minSplitSize();

    options["timeout"] = QString::number(m_settings->timeout());
    options["connect-timeout"] = QString::number(m_settings->connectTimeout());
    options["max-tries"] = QString::number(m_settings->maxTries());
    options["retry-wait"] = QString::number(m_settings->retryWait());

    if (!m_settings->userAgent().isEmpty()) {
        options["user-agent"] = m_settings->userAgent();
    }

    sendJsonRpc("aria2.changeGlobalOption", QVariantList{options});
}

void Aria2Service::connectToSocket()
{
    if (m_webSocket->state() == QAbstractSocket::UnconnectedState) {
        QString url = "ws://localhost:" + QString::number(m_settings->rpcPort()) + "/jsonrpc";
        m_webSocket->open(QUrl(url));
    }
}

void Aria2Service::sendJsonRpc(const QString &method, const QVariant &params, const QString &id)
{
    if (!m_isConnected || m_webSocket->state() != QAbstractSocket::ConnectedState) return;

    QJsonObject request;
    request["jsonrpc"] = "2.0";
    request["id"] = id.isEmpty() ? QString::number(QDateTime::currentMSecsSinceEpoch()) : id;
    request["method"] = method;
    if (params.isValid()) request["params"] = QJsonArray::fromVariantList(params.toList());

    if (!m_settings->rpcSecret().isEmpty()) {
        QString token = "token:" + m_settings->rpcSecret();
        if (request.contains("params")) {
             QJsonArray arr = request["params"].toArray();
             arr.insert(0, token);
             request["params"] = arr;
        } else {
             request["params"] = QJsonArray{token};
        }
    }

    QJsonDocument doc(request);
    m_webSocket->sendTextMessage(QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
}

void Aria2Service::onSocketConnected()
{
    qInfo() << "Aria2 WebSocket Connected.";
    m_isConnected = true;
    m_reconnectTimer.stop();
    m_statusTimer.start();
    emit connectionStatusChanged();
    applyGlobalSettings();
    emit logReceived("Aria2 Connected");

    if (m_settings->resumeTasks()) {
        unpauseAll();
    } else {
        pauseAll();
    }
}

void Aria2Service::onSocketDisconnected()
{
    qWarning() << "Aria2 WebSocket Disconnected! Process State:" << m_process->state();
    m_isConnected = false;
    m_statusTimer.stop();
    emit connectionStatusChanged();
    m_reconnectTimer.start();
}

void Aria2Service::onStatusTimerTimeout()
{
    if(!m_isConnected) return;
    sendJsonRpc("aria2.tellActive", QVariantList{}, "REQ_ACTIVE");
    sendJsonRpc("aria2.tellWaiting", QVariantList{0, 1000}, "REQ_WAITING");
    sendJsonRpc("aria2.tellStopped", QVariantList{0, 1000}, "REQ_STOPPED");
}

void Aria2Service::onSocketTextMessageReceived(const QString &message)
{
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8());
    if (!doc.isObject()) return;
    QJsonObject obj = doc.object();

    if (obj.contains("error")) return;
    if (!obj.contains("id")) return;
    QString id = obj["id"].toString();

    if (obj.contains("result")) {
        if (obj["result"].isArray()) {
            QJsonArray results = obj["result"].toArray();
            std::vector<Task> tasks;
            for (const auto &item : results) {
                tasks.push_back(parseTaskJson(item.toObject()));
            }

            if (id == "REQ_ACTIVE") m_activeTasks = tasks;
            else if (id == "REQ_WAITING") m_waitingTasks = tasks;
            else if (id == "REQ_STOPPED") m_stoppedTasks = tasks;

            emit tasksUpdated();
        }
    }
}

Task Aria2Service::parseTaskJson(const QJsonObject &json)
{
    Task task;
    task.gid = json["gid"].toString();
    task.status = json["status"].toString();
    task.totalLength = json["totalLength"].toString().toLongLong();
    task.completedLength = json["completedLength"].toString().toLongLong();
    task.downloadSpeed = json["downloadSpeed"].toString().toLongLong();
    task.uploadSpeed = json["uploadSpeed"].toString().toLongLong();

    if(json.contains("numSeeders")) task.connections = json["numSeeders"].toString().toInt();
    else if(json.contains("connections")) task.connections = json["connections"].toString().toInt();
    else task.connections = 0;

    QJsonArray files = json["files"].toArray();
    bool isBitTorrent = json.contains("bittorrent");

    if (!files.isEmpty()) {
        QJsonObject fileObj = files[0].toObject();
        task.path = fileObj["path"].toString();
        QJsonArray uris = fileObj["uris"].toArray();
        if(!uris.isEmpty()) task.url = uris[0].toObject()["uri"].toString();

        if (isBitTorrent) {
            QJsonObject bt = json["bittorrent"].toObject();
            if (bt.contains("info")) {
                task.name = bt["info"].toObject()["name"].toString();
            }
        }

        if (task.name.isEmpty() && !task.path.isEmpty()) {
            task.name = QFileInfo(task.path).fileName();
        }

        if (task.name.isEmpty() && !task.url.isEmpty()) {
            QUrl qurl(task.url);
            task.name = qurl.fileName();

            if (task.name.isEmpty()) {
                task.name = task.url;
            } else {
                task.name = QUrl::fromPercentEncoding(task.name.toUtf8());
            }
        }

        if (task.name.isEmpty()) {
             task.name = isBitTorrent ? "Metadata..." : "Unknown Task";
        }
    } else {
        task.name = "Unknown Task";
    }
    return task;
}

std::vector<Task> Aria2Service::getActiveTasks() const { return m_activeTasks; }
std::vector<Task> Aria2Service::getWaitingTasks() const { return m_waitingTasks; }
std::vector<Task> Aria2Service::getStoppedTasks() const { return m_stoppedTasks; }