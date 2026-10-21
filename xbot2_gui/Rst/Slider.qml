import QtQuick
import QtQuick.Templates as T

// shortcut: horizontal only (the fork has no vertical Slider), add a vertical layout if one appears
T.Slider {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitHandleWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitHandleHeight + topPadding + bottomPadding,
                             Robosintesi.geom.touchHeight)

    padding: 6
    opacity: enabled ? 1 : Robosintesi.geom.disabledOpacity

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        implicitWidth: 20
        implicitHeight: 20
        radius: width / 2
        color: control.pressed ? Qt.darker(Robosintesi.colors.text, 1.25) : Robosintesi.colors.text
        border.color: control.visualFocus ? Robosintesi.colors.accent : color
        border.width: control.visualFocus ? 2 : 1
    }

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        implicitWidth: 200
        implicitHeight: 4
        width: control.availableWidth
        height: implicitHeight
        radius: height / 2
        color: Robosintesi.colors.text

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: Robosintesi.colors.accent
        }
    }
}
