#pragma once

#include <QObject>
#include <QClipboard>
#include <QGuiApplication>

class ClipboardHelper : public QObject
{
    Q_OBJECT
public:
    explicit ClipboardHelper(QObject *parent = nullptr);

    Q_INVOKABLE void copy(const QString &text);

    signals:
        void linkDetected(QString link);

private slots:
    void onClipboardChanged();

private:
    QClipboard *m_clipboard;
    bool isDownloadable(const QString &text);
};