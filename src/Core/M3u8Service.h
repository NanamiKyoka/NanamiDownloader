#pragma once

#include <QObject>
#include <QProcess>
#include <QMap>
#include <QJsonObject>
#include <vector>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include "TaskModel.h"
#include "SettingsManager.h"

class M3u8Service : public QObject
{
    Q_OBJECT

public:
    explicit M3u8Service(SettingsManager* settings, QObject *parent = nullptr);
    ~M3u8Service();

    void loadTasks();
    void startTask(const QString &url, const QString &saveName, const QString &saveDir, const QJsonObject &options);
    void resumeTask(const QString &gid);
    void restartTask(const QString &gid);
    void cancelTask(const QString &gid);
    void deleteTask(const QString &gid, bool deleteFile);
    void stopTask(const QString &gid);
    void removeTask(const QString &gid);
    void openTaskFolder(const QString &gid);

    void pauseAll();
    void resumeAll();

    std::vector<Task> getActiveTasks() const;
    std::vector<Task> getWaitingTasks() const;
    std::vector<Task> getStoppedTasks() const;

    signals:
        void tasksUpdated();
    void errorOccurred(QString message);

private slots:
    void onProcessReadyReadStandardOutput();
    void onProcessReadyReadStandardError();
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessError(QProcess::ProcessError error);

private:
    struct M3u8Job {
        QProcess *process = nullptr;
        Task task;
        QJsonObject options;
        QString saveDir;
    };

    QMap<QString, M3u8Job> m_jobs;
    SettingsManager *m_settings;

    QString generateGid();
    void saveTasksToDisk();
    void processOutput(const QString &output, const QString &gid);
    void startProcessInternal(const QString &gid);
    qint64 parseSizeString(const QString &sizeStr, const QString &unit);
};