import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// icon and label in a tint (connection state, status chips); compact shows the icon only
Rectangle {
    id: pill

    property color tint: Robosintesi.status.ok
    property string iconText
    property string label
    property int iconSize: 20
    property int fontSize: 14
    property int padding: 16
    property int gap: 8
    property bool compact: false

    implicitHeight: 40
    implicitWidth: compact ? implicitHeight : pillRow.implicitWidth + 2 * padding
    radius: height / 2
    color: Qt.alpha(tint, 0.12)

    RowLayout {
        id: pillRow
        anchors.centerIn: parent
        spacing: pill.gap

        RstIcon {
            visible: pill.iconText !== ""
            text: pill.iconText
            size: pill.iconSize
            color: pill.tint
        }

        Label {
            visible: !pill.compact
            text: pill.label
            font.pixelSize: pill.fontSize
            color: pill.tint
        }
    }
}
