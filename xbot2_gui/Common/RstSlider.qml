import QtQuick
import QtQuick.Controls.Basic

import Common

Slider {
    id: rstSlider
    value: 0.5

    background: Rectangle {
        x: rstSlider.leftPadding
        y: rstSlider.topPadding + rstSlider.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 4
        width: rstSlider.availableWidth
        height: implicitHeight
        radius: 6
        color: Robosintesi.colors.text

        Rectangle {
            width: rstSlider.visualPosition * parent.width
            height: parent.height
            color: Robosintesi.colors.accent
            radius: 6
        }
    }

    handle: Rectangle {
        x: rstSlider.leftPadding + rstSlider.visualPosition * (rstSlider.availableWidth - width)
        y: rstSlider.topPadding + rstSlider.availableHeight / 2 - height / 2
        implicitWidth: 20
        implicitHeight: 20
        radius: 13
        color: rstSlider.pressed ? Qt.darker(Robosintesi.colors.text, 1.25) : Robosintesi.colors.text
        border.color: rstSlider.pressed ? Qt.darker(Robosintesi.colors.text, 1.25) : Robosintesi.colors.text
    }
}
