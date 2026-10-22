import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// segmented control; a tap only emits activated, the owner sets currentIndex
Rectangle {
    id: root

    property var model: []
    property int currentIndex: 0
    property int itemHeight: 36
    property int fontSize: 14
    // the items share the whole width
    property bool fillWidth: false

    signal activated(int index)

    implicitWidth: row.implicitWidth + 8
    implicitHeight: itemHeight + 8
    radius: 14
    color: Qt.alpha(Robosintesi.colors.background, 0.5)

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        Repeater {
            model: root.model

            AbstractButton {
                id: item

                required property int index
                required property string modelData
                readonly property bool selected: index === root.currentIndex

                Layout.fillWidth: root.fillWidth
                Layout.preferredHeight: root.itemHeight
                implicitWidth: implicitContentWidth + leftPadding + rightPadding
                leftPadding: 12
                rightPadding: 12
                text: modelData

                onClicked: root.activated(index)

                background: Rectangle {
                    radius: 10
                    color: item.selected ? Robosintesi.colors.text : "transparent"
                }

                contentItem: Label {
                    text: item.text
                    font.pixelSize: root.fontSize
                    color: item.selected ? Robosintesi.colors.background : Robosintesi.colors.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
