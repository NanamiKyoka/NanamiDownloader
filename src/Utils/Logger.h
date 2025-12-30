#pragma once

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QMutex>
#include <QDateTime>
#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>
#include <iostream>

class Logger : public QObject
{
    Q_OBJECT
public:
    static Logger* instance();

    void init();
    QString getLogPath() const;
    Q_INVOKABLE void openLogDir();
    Q_INVOKABLE void clearLogFile();

    static void messageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg);

    signals:
        void newLogEntry(QString time, QString level, QString message);

private:
    explicit Logger(QObject *parent = nullptr);
    ~Logger();

    void write(QtMsgType type, const QMessageLogContext &context, const QString &msg);

    static Logger* m_instance;
    QFile m_logFile;
    QTextStream m_out;
    QMutex m_mutex;
    QString m_logPath;
};