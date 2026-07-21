import QtQuick
import QtQuick.Controls

import Common

Button {
    id: rstButton

    property color backgroundColor: Robosintesi.colors.text
    property color textColor: Robosintesi.colors.background
    property real radius: CommonProperties.geom.defaultRadius

    font.pixelSize: CommonProperties.font.h3
    // font.bold: true

    background: Rectangle {
        color: rstButton.down ? Qt.darker(rstButton.backgroundColor, 1.2) : rstButton.backgroundColor
        radius: rstButton.radius
        border.color: rstButton.backgroundColor
        border.width: 1
    }

    contentItem: Text {
        text: rstButton.text
        font: rstButton.font
        color: rstButton.textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
