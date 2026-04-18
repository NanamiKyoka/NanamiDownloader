/**
 * @file ErrorHandler.cpp
 * @brief 统一错误处理类实现
 */

#include "ErrorHandler.h"
#include <QDebug>

ErrorHandler* ErrorHandler::m_instance = nullptr;

ErrorHandler* ErrorHandler::instance()
{
    if (!m_instance) {
        m_instance = new ErrorHandler();
    }
    return m_instance;
}

ErrorHandler::ErrorHandler(QObject *parent)
    : QObject(parent)
{
}

void ErrorHandler::reportError(const ErrorInfo &error)
{
    if (!error.isValid()) {
        return;
    }

    qWarning() << "Error occurred:"
               << "Type:" << errorTypeToString(error.type)
               << "Message:" << error.message
               << "Context:" << error.context
               << "Service:" << error.serviceName;

    emit errorOccurred(error);

    if (error.recoverable && !error.recoveryAction.isEmpty()) {
        emit recoverySuggested(error.recoveryAction);
    }
}

void ErrorHandler::reportError(DownloadError type, const QString &message, const QString &context)
{
    ErrorInfo error;
    error.type = type;
    error.message = message;
    error.context = context;
    reportError(error);
}

QString ErrorHandler::userFriendlyMessage(const ErrorInfo &error) const
{
    QString baseMessage = errorTypeToString(error.type);
    
    if (!error.message.isEmpty()) {
        return baseMessage + ": " + error.message;
    }
    
    return baseMessage;
}

QString ErrorHandler::errorTypeToString(DownloadError type) const
{
    switch (type) {
    case DownloadError::None:
        return QString();
    case DownloadError::NetworkError:
        return tr("网络错误");
    case DownloadError::AuthError:
        return tr("认证失败");
    case DownloadError::FileError:
        return tr("文件错误");
    case DownloadError::InvalidUrl:
        return tr("无效链接");
    case DownloadError::DiskFull:
        return tr("磁盘空间不足");
    case DownloadError::PermissionDenied:
        return tr("权限被拒绝");
    case DownloadError::ConnectionTimeout:
        return tr("连接超时");
    case DownloadError::ServerError:
        return tr("服务器错误");
    case DownloadError::TaskNotFound:
        return tr("任务不存在");
    case DownloadError::ServiceUnavailable:
        return tr("服务不可用");
    case DownloadError::Unknown:
    default:
        return tr("未知错误");
    }
}
