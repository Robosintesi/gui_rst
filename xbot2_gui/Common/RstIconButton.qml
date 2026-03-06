import QtQuick
import QtQuick.Controls

import Common

Button {
    id: rstIconButton

    property string iconText: ""
    property string iconFont: 'Material Symbols Outlined'
    property int iconSize: CommonProperties.font.h1

    anchors.margins: CommonProperties.geom.margins
    anchors.leftMargin: CommonProperties.geom.margins
    anchors.rightMargin: CommonProperties.geom.margins
    anchors.topMargin: CommonProperties.geom.margins
    anchors.bottomMargin: CommonProperties.geom.margins

    flat: true

    background: Rectangle {
        color: Robosintesi.colors.text
        radius: CommonProperties.geom.defaultRadius
        // border.color: Robosintesi.colors.text
        border.width: 0
    }

    contentItem: Label {
        text: rstIconButton.iconText
        font.family: rstIconButton.iconFont
        font.pixelSize: rstIconButton.iconSize
        color: Robosintesi.colors.background
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
