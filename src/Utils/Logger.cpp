#include "Logger.h"
#include <QDesktopServices>
#include <QUrl>
#include <algorithm>

Logger* Logger::m_instance = nullptr;

Logger* Logger::instance()
{
    if (!m_instance) {
        m_instance = new Logger();
    }
    return m_instance;
}

Logger::Logger(QObject *parent) : QObject(parent)
{
}

Logger::~Logger()
{
    if (m_logFile.isOpen()) {
        m_logFile.close();
    }
}

void Logger::init()
{
    QString logDir = QCoreApplication::applicationDirPath() + "/logs";
    QDir dir(logDir);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    QString dateStr = QDate::currentDate().toString("yyyy_MM_dd");
    QString baseName = QString("%1").arg(dateStr);

    QStringList nameFilters;
    nameFilters << baseName + "_??.log";

    QFileInfoList files = dir.entryInfoList(nameFilters, QDir::Files);

    if (files.size() >= 10) {
        std::sort(files.begin(), files.end(), [](const QFileInfo &a, const QFileInfo &b){
            return a.lastModified() < b.lastModified();
        });

        m_logPath = files.first().absoluteFilePath();
    } else {
        int index = 0;
        while (true) {
            QString potentialName = QString("%1_%2.log").arg(baseName).arg(index, 2, 10, QChar('0'));
            if (!dir.exists(potentialName)) {
                m_logPath = dir.filePath(potentialName);
                break;
            }
            index++;
        }
    }

    m_logFile.setFileName(m_logPath);
    if (m_logFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        m_out.setDevice(&m_logFile);
    }
}

QString Logger::getLogPath() const
{
    return m_logPath;
}

void Logger::openLogDir()
{
    QFileInfo fi(m_logPath);
    QDesktopServices::openUrl(QUrl::fromLocalFile(fi.absolutePath()));
}

void Logger::clearLogFile()
{
    QMutexLocker locker(&m_mutex);
    if (m_logFile.isOpen()) {
        m_logFile.resize(0);
    }
}

void Logger::messageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    if (m_instance) {
        m_instance->write(type, context, msg);
    }
}

void Logger::write(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QMutexLocker locker(&m_mutex);

    QString level;
    switch (type) {
    case QtDebugMsg:    level = "DEBUG"; break;
    case QtInfoMsg:     level = "INFO "; break;
    case QtWarningMsg:  level = "WARN "; break;
    case QtCriticalMsg: level = "CRIT "; break;
    case QtFatalMsg:    level = "FATAL"; break;
    }

    QString time = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz");
    QString logMessage = QString("[%1] [%2] %3").arg(time, level, msg);

    if (m_logFile.isOpen()) {
        m_out << logMessage << "\n";
        m_out.flush();
    }

    std::cout << logMessage.toStdString() << std::endl;

    emit newLogEntry(time, level, msg);
}