import QtQuick
import QtQuick.Controls

// pill button with an optional icon (style 11a): Primary filled, Secondary tonal, Destructive red
Button {
    id: rstButton

    enum Kind { Primary, Secondary, Destructive }

    property int kind: RstButton.Primary
    property color backgroundColor: [Robosintesi.colors.text, Qt.alpha(Robosintesi.colors.text, 0.08),
                                     Qt.alpha(Robosintesi.status.err, 0.14)][kind]
    property color textColor: [Robosintesi.colors.background, Robosintesi.colors.text,
                               Robosintesi.status.errText][kind]
    property real radius: height / 2
    property string iconText: ""
    // filled and heavier, except in the tonal buttons
    property bool iconFilled: kind !== RstButton.Secondary
    property int iconSize: 24

    implicitHeight: 56
    leftPadding: iconText !== "" ? 18 : 24
    rightPadding: 24
    spacing: 8
    font.pixelSize: 17

    background: Rectangle {
        radius: rstButton.radius
        color: rstButton.backgroundColor

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: rstButton.down
            color: Qt.alpha(rstButton.textColor, 0.12)
        }
    }

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            anchors.centerIn: parent
            spacing: rstButton.spacing

            RstIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: rstButton.iconText !== ""
                text: rstButton.iconText
                size: rstButton.iconSize
                filled: rstButton.iconFilled
                color: rstButton.textColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: rstButton.text
                font: rstButton.font
                color: rstButton.textColor
            }
        }
    }
}
