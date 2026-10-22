import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// section title, with an optional detail next to it (a count, a unit, a name)
RowLayout {
    property alias text: title.text
    property alias detail: detailLabel.text

    spacing: 8

    Label {
        id: title
        Layout.alignment: Qt.AlignBaseline
        font.pixelSize: 12
        font.letterSpacing: 3
        color: Robosintesi.colors.textSecondary
    }

    // takes the free width, so a kicker with Layout.fillWidth pushes what follows to the right
    Label {
        id: detailLabel
        Layout.alignment: Qt.AlignBaseline
        Layout.fillWidth: true
        font.pixelSize: 13
        color: Robosintesi.colors.textSecondary
    }
}
