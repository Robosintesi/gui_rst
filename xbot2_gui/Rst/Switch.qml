import QtQuick
import QtQuick.Templates as T

T.Switch {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding,
                             Robosintesi.geom.touchHeight)

    padding: 6
    spacing: 8
    font.pixelSize: Robosintesi.fonts.control
    font.capitalization: Font.AllLowercase
    opacity: enabled ? 1 : Robosintesi.geom.disabledOpacity

    indicator: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        implicitWidth: 40
        implicitHeight: 20
        radius: height / 2
        color: control.checked ? Robosintesi.colors.text : Robosintesi.colors.foreground
        border.color: control.visualFocus ? Robosintesi.colors.accent : Robosintesi.colors.text
        border.width: 2

        Rectangle {
            readonly property real size: control.checked ? 16 : 12

            x: control.checked ? parent.width - width - 2 : 4
            y: (parent.height - height) / 2
            width: size
            height: size
            radius: size / 2
            color: control.checked ? Robosintesi.colors.foreground : Robosintesi.colors.text

            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }
        }
    }

    contentItem: Text {
        leftPadding: control.indicator.width + control.spacing
        text: control.text
        font: control.font
        color: Robosintesi.colors.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
