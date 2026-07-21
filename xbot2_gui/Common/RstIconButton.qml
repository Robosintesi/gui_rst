import QtQuick
import QtQuick.Controls

import Common

Button {
    id: rstIconButton

    property string iconText: ""
    property string iconFont: 'Material Symbols Outlined'
    property int iconSize: CommonProperties.font.h1
    property color iconColor: Robosintesi.colors.background
    property color backgroundColor: Robosintesi.colors.text
    property color borderColor: "transparent"
    property int borderWidth: 0

    anchors.margins: CommonProperties.geom.margins
    anchors.leftMargin: CommonProperties.geom.margins
    anchors.rightMargin: CommonProperties.geom.margins
    anchors.topMargin: CommonProperties.geom.margins
    anchors.bottomMargin: CommonProperties.geom.margins

    flat: true

    background: Rectangle {
        color: rstIconButton.backgroundColor
        radius: CommonProperties.geom.defaultRadius
        border.color: rstIconButton.borderColor
        border.width: rstIconButton.borderWidth
    }

    contentItem: Label {
        text: rstIconButton.iconText
        font.family: rstIconButton.iconFont
        font.pixelSize: rstIconButton.iconSize
        color: rstIconButton.iconColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
