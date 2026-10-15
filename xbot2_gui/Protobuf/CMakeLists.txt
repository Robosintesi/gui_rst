find_package(Qt6 COMPONENTS
    Protobuf
    ProtobufQuick
)

add_library(xbot2_gui_proto STATIC)

qt_add_qml_module(xbot2_gui_proto
    URI Protobuf
    VERSION 1.0
    QML_FILES
    SOURCES
    protobuf_deserialization.h
    protobuf_deserialization.cpp

)

# relative to this file, so it also works when the repo is a subdirectory of another project
set(PROTO_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../proto)

qt_add_protobuf(xbot2_gui_msgs
    PROTO_FILES
    ${PROTO_DIR}/generic.proto
    ${PROTO_DIR}/jointstate.proto
    ${PROTO_DIR}/text.proto
    ${PROTO_DIR}/process_output.proto
    ${PROTO_DIR}/theora_packet.proto
    QML
    QML_URI "xbot2_gui.msgs"
)



target_link_libraries(xbot2_gui_proto PRIVATE Qt6::Protobuf Qt6::ProtobufQuick xbot2_gui_msgs)

target_link_libraries(xbot2_gui PRIVATE xbot2_gui_protoplugin xbot2_gui_msgs)


