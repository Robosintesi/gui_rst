import QtQuick
import QtQuick.Templates as T

T.ProgressBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 1
    opacity: enabled ? 1 : Robosintesi.geom.disabledOpacity

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: 4
        clip: true

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: height / 2
            color: Robosintesi.colors.foreground
            visible: !control.indeterminate
        }

        // stripes scrolling while the amount of work is unknown
        Row {
            spacing: 20
            visible: control.indeterminate

            Repeater {
                model: control.width / 40 + 1

                Rectangle {
                    color: Robosintesi.colors.foreground
                    width: 20
                    height: control.height
                }
            }

            XAnimator on x {
                from: 0
                to: -40
                loops: Animation.Infinite
                running: control.indeterminate && control.visible
            }
        }
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 6
        radius: height / 2
        color: Robosintesi.colors.text
    }
}
