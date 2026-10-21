# general purpose Robosintesi app: the main.qml that xbot2_gui (RstMain/main.cpp) loads
qt_add_library(rst_main STATIC)

qt_add_qml_module(rst_main
    URI RstMain
    VERSION 1.0
    QML_FILES
    main.qml
)

target_link_libraries(xbot2_gui PRIVATE rst_mainplugin)
