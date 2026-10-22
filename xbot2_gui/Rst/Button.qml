import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

// Button of the Rst style (11a): pill, plus disabled, focus, flat, checked and icon
T.Button {
    id: control

    readonly property color fillColor: checked ? Robosintesi.colors.foreground : Robosintesi.colors.text
    readonly property color labelColor: flat || checked ? Robosintesi.colors.text
                                                        : Robosintesi.colors.background

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 8
    horizontalPadding: 16
    spacing: 6
    font.pixelSize: Robosintesi.fonts.control
    opacity: enabled ? 1 : Robosintesi.geom.disabledOpacity

    icon.width: 24
    icon.height: 24
    icon.color: labelColor

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display
        icon: control.icon
        text: control.text
        font: control.font
        color: control.labelColor
    }

    background: Rectangle {
        implicitWidth: 64
        implicitHeight: Robosintesi.geom.touchHeight
        radius: height / 2
        color: {
            if (control.flat)
                return control.down ? Qt.rgba(control.fillColor.r, control.fillColor.g,
                                              control.fillColor.b, 0.2)
                                    : "transparent"
            return control.down ? Qt.darker(control.fillColor, 1.2) : control.fillColor
        }
        border.color: control.visualFocus ? Robosintesi.colors.accent : Robosintesi.colors.background
        border.width: control.visualFocus ? 2 : 0
    }
}
