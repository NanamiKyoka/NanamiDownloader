cmake_minimum_required(VERSION 3.16)

project(NanamiDownloader)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets Quick Network WebSockets QuickControls2 Concurrent)

find_package(LibtorrentRasterbar CONFIG REQUIRED)
find_package(Boost REQUIRED)
find_package(OpenSSL REQUIRED)

qt_add_executable(NanamiDownloader
        src/main.cpp
        src/Utils/CursorPosProvider.h
        src/Utils/SingleInstanceManager.cpp
        src/Utils/SingleInstanceManager.h
        src/Utils/Logger.cpp
        src/Utils/Logger.h

        src/Core/Aria2Service.cpp
        src/Core/Aria2Service.h
        src/Core/M3u8Service.cpp
        src/Core/M3u8Service.h
        src/Core/TorrentService.cpp
        src/Core/TorrentService.h
        src/Core/TaskModel.cpp
        src/Core/TaskModel.h
        src/Core/LinkHelper.cpp
        src/Core/LinkHelper.h
        src/Core/SettingsManager.cpp
        src/Core/SettingsManager.h
        src/Core/ClipboardHelper.cpp
        src/Core/ClipboardHelper.h
        src/Core/DownloadManager.cpp
        src/Core/DownloadManager.h
        src/Core/AutoStartManager.cpp
        src/Core/AutoStartManager.h

        src/Drivers/BaiduNetdisk/BaiduService.cpp
        src/Drivers/BaiduNetdisk/BaiduService.h
        src/Drivers/BaiduNetdisk/BaiduFileModel.cpp
        src/Drivers/BaiduNetdisk/BaiduFileModel.h

        src/Drivers/Thunder/ThunderService.cpp
        src/Drivers/Thunder/ThunderService.h
        src/Drivers/Thunder/ThunderFileModel.cpp
        src/Drivers/Thunder/ThunderFileModel.h

        src/UI/ThemeController.cpp
        src/UI/ThemeController.h

        resources.qrc
        NanamiDownloader.rc
)

target_link_libraries(NanamiDownloader PRIVATE
        Qt6::Core
        Qt6::Widgets
        Qt6::Quick
        Qt6::Network
        Qt6::WebSockets
        Qt6::QuickControls2
        Qt6::Concurrent
        LibtorrentRasterbar::torrent-rasterbar
        OpenSSL::SSL
        OpenSSL::Crypto
)

find_package(Qt6 OPTIONAL_COMPONENTS LinguistTools)

if (TARGET Qt6::lupdate AND TARGET Qt6::lrelease)

    set(TRANSLATION_FILES
            ${CMAKE_SOURCE_DIR}/translations/zh_CN.ts
            ${CMAKE_SOURCE_DIR}/translations/zh_TW.ts
            ${CMAKE_SOURCE_DIR}/translations/en_US.ts
            ${CMAKE_SOURCE_DIR}/translations/ja_JP.ts
            ${CMAKE_SOURCE_DIR}/translations/ko_KR.ts
    )

    qt_add_translations(NanamiDownloader
            TS_FILES ${TRANSLATION_FILES}
            RESOURCE_PREFIX "/translations"
    )

    set(TS_UPDATE_SOURCES
            src/UI/Main.qml
            src/UI/NewTaskDialog.qml
            src/UI/SettingsView.qml
            src/UI/BasicSettingsView.qml
            src/UI/AdvancedSettingsView.qml
            src/UI/Sidebar.qml
            src/UI/TaskListView.qml
            src/UI/CloseConfirmDialog.qml
            src/UI/DeleteConfirmDialog.qml
            src/UI/AddTorrentDialog.qml
            src/UI/OverwriteConfirmDialog.qml
            src/UI/TaskDetailView.qml
            src/UI/CloudMountSettingsView.qml
            src/UI/AboutDialog.qml

            src/UI/Drivers/BaiduView.qml
            src/UI/Drivers/ThunderView.qml
    )

    add_custom_target(update_translations
            COMMAND Qt6::lupdate ${TS_UPDATE_SOURCES} -ts ${TRANSLATION_FILES}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )
endif ()

set_target_properties(NanamiDownloader PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

install(TARGETS NanamiDownloader RUNTIME DESTINATION bin)

if (WIN32)

    add_custom_command(TARGET NanamiDownloader POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/bin
            COMMAND ${CMAKE_COMMAND} -D SOURCE_DIR=${CMAKE_SOURCE_DIR}/third_party/bin -D TARGET_DIR=${CMAKE_BINARY_DIR}/bin -P ${CMAKE_SOURCE_DIR}/cmake/copy_third_party.cmake
    )

    if (CMAKE_BUILD_TYPE STREQUAL "Release")
        find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS ${QT_ROOT}/bin)

        set_target_properties(${PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE TRUE )

        if (NOT WINDEPLOYQT_EXECUTABLE AND TARGET Qt6::windeployqt)
            get_target_property(WINDEPLOYQT_EXECUTABLE Qt6::windeployqt IMPORTED_LOCATION)
        endif()

        if (WINDEPLOYQT_EXECUTABLE)
            add_custom_command(TARGET NanamiDownloader POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/bin
                    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:NanamiDownloader> ${CMAKE_BINARY_DIR}/bin/
                    COMMAND ${WINDEPLOYQT_EXECUTABLE}
                    --qmldir ${CMAKE_SOURCE_DIR}/src/UI
                    --no-translations
                    --compiler-runtime
                    ${CMAKE_BINARY_DIR}/bin/NanamiDownloader.exe
            )
        endif ()
    endif ()
endif ()