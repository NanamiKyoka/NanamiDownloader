/**
 * @file ErrorHandler.h
 * @brief 统一错误处理类，提供一致的错误处理体验
 * 
 * 该类负责：
 * - 定义标准错误类型和错误信息结构
 * - 提供错误信号的统一发射点
 * - 支持错误恢复建议
 */

#pragma once

#include <QObject>
#include <QString>

/**
 * @enum DownloadError
 * @brief 下载相关错误类型枚举
 */
enum class DownloadError {
    None = 0,
    NetworkError,
    AuthError,
    FileError,
    InvalidUrl,
    DiskFull,
    PermissionDenied,
    ConnectionTimeout,
    ServerError,
    TaskNotFound,
    ServiceUnavailable,
    Unknown
};

/**
 * @struct ErrorInfo
 * @brief 错误信息结构体
 */
struct ErrorInfo {
    DownloadError type = DownloadError::None;
    QString message;
    QString context;
    QString serviceName;
    bool recoverable = false;
    QString recoveryAction;
    
    ErrorInfo() = default;
    
    ErrorInfo(DownloadError t, const QString &msg, const QString &ctx = QString())
        : type(t), message(msg), context(ctx), recoverable(false) {}
    
    bool isValid() const { return type != DownloadError::None; }
};

/**
 * @class ErrorHandler
 * @brief 全局错误处理器
 * 
 * 单例模式，提供统一的错误处理接口。
 * 所有服务应通过此类报告错误，确保一致性。
 */
class ErrorHandler : public QObject
{
    Q_OBJECT

public:
    static ErrorHandler* instance();
    
    /**
     * @brief 报告错误
     * @param error 错误信息
     */
    Q_INVOKABLE void reportError(const ErrorInfo &error);
    
    /**
     * @brief 报告错误（便捷方法）
     * @param type 错误类型
     * @param message 错误消息
     * @param context 上下文信息
     */
    Q_INVOKABLE void reportError(DownloadError type, const QString &message, const QString &context = QString());
    
    /**
     * @brief 获取用户友好的错误描述
     * @param error 错误信息
     * @return 用户可理解的错误描述
     */
    Q_INVOKABLE QString userFriendlyMessage(const ErrorInfo &error) const;
    
    /**
     * @brief 获取错误类型的用户友好描述
     * @param type 错误类型
     * @return 描述文本
     */
    Q_INVOKABLE QString errorTypeToString(DownloadError type) const;

signals:
    /**
     * @brief 错误发生信号
     * @param error 错误信息
     */
    void errorOccurred(const ErrorInfo &error);
    
    /**
     * @brief 恢复建议信号
     * @param action 建议的操作描述
     */
    void recoverySuggested(const QString &action);

private:
    explicit ErrorHandler(QObject *parent = nullptr);
    ~ErrorHandler() = default;
    
    static ErrorHandler *m_instance;
};
