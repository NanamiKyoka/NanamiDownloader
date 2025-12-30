# NanamiDownloader

<p align="center">
  <img src="../src/Icons/icon.svg" alt="NanamiDownloader Logo" width="128" height="128"/>
</p>


<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPLv3-blue.svg" alt="License"></a>
  <a href="#"><img src="https://img.shields.io/badge/platform-Windows-lightgrey.svg" alt="Platform"></a>
  <a href="#"><img src="https://img.shields.io/badge/language-C++20-orange.svg" alt="Language"></a>
  <a href="#"><img src="https://img.shields.io/badge/Qt-6.10+-green.svg" alt="Qt Version"></a>
</p>
NanamiDownloader is a modern, download tool developed with C++20 and Qt6/QML. It integrates several mature open-source download cores from the industry, aiming to provide a simple and efficient download experience.

> ~~(This is my first project, actually made mainly for my own use. It currently only supports Windows; other platforms are coming soon... maybe 🕊️)~~

[简体中文](../README.md) | English

## ✨ Core Features

### 📥 All-in-One Download Engine
This project integrates existing excellent open-source libraries to support multiple protocols:
- **HTTP/HTTPS/FTP**: Utilizes **Aria2** for file downloading, supporting multi-threaded segmented downloading and resume capability.
- **BT/Magnet Links**: Built-in **Libtorrent** library, with native support for parsing Magnet links and .torrent files, including DHT network support.
- **Streaming Video**: Calls **N_m3u8DL-RE** to automatically sniff and download M3U8 format streaming media, merging them automatically upon completion.

### ☁️ Cloud Drive Mounting Assistant
Built-in mounting and management functions for select cloud drives (needs to be manually enabled in "Advanced Settings"):
- **Baidu Netdisk**: Supports login via Refresh Token and mounting the cloud directory. (Baidu Netdisk SVIP users can enjoy high-speed downloads).
- **Thunder Drive**: Supports account/password login and mounting the cloud directory.

### 🖥️ Modern Interaction
- **Clean Interface**: Built with Qt Quick (QML). The interface design pays tribute to **[Motrix](https://motrix.app/)**, striving for neatness and aesthetics.
- **Theme Switching**: Perfectly supports both Light and Dark modes, adapting to different usage environments.
- **Smart Assistance**:
    - 📋 **Clipboard Monitor**: Automatically recognizes copied download links.
    - 🖥️ **System Tray**: Supports minimizing to the tray for silent background downloading.

### ⚙️ Advanced Configuration
- **Network Proxy**: Supports configuring HTTP/SOCKS5 proxies separately for different kernels.
- **Task Management**: Supports pausing, resuming, removing tasks (with optional file deletion), and opening file locations.
- **Performance Tuning**: Exposes kernel parameter adjustments, such as global speed limits, maximum connection counts, User-Agent spoofing, etc.

## 📸 Interface Preview

| Dark Theme | Light Theme |
| :---: | :---: |
| ![dark](./screenshot/dark.png) | ![light](./screenshot/light.png) |

## 📦 Installation & Usage

1. Go to the **[Releases](../../releases)** page to download the latest installation package.
2. Run the installer to complete the installation.
3. Launch the software. It is recommended to verify the default download path in "Basic Settings".
4. **Optional**: If you need cloud drive features, please enable and configure them in "Advanced Settings" -> "Cloud Mount".

## 🔨 Build from Source

If you wish to compile this project from source:

### Prerequisites
- **C++ Compiler**: Supports C++20 standard (MSVC 2019+ or MinGW recommended).
- **Qt**: Version 6.10.1 or higher.
- **CMake**: 3.16+.
- **vcpkg**: Recommended for managing third-party dependencies.

### Build Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/NanamiKyoka/NanamiDownloader.git
   cd NanamiDownloader
   ```

2. **Install Dependencies (using vcpkg)**:
   ```bash
   # Please choose the triplet corresponding to your compiler environment
   vcpkg install libtorrent[openssl] boost openssl --triplet x64-mingw-dynamic
   ```

3. **CMake Configure & Build**:
   Ensure that `QT_ROOT` and `VCPKG_ROOT` environment variables are set.
   
   ```bash
   mkdir build && cd build
   # Note: Replace with your actual vcpkg toolchain file path
   cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=[path/to/vcpkg.cmake]
   cmake --build . --config Release
   ```
   
4. **Deploy External Tools**:
   The program relies on the following external executables. Please place them in the `bin` directory of the build artifacts (or in `/third_party/bin` under the project root, CMake will attempt to copy them automatically):
    - `aria2c.exe`
    - `ffmpeg.exe`
    - `N_m3u8DL-RE.exe`

## 📄 Credits & License

This project is licensed under the **GPLv3** open-source license.

The implementation of this project relies on the following excellent open-source projects:

- **[Qt Framework](https://www.qt.io)** (LGPL v3)
- **[Libtorrent (Rasterbar)](https://github.com/arvidn/libtorrent)** (BSD)
- **[Aria2](https://github.com/aria2/aria2)** (GPLv2+)
- **[FFmpeg](https://ffmpeg.org)** (GPL v3)
- **[N_m3u8DL-RE](https://github.com/nilaoda/N_m3u8DL-RE)** (MIT)
- **[OpenSSL](https://www.openssl.org)** (Apache 2.0)
- **[Boost](https://www.boost.org)** (Boost Software License)

For detailed third-party component information and license statements, please check the [NOTICE](../NOTICE) file.

---

## ⚠️ Disclaimer

**NanamiDownloader** is intended solely as a tool for technical learning and exchange, to allow users to legally download internet resources.

1. This software will **not** collect any user privacy information.
2. The copyright of all resources downloaded using this software belongs to the original authors or their legal holders.
3. The developer is not responsible for the content downloaded by users, nor for any loss or damage caused by the use of this software.
4. The cloud drive mounting function of this software is intended only for facilitating the management of the user's **own** legal data and must not be used for infringing on others' intellectual property rights or for illegal distribution.

**Using this software indicates that you have read and agreed to all terms of this disclaimer.**