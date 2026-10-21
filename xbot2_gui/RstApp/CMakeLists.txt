# Robosintesi app window (RstWindow) and rst::runApp(), which an app main.cpp calls
qt_add_library(rst_app STATIC)

qt_add_qml_module(rst_app
    URI RstApp
    VERSION 1.0
    QML_FILES
    RstWindow.qml
)

target_sources(rst_app PRIVATE rstapp.h rstapp.cpp)
target_include_directories(rst_app PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(rst_app PRIVATE Qt6::Widgets Qt6::Quick Qt6::QuickControls2)

if(NOT EMSCRIPTEN)
    target_link_libraries(rst_app PRIVATE Qt6::WebView)
endif()

target_link_libraries(xbot2_gui PRIVATE rst_app rst_appplugin)
