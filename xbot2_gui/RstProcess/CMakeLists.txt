# Process page of the Robosintesi apps (IIT's Launcher stays as it is)
qt_add_library(rst_process STATIC)

qt_add_qml_module(rst_process
    URI RstProcess
    VERSION 1.0
    QML_FILES
    Process.qml
)

target_link_libraries(xbot2_gui PRIVATE rst_processplugin)
