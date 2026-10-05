# Rashin: the desktop's AI companion app. One binary (qt_add_executable) with
# its QML surfaces compiled into it as the `RashinApp` module, and the C++
# types registered as QML_ELEMENT in the same module. A single artifact keeps
# the app trivially exportable: it depends on Qt only, never on Quickshell, so
# it opens as a normal window under any compositor.
#
# build.sh wraps configure + build and drops the binary on a PATH directory.
cmake_minimum_required(VERSION 3.28)

project(rashin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.6 REQUIRED COMPONENTS Quick Network DBus)

qt_standard_project_setup(REQUIRES 6.6)

file(GLOB rashin_qml CONFIGURE_DEPENDS
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    qml/*.qml qml/*/*.qml qml/*/*/*.qml)

# QML file names must be unique across qml/: each becomes a type named after
# its file at the module root, so pages import nothing to reach primitives.
foreach(qml_file IN LISTS rashin_qml)
    get_filename_component(qml_name "${qml_file}" NAME)
    set_source_files_properties("${qml_file}" PROPERTIES QT_RESOURCE_ALIAS "${qml_name}")
    file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/${qml_file}" singleton_pragma LIMIT_COUNT 1 REGEX "^pragma Singleton")
    if(singleton_pragma)
        set_source_files_properties("${qml_file}" PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
    endif()
endforeach()

qt_add_executable(rashin-app
    main.cpp
    src/chatbridge.cpp src/chatbridge.hpp
    src/daemonclient.cpp src/daemonclient.hpp
    src/markdown.cpp src/markdown.hpp
    src/preferences.cpp src/preferences.hpp
    src/quickask.cpp src/quickask.hpp
    src/notify.cpp src/notify.hpp
    src/clipboard.hpp
    src/runner.hpp
)

qt_add_qml_module(rashin-app
    URI RashinApp
    VERSION 1.0
    QML_FILES ${rashin_qml}
)

# qmltyperegistrar includes the QML_ELEMENT headers by bare name.
target_include_directories(rashin-app PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

# The chat plane rides the daemon's follow process; the request plane rides
# loopback HTTP; notifications ride the session bus. No compositor APIs.
target_link_libraries(rashin-app PRIVATE Qt6::Quick Qt6::Network Qt6::DBus)

set_target_properties(rashin-app PROPERTIES
    OUTPUT_NAME "rashin-app"
    INSTALL_RPATH "$ORIGIN"
    BUILD_WITH_INSTALL_RPATH ON)

install(TARGETS rashin-app DESTINATION bin)
