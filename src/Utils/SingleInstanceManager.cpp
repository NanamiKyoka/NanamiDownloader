#include "SingleInstanceManager.h"
#include <QCoreApplication>
#include <QDateTime>

SingleInstanceManager::SingleInstanceManager(const QString &uniqueKey, QObject *parent)
    : QObject(parent)
    , m_key(uniqueKey)
    , m_server(nullptr)
{
}

bool SingleInstanceManager::checkAndListen()
{
    QLocalSocket socket;
    socket.connectToServer(m_key);

    if (socket.waitForConnected(500)) {
        qInfo() << "Another instance is running. Sending WAKEUP signal.";
        socket.write("WAKEUP");
        socket.flush();
        socket.waitForBytesWritten(500);
        socket.disconnectFromServer();
        return false;
    }
    qInfo() << "No other instance found. Starting server.";

    QLocalServer::removeServer(m_key);

    m_server = new QLocalServer(this);
    connect(m_server, &QLocalServer::newConnection, this, &SingleInstanceManager::onNewConnection);

    if (!m_server->listen(m_key)) {
        return true;
    }

    return true;
}

void SingleInstanceManager::onNewConnection()
{
    QLocalSocket *socket = m_server->nextPendingConnection();
    if (!socket) return;

    connect(socket, &QLocalSocket::readyRead, this, [this, socket]() {
        QByteArray data = socket->readAll();
        if (data == "WAKEUP") {
            qInfo() << "Received WAKEUP signal from secondary instance.";
            emit raiseWindowRequested();
        }
    });
    
    connect(socket, &QLocalSocket::disconnected, socket, &QLocalSocket::deleteLater);
}