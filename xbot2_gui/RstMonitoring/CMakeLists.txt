# Monitoring page of the Robosintesi apps (IIT's Monitoring stays as it is) and RstViewer, the 3D
# view the project pages use too
qt_add_library(rst_monitoring STATIC)

qt_add_qml_module(rst_monitoring
    URI RstMonitoring
    VERSION 1.0
    QML_FILES
    Format.js
    JointCommand.qml
    JointRow.qml
    Monitoring.qml
    RobotView.qml
    RstViewer.qml
)

target_link_libraries(xbot2_gui PRIVATE rst_monitoringplugin)
