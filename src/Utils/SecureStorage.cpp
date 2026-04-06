/**
 * @file SecureStorage.cpp
 * @brief 安全存储类实现
 */

#include "SecureStorage.h"
#include <QDebug>
#include <QCoreApplication>

#ifdef Q_OS_WIN
#include <windows.h>
#include <dpapi.h>
#pragma comment(lib, "crypt32.lib")
#endif

QSettings& SecureStorage::settings()
{
    static QSettings s("NanamiDownloader", "SecureStorage");
    return s;
}

bool SecureStorage::store(const QString &key, const QString &value)
{
    if (key.isEmpty()) {
        return false;
    }

    if (value.isEmpty()) {
        remove(key);
        return true;
    }

    QByteArray encrypted = encrypt(value);
    if (encrypted.isEmpty()) {
        qWarning() << "SecureStorage: Failed to encrypt value for key:" << key;
        return false;
    }

    settings().setValue(key, encrypted);
    settings().sync();
    return true;
}

QString SecureStorage::retrieve(const QString &key, const QString &defaultValue)
{
    if (key.isEmpty()) {
        return defaultValue;
    }

    if (!settings().contains(key)) {
        return defaultValue;
    }

    QByteArray encrypted = settings().value(key).toByteArray();
    if (encrypted.isEmpty()) {
        return defaultValue;
    }

    QString decrypted = decrypt(encrypted);
    if (decrypted.isNull()) {
        qWarning() << "SecureStorage: Failed to decrypt value for key:" << key;
        return defaultValue;
    }

    return decrypted;
}

void SecureStorage::remove(const QString &key)
{
    settings().remove(key);
    settings().sync();
}

bool SecureStorage::contains(const QString &key)
{
    return settings().contains(key);
}

QByteArray SecureStorage::encrypt(const QString &data)
{
#ifdef Q_OS_WIN
    QByteArray utf8Data = data.toUtf8();
    DATA_BLOB inputBlob;
    inputBlob.pbData = reinterpret_cast<BYTE*>(utf8Data.data());
    inputBlob.cbData = static_cast<DWORD>(utf8Data.size());

    DATA_BLOB outputBlob;
    ZeroMemory(&outputBlob, sizeof(outputBlob));

    BOOL result = CryptProtectData(
        &inputBlob,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        CRYPTPROTECT_UI_FORBIDDEN,
        &outputBlob
    );

    if (!result) {
        qWarning() << "SecureStorage: CryptProtectData failed, error:" << GetLastError();
        return QByteArray();
    }

    QByteArray encrypted(reinterpret_cast<char*>(outputBlob.pbData), outputBlob.cbData);
    LocalFree(outputBlob.pbData);

    return encrypted.toBase64();
#else
    qWarning() << "SecureStorage: Encryption not supported on this platform";
    return QByteArray();
#endif
}

QString SecureStorage::decrypt(const QByteArray &encryptedData)
{
#ifdef Q_OS_WIN
    QByteArray rawEncrypted = QByteArray::fromBase64(encryptedData);
    
    DATA_BLOB inputBlob;
    inputBlob.pbData = reinterpret_cast<BYTE*>(rawEncrypted.data());
    inputBlob.cbData = static_cast<DWORD>(rawEncrypted.size());

    DATA_BLOB outputBlob;
    ZeroMemory(&outputBlob, sizeof(outputBlob));

    BOOL result = CryptUnprotectData(
        &inputBlob,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        CRYPTPROTECT_UI_FORBIDDEN,
        &outputBlob
    );

    if (!result) {
        qWarning() << "SecureStorage: CryptUnprotectData failed, error:" << GetLastError();
        return QString();
    }

    QString decrypted = QString::fromUtf8(reinterpret_cast<char*>(outputBlob.pbData), outputBlob.cbData);
    LocalFree(outputBlob.pbData);

    return decrypted;
#else
    Q_UNUSED(encryptedData);
    qWarning() << "SecureStorage: Decryption not supported on this platform";
    return QString();
#endif
}
