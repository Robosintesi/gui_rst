import QtQuick
import QtQuick.Layouts

// panel of a page; the children go in a column
Rectangle {
    id: panel

    default property alias content: column.data
    property alias spacing: column.spacing
    property int padding: 24
    property int horizontalPadding: padding

    radius: Robosintesi.geom.radius
    color: Robosintesi.colors.panel
    implicitWidth: column.implicitWidth + 2 * horizontalPadding
    implicitHeight: column.implicitHeight + 2 * padding

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.topMargin: panel.padding
        anchors.bottomMargin: panel.padding
        anchors.leftMargin: panel.horizontalPadding
        anchors.rightMargin: panel.horizontalPadding
        spacing: 16
    }
}
