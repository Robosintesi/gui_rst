import QtQuick
import QtQuick.Controls

import Common

Switch {
    id: rstSwitch

    property color boxColorOn: Robosintesi.colors.text
    property color boxColorOff: Robosintesi.colors.foreground
    property color pinColorOn: Robosintesi.colors.foreground
    property color pinColorOff: Robosintesi.colors.text

    indicator: Rectangle {
        x: rstSwitch.leftPadding
        y: parent.height / 2 - height / 2
        width: 40
        height: 20
        radius: height / 2
        color: rstSwitch.checked ? rstSwitch.boxColorOn : rstSwitch.boxColorOff
        border.color: rstSwitch.checked ? rstSwitch.boxColorOn : Robosintesi.colors.text
        border.width: 2

        Rectangle {
            x: rstSwitch.checked ? parent.width - width - 2 : 4
            y: (parent.height - height) / 2
            width: rstSwitch.checked ? 16 : 12
            height: rstSwitch.checked ? 16 : 12
            radius: height / 2
            color: rstSwitch.checked ? rstSwitch.pinColorOn : rstSwitch.pinColorOff

            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }
        }
    }
}
