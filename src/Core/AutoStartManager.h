#pragma once

#include <QObject>

class AutoStartManager : public QObject
{
    Q_OBJECT

public:
    explicit AutoStartManager(QObject *parent = nullptr);

    bool isAutoStart() const;
    void setAutoStart(bool enable);
};