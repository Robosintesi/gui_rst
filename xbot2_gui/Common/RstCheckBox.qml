import QtQuick
import QtQuick.Controls

import Common

CheckBox {
    id: rstCheckBox

    property color boxColorChecked: Robosintesi.colors.text
    property color boxColorUnchecked: "transparent"
    property color borderColor: Robosintesi.colors.text
    property color checkmarkColor: Robosintesi.colors.background
    property real boxSize: 18
    property real radius: 4

    indicator: Rectangle {
        x: rstCheckBox.leftPadding
        y: parent.height / 2 - height / 2
        width: rstCheckBox.boxSize
        height: rstCheckBox.boxSize
        radius: rstCheckBox.radius
        color: rstCheckBox.checked ? rstCheckBox.boxColorChecked : rstCheckBox.boxColorUnchecked
        border.color: rstCheckBox.borderColor
        border.width: 1.5

        Label {
            anchors.centerIn: parent
            text: "\ue5ca"
            font.pixelSize: rstCheckBox.boxSize //* 0.75
            font.bold: true
            font.family: 'Material Symbols Outlined'
            color: rstCheckBox.checkmarkColor
            visible: rstCheckBox.checked
        }
    }
}
