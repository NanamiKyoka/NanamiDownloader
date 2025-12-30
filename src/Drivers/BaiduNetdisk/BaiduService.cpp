#include "BaiduService.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QDebug>

BaiduService::BaiduService(SettingsManager* settings, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
    , m_netManager(new QNetworkAccessManager(this))
{
}

BaiduService::~BaiduService() {}

void BaiduService::refreshToken()
{
    qInfo() << "Attempting to refresh Baidu Token...";
    QString url = "https://openapi.baidu.com/oauth/2.0/token";
    QUrlQuery query;
    query.addQueryItem("grant_type", "refresh_token");
    query.addQueryItem("refresh_token", m_settings->baiduRefreshToken());
    query.addQueryItem("client_id", CLIENT_ID);
    query.addQueryItem("client_secret", CLIENT_SECRET);

    QUrl qurl(url);
    qurl.setQuery(query);
    QNetworkRequest req(qurl);
    req.setHeader(QNetworkRequest::UserAgentHeader, "pan.baidu.com");

    QNetworkReply *reply = m_netManager->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply](){
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            QString errMsg = "Baidu Token Refresh Failed: " + reply->errorString();
            qWarning() << errMsg;
            emit errorOccurred(errMsg);
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonObject root = doc.object();

        if (root.contains("access_token")) {
            QString access = root["access_token"].toString();
            QString refresh = root["refresh_token"].toString();
            m_settings->setBaiduAccessToken(access);
            m_settings->setBaiduRefreshToken(refresh);
            qInfo() << "Baidu Token Refreshed Successfully";
        } else {
            qWarning() << "Baidu Token Refresh response invalid:" << doc.toJson(QJsonDocument::Compact);
            emit errorOccurred("Invalid Token Response from Baidu");
        }
    });
}

void BaiduService::listFiles(const QString &path)
{
    if (m_settings->baiduRefreshToken().isEmpty()) {
        emit errorOccurred("Please set Baidu Refresh Token in Settings.");
        return;
    }
    if (m_settings->baiduAccessToken().isEmpty()) {
        refreshToken();
        return;
    }
    fetchFileList(path);
}

void BaiduService::fetchFileList(const QString &path)
{
    QString url = "https://pan.baidu.com/rest/2.0/xpan/file";
    QUrlQuery query;
    query.addQueryItem("method", "list");
    query.addQueryItem("dir", path);
    query.addQueryItem("order", "name");
    query.addQueryItem("start", "0");
    query.addQueryItem("limit", "1000");
    query.addQueryItem("web", "web");
    query.addQueryItem("access_token", m_settings->baiduAccessToken());

    QUrl qurl(url);
    qurl.setQuery(query);
    QNetworkRequest req(qurl);
    req.setHeader(QNetworkRequest::UserAgentHeader, "pan.baidu.com");

    QNetworkReply *reply = m_netManager->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply](){
        reply->deleteLater();
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject root = doc.object();

        int errno_ = root["errno"].toInt();
        if (errno_ != 0) {
            if (errno_ == -6 || errno_ == 111) {
                qInfo() << "Baidu Token expired (errno" << errno_ << "), refreshing...";
                refreshToken();
            } else {
                QString msg = "Baidu List Failed: " + QString::number(errno_);
                qWarning() << msg;
                emit errorOccurred(msg);
            }
            return;
        }

        std::vector<BaiduFile> files;
        QJsonArray list = root["list"].toArray();
        for (const auto &val : list) {
            QJsonObject item = val.toObject();
            BaiduFile f;
            f.fs_id = QString::number(item["fs_id"].toVariant().toLongLong());
            f.server_filename = item["server_filename"].toString();
            f.path = item["path"].toString();
            f.size = item["size"].toVariant().toLongLong();
            f.isdir = (item["isdir"].toInt() == 1);
            f.server_mtime = item["server_mtime"].toVariant().toLongLong();
            files.push_back(f);
        }
        emit fileListUpdated(files);
    });
}

void BaiduService::downloadFiles(const QStringList &fsIds, const QString &savePath)
{
    if (fsIds.isEmpty()) return;
    qInfo() << "Resolving download links for" << fsIds.size() << "files.";
    fetchDlinks(fsIds, savePath);
}

void BaiduService::fetchDlinks(const QStringList &fsIds, const QString &savePath)
{
    QString url = "https://pan.baidu.com/rest/2.0/xpan/multimedia";
    QUrlQuery query;
    query.addQueryItem("method", "filemetas");
    query.addQueryItem("fsids", "[" + fsIds.join(",") + "]");
    query.addQueryItem("dlink", "1");
    query.addQueryItem("access_token", m_settings->baiduAccessToken());

    QUrl qurl(url);
    qurl.setQuery(query);
    QNetworkRequest req(qurl);
    req.setHeader(QNetworkRequest::UserAgentHeader, "pan.baidu.com");

    QNetworkReply *reply = m_netManager->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, savePath](){
        reply->deleteLater();
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject root = doc.object();

        if (root["errno"].toInt() != 0) {
            QString msg = "Get Link Failed: " + QString::number(root["errno"].toInt());
            qWarning() << msg;
            emit errorOccurred(msg);
            return;
        }

        QJsonArray list = root["list"].toArray();
        for (const auto &val : list) {
            QJsonObject item = val.toObject();
            QString dlink = item["dlink"].toString();
            QString filename = item["server_filename"].toString();
            if (filename.isEmpty() || filename.startsWith(".")) {
                filename = item["filename"].toString();
            }
            if (filename.isEmpty()) {
                filename = QFileInfo(item["path"].toString()).fileName();
            }

            if (dlink.isEmpty()) continue;

            QString finalUrl = dlink + "&access_token=" + m_settings->baiduAccessToken();
            QJsonObject options;
            options["dir"] = savePath;
            options["out"] = filename;
            options["user-agent"] = "pan.baidu.com";

            if (m_settings->split() > 0) {
                options["split"] = QString::number(m_settings->split());
            }
            if (m_settings->maxConnectionPerServer() > 0) {
                options["max-connection-per-server"] = QString::number(m_settings->maxConnectionPerServer());
            }

            emit linkResolved(finalUrl, options, savePath, filename);
        }
    });
}

void BaiduService::deleteFiles(const QStringList &paths)
{
    if (paths.isEmpty()) return;
    executeDelete(paths);
}

void BaiduService::executeDelete(const QStringList &paths)
{
    QString url = "https://pan.baidu.com/rest/2.0/xpan/file";
    QUrlQuery query;
    query.addQueryItem("method", "filemanager");
    query.addQueryItem("opera", "delete");
    query.addQueryItem("access_token", m_settings->baiduAccessToken());

    QUrl qurl(url);
    qurl.setQuery(query);
    QNetworkRequest req(qurl);
    req.setHeader(QNetworkRequest::UserAgentHeader, "pan.baidu.com");
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QStringList jsonList;
    for(const QString &p : paths) {
        jsonList << QString("{\"path\":\"%1\"}").arg(p);
    }
    QString postData = "filelist=[" + jsonList.join(",") + "]";

    QNetworkReply *reply = m_netManager->post(req, postData.toUtf8());
    connect(reply, &QNetworkReply::finished, this, [this, reply](){
        reply->deleteLater();
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (doc.object()["errno"].toInt() == 0) {
            qInfo() << "Baidu File(s) deleted successfully.";
        } else {
            QString msg = "Delete failed: " + QString::number(doc.object()["errno"].toInt());
            qWarning() << msg;
            emit errorOccurred(msg);
        }
    });
}