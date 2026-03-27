execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET_DIR})

# 第三方可执行文件列表
set(FILE_LIST
    "aria2c.exe"
    "ffmpeg.exe"
    "N_m3u8DL-RE.exe"
)

# 复制可执行文件
foreach(FILE_NAME ${FILE_LIST})
    set(SOURCE_FILE "${SOURCE_DIR}/${FILE_NAME}")
    set(TARGET_FILE "${TARGET_DIR}/${FILE_NAME}")
    
    if(EXISTS "${SOURCE_FILE}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SOURCE_FILE}" "${TARGET_FILE}"
        )
        message(STATUS "Copied ${FILE_NAME} to build directory")
    else()
        message(STATUS "File ${FILE_NAME} not found at ${SOURCE_FILE}, skipping copy")
    endif()
endforeach()

# 复制 DLL 文件 (从 third_party/dll 目录)
set(DLL_SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/dll")
if(EXISTS "${DLL_SOURCE_DIR}")
    file(GLOB DLL_FILES "${DLL_SOURCE_DIR}/*.dll")
    foreach(DLL_FILE ${DLL_FILES})
        get_filename_component(DLL_NAME ${DLL_FILE} NAME)
        set(TARGET_DLL "${TARGET_DIR}/${DLL_NAME}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DLL_FILE}" "${TARGET_DLL}"
        )
        message(STATUS "Copied ${DLL_NAME} to build directory")
    endforeach()
else()
    message(STATUS "DLL directory ${DLL_SOURCE_DIR} not found, skipping DLL copy")
endif()