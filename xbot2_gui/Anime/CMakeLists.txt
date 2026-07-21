add_library(xbot2_gui_anime STATIC)

qt_add_qml_module(xbot2_gui_anime
    URI Anime
    VERSION 1.0
    QML_FILES
    Anime.qml
    ScenarioPopup.qml
    QML_FILES Anime.js
)

target_link_libraries(xbot2_gui PRIVATE xbot2_gui_animeplugin)
