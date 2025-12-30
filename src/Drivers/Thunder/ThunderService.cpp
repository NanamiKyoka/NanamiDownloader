#include "ThunderService.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QDebug>
#include <QCryptographicHash>
#include <QDateTime>

ThunderService::ThunderService(SettingsManager* settings, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
    , m_netManager(new QNetworkAccessManager(this))
{
}

ThunderService::~ThunderService() {}

QNetworkRequest ThunderService::createRequest(const QString &url)
{
    QNetworkRequest req((QUrl(url)));
    if (!m_settings->thunderAccessToken().isEmpty()) {
        req.setRawHeader("Authorization", ("Bearer " + m_settings->thunderAccessToken()).toUtf8());
    }
    req.setHeader(QNetworkRequest::UserAgentHeader, GENERAL_USER_AGENT);

    if (!m_settings->thunderCaptchaToken().isEmpty()) {
        req.setRawHeader("X-Captcha-Token", m_settings->thunderCaptchaToken().toUtf8());
    }

    req.setRawHeader("x-device-id", m_settings->thunderDeviceId().toUtf8());
    req.setRawHeader("x-client-id", CLIENT_ID.toUtf8());
    req.setRawHeader("x-client-version", CLIENT_VERSION.toUtf8());
    req.setRawHeader("Accept", "application/json;charset=UTF-8");

    return req;
}

QString ThunderService::generateDeviceSign(const QString &deviceId)
{
    QString base = deviceId + PACKAGE_NAME + APP_ID + APP_KEY;
    QByteArray sha1 = QCryptographicHash::hash(base.toUtf8(), QCryptographicHash::Sha1).toHex();
    QByteArray md5 = QCryptographicHash::hash(sha1, QCryptographicHash::Md5).toHex();
    return "div101." + deviceId + md5;
}

QString ThunderService::generateCaptchaSign(const QString &timestamp)
{
    QString deviceId = m_settings->thunderDeviceId();
    QStringList algorithms = {
        "9uJNVj/wLmdwKrJaVj/omlQ", "Oz64Lp0GigmChHMf/6TNfxx7O9PyopcczMsnf", "Eb+L7Ce+Ej48u", "jKY0",
        "ASr0zCl6v8W4aidjPK5KHd1Lq3t+vBFf41dqv5+fnOd", "wQlozdg6r1qxh0eRmt3QgNXOvSZO6q/GXK",
        "gmirk+ciAvIgA/cxUUCema47jr/YToixTT+Q6O", "5IiCoM9B1/788ntB", "P07JH0h6qoM6TSUAK2aL9T5s2QBVeY9JWvalf", "+oK0AN"
    };

    QString str = CLIENT_ID + CLIENT_VERSION + PACKAGE_NAME + deviceId + timestamp;
    for (const QString &algo : algorithms) {
        str = QCryptographicHash::hash((str + algo).toUtf8(), QCryptographicHash::Md5).toHex();
    }
    return "1." + str;
}

void ThunderService::refreshCaptchaToken(const QString &action, const QString &username)
{
    QString url = XLUSER_API + "/v1/shield/captcha/init";
    QNetworkRequest req((QUrl(url)));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    req.setHeader(QNetworkRequest::UserAgentHeader, GENERAL_USER_AGENT);

    QString timestamp = QString::number(QDateTime::currentMSecsSinceEpoch());
    QString sign = generateCaptchaSign(timestamp);

    QJsonObject meta;
    meta["client_version"] = CLIENT_VERSION;
    meta["package_name"] = PACKAGE_NAME;
    meta["timestamp"] = timestamp;
    meta["captcha_sign"] = sign;

    if (username.contains("@")) {
        meta["email"] = username;
    } else if (username.length() >= 11 && username.length() <= 13) {
        meta["phone_number"] = username;
    } else {
        meta["username"] = username;
    }

    QJsonObject body;
    body["action"] = action;
    body["captcha_token"] = m_settings->thunderCaptchaToken();
    body["client_id"] = CLIENT_ID;
    body["device_id"] = m_settings->thunderDeviceId();
    body["meta"] = meta;
    body["redirect_uri"] = "xlaccsdk01://xunlei.com/callback?state=harbor";

    QNetworkReply *reply = m_netManager->post(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply, action](){
        reply->deleteLater();
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject root = doc.object();

        QString newToken = root["captcha_token"].toString();
        if (!newToken.isEmpty()) {
            m_settings->setThunderCaptchaToken(newToken);
            qInfo() << "Captcha Token Refreshed automatically.";
            if (action.contains("login")) {
                login();
            }
        } else {
            if (root.contains("url") && !root["url"].toString().isEmpty()) {
                 QString verifyUrl = root["url"].toString();
                 qInfo() << "Captcha verify required:" << verifyUrl;
            }
            QString msg = "Failed to refresh Captcha Token: " + QString::fromUtf8(data);
            qWarning() << msg;
            emit errorOccurred(msg);
        }
    });
}

void ThunderService::forceLogin()
{
    qInfo() << "Force logging in to Thunder...";
    login();
}

void ThunderService::login()
{
    if (m_settings->thunderUsername().isEmpty() || m_settings->thunderPassword().isEmpty()) {
        emit errorOccurred("Please set Thunder Username and Password in Settings.");
        return;
    }

    QString url = XLUSER_API + "/xluser.core.login/v3/login";
    QNetworkRequest req((QUrl(url)));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    req.setHeader(QNetworkRequest::UserAgentHeader, "android-ok-http-client/xl-acc-sdk/version-5.0.12.512000");

    QJsonObject body;
    body["protocolVersion"] = "301";
    body["sequenceNo"] = "1000012";
    body["platformVersion"] = "10";
    body["isCompressed"] = "0";
    body["appid"] = APP_ID;
    body["clientVersion"] = CLIENT_VERSION;
    body["peerID"] = "00000000000000000000000000000000";
    body["appName"] = "ANDROID-" + PACKAGE_NAME;
    body["sdkVersion"] = "512000";
    body["devicesign"] = generateDeviceSign(m_settings->thunderDeviceId());
    body["netWorkType"] = "WIFI";
    body["providerName"] = "NONE";
    body["deviceModel"] = "M2004J7AC";
    body["deviceName"] = "Xiaomi_M2004j7ac";
    body["OSVersion"] = "12";
    body["userName"] = m_settings->thunderUsername();
    body["passWord"] = m_settings->thunderPassword();
    body["creditkey"] = m_settings->thunderCreditKey();
    body["hl"] = "zh-CN";
    body["verifyCode"] = "";
    body["verifyKey"] = "";
    body["isMd5Pwd"] = "0";

    QNetworkReply *reply = m_netManager->post(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply, url](){
        reply->deleteLater();
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject root = doc.object();

        int code = 0;
        if (root.contains("errorCode")) {
            if (root["errorCode"].isString()) {
                code = root["errorCode"].toString().toInt();
            } else {
                code = root["errorCode"].toInt();
            }
        }

        QString errorStr = root["error"].toString();
        QString errDesc = root["errorDescription"].toString();

        if (code != 0 || (errorStr != "success" && !errorStr.isEmpty())) {

            // Error 6 or 1007: Risk Control -> Manual Verification
            if (code == 6 || code == 1007 || errorStr == "review_panel") {
                QString creditKey = root["creditkey"].toString();
                QString reviewUrl = root["reviewurl"].toString();

                m_settings->setThunderCreditKey(creditKey);

                QString deviceSign = generateDeviceSign(m_settings->thunderDeviceId());

                QJsonObject reviewJson;
                reviewJson["creditkey"] = creditKey;
                reviewJson["reviewurl"] = reviewUrl + "&deviceid=" + deviceSign;
                reviewJson["deviceid"] = deviceSign;
                reviewJson["devicesign"] = deviceSign;

                QJsonDocument jsonDoc(reviewJson);
                QString jsonStr = QString::fromUtf8(jsonDoc.toJson(QJsonDocument::Compact));

                qInfo() << "Thunder Login: Manual verification required.";
                emit verificationRequired(jsonStr);
                return;
            }

            // Error 9: Captcha Token Invalid/Expired -> Auto Refresh
            if (code == 9 || errDesc.contains("验证码无效")) {
                qInfo() << "Captcha Token invalid (Error 9), refreshing...";
                refreshCaptchaToken("POST:/xluser.core.login/v3/login", m_settings->thunderUsername());
                return;
            }

            if (errDesc.isEmpty()) errDesc = root["error"].toString();
            QString msg = "Thunder Login Failed (" + QString::number(code) + "): " + errDesc;
            qCritical() << msg;
            emit errorOccurred(msg);
            return;
        }

        QString sessionId = root["sessionID"].toString();
        if (!sessionId.isEmpty()) {
            fetchToken(sessionId);
        } else {
            QString msg = "Login failed: No SessionID. Response: " + QString::fromUtf8(data);
            qWarning() << msg;
            emit errorOccurred(msg);
        }
    });
}

void ThunderService::fetchToken(const QString &sessionId)
{
    QString url = XLUSER_API + "/v1/auth/signin/token";
    QUrl qurl(url);
    QNetworkRequest req(qurl);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    req.setHeader(QNetworkRequest::UserAgentHeader, GENERAL_USER_AGENT);

    if (!m_settings->thunderCaptchaToken().isEmpty()) {
        req.setRawHeader("X-Captcha-Token", m_settings->thunderCaptchaToken().toUtf8());
    }
    req.setRawHeader("x-device-id", m_settings->thunderDeviceId().toUtf8());
    req.setRawHeader("x-client-id", CLIENT_ID.toUtf8());

    QJsonObject body;
    body["client_id"] = CLIENT_ID;
    body["client_secret"] = CLIENT_SECRET;
    body["provider"] = "access_end_point_token";
    body["signin_token"] = sessionId;

    QNetworkReply *reply = m_netManager->post(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply](){
        reply->deleteLater();
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject root = doc.object();

        if (root.contains("error_code")) {
             int code = root["error_code"].toInt();
             if (code == 9) {
                 qInfo() << "Fetch Token failed: Captcha Invalid. Refreshing...";
                 refreshCaptchaToken("POST:/v1/auth/signin/token", m_settings->thunderUsername());
                 return;
             }
        }

        if (root.contains("access_token")) {
            QString access = root["access_token"].toString();
            QString refresh = root["refresh_token"].toString();
            m_settings->setThunderAccessToken(access);
            if(!refresh.isEmpty()) m_settings->setThunderRefreshToken(refresh);

            qInfo() << "Thunder Login Success";
            emit authRequired();
        } else {
            QString err = root["error_description"].toString();
            if (err.isEmpty()) err = root["error"].toString();
            QString msg = "Fetch Token Failed: " + err;
            qWarning() << msg;
            emit errorOccurred(msg);
        }
    });
}

void ThunderService::listFiles(const QString &parentId)
{
    if (m_settings->thunderAccessToken().isEmpty()) {
        if (!m_settings->thunderUsername().isEmpty() && !m_settings->thunderPassword().isEmpty()) {
            if (m_settings->thunderCaptchaToken().isEmpty()) {
                 refreshCaptchaToken("POST:/xluser.core.login/v3/login", m_settings->thunderUsername());
            } else {
                 login();
            }
        } else {
            emit errorOccurred("Thunder credentials not set.");
        }
        return;
    }
    fetchFileList(parentId);
}

void ThunderService::fetchFileList(const QString &parentId)
{
    QString pid = parentId;
    if (pid.isEmpty()) pid = m_settings->thunderMountPathId();

    QString url = API_URL + "/files";
    QUrlQuery query;
    query.addQueryItem("space", "");
    query.addQueryItem("__type", "drive");
    query.addQueryItem("refresh", "true");
    query.addQueryItem("__sync", "true");
    query.addQueryItem("parent_id", pid);
    query.addQueryItem("with_audit", "true");
    query.addQueryItem("limit", "100");
    query.addQueryItem("filters", "{\"phase\":{\"eq\":\"PHASE_TYPE_COMPLETE\"},\"trashed\":{\"eq\":false}}");

    QUrl qurl(url);
    qurl.setQuery(query);

    QNetworkRequest req = createRequest(qurl.toString());
    QNetworkReply *reply = m_netManager->get(req);

    connect(reply, &QNetworkReply::finished, this, [this, reply, parentId](){
        reply->deleteLater();
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject root = doc.object();

        if (root.contains("error_code") && root["error_code"].toInt() != 0) {
            int code = root["error_code"].toInt();
            if (code == 4122 || code == 4121 || code == 10 || code == 16) {
                qInfo() << "Token expired (code " << code << "), logging in...";
                login();
            } else if (code == 9) {
                qInfo() << "Captcha expired (code 9), refreshing...";
                refreshCaptchaToken("GET:/drive/v1/files", m_settings->thunderUsername());
            } else {
                QString msg = "Thunder List Failed: " + root["error_description"].toString();
                qWarning() << msg;
                emit errorOccurred(msg);
            }
            return;
        }

        std::vector<ThunderFile> files;
        QJsonArray list = root["files"].toArray();
        for (const auto &val : list) {
            QJsonObject item = val.toObject();
            ThunderFile f;
            f.id = item["id"].toString();
            f.name = item["name"].toString();
            f.kind = item["kind"].toString();
            f.parent_id = item["parent_id"].toString();
            f.size = item["size"].toString().toLongLong();
            f.thumbnail = item["thumbnail_link"].toString();
            f.hash = item["hash"].toString();
            f.created_time = QDateTime::fromString(item["created_time"].toString(), Qt::ISODate);
            f.modified_time = QDateTime::fromString(item["modified_time"].toString(), Qt::ISODate);
            files.push_back(f);
        }
        emit fileListUpdated(files);
    });
}

void ThunderService::downloadFiles(const QStringList &fileIds, const QString &savePath)
{
    if (fileIds.isEmpty()) return;
    qInfo() << "Downloading Thunder files:" << fileIds;
    fetchDlinks(fileIds, savePath);
}

void ThunderService::fetchDlinks(const QStringList &fileIds, const QString &savePath)
{
    for (const QString &id : fileIds) {
        QString url = API_URL + "/files/" + id;
        QNetworkRequest req = createRequest(url);

        QNetworkReply *reply = m_netManager->get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply, savePath, id](){
            reply->deleteLater();
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            QJsonObject root = doc.object();

            if (root.contains("error_code") && root["error_code"].toInt() != 0) {
                 int code = root["error_code"].toInt();
                 QString errDesc = root["error_description"].toString();

                 if (code == 4122 || code == 4121 || code == 10 || code == 16) {
                     login();
                     emit errorOccurred("Token expired during link fetch. Please try again.");
                     return;
                 }

                 if (code == 9 || errDesc.contains("验证码无效")) {
                     QString action = "GET:/drive/v1/files/" + id;
                     refreshCaptchaToken(action, m_settings->thunderUsername());
                     emit errorOccurred("Captcha invalid. Auto-refreshing... Please retry download in a few seconds.");
                     return;
                 }

                 QString msg = "Get Link Failed: " + errDesc;
                 qWarning() << msg;
                 emit errorOccurred(msg);
                 return;
            }

            QString link = root["web_content_link"].toString();
            QString name = root["name"].toString();

            if (link.isEmpty()) return;

            QJsonObject options;
            options["dir"] = savePath;
            options["out"] = name;

            QJsonArray headers;
            headers.append("User-Agent: " + DOWNLOAD_USER_AGENT);
            if (!m_settings->thunderAccessToken().isEmpty()) {
                headers.append("Authorization: Bearer " + m_settings->thunderAccessToken());
            }
            options["header"] = headers;

            if (m_settings->split() > 0) {
                options["split"] = QString::number(m_settings->split());
            }
            if (m_settings->maxConnectionPerServer() > 0) {
                options["max-connection-per-server"] = QString::number(m_settings->maxConnectionPerServer());
            }

            emit linkResolved(link, options, savePath, name);
        });
    }
}

void ThunderService::deleteFiles(const QStringList &fileIds)
{
    if (fileIds.isEmpty()) return;
    executeDelete(fileIds);
}

void ThunderService::executeDelete(const QStringList &fileIds)
{
    QString url = API_URL + "/files:batchTrash";
    QNetworkRequest req = createRequest(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject body;
    QJsonArray ids;
    for(const QString &id : fileIds) ids.append(id);
    body["ids"] = ids;

    QNetworkReply *reply = m_netManager->post(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply](){
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            qInfo() << "Thunder File(s) moved to trash.";
        } else {
            QString msg = "Delete failed: " + reply->errorString();
            qWarning() << msg;
            emit errorOccurred(msg);
        }
    });
}