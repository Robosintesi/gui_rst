import QtQuick
import QtQuick.Layouts
import Common

RowLayout {
    property real min: -1
    property real max: 1
    property real value: 0.5
    property real valueRef: value
    property int barMargin: 0
    property int barRadius: 4
    property alias bar: bar
    property alias refMarker: refMarker

    id: root
    spacing: 5

    Rectangle {
        id: barBox
        Layout.fillWidth: true
        height: textRect.height //+ 10
        color: Robosintesi.colors.text
        radius: barRadius
        clip: true

        Rectangle {
            id: bar
            visible: value < 0.005 && value > -0.005 ? false : true
            anchors.verticalCenter: barBox.verticalCenter
            height: parent.height - 4 //* barMargin
            radius: barRadius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#357D97" }
                GradientStop { position: 1.0; color: "#005683" }
            }
        }

        Rectangle {
            id: centerLine
            visible: false
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: value > 0 ? bar.left : bar.right
            height: bar.height
            width: 6
            radius: 2
            color: Robosintesi.colors.background
            opacity: 0.5
        }

        ReferenceMarker {
            id: refMarker
            visible: false
            height: bar.height
            width: 8
            fillColor: Qt.darker(CommonProperties.colors.primary)
        }
    }

    Rectangle {
        id: textRect
        color: Robosintesi.colors.text
        opacity: 0.95
        width: 50
        height: valueText.height + 5
        radius: 5

        Text {
            id: valueText
            text: value.toFixed(2)
            anchors.centerIn: parent
            color: Robosintesi.colors.background
        }
    }

}
