import QtQuick
import QtQuick.Templates as T

// Popup of the Rst style: rounded panel on the background color, with a thin border
T.Popup {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 20

    background: Rectangle {
        radius: Robosintesi.geom.radius
        color: Robosintesi.colors.background
        border.color: Qt.alpha(Robosintesi.colors.text, 0.14)
    }

    T.Overlay.modal: Rectangle {
        color: Qt.alpha(Robosintesi.brand.black, 0.5)
    }

    T.Overlay.modeless: Rectangle {
        color: Qt.alpha(Robosintesi.brand.black, 0.12)
    }
}
