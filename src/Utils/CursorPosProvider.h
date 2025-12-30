#pragma once

#include <QObject>
#include <QCursor>
#include <QPoint>

class CursorPosProvider : public QObject
{
    Q_OBJECT
public:
    explicit CursorPosProvider(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE QPoint cursorPosition() const {
        return QCursor::pos();
    }
};