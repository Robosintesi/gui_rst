import QtQuick
import QtQuick.Controls

// round tonal icon button (style 11a), 48 px unless the layout says otherwise; checked as pressed
AbstractButton {
    id: rstIconButton

    property string iconText: ""
    property int iconSize: 24

    implicitWidth: 48
    implicitHeight: 48

    background: Rectangle {
        radius: height / 2
        color: Qt.alpha(Robosintesi.colors.text, rstIconButton.down || rstIconButton.checked ? 0.16 : 0.08)
    }

    contentItem: RstIcon {
        text: rstIconButton.iconText
        size: rstIconButton.iconSize
    }
}
