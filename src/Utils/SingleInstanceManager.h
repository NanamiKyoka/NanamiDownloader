#pragma once

#include <QObject>
#include <QLocalServer>
#include <QLocalSocket>

class SingleInstanceManager : public QObject
{
    Q_OBJECT
public:
    explicit SingleInstanceManager(const QString &uniqueKey, QObject *parent = nullptr);

    bool checkAndListen();

    signals:
        void raiseWindowRequested();

private slots:
    void onNewConnection();

private:
    QString m_key;
    QLocalServer *m_server;
};