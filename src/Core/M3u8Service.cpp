#include "M3u8Service.h"
#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>
#include <QDateTime>
#include <QRegularExpression>
#include <QDesktopServices>
#include <QUrl>
#include <QDebug>

M3u8Service::M3u8Service(SettingsManager* settings, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
{
    loadTasks();
}

M3u8Service::~M3u8Service()
{
    saveTasksToDisk();
    for(auto& job : m_jobs) {
        if(job.process && job.process->state() != QProcess::NotRunning) {
            job.process->kill();
            job.process->waitForFinished(500);
        }
    }
}

void M3u8Service::loadTasks()
{
    QFile file(QCoreApplication::applicationDirPath() + "/m3u8_tasks.json");
    if (!file.open(QIODevice::ReadOnly)) return;

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    QJsonArray array = doc.array();

    bool resume = m_settings->resumeTasks();

    for (const auto &val : array) {
        QJsonObject obj = val.toObject();
        QString gid = obj["gid"].toString();

        M3u8Job job;
        job.task.gid = gid;
        job.task.name = obj["name"].toString();
        job.task.path = obj["path"].toString();
        job.task.url = obj["url"].toString();
        job.task.status = obj["status"].toString();

        job.task.totalLength = obj["totalLength"].toVariant().toLongLong();
        job.task.completedLength = obj["completedLength"].toVariant().toLongLong();
        job.task.downloadSpeed = 0;
        job.task.connections = 1;

        job.saveDir = obj["saveDir"].toString();
        job.options = obj["options"].toObject();
        job.process = nullptr;

        m_jobs.insert(gid, job);

        if (resume && job.task.status == "active") {
            startProcessInternal(gid);
        } else if (job.task.status == "active") {
            m_jobs[gid].task.status = "paused";
        }
    }
    emit tasksUpdated();
}

void M3u8Service::saveTasksToDisk()
{
    QJsonArray array;
    for (auto it = m_jobs.begin(); it != m_jobs.end(); ++it) {
        QJsonObject obj;
        obj["gid"] = it.key();
        obj["name"] = it.value().task.name;
        obj["path"] = it.value().task.path;
        obj["url"] = it.value().task.url;
        obj["status"] = it.value().task.status;
        obj["totalLength"] = it.value().task.totalLength;
        obj["completedLength"] = it.value().task.completedLength;
        obj["saveDir"] = it.value().saveDir;
        obj["options"] = it.value().options;
        array.append(obj);
    }

    QFile file(QCoreApplication::applicationDirPath() + "/m3u8_tasks.json");
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(array).toJson());
    }
}

void M3u8Service::startTask(const QString &url, const QString &saveName, const QString &saveDir, const QJsonObject &options)
{
    QString gid = generateGid();

    QString finalName = saveName.isEmpty() ? "video_" + gid : saveName;
    if (!finalName.endsWith(".mp4") && !finalName.endsWith(".mkv") && !finalName.endsWith(".ts")) {
        finalName += ".mp4";
    }
    QString finalDir = saveDir;
    if (finalDir.startsWith("file:///")) finalDir = finalDir.mid(8);

    M3u8Job job;
    job.task.gid = gid;
    job.task.name = QFileInfo(finalName).completeBaseName();
    job.task.path = QDir(finalDir).filePath(finalName);
    job.task.url = url;
    job.task.status = "waiting";
    job.task.totalLength = 0;
    job.task.completedLength = 0;
    job.task.connections = 1;
    job.saveDir = finalDir;
    job.options = options;
    job.process = nullptr;

    m_jobs.insert(gid, job);
    saveTasksToDisk();

    startProcessInternal(gid);
    qInfo() << "Added M3U8 Task:" << job.task.name << "GID:" << gid;
}

void M3u8Service::resumeTask(const QString &gid)
{
    if (m_jobs.contains(gid)) {
        if (m_jobs[gid].task.status != "active") {
            startProcessInternal(gid);
        }
    }
}

void M3u8Service::restartTask(const QString &gid)
{
    if (m_jobs.contains(gid)) {
        stopTask(gid);

        M3u8Job &job = m_jobs[gid];
        job.task.status = "waiting";
        job.task.completedLength = 0;
        job.task.totalLength = 0;
        job.task.downloadSpeed = 0;

        startProcessInternal(gid);
    }
}

void M3u8Service::cancelTask(const QString &gid)
{
    if (m_jobs.contains(gid)) {
        if (m_jobs[gid].process && m_jobs[gid].process->state() != QProcess::NotRunning) {
            m_jobs[gid].process->kill();
        }
        m_jobs[gid].task.status = "removed";
        m_jobs[gid].task.downloadSpeed = 0;
        emit tasksUpdated();
        saveTasksToDisk();
    }
}

void M3u8Service::deleteTask(const QString &gid, bool deleteFile)
{
    if (m_jobs.contains(gid)) {
        if (deleteFile) {
            QString path = m_jobs[gid].task.path;
            if(!path.isEmpty()) QFile::remove(path);
        }

        if (m_jobs[gid].process) {
            m_jobs[gid].process->kill();
            m_jobs[gid].process->deleteLater();
        }
        m_jobs.remove(gid);
        emit tasksUpdated();
        saveTasksToDisk();
    }
}

void M3u8Service::startProcessInternal(const QString &gid)
{
    if (!m_jobs.contains(gid)) return;

    QString appDir = QCoreApplication::applicationDirPath();
    QString program = appDir + "/N_m3u8DL-RE.exe";
    QString ffmpegPath = appDir + "/ffmpeg.exe";

    if (!QFile::exists(program)) {
        m_jobs[gid].task.status = "error";
        QString errMsg = "Error: N_m3u8DL-RE.exe not found at " + program;
        qCritical() << errMsg;
        emit errorOccurred(errMsg);
        emit tasksUpdated();
        return;
    }

    bool ffmpegValid = false;
    if (QFile::exists(ffmpegPath)) {
        QProcess check;
        check.start(ffmpegPath, QStringList() << "-version");
        if (check.waitForFinished(2000) && check.exitCode() == 0) {
            ffmpegValid = true;
        }
    }

    M3u8Job &job = m_jobs[gid];
    if (job.process) {
        job.process->deleteLater();
        job.process = nullptr;
    }

    QStringList arguments;
    arguments << job.task.url;
    arguments << "--save-dir" << job.saveDir;
    arguments << "--save-name" << job.task.name;
    arguments << "--auto-select";
    arguments << "--no-log";

    int speedLimit = m_settings->globalMaxDownloadSpeed();
    if (speedLimit > 0) {
        arguments << "--max-speed" << (QString::number(speedLimit) + "K");
    }

    QString ruleProxy = m_settings->matchProxy(job.task.url);
    if (!ruleProxy.isEmpty()) {
        arguments << "--custom-proxy" << ruleProxy;
    } else if (m_settings->m3u8ProxyEnabled() && !m_settings->m3u8ProxyUrl().isEmpty()) {
        arguments << "--custom-proxy" << m_settings->m3u8ProxyUrl();
    }

    if (ffmpegValid) {
        arguments << "--ffmpeg-binary-path" << ffmpegPath;
    }

    if (job.options.contains("headers")) {
        QJsonObject headers = job.options["headers"].toObject();
        for(auto it = headers.begin(); it != headers.end(); ++it) {
             if (!it.value().toString().isEmpty()) {
                 arguments << "-H" << (it.key() + ": " + it.value().toString());
             }
        }
    }

    if (job.options.contains("key") && !job.options["key"].toString().isEmpty()) {
        arguments << "--key" << job.options["key"].toString();
    }

    QProcess *process = new QProcess(this);
    process->setProperty("gid", gid);
    process->setProgram(program);
    process->setArguments(arguments);
    process->setWorkingDirectory(appDir);

    process->setProcessChannelMode(QProcess::SeparateChannels);

    connect(process, &QProcess::readyReadStandardOutput, this, &M3u8Service::onProcessReadyReadStandardOutput);
    connect(process, &QProcess::readyReadStandardError, this, &M3u8Service::onProcessReadyReadStandardError);
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &M3u8Service::onProcessFinished);
    connect(process, &QProcess::errorOccurred, this, &M3u8Service::onProcessError);

    job.process = process;
    job.task.status = "active";
    job.task.downloadSpeed = 0;

    qInfo().noquote() << "Starting M3U8 process:" << program << arguments.join(" ");

    process->start();
    emit tasksUpdated();
    saveTasksToDisk();
}

void M3u8Service::stopTask(const QString &gid)
{
    if (m_jobs.contains(gid)) {
        if (m_jobs[gid].process && m_jobs[gid].process->state() != QProcess::NotRunning) {
            m_jobs[gid].process->kill();
        }
        m_jobs[gid].task.status = "paused";
        m_jobs[gid].task.downloadSpeed = 0;
        emit tasksUpdated();
        saveTasksToDisk();
    }
}

void M3u8Service::removeTask(const QString &gid)
{
    deleteTask(gid, false);
}

void M3u8Service::openTaskFolder(const QString &gid)
{
    if (m_jobs.contains(gid)) {
        QFileInfo fi(m_jobs[gid].task.path);
        QDesktopServices::openUrl(QUrl::fromLocalFile(fi.absolutePath()));
    }
}

void M3u8Service::pauseAll()
{
    for (auto it = m_jobs.begin(); it != m_jobs.end(); ++it) {
        if (it.value().task.status == "active" || it.value().task.status == "waiting") {
            stopTask(it.key());
        }
    }
}

void M3u8Service::resumeAll()
{
    for (auto it = m_jobs.begin(); it != m_jobs.end(); ++it) {
        if (it.value().task.status == "paused") {
            startProcessInternal(it.key());
        }
    }
}

std::vector<Task> M3u8Service::getActiveTasks() const
{
    std::vector<Task> list;
    for (auto it = m_jobs.begin(); it != m_jobs.end(); ++it) {
        if (it.value().task.status == "active") list.push_back(it.value().task);
    }
    return list;
}

std::vector<Task> M3u8Service::getWaitingTasks() const
{
    std::vector<Task> list;
    for (auto it = m_jobs.begin(); it != m_jobs.end(); ++it) {
        if (it.value().task.status == "paused" || it.value().task.status == "waiting") list.push_back(it.value().task);
    }
    return list;
}

std::vector<Task> M3u8Service::getStoppedTasks() const
{
    std::vector<Task> list;
    for (auto it = m_jobs.begin(); it != m_jobs.end(); ++it) {
        QString s = it.value().task.status;
        if (s == "complete" || s == "error" || s == "removed") list.push_back(it.value().task);
    }
    return list;
}

qint64 M3u8Service::parseSizeString(const QString &sizeStr, const QString &unit)
{
    double val = sizeStr.toDouble();
    qint64 multiplier = 1;
    QString u = unit.toUpper();
    if (u.contains("K")) multiplier = 1024;
    else if (u.contains("M")) multiplier = 1024 * 1024;
    else if (u.contains("G")) multiplier = 1024 * 1024 * 1024;
    else if (u.contains("T")) multiplier = 1024LL * 1024 * 1024 * 1024;

    return static_cast<qint64>(val * multiplier);
}

void M3u8Service::onProcessReadyReadStandardOutput()
{
    QProcess *p = qobject_cast<QProcess*>(sender());
    if (!p) return;
    QString gid = p->property("gid").toString();

    QByteArray data = p->readAllStandardOutput();
    QString output = QString::fromLocal8Bit(data).trimmed();

    processOutput(output, gid);
}

void M3u8Service::onProcessReadyReadStandardError()
{
    QProcess *p = qobject_cast<QProcess*>(sender());
    if (!p) return;
    QString gid = p->property("gid").toString();

    QByteArray data = p->readAllStandardError();
    QString output = QString::fromLocal8Bit(data).trimmed();

    processOutput(output, gid);
}

void M3u8Service::processOutput(const QString &output, const QString &gid)
{
    if (!m_jobs.contains(gid)) return;
    if (output.isEmpty()) return;

    M3u8Job &job = m_jobs[gid];

    static QRegularExpression mainRx(R"((\d+\.?\d*)%\s+(\d+\.?\d*)([A-Za-z]+)\/(\d+\.?\d*)([A-Za-z]+)\s+(\d+\.?\d*)([A-Za-z]+))");
    QRegularExpressionMatch match = mainRx.match(output);

    if (match.hasMatch()) {
        job.task.completedLength = parseSizeString(match.captured(2), match.captured(3));
        job.task.totalLength = parseSizeString(match.captured(4), match.captured(5));
        job.task.downloadSpeed = parseSizeString(match.captured(6), match.captured(7));
    } else {
        static QRegularExpression totalRx(R"((?:Total Size|Content Length):\s*(\d+\.?\d*)\s*([KMGT]?B))", QRegularExpression::CaseInsensitiveOption);
        QRegularExpressionMatch totalMatch = totalRx.match(output);
        if (totalMatch.hasMatch()) {
            job.task.totalLength = parseSizeString(totalMatch.captured(1), totalMatch.captured(2));
        }

        static QRegularExpression percentOnlyRx(R"((\d+\.?\d*)\%)");
        QRegularExpressionMatch pMatch = percentOnlyRx.match(output);
        if (pMatch.hasMatch()) {
            double percent = pMatch.captured(1).toDouble();
            if (job.task.totalLength > 0) {
                job.task.completedLength = static_cast<qint64>(job.task.totalLength * (percent / 100.0));
            }
        }
    }

    emit tasksUpdated();
}

void M3u8Service::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    QProcess *p = qobject_cast<QProcess*>(sender());
    if (!p) return;
    QString gid = p->property("gid").toString();

    if (m_jobs.contains(gid)) {
        if (m_jobs[gid].task.status != "paused" && m_jobs[gid].task.status != "removed") {
            if (exitCode == 0 && exitStatus == QProcess::NormalExit) {
                m_jobs[gid].task.status = "complete";
                if (m_jobs[gid].task.totalLength > 0) {
                    m_jobs[gid].task.completedLength = m_jobs[gid].task.totalLength;
                } else if (m_jobs[gid].task.completedLength > 0) {
                    m_jobs[gid].task.totalLength = m_jobs[gid].task.completedLength;
                }
                m_jobs[gid].task.downloadSpeed = 0;
                qInfo() << "M3U8 Finished Successfully. GID:" << gid;
            } else {
                m_jobs[gid].task.status = "error";
                QString errMsg = "M3U8 Failed. Exit Code: " + QString::number(exitCode);
                qWarning() << errMsg << "GID:" << gid;
                emit errorOccurred(errMsg);
            }
        }
        m_jobs[gid].process = nullptr;
        p->deleteLater();
    }
    emit tasksUpdated();
    saveTasksToDisk();
}

void M3u8Service::onProcessError(QProcess::ProcessError error)
{
    QProcess *p = qobject_cast<QProcess*>(sender());
    if (!p) return;
    QString gid = p->property("gid").toString();

    if (m_jobs.contains(gid)) {
        if (error != QProcess::Crashed && m_jobs[gid].task.status != "removed") {
             m_jobs[gid].task.status = "error";
             QString errMsg = "M3U8 Process Error: " + p->errorString();
             qCritical() << errMsg << "GID:" << gid;
             emit errorOccurred(errMsg);
        }
    }
    emit tasksUpdated();
    saveTasksToDisk();
}

QString M3u8Service::generateGid()
{
    return "m3u8_" + QString::number(QDateTime::currentMSecsSinceEpoch());
}