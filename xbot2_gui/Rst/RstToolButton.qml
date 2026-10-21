import QtQuick
import QtQuick.Controls

// button of the toolbars over the 3D views: icon, with the text as a label (TextBesideIcon) or
// as a tooltip (IconOnly)
AbstractButton {
    id: tool

    property string iconText

    display: AbstractButton.IconOnly
    implicitWidth: display === AbstractButton.IconOnly ? 48 : implicitContentWidth + 32
    implicitHeight: 48

    ToolTip.visible: hovered && display === AbstractButton.IconOnly
    ToolTip.text: text

    background: Rectangle {
        radius: 12
        color: tool.checked ? Qt.alpha(Robosintesi.colors.text, 0.16)
                            : tool.down ? Qt.alpha(Robosintesi.colors.text, 0.08) : "transparent"
    }

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            RstIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: tool.iconText
                size: 22
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: tool.display !== AbstractButton.IconOnly
                text: tool.text
                font.pixelSize: 15
                color: Robosintesi.colors.text
            }
        }
    }
}
