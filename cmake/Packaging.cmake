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
endif()

# CPack
set(CPACK_PACKAGE_NAME "IndigenousGCS")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${PROJECT_DESCRIPTION})
set(CPACK_PACKAGE_VENDOR "Indigenous GCS")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Indigenous GCS")

if(APPLE)
    set(CPACK_GENERATOR "DragNDrop")
    set(CPACK_DMG_VOLUME_NAME "IndigenousGCS")
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
endif()

include(CPack)
