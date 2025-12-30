#include "LinkHelper.h"
#include <QByteArray>
#include <QUrl>

QString LinkHelper::processLink(const QString &link)
{
    QString trimmed = link.trimmed();
    if (isThunder(trimmed)) {
        return decodeThunder(trimmed);
    }
    return trimmed;
}

bool LinkHelper::isThunder(const QString &link)
{
    return link.startsWith("thunder://", Qt::CaseInsensitive);
}

QString LinkHelper::decodeThunder(const QString &link)
{
    QString base64 = link.mid(10);
    QByteArray decoded = QByteArray::fromBase64(base64.toUtf8());
    QString decodedStr = QString::fromUtf8(decoded);
    
    if (decodedStr.startsWith("AA") && decodedStr.endsWith("ZZ")) {
        return decodedStr.mid(2, decodedStr.length() - 4);
    }
    return decodedStr;
}