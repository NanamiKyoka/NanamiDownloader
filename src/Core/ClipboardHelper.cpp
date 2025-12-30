#include "ClipboardHelper.h"
#include <QRegularExpression>
#include <QUrl>

ClipboardHelper::ClipboardHelper(QObject *parent)
    : QObject(parent)
{
    m_clipboard = QGuiApplication::clipboard();
    connect(m_clipboard, &QClipboard::changed, this, &ClipboardHelper::onClipboardChanged);
}

void ClipboardHelper::copy(const QString &text)
{
    if (m_clipboard) {
        m_clipboard->setText(text);
    }
}

void ClipboardHelper::onClipboardChanged()
{
    QString text = m_clipboard->text().trimmed();
    if (text.isEmpty()) return;

    if (isDownloadable(text)) {
        emit linkDetected(text);
    }
}

bool ClipboardHelper::isDownloadable(const QString &text)
{
    if (text.startsWith("magnet:?", Qt::CaseInsensitive) ||
        text.startsWith("thunder://", Qt::CaseInsensitive) ||
        text.startsWith("ftp://", Qt::CaseInsensitive) ||
        text.startsWith("ftps://", Qt::CaseInsensitive) ||
        text.startsWith("ed2k://", Qt::CaseInsensitive)) {
        return true;
        }

    if (text.startsWith("http://", Qt::CaseInsensitive) ||
        text.startsWith("https://", Qt::CaseInsensitive)) {

        static const QRegularExpression re(
            R"(\.(?:zip|rar|7z|tar|gz|tgz|iso|dmg|pkg|exe|msi|apk|ipa|jar|xapk|mp4|mkv|avi|mov|mpg|mpeg|flv|webm|mp3|flac|wav|m4a|aac|ogg|pdf|epub|mobi|azw3|torrent|m3u8|ts)(?:[\?#].*)?$)",
            QRegularExpression::CaseInsensitiveOption
        );

        return re.match(text).hasMatch();
        }

    return false;
}