# Robosintesi theme, also the Qt Quick Controls style "Rst" (Material draws the other controls)
qt_add_library(rst STATIC)

set_source_files_properties(Robosintesi.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(rst
    URI Rst
    VERSION 1.0
    QML_FILES
    Robosintesi.qml
    RstButton.qml
    RstIcon.qml
    RstIconButton.qml
    RstKicker.qml
    RstLog.qml
    RstPanel.qml
    RstPill.qml
    RstReadout.qml
    RstSegmented.qml
    RstToolButton.qml
    Button.qml
    CheckBox.qml
    Switch.qml
    Slider.qml
    ProgressBar.qml
    Popup.qml
    RESOURCES
    fonts/Inter_18pt-Regular.ttf
    fonts/Inter_18pt-Bold.ttf
    fonts/Inter_18pt-SemiBold.ttf
    fonts/MaterialSymbolsRoundedThin.ttf
    fonts/MaterialSymbolsRoundedFilled.ttf
    fonts/SpaceGrotesk-Bold.ttf
    logos/ideogram_black.svg
    logos/ideogram_blue.svg
    logos/ideogram_cool_gray.svg
    logos/logotype_black.svg
    logos/logotype_blue.svg
    logos/logotype_cool_gray.svg
)

target_link_libraries(xbot2_gui PRIVATE rstplugin)
