execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET_DIR})

set(FILE_LIST
    "aria2c.exe"
    "ffmpeg.exe" 
    "N_m3u8DL-RE.exe"
)

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