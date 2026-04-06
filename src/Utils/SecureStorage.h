/**
 * @file SecureStorage.h
 * @brief 安全存储类，使用 Windows DPAPI 加密敏感信息
 * 
 * 该类负责：
 * - 使用 DPAPI 加密/解密敏感数据
 * - 加密后的数据与当前 Windows 用户绑定
 * - 提供简单的 API 存储和检索敏感信息
 */

#pragma once

#include <QString>
#include <QSettings>
#include <QByteArray>

/**
 * @class SecureStorage
 * @brief 安全存储管理器
 * 
 * 使用 Windows DPAPI (Data Protection API) 加密敏感数据。
 * 加密后的数据只能由同一 Windows 用户解密。
 */
class SecureStorage
{
public:
    /**
     * @brief 存储加密的敏感数据
     * @param key 存储键名
     * @param value 要存储的明文值
     * @return 是否成功
     */
    static bool store(const QString &key, const QString &value);
    
    /**
     * @brief 检索解密后的敏感数据
     * @param key 存储键名
     * @param defaultValue 默认值（如果不存在）
     * @return 解密后的明文值
     */
    static QString retrieve(const QString &key, const QString &defaultValue = QString());
    
    /**
     * @brief 删除存储的敏感数据
     * @param key 存储键名
     */
    static void remove(const QString &key);
    
    /**
     * @brief 检查是否存在指定的键
     * @param key 存储键名
     * @return 是否存在
     */
    static bool contains(const QString &key);

private:
    /**
     * @brief 使用 DPAPI 加密数据
     * @param data 明文数据
     * @return 加密后的 Base64 字符串
     */
    static QByteArray encrypt(const QString &data);
    
    /**
     * @brief 使用 DPAPI 解密数据
     * @param encryptedData 加密的 Base64 字符串
     * @return 解密后的明文
     */
    static QString decrypt(const QByteArray &encryptedData);
    
    static QSettings& settings();
};
