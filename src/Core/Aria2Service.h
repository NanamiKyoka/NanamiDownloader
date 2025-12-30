#pragma once

#include <QJsonObject>
#include <QObject>
#include <QProcess>
#include <QWebSocket>
#include <QTimer>
#include <vector>
#include <QQueue>
#include "TaskModel.h"
#include "SettingsManager.h"

class Aria2Service : public QObject
{
    Q_OBJECT

public:
    explicit Aria2Service(SettingsManager* settings, QObject *parent = nullptr);
    ~Aria2Service();

    bool isConnected() const;
    void startService();
    void shutdownService();

    void addUri(const QString &uri, const QJsonObject &options = QJsonObject());
    void addTorrent(const QString &filePath, const QJsonObject &options = QJsonObject());

    void pause(const QString &gid);
    void unpause(const QString &gid);
    void remove(const QString &gid);
    void removeDownloadResult(const QString &gid);
    void pauseAll();
    void unpauseAll();
    void purgeDownloadResult();

    void applyGlobalSettings();

    std::vector<Task> getActiveTasks() const;
    std::vector<Task> getWaitingTasks() const;
    std::vector<Task> getStoppedTasks() const;

    signals:
        void connectionStatusChanged();
    void logReceived(QString log);
    void tasksUpdated();

private slots:
    void onSocketConnected();
    void onSocketDisconnected();
    void onSocketTextMessageReceived(const QString &message);
    void onStatusTimerTimeout();

private:
    QProcess *m_process;
    QWebSocket *m_webSocket;
    QTimer m_reconnectTimer;
    QTimer m_statusTimer;
    bool m_isConnected;
    SettingsManager *m_settings;

    std::vector<Task> m_activeTasks;
    std::vector<Task> m_waitingTasks;
    std::vector<Task> m_stoppedTasks;

    void connectToSocket();
    void sendJsonRpc(const QString &method, const QVariant &params = QVariant(), const QString &id = "");
    Task parseTaskJson(const QJsonObject &json);
};