import QtQuick
import QtQuick.Templates as T

T.CheckBox {
    id: control

    readonly property real boxSize: 18

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
        implicitWidth: control.boxSize
        implicitHeight: control.boxSize
        radius: Robosintesi.geom.radiusSmall
        color: control.checked ? Robosintesi.colors.text : "transparent"
        border.color: control.visualFocus ? Robosintesi.colors.accent : Robosintesi.colors.text
        border.width: control.visualFocus ? 2 : 1.5

        RstIcon {
            anchors.centerIn: parent
            text: Robosintesi.symbols.check
            size: control.boxSize
            filled: true
            color: Robosintesi.colors.background
            visible: control.checked
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
