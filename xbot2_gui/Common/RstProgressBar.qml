import QtQuick
import QtQuick.Controls.Basic

import Common

ProgressBar {
    id: rstProgressBar
    value: 0.5
    padding: 2

    property color progressColor: Robosintesi.colors.foreground
    property color backgroundColor: Robosintesi.colors.text
    property int barRadius: 12

    implicitHeight: 6
    height: 6

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 6
        color: backgroundColor
        radius: barRadius
    }

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: 4

        // Progress indicator for determinate state.
        Rectangle {
            width: rstProgressBar.visualPosition * parent.width
            height: parent.height
            radius: barRadius
            color: progressColor
            visible: !rstProgressBar.indeterminate
        }

        // Scrolling animation for indeterminate state.
        Item {
            anchors.fill: parent
            visible: rstProgressBar.indeterminate
            clip: true

            Row {
                spacing: 20

                Repeater {
                    model: rstProgressBar.width / 40 + 1

                    Rectangle {
                        color: progressColor
                        width: 20
                        height: rstProgressBar.height
                    }
                }
                XAnimator on x {
                    from: 0
                    to: -40
                    loops: Animation.Infinite
                    running: rstProgressBar.indeterminate
                }
            }
        }
    }
}
