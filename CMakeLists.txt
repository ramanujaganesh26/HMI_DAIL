cmake_minimum_required(VERSION 3.16)

project(HMIMI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

qt_add_executable(appHMIMI
    main.cpp
    src/SpeedometerController.h
    src/SpeedometerController.cpp
    src/TelemetryModel.h
    src/TelemetryModel.cpp
    src/MatlabExporter.h
    src/MatlabExporter.cpp
)

qt_add_qml_module(appHMIMI
    URI HMIMI
    VERSION 1.0
    SOURCES
        src/SpeedometerController.h
        src/SpeedometerController.cpp
        src/TelemetryModel.h
        src/TelemetryModel.cpp
        src/MatlabExporter.h
        src/MatlabExporter.cpp
    QML_FILES
        Main.qml
        Theme.qml
        components/HeaderBar.qml
        components/SpeedGauge.qml
        components/RpmGearWidget.qml
        components/TelemetryChart.qml
        components/TelemetryTable.qml
        components/MatlabExportModal.qml
)

set_target_properties(appHMIMI PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_include_directories(appHMIMI PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(appHMIMI
    PRIVATE Qt6::Quick
)

install(TARGETS appHMIMI
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

