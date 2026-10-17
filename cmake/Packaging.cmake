# cmake/Packaging.cmake
# Platform-specific packaging configuration

if(APPLE)
    set_source_files_properties(
        "${CMAKE_SOURCE_DIR}/resources/icons/app_icon.icns"
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources
    )
    target_sources(IndigenousGCS PRIVATE "${CMAKE_SOURCE_DIR}/resources/icons/app_icon.icns")
    set_target_properties(IndigenousGCS PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "Indigenous GCS"
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.indigenousgcs.app"
        MACOSX_BUNDLE_COPYRIGHT "Indigenous GCS Contributors"
        MACOSX_BUNDLE_ICON_FILE "app_icon.icns"
    )
endif()

if(WIN32)
    set_target_properties(IndigenousGCS PROPERTIES
        WIN32_EXECUTABLE TRUE
    )

    # Embed the application icon and version metadata into the .exe. Without
    # this the executable shows a generic icon in Explorer and the taskbar.
    # The .rc is compiled by CMake's built-in RC support on MSVC/MinGW.
    set(_igcs_rc "${CMAKE_SOURCE_DIR}/resources/icons/app_icon.rc")
    if(EXISTS "${_igcs_rc}")
        set_source_files_properties("${_igcs_rc}" PROPERTIES LANGUAGE RC)
        target_sources(IndigenousGCS PRIVATE "${_igcs_rc}")
        set_source_files_properties(
            "${CMAKE_SOURCE_DIR}/resources/icons/app_icon.ico"
            PROPERTIES HEADER_FILE_ONLY TRUE
        )
        target_sources(IndigenousGCS PRIVATE
            "${CMAKE_SOURCE_DIR}/resources/icons/app_icon.ico")
        # The .rc references the icon by relative name, so give the RC compiler
        # the icon's directory as an include path.
        target_include_directories(IndigenousGCS PRIVATE
            "${CMAKE_SOURCE_DIR}/resources/icons")
    endif()
endif()

# CPack common settings
set(CPACK_PACKAGE_NAME "IndigenousGCS")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${PROJECT_DESCRIPTION})
set(CPACK_PACKAGE_VENDOR "Indigenous GCS")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Indigenous GCS")

# Platform-specific CPack settings
if(APPLE)
    set(CPACK_GENERATOR "DragNDrop")
    set(CPACK_BUNDLE_NAME "IndigenousGCS")
    set(CPACK_BUNDLE_ICON "${CMAKE_SOURCE_DIR}/resources/icons/app_icon.icns")
    set(CPACK_DMG_VOLUME_NAME "IndigenousGCS")
    set(CPACK_DMG_FORMAT "UDZO")
    set(CPACK_DMG_BACKGROUND_IMAGE "")
    # DS_Store setup script path (create your own for custom icon placement)
    # set(CPACK_DMG_DS_STORE_SETUP_SCRIPT "${CMAKE_SOURCE_DIR}/cmake/create_dmg_ds_store.scpt")
    set(CPACK_PACKAGE_FILE_NAME "IndigenousGCS-${PROJECT_VERSION}-macOS")

elseif(WIN32)
    set(CPACK_GENERATOR "NSIS")
    set(CPACK_NSIS_DISPLAY_NAME "Indigenous GCS")
    set(CPACK_NSIS_PACKAGE_NAME "IndigenousGCS")
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
    set(CPACK_NSIS_MODIFY_PATH OFF)
    set(CPACK_NSIS_CONTACT "Indigenous GCS Contributors")
    set(CPACK_NSIS_URL_INFO_ABOUT "https://github.com/IndigenousGCS")
    set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")
    set(CPACK_NSIS_BRANDING_TEXT "Indigenous GCS")
    # NSIS installer / uninstaller icons (must be .ico files)
    if(EXISTS "${CMAKE_SOURCE_DIR}/resources/icons/app_icon.ico")
        set(CPACK_NSIS_MUI_ICON    "${CMAKE_SOURCE_DIR}/resources/icons/app_icon.ico")
        set(CPACK_NSIS_MUI_UNIICON "${CMAKE_SOURCE_DIR}/resources/icons/app_icon.ico")
    endif()
    set(CPACK_PACKAGE_FILE_NAME "IndigenousGCS-${PROJECT_VERSION}-Windows")
endif()

include(CPack)
