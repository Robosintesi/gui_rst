# Network page of the Robosintesi apps (IIT's Home/HelloScreen stays as it is)
qt_add_library(rst_network STATIC)

qt_add_qml_module(rst_network
    URI RstNetwork
    VERSION 1.0
    QML_FILES
    Network.qml
)

target_link_libraries(xbot2_gui PRIVATE rst_networkplugin)
