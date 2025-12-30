#pragma once

#include <QString>

class LinkHelper
{
public:
    static QString processLink(const QString &link);

private:
    static bool isThunder(const QString &link);
    static QString decodeThunder(const QString &link);
};